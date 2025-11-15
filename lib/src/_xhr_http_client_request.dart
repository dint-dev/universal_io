// Copyright 2020 terrier989@gmail.com.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:typed_data/typed_buffers.dart';

import '_xhr_http_client_response.dart';
import '_exports_in_browser.dart';
import '_http_headers_impl.dart';
import '_io_sink_base.dart';
import 'js/_xhr.dart';

final class XhrHttpClientRequest extends BrowserHttpClientRequest
    with IOSinkBase {
  final BrowserHttpClient client;

  String? _browserResponseType;

  @override
  final String method;

  @override
  final Uri uri;

  @override
  final HttpHeaders headers = HttpHeadersImpl('1.1');

  final _completer = Completer<BrowserHttpClientResponse>();

  Future? _addStreamFuture;

  @override
  final List<Cookie> cookies = <Cookie>[];

  final bool _supportsBody;

  Future<BrowserHttpClientResponse>? _result;

  final _buffer = Uint8Buffer();

  @override
  bool bufferOutput = false;

  @override
  int contentLength = -1;

  @override
  bool followRedirects = true;

  @override
  int maxRedirects = 5;

  @override
  bool persistentConnection = false;

  @internal
  XhrHttpClientRequest(this.client, this.method, this.uri)
    : _supportsBody = _httpMethodSupportsBody(method) {
    // Add "User-Agent" header
    final userAgent = client.userAgent;
    if (userAgent != null) {
      headers.set(HttpHeaders.userAgentHeader, userAgent);
    }

    // Set default values
    browserCredentialsMode = client.browserCredentialsMode;
    followRedirects = true;
    maxRedirects = 5;
    bufferOutput = true;
  }

  @override
  String? get browserResponseType => _browserResponseType;

  @override
  set browserResponseType(String? value) {
    if (value != null) {
      const validValues = <String>{
        'arraybuffer',
        'blob',
        'document',
        'json',
        'text',
      };
      if (!validValues.contains(value)) {
        throw ArgumentError.value(value);
      }
    }
    _browserResponseType = value;
  }

  @override
  HttpConnectionInfo? get connectionInfo => null;

  @override
  Future<HttpClientResponse> get done {
    return _completer.future;
  }

  @override
  void abort([Object? exception, StackTrace? stackTrace]) {}

  @override
  void add(List<int> event) {
    _checkAddRequirements();
    _buffer.addAll(event);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    if (_completer.isCompleted) {
      throw StateError('HTTP request is closed already');
    }
    _completer.completeError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    _checkAddRequirements();
    final future = stream
        .listen(
          (item) {
            _buffer.addAll(item);
          },
          onError: (error) {
            addError(error);
          },
          cancelOnError: true,
        )
        .asFuture(null);
    _addStreamFuture = future;
    await future;
    _addStreamFuture = null;
  }

  @override
  Future<BrowserHttpClientResponse> close() async {
    return _result ??= _close();
  }

  @override
  Future flush() async {
    // Wait for added stream
    if (_addStreamFuture != null) {
      await _addStreamFuture;
      _addStreamFuture = null;
    }
  }

  void _checkAddRequirements() {
    if (!_supportsBody) {
      throw StateError('HTTP method $method does not support body');
    }
    if (_completer.isCompleted) {
      throw StateError('StreamSink is closed');
    }
    if (_addStreamFuture != null) {
      throw StateError('StreamSink is bound to a stream');
    }
  }

  String _chooseBrowserResponseType() {
    final custom = browserResponseType;
    if (custom != null) {
      return custom;
    }
    final accept = headers.value('Accept');
    if (accept != null) {
      try {
        final contentType = ContentType.parse(accept);
        final textMimes = BrowserHttpClient.defaultTextMimes;
        if ((contentType.primaryType == 'text' &&
                textMimes.contains('text/*')) ||
            textMimes.contains(contentType.mimeType)) {
          return 'text';
        }
      } catch (error) {
        // Ignore error
      }
    }
    return 'arraybuffer';
  }

  Future<BrowserHttpClientResponse> _close() async {
    await flush();

    final uriString = uri.toString();
    final xhrResponseType = _chooseBrowserResponseType();
    _browserResponseType = xhrResponseType;
    final xhr = _newXhr(uriString: uriString, responseType: xhrResponseType);

    final callback = client.onBrowserHttpClientRequestClose;
    if (callback != null) {
      await callback(this);
    }

    try {
      final headersCompleter = _completer;
      final streamController = StreamController<Uint8List>(
        onCancel: () {
          if (xhr.readyState != Xhr.readyStateDone) {
            xhr.abort();
          }
        },
      );

      final origin = windowOrigin;

      Timer? connectionTimer;
      final connectionTimeout = client.connectionTimeout;
      if (connectionTimeout != null) {
        connectionTimer = Timer(connectionTimeout, () {
          if (xhr.readyState != Xhr.readyStateDone) {
            xhr.abort();
          }
          _emitError(
            error: TimeoutException(null, connectionTimeout),
            headersCompleter: headersCompleter,
            streamController: streamController,
          );
        });
      }

      //
      // Something else than "text" or "arraybuffer"
      //
      XhrHttpClientResponse? response;
      var seenTextLength = 0;
      void emitTextChunk() {
        if (!streamController.isClosed) {
          final response = xhr.response;
          if (response.isA<JSString>()) {
            final responseString = (response as JSString).toDart;
            final textChunk = responseString.substring(seenTextLength);
            seenTextLength = responseString.length;
            streamController.add(Utf8Encoder().convert(textChunk));
          }
        }
      }

      xhr.onReadyStateChange = () {
        switch (xhr.readyState) {
          case Xhr.readyStateUnsent || Xhr.readyStateOpened:
            break;

          case Xhr.readyStateHeadersReceived:
            connectionTimer?.cancel();
            assert(response == null);
            response = _receivedXhrHeaders(
              headersCompleter: headersCompleter,
              streamController: streamController,
              xhr: xhr,
            );
            if (response == null) {
              xhr.abort();
            }
            break;

          case Xhr.readyStateLoading:
            response?.browserResponse = xhr.response;
            if (browserResponseType == 'text' && !streamController.isClosed) {
              emitTextChunk();
            }
            break;

          case Xhr.readyStateDone:
            connectionTimer?.cancel();
            response?.browserResponse = xhr.response;
            if (xhr.status == 0) {
              _emitError(
                error: BrowserHttpClientException(
                  method: method,
                  url: uriString,
                  origin: origin,
                  headers: headers,
                  browserResponseType: xhrResponseType,
                  browserCredentialsMode: browserCredentialsMode,
                ),
                headersCompleter: headersCompleter,
                streamController: streamController,
              );
            } else {
              assert(headersCompleter.isCompleted);
              switch (browserResponseType) {
                case 'text':
                  emitTextChunk();
                  break;
                case 'arraybuffer':
                  _emitArrayBuffer(streamController, xhr.response);
                  break;
              }
            }
            if (!streamController.isClosed) {
              streamController.close();
            }
            break;
          default:
            assert(false, 'Unknown XHR readyState ${xhr.readyState}');
            break;
        }
      }.toJS;
      _sendXhr(xhr);
    } catch (e, stackTrace) {
      // Something went wrong
      _completer.completeError(e, stackTrace);
    }
    return _completer.future;
  }

  void _emitArrayBuffer(
    StreamController<Uint8List> streamController,
    JSAny object,
  ) {
    if (!streamController.isClosed) {
      if (object.isA<JSArrayBuffer>()) {
        // "arraybuffer" response type
        streamController.add(Uint8List.view((object as JSArrayBuffer).toDart));
      }
    }
  }

  void _emitError({
    required Object error,
    required Completer<BrowserHttpClientResponse> headersCompleter,
    required StreamController<Uint8List> streamController,
  }) {
    if (!headersCompleter.isCompleted) {
      headersCompleter.completeError(error, StackTrace.current);
    }
    if (!streamController.isClosed) {
      streamController.addError(error, StackTrace.current);
    }
  }

  Xhr _newXhr({required String uriString, required String responseType}) {
    final xhr = Xhr();

    // Set method and URI
    final method = this.method;
    xhr.open(method, uriString);

    // Set response body type
    xhr.responseType = responseType;

    // Timeout
    final timeout = client.connectionTimeout;
    if (timeout != null) {
      xhr.timeout = timeout.inMilliseconds;
    }

    // Credentials mode?
    final browserCredentialsMode = this.browserCredentialsMode;
    xhr.withCredentials = browserCredentialsMode;

    // Copy headers to html.HttpRequest
    final headers = this.headers;
    headers.forEach((name, values) {
      for (var value in values) {
        xhr.setRequestHeader(name, value);
      }
    });
    return xhr;
  }

  XhrHttpClientResponse? _receivedXhrHeaders({
    required Completer<BrowserHttpClientResponse> headersCompleter,
    required StreamController<Uint8List> streamController,
    required Xhr xhr,
  }) {
    if (headersCompleter.isCompleted) {
      return null;
    }
    try {
      // Create HttpClientResponse
      final response = XhrHttpClientResponse(
        request: this,
        statusCode: xhr.status ?? 200,
        reasonPhrase: xhr.statusText ?? 'OK',
        body: streamController.stream,
      );
      _copyResponseHeadersFromXhr(response.headers, xhr);
      headersCompleter.complete(response);
      response.browserResponse = xhr.response;
      return response;
    } catch (error, stackTrace) {
      headersCompleter.completeError(error, stackTrace);
      return null;
    }
  }

  void _sendXhr(Xhr xhr) {
    final buffer = _buffer;
    if (buffer.isNotEmpty) {
      // Send with body
      xhr.send(Uint8List.fromList(buffer).toJS);
    } else {
      // Send without body
      xhr.send();
    }
  }

  static void _copyResponseHeadersFromXhr(HttpHeaders headers, Xhr xhr) {
    final xhrHeaders = xhr.getAllResponseHeaders().toDart;
    if (xhrHeaders.isEmpty) {
      return;
    }
    var lines = xhrHeaders.split('\r\n');
    if (lines.last == '') {
      lines = lines.sublist(0, lines.length - 1);
    }
    for (var line in lines) {
      final i = line.indexOf(': ');
      if (i < 0) {
        assert(false, 'Got malformed header line `$line`');
        continue;
      }
      final name = line.substring(0, i);
      final value = line.substring(i + 2);
      headers.add(name, value);
    }
  }

  static bool _httpMethodSupportsBody(String method) {
    return switch (method) {
      'GET' || 'HEAD' || 'OPTIONS' => false,
      _ => true,
    };
  }
}
