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
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:universal_io/io.dart';

import 'base_io_sink.dart';
import 'http_headers_impl.dart';

abstract class BaseHttpClient implements HttpClient {
  @override
  Duration idleTimeout = Duration(seconds: 15);

  @override
  Duration connectionTimeout;

  @override
  int maxConnectionsPerHost;

  @override
  bool autoUncompress = true;

  @override
  String userAgent;

  @override
  Future<bool> Function(Uri url, String scheme, String realm) authenticate;

  @override
  Future<bool> Function(String host, int port, String scheme, String realm)
      authenticateProxy;

  @override
  bool Function(X509Certificate cert, String host, int port)
      badCertificateCallback;

  @override
  String Function(Uri url) findProxy;

  bool _isClosed = false;

  @override
  void addCredentials(
      Uri url, String realm, HttpClientCredentials credentials) {
    throw UnimplementedError();
  }

  @override
  void addProxyCredentials(
      String host, int port, String realm, HttpClientCredentials credentials) {}

  @override
  void close({bool force = false}) {
    _isClosed = true;
  }

  @override
  Future<HttpClientRequest> delete(String host, int port, String path) {
    return open("DELETE", host, port, path);
  }

  @override
  Future<HttpClientRequest> deleteUrl(Uri url) {
    return openUrl("DELETE", url);
  }

  /// A protected method only for implementations.
  ///
  /// This method is called after the operation has been validated.
  @protected
  Future<HttpClientRequest> didOpenUrl(String method, Uri url);

  @override
  Future<HttpClientRequest> get(String host, int port, String path) {
    return open("GET", host, port, path);
  }

  @override
  Future<HttpClientRequest> getUrl(Uri url) {
    return openUrl("GET", url);
  }

  @override
  Future<HttpClientRequest> head(String host, int port, String path) {
    return open("HEAD", host, port, path);
  }

  @override
  Future<HttpClientRequest> headUrl(Uri url) {
    return openUrl("HEAD", url);
  }

  @override
  Future<HttpClientRequest> open(
      String method, String host, int port, String path) {
    String query;
    final i = path.indexOf("?");
    if (i >= 0) {
      query = path.substring(i + 1);
      path = path.substring(0, i);
    }
    final uri = Uri(
      scheme: "http",
      host: host,
      port: port,
      path: path,
      query: query,
      fragment: null,
    );
    return openUrl(method, uri);
  }

  @protected
  Future<HttpClientRequest> openUrl(String method, Uri url) {
    if (_isClosed) {
      throw StateError("HTTP client is closed");
    }
    return didOpenUrl(method, url);
  }

  @override
  Future<HttpClientRequest> patch(String host, int port, String path) {
    return open("PATCH", host, port, path);
  }

  @override
  Future<HttpClientRequest> patchUrl(Uri url) {
    return openUrl("PATCH", url);
  }

  @override
  Future<HttpClientRequest> post(String host, int port, String path) {
    return open("POST", host, port, path);
  }

  @override
  Future<HttpClientRequest> postUrl(Uri url) {
    return openUrl("POST", url);
  }

  @override
  Future<HttpClientRequest> put(String host, int port, String path) {
    return open("PUT", host, port, path);
  }

  @override
  Future<HttpClientRequest> putUrl(Uri url) {
    return openUrl("PUT", url);
  }
}

abstract class BaseHttpClientRequest extends HttpClientRequest with BaseIOSink {
  final BaseHttpClient client;

  @override
  final String method;

  @override
  final Uri uri;

  @override
  final HttpHeaders headers = HttpHeadersImpl("1.1");

  final Completer<HttpClientResponse> _completer =
      Completer<HttpClientResponse>();

  Future _addStreamFuture;

  @override
  final List<Cookie> cookies = <Cookie>[];

  final bool _supportsBody;

  BaseHttpClientRequest(this.client, this.method, this.uri)
      : this._supportsBody = _httpMethodSupportsBody(method) {
    if (method == null) {
      throw ArgumentError.notNull("method");
    }
    if (uri == null) {
      throw ArgumentError.notNull("uri");
    }

    // Add "User-Agent" header
    final userAgent = client.userAgent;
    if (userAgent != null) {
      headers.set(HttpHeaders.userAgentHeader, userAgent);
    }
  }

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
  void add(List<int> event) {
    if (!_supportsBody) {
      throw StateError("HTTP method $method does not support body");
    }
    if (_completer.isCompleted) {
      throw StateError("StreamSink is closed");
    }
    if (_addStreamFuture != null) {
      throw StateError("StreamSink is bound to a stream");
    }
    didAdd(event);
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    if (_completer.isCompleted) {
      throw StateError("HTTP request is closed already");
    }
    _completer.completeError(error, stackTrace);
  }

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    if (_completer.isCompleted) {
      throw StateError("StreamSink is closed");
    }
    if (_addStreamFuture != null) {
      throw StateError("StreamSink is bound to a stream");
    }
    final future = stream.listen((item) {
      didAdd(item);
    }, onError: (error) {
      addError(error);
    }, cancelOnError: true).asFuture(null);
    _addStreamFuture = future;
    await future;
    _addStreamFuture = null;
    return null;
  }

  @override
  Future<HttpClientResponse> close() async {
    if (_completer.isCompleted) {
      return _completer.future;
    }
    try {
      // Flush
      await flush();

      // Close
      final result = await didClose();

      // Complete future
      _completer.complete(result);
      return _completer.future;
    } catch (error, stackTrace) {
      // Something failed
      // Complete with an error
      _completer.completeError(error, stackTrace);
      return _completer.future;
    }
  }

  /// A protected method only for implementations.
  ///
  /// This method is called after the operation has been validated.
  @protected
  void didAdd(List<int> data);

  /// A protected method only for implementations.
  ///
  /// Method [close] first waits writes to complete before calling this method.
  @protected
  Future<HttpClientResponse> didClose();

  @override
  Future flush() async {
    // Wait for added stream
    if (_addStreamFuture != null) {
      await _addStreamFuture;
      _addStreamFuture = null;
    }
    return Future.value(null);
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
}

abstract class BaseHttpClientResponse extends Stream<List<int>>
    implements HttpClientResponse {
  @override
  final HttpHeaders headers = HttpHeadersImpl("1.1");
  BaseHttpClientRequest request;
  List<Cookie> _cookies;

  BaseHttpClientResponse(this.request);

  @override
  X509Certificate get certificate => null;

  BaseHttpClient get client => request.client;

  @override
  HttpClientResponseCompressionState get compressionState {
    return HttpClientResponseCompressionState.decompressed;
  }

  @override
  HttpConnectionInfo get connectionInfo => null;

  @override
  int get contentLength => -1;

  @override
  List<Cookie> get cookies {
    var cookies = this._cookies;
    if (cookies == null) {
      cookies = <Cookie>[];
      final headerValues = headers[HttpHeaders.setCookieHeader] ?? <String>[];
      for (var headerValue in headerValues) {
        _cookies.add(Cookie.fromSetCookieValue(headerValue));
      }
      this._cookies = cookies;
    }
    return cookies;
  }

  @override
  bool get isRedirect =>
      HttpStatus.temporaryRedirect == statusCode ||
      HttpStatus.movedPermanently == statusCode;

  @override
  bool get persistentConnection => false;

  @override
  String get reasonPhrase => null;

  @override
  List<RedirectInfo> get redirects => const <RedirectInfo>[];

  int get statusCode;

  @override
  Future<Socket> detachSocket() {
    return null;
  }

  @override
  StreamSubscription<Uint8List> listen(void onData(Uint8List event),
      {Function onError, void onDone(), bool cancelOnError});

  @override
  Future<HttpClientResponse> redirect(
      [String method, Uri url, bool followLoops]) {
    final newUrl =
        url ?? Uri.parse(this.headers.value(HttpHeaders.locationHeader));
    return client
        .openUrl(method ?? request.method, newUrl ?? request.uri)
        .then((newRequest) {
      request.headers.forEach((name, value) {
        newRequest.headers.add(name, value);
      });
      newRequest.followRedirects = true;
      return newRequest.close();
    });
  }
}
