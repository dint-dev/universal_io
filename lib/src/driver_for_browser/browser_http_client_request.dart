// Copyright 'dart-universal_io' project authors.
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
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:typed_data/typed_buffers.dart';
import 'package:universal_io/driver_base.dart';
import 'package:universal_io/io.dart';
import 'browser_http_client_exception.dart';
import 'browser_http_client_response.dart';

import 'browser_http_client.dart';

/// Used by [BrowserHttpClient].
class BrowserHttpClientRequest extends BaseHttpClientRequest {
  final HttpClient client;

  @override
  final String method;

  @override
  final Uri uri;

  @override
  final HttpHeaders headers = HttpHeadersImpl("1.0");

  final Int8Buffer _buffer = Int8Buffer();

  final Completer<HttpClientResponse> _completer =
  Completer<HttpClientResponse>();

  bool _closed = false;
  Future _requestBodyFuture;

  @override
  final List<Cookie> cookies = <Cookie>[];

  bool useCorsCredentials = false;

  BrowserHttpClientRequest(this.method, this.uri, {BrowserHttpClient client}) : this.client = client ?? new BrowserHttpClient();

  @override
  HttpConnectionInfo get connectionInfo => null;

  @override
  Future<HttpClientResponse> get done {
    return _completer.future;
  }

  @override
  Encoding get encoding => utf8;

  @override
  set encoding(Encoding value) {
    throw StateError("IOSink encoding is not mutable");
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    if (_closed) {
      throw StateError("HTTP request is closed already");
    }
    _completer.completeError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) {
    if (_requestBodyFuture != null) {
      throw StateError("StreamSink is bound to a stream");
    }
    if (_closed) {
      throw StateError("StreamSink is closed");
    }
    _requestBodyFuture = stream.listen((item) {
      _buffer.addAll(item);
    }, onError: (error) {
      addError(error);
    }, cancelOnError: true).asFuture(null);
    return _requestBodyFuture;
  }

  @override
  Future<void> flush() {
    return Future<void>.value();
  }

  @override
  void internallyAdd(List<int> event) {
    if (_requestBodyFuture != null) {
      throw StateError("StreamSink is bound to a stream");
    }
    if (_closed) {
      throw StateError("StreamSink is closed");
    }
    if (event.isEmpty) {
      return;
    }
    if (!_httpMethodSupportsBody(method)) {
      throw StateError("HTTP method $method does not support body");
    }
    _buffer.addAll(event);
  }

  @override
  Future<HttpClientResponse> internallyClose() {
    if (_closed) {
      throw StateError("StreamSink is closed");
    }
    if (!_completer.isCompleted) {
      if (_requestBodyFuture != null) {
        _requestBodyFuture.then((_) {
          return _send();
        });
      } else {
        _send();
      }
    }
    return _completer.future;
  }

  @override
  void write(Object obj) {
    String string = '$obj';
    if (string.isEmpty) return;
    add(utf8.encode(string));
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    Iterator iterator = objects.iterator;
    if (!iterator.moveNext()) return;
    if (separator.isEmpty) {
      do {
        write(iterator.current);
      } while (iterator.moveNext());
    } else {
      write(iterator.current);
      while (iterator.moveNext()) {
        write(separator);
        write(iterator.current);
      }
    }
  }

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }

  @override
  void writeln([Object object = ""]) {
    write(object);
    write("\n");
  }

  void _send() {
    try {
      final xhr = html.HttpRequest();

      // Set method and URI
      final uriString = uri.toString();
      xhr.open(method, uriString);

      // Set response body type
      xhr.responseType = 'blob';

      // Set timeout
      final timeout = this.client.connectionTimeout;
      if (timeout != null) {
        xhr.timeout = timeout.inMilliseconds;
      }

      // Do we have credentials enabled?
      // Or are we are trying to send cross-origin cookies?
      final origin = html.window.origin;
      var corsCredentialsMode = this.useCorsCredentials ||
          (BrowserHttpClient.isCrossOriginUrl(uriString, origin: origin) &&
              this.cookies.isNotEmpty);

      if (corsCredentialsMode) {
        // Yes
        xhr.withCredentials = true;
      }

      // Copy headers to html.HttpRequest
      headers.forEach((name, values) {
        for (var value in values) {
          xhr.setRequestHeader(name, value);
        }
      });

      final completer = this._completer;

      xhr.onReadyStateChange.listen((event) {
        if (xhr.readyState == html.HttpRequest.LOADING) {}
      });

      // Set response handler
      xhr.onLoadEnd.first.then((_) async {
        // Read body
        final body = await _readResponseBody(method, uri, xhr);
        if (completer.isCompleted) {
          // An error occurred during reading
          return;
        }

        // Create HttpClientResponse
        final httpClientResponse = BrowserHttpClientResponse(
          xhr,
          body,
          client: client,
          request: this,
        );

        // Complete the future
        completer.complete(httpClientResponse);
      });

      xhr.onError.listen((html.ProgressEvent event) {
        if (completer.isCompleted) {
          return;
        }

        // Unfortunately, the underlying XMLHttpRequest API doesn't expose any
        // specific information about the error itself.
        //
        // We gather the information that we have and try to produce a
        // descriptive exception.
        final error = BrowserHttpClientException(
          method: method,
          url: uriString,
          origin: origin,
          corsCredentialsMode: corsCredentialsMode,
        );

        completer.completeError(error, StackTrace.current);
      });

      if (_httpMethodSupportsBody(method)) {
        // Send with body
        xhr.send(Uint8List.fromList(_buffer));
      } else {
        // Send without body
        xhr.send();
      }
    } catch (e) {
      // Something went wrong
      _completer.completeError(e);
    }
  }

  static bool _httpMethodSupportsBody(String method) {
    switch (method) {
      case "GET":
        return false;
      case "HEAD":
        return false;
      case "OPTIONS":
        return false;
      default:
        return true;
    }
  }

  static Stream<List<int>> _readResponseBody(
      String method, Uri uri, html.HttpRequest request) {
    final blob = request.response;
    if (blob == null) {
      // No body
      return Stream<List<int>>.empty();
    }

    // Read response with FileReader
    final controller = StreamController<Uint8List>();
    var fileReader = html.FileReader();
    fileReader.onLoad.first.then((html.ProgressEvent event) {
      var body = fileReader.result as Uint8List;
      controller.add(body);
      controller.close();
    });

    fileReader.onError.listen((html.ProgressEvent event) {
      controller.addError(
        SocketException("FileReader error. Request was: '$method $uri'"),
        StackTrace.current,
      );
      controller.close();
    });
    fileReader.readAsArrayBuffer(blob);
    return controller.stream;
  }
}