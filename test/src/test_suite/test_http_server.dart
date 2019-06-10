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

import 'package:async/async.dart';
import 'package:meta/meta.dart';
import 'package:stream_channel/stream_channel.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

void hybridMain(StreamChannel channel, Object message) async {
  _handleChannel(channel.cast<List>());
}

Future<HttpServer> _bindHttpServer() {
  return HttpServer.bind(
    "localhost",
    0,
  );
}

Future<HttpServer> _bindSecureHttpServer() {
  // Create TLS security context
  final securityContext = SecurityContext();
  securityContext.useCertificateChain(
    "test/src/test_suite/localhost.crt",
  );
  securityContext.usePrivateKey(
    "test/src/test_suite/localhost.key",
  );

  // Bind
  return HttpServer.bindSecure(
    "localhost",
    0,
    securityContext,
  );
}

void _handleChannel(StreamChannel channel) {
  final httpServerCompleter = Completer<HttpServer>();
  final doneCompleter = Completer();
  channel.stream.listen((message) async {
    final type = message[0] as String;
    switch (type) {
      case "bind":
        // Bind
        httpServerCompleter.complete(_bindHttpServer());
        break;

      case "bindSecure":
        httpServerCompleter.complete(_bindSecureHttpServer());
        break;

      default:
        throw ArgumentError("Unsupported message type '$type'");
    }
  }, onDone: () {
    if (!httpServerCompleter.isCompleted) {
      httpServerCompleter.complete();
    }
    doneCompleter.complete();
  });

  // When we receive a server
  httpServerCompleter.future.then((server) {
    if (server == null) {
      return;
    }

    // Tell the test where we are listening
    channel.sink.add(["info", server.port]);

    // Close it when the channel closes
    doneCompleter.future.whenComplete(() {
      server.close();
    });

    // Listen for requests
    server.listen(
      (request) async {
        // Decode request body
        final requestBody = await utf8.decodeStream(request);

        // Tell the test about the request we received
        if (request.method != "OPTIONS") {
          channel.sink.add([
            "request",
            request.method,
            request.uri.toString(),
            requestBody,
          ]);
        }

        _handleHttpRequest(request);
      },
      onError: (error, stackTrace) {
        channel.sink.addError(error, stackTrace);
      },
      onDone: () {
        channel.sink.close();
      },
    );
  });
}

void _handleHttpRequest(HttpRequest request) async {
  // Respond based on the path
  final response = request.response;
  try {
    // Check that the request is from loopback
    if (!request.connectionInfo.remoteAddress.isLoopback) {
      throw StateError("Unauthorized remote address");
    }

    // CORS:
    // We need to allow origin.
    final origin = request.headers.value("Origin");
    response.headers.set(
      "Access-Control-Allow-Origin",
      origin ?? "*",
    );

    // CORS:
    // We need allow methods that are not simple.
    // (simple methods are GET, HEAD, POST)
    response.headers.set(
      "Access-Control-Allow-Methods",
      "DELETE, GET, HEAD, PATCH, POST, PUT",
    );

    // CORS:
    // We need to allow reading our example response header.
    response.headers.set(
      "Access-Control-Expose-Headers",
      "X-Response-Header",
    );

    response.headers.set("X-Response-Header", "value");
    response.headers.contentType = ContentType.text;

    switch (request.uri.path) {
      case "/greeting":
        response.statusCode = 200;
        response.write("Hello world!");
        break;

      case "/allow_cors_credentials":
        response.statusCode = 200;
        response.headers.set("Access-Control-Allow-Credentials", "true");
        response.cookies.add(Cookie("exampleName", "exampleValue"));
        response.write("Hello world!");
        break;

      case "/404":
        response.statusCode = 404;
        break;

      default:
        response.statusCode = 500;
        response.write("Invalid path '${request.uri.path}'");
        break;
    }
  } finally {
    await response.close();
  }
}

class TestHttpRequest {
  final String method;
  final String uri;
  final String body;
  TestHttpRequest(this.method, this.uri, this.body);
}

abstract class TestHttpServer {
  int get port;
  StreamQueue<TestHttpRequest> get requestsQueue;

  void close() {}

  static Future<TestHttpServer> bind(
      {bool secure = false, @required bool hybrid}) async {
    if (hybrid) {
      return _HybridTestHttpServer.bind(secure: secure);
    }
    return _NormalTestHttpServer.bind(secure: secure);
  }
}

class _HybridTestHttpServer implements TestHttpServer {
  static const _spawnUri = "src/test_suite/test_http_server.dart";

  final StreamChannel<List> _streamChannel;

  @override
  final int port;

  @override
  final StreamQueue<TestHttpRequest> requestsQueue;

  _HybridTestHttpServer._(this._streamChannel, this.port, this.requestsQueue);

  void close() {
    _streamChannel.sink.close();
  }

  static Future<TestHttpServer> bind({bool secure = false}) async {
    // Get channel
    final channel = spawnHybridUri(_spawnUri);

    // Send "bind" message
    channel.sink.add([secure ? "bindSecure" : "bind"]);

    final requestsSink = StreamController<TestHttpRequest>();
    Completer completer = Completer<TestHttpServer>();
    channel.stream.listen(
      (args) {
        final type = args[0] as String;
        switch (type) {
          case "info":
            final port = (args[1] as num).toInt();

            final result = _HybridTestHttpServer._(
              channel.cast<List>(),
              port,
              StreamQueue<TestHttpRequest>(requestsSink.stream),
            );
            completer.complete(result);
            completer = null;
            break;

          case "request":
            requestsSink.add(TestHttpRequest(
              args[1] as String,
              args[2] as String,
              args[3] as String,
            ));
            break;

          default:
            throw ArgumentError("Unsupported message type '$type'");
        }
      },
      onError: (error, stackTrace) {
        if (completer != null) {
          completer.completeError(error, stackTrace);
          completer = null;
        }
        requestsSink.addError(error, stackTrace);
      },
      onDone: () {
        if (completer != null) {
          completer.completeError(StateError(
            "Channel was closed before 'info' message was received.",
          ));
          completer = null;
        }
        requestsSink.close();
      },
    );

    // Create server
    return completer.future;
  }
}

class _NormalTestHttpServer implements TestHttpServer {
  final HttpServer server;
  final StreamQueue<TestHttpRequest> requestsQueue;

  _NormalTestHttpServer._(this.server, this.requestsQueue);

  @override
  int get port => server.port;

  @override
  void close() {
    server.close();
  }

  static Future<TestHttpServer> bind({bool secure = false}) async {
    final HttpServer server =
        await (secure ? _bindSecureHttpServer() : _bindHttpServer());
    final requestsController = StreamController<TestHttpRequest>();
    server.listen((request) async {
      if (request.method != "OPTIONS") {
        final body = await utf8.decodeStream(request);
        requestsController.add(TestHttpRequest(
          request.method,
          request.uri.toString(),
          body,
        ));
      }
      _handleHttpRequest(request);
    }, onDone: () {
      requestsController.close();
    });
    final requests = StreamQueue<TestHttpRequest>(
      requestsController.stream,
    );
    return _NormalTestHttpServer._(server, requests);
  }
}
