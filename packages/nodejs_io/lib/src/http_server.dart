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
  final node_io.HttpRequest impl;

  @override
  final HttpResponse response;

  @override
  final List<Cookie> cookies = <Cookie>[];

  @override
  final HttpHeaders headers = HttpHeadersImpl('1.1');

  _NodeJsHttpRequest(this.impl, this.response) {
    impl.headers.forEach((name, values) {
      for (var value in values) {
        headers.add(name, value);
      }
    });
    for (var cookie in impl.cookies) {
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
    return impl.contentLength;
  }

  @override
  String get method {
    return impl.method;
  }

  @override
  bool get persistentConnection {
    return impl.persistentConnection;
  }

  @override
  String get protocolVersion {
    return impl.protocolVersion;
  }

  @override
  Uri get requestedUri {
    return impl.requestedUri;
  }

  @override
  HttpSession get session {
    throw UnimplementedError();
  }

  @override
  Uri get uri {
    return impl.uri;
  }

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    return impl.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}

class _NodeJsHttpResponse extends BaseIOSink implements HttpResponse {
  final node_io.HttpResponse impl;

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

  _NodeJsHttpResponse(this.impl);

  @override
  HttpConnectionInfo get connectionInfo {
    throw UnimplementedError();
  }

  @override
  Duration get deadline => impl.deadline;

  @override
  set deadline(Duration value) {
    impl.deadline = value;
  }

  @override
  Future get done => impl.done;

  @override
  String get reasonPhrase => impl.reasonPhrase;

  @override
  set reasonPhrase(String value) {
    impl.reasonPhrase = value;
  }

  @override
  int get statusCode => impl.statusCode;

  @override
  set statusCode(int value) {
    impl.statusCode = value;
  }

  @override
  void add(List<int> data) {
    _commitHeaders();
    impl.add(data);
  }

  @override
  void addError(Object error, [StackTrace stackTrace]) {
    impl.addError(error, stackTrace);
  }

  @override
  Future close() {
    _commitHeaders();
    return impl.close();
  }

  @override
  Future<Socket> detachSocket({bool writeHeaders = true}) {
    throw UnimplementedError();
  }

  @override
  Future redirect(Uri location, {int status = HttpStatus.movedTemporarily}) {
    return impl.redirect(location, status: status);
  }

  void _commitHeaders() {
    if (_isHeadersCommitted) {
      return;
    }
    _isHeadersCommitted = true;
    headers.forEach((name, values) {
      for (var value in values) {
        impl.headers.add(name, value);
      }
    });
    for (var cookie in cookies) {
      impl.cookies.add(node_io.Cookie.fromSetCookieValue(cookie.toString()));
    }
  }
}

class _NodeJsHttpServer extends Stream<HttpRequest> implements HttpServer {
  final node_io.HttpServer impl;

  @override
  String serverHeader;

  @override
  bool autoCompress;

  @override
  Duration idleTimeout;

  _NodeJsHttpServer(this.impl);

  @override
  InternetAddress get address {
    return InternetAddress(impl.address.address);
  }

  @override
  HttpHeaders get defaultResponseHeaders {
    throw UnimplementedError();
  }

  @override
  int get port {
    return impl.port;
  }

  @override
  set sessionTimeout(int timeout) {
    impl.sessionTimeout = timeout;
  }

  @override
  Future close({bool force = false}) {
    return impl.close(force: force);
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
    return impl.map((nodeRequest) {
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
