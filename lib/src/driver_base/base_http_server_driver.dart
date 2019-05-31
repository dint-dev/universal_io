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

import 'package:meta/meta.dart';
import 'package:universal_io/driver.dart';
import 'package:universal_io/io.dart';

import 'base_io_sink.dart';
import 'http_headers_impl.dart';

class BaseHttpServerDriver extends HttpServerDriver {
  const BaseHttpServerDriver();

  @override
  Future<HttpServer> bindHttpServer(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    throw UnimplementedError();
  }
}

abstract class BaseHttpRequest extends Stream<List<int>>
    implements HttpRequest {
  @override
  final HttpConnectionInfo connectionInfo;

  @override
  final String protocolVersion;

  @override
  final HttpHeaders headers = HttpHeadersImpl("1.0");

  @override
  final Uri uri;

  @override
  final String method;

  BaseHttpRequest(this.method, this.uri,
      {this.protocolVersion = "1.0", this.connectionInfo});

  @override
  X509Certificate get certificate {
    return null;
  }

  @override
  int get contentLength {
    return null;
  }

  @override
  List<Cookie> get cookies {
    throw UnimplementedError();
  }

  @override
  bool get persistentConnection {
    return false;
  }

  @override
  Uri get requestedUri {
    final uri = this.uri;
    final hosts = this.headers["Host"];
    final host = (hosts == null || hosts.isEmpty) ? null : hosts.first;
    return Uri(scheme: "https", host: host, path: uri.path, query: uri.query);
  }

  @override
  HttpResponse get response;

  @override
  HttpSession get session {
    throw UnimplementedError();
  }
}

abstract class BaseHttpResponse extends BaseIOSink implements HttpResponse {
  @override
  int contentLength;

  @override
  int statusCode = HttpStatus.ok;

  @override
  String reasonPhrase;

  @override
  bool persistentConnection = false;

  @override
  Duration deadline;

  @override
  bool bufferOutput = true;

  @override
  final HttpHeaders headers = HttpHeadersImpl("1.0");

  final Completer<void> _completer = Completer<void>();
  final List<Future> _futures = <Future>[];

  @override
  Encoding encoding = utf8;

  @override
  HttpConnectionInfo get connectionInfo {
    throw UnimplementedError();
  }

  @override
  List<Cookie> get cookies {
    throw UnimplementedError();
  }

  @override
  Future get done => _completer.future;

  @override
  void add(List<int> data) {
    final future = internallyAdd(data);
    _futures.add(future);
  }

  @override
  void addError(error, [StackTrace stackTrace]) {
    _completer.completeError(error, stackTrace);
  }

  @override
  Future close() async {
    try {
      await Future.wait(_futures);
      _completer.complete();
    } catch (error, stackTrace) {
      _completer.completeError(error, stackTrace);
    }
  }

  @override
  Future<Socket> detachSocket({bool writeHeaders = true}) {
    throw UnimplementedError();
  }

  @protected
  Future<void> internallyAdd(List<int> data);

  @override
  Future redirect(Uri location, {int status = HttpStatus.movedTemporarily}) {
    throw UnimplementedError();
  }
}

abstract class BaseHttpServer extends Stream<HttpRequest>
    implements HttpServer {
  @override
  String serverHeader;

  @override
  final HttpHeaders defaultResponseHeaders = HttpHeadersImpl("1.0");

  @override
  bool autoCompress = false;

  @override
  Duration idleTimeout = const Duration(seconds: 120);

  /// Sets the timeout, in seconds, for sessions of this [HttpServer].
  /// The default timeout is 20 minutes.
  @override
  set sessionTimeout(int timeout) {}

  @override
  HttpConnectionsInfo connectionsInfo() {
    return HttpConnectionsInfo();
  }
}
