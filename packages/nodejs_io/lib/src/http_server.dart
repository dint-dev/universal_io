// Copyright 2019 terrier989@gmail.com.
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

part of nodejs_io;

class _NodeJsHttpServerOverrides extends HttpServerOverrides {
  @override
  Future<HttpServer> bind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) async {
    final nodeServer = await node_io.HttpServer.bind(
      address,
      port,
      backlog: backlog,
      v6Only: v6Only,
      shared: shared,
    );
    return _NodeJsHttpServer(nodeServer);
  }

  @override
  Future<HttpServer> bindSecure(address, int port, SecurityContext context,
      {int backlog = 0,
      bool v6Only = false,
      bool requestClientCertificate = false,
      bool shared = false}) {
    throw UnimplementedError();
  }
}

class _NodeJsHttpRequest extends Stream<Uint8List> implements HttpRequest {
  final node_io.HttpRequest _impl;

  @override
  final HttpResponse response;

  @override
  final List<Cookie> cookies = <Cookie>[];

  @override
  final HttpHeaders headers = HttpHeadersImpl('1.1');

  _NodeJsHttpRequest(this._impl, this.response) {
    _impl.headers.forEach((name, values) {
      for (var value in values) {
        headers.add(name, value);
      }
    });
    for (var cookie in _impl.cookies) {
      cookies.add(Cookie.fromSetCookieValue(cookie.toString()));
    }
  }

  @override
  X509Certificate get certificate {
    throw UnimplementedError();
  }

  @override
  HttpConnectionInfo get connectionInfo {
    throw UnimplementedError();
  }

  @override
  int get contentLength {
    return _impl.contentLength;
  }

  @override
  String get method {
    return _impl.method;
  }

  @override
  bool get persistentConnection {
    return _impl.persistentConnection;
  }

  @override
  String get protocolVersion {
    return _impl.protocolVersion;
  }

  @override
  Uri get requestedUri {
    return _impl.requestedUri;
  }

  @override
  HttpSession get session {
    throw UnimplementedError();
  }

  @override
  Uri get uri {
    return _impl.uri;
  }

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    return _impl.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _NodeJsHttpResponse extends BaseIOSink implements HttpResponse {
  final node_io.HttpResponse _impl;

  bool _isHeadersCommitted = false;

  @override
  int contentLength;

  @override
  bool persistentConnection = false;

  @override
  bool bufferOutput = true;

  @override
  final HttpHeaders headers = HttpHeadersImpl('1.1');

  @override
  final List<Cookie> cookies = <Cookie>[];

  _NodeJsHttpResponse(this._impl);

  @override
  HttpConnectionInfo get connectionInfo {
    throw UnimplementedError();
  }

  @override
  Duration get deadline => _impl.deadline;

  @override
  set deadline(Duration value) {
    _impl.deadline = value;
  }

  @override
  Future get done => _impl.done;

  @override
  String get reasonPhrase => _impl.reasonPhrase;

  @override
  set reasonPhrase(String value) {
    _impl.reasonPhrase = value;
  }

  @override
  int get statusCode => _impl.statusCode;

  @override
  set statusCode(int value) {
    _impl.statusCode = value;
  }

  @override
  void add(List<int> data) {
    _commitHeaders();
    _impl.add(data);
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    _impl.addError(error, stackTrace);
  }

  @override
  Future close() {
    _commitHeaders();
    return _impl.close();
  }

  @override
  Future<Socket> detachSocket({bool writeHeaders = true}) {
    throw UnimplementedError();
  }

  @override
  Future redirect(Uri location, {int status = HttpStatus.movedTemporarily}) {
    return _impl.redirect(location, status: status);
  }

  void _commitHeaders() {
    if (_isHeadersCommitted) {
      return;
    }
    _isHeadersCommitted = true;
    headers.forEach((name, values) {
      for (var value in values) {
        _impl.headers.add(name, value);
      }
    });
    for (var cookie in cookies) {
      _impl.cookies.add(node_io.Cookie.fromSetCookieValue(cookie.toString()));
    }
  }
}

class _NodeJsHttpServer extends Stream<HttpRequest> implements HttpServer {
  final node_io.HttpServer _impl;

  @override
  String serverHeader;

  @override
  bool autoCompress;

  @override
  Duration idleTimeout;

  _NodeJsHttpServer(this._impl);

  @override
  InternetAddress get address {
    return InternetAddress(_impl.address.address);
  }

  @override
  HttpHeaders get defaultResponseHeaders {
    throw UnimplementedError();
  }

  @override
  int get port {
    return _impl.port;
  }

  @override
  set sessionTimeout(int timeout) {
    _impl.sessionTimeout = timeout;
  }

  @override
  Future close({bool force = false}) {
    return _impl.close(force: force);
  }

  @override
  HttpConnectionsInfo connectionsInfo() {
    throw UnimplementedError();
  }

  @override
  StreamSubscription<HttpRequest> listen(
      void Function(HttpRequest event) onData,
      {Function onError,
      void Function() onDone,
      bool cancelOnError}) {
    return _impl.map((nodeRequest) {
      return _NodeJsHttpRequest(
        nodeRequest,
        _NodeJsHttpResponse(nodeRequest.response),
      );
    }).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
