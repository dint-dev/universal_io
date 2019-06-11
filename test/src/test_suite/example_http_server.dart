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

import 'localhost_certificate.dart';

/// Used for testing [HttpClient].
///
/// Records received requests.
///
/// In browser, we use [_HybridExampleHttpServer].
/// Otherwise we use [_NormalExampleHttpServer].
abstract class ExampleHttpServer {
  /// Port where the server is listening.
  int get port;

  /// Received HTTP requests.
  StreamQueue<ExampleHttpRequest> get requestsQueue;

  /// Closes the server.
  void close();

  static Future<ExampleHttpServer> bind(
      {bool secure = false, @required bool hybrid}) async {
    if (hybrid) {
      return _HybridExampleHttpServer.bind(secure: secure);
    }
    return _NormalExampleHttpServer.bind(secure: secure);
  }
}

/// Used for testing [HttpClient].
class ExampleHttpRequest {
  final String method;
  final String uri;
  final String body;
  ExampleHttpRequest(this.method, this.uri, this.body);
}

void hybridMain(StreamChannel objectChannel, Object message) async {
  final channel = objectChannel.cast<List>();
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
  final server = await httpServerCompleter.future;
  if (server == null) {
    return;
  }

  // Tell the test where we are listening
  await channel.sink.add(["info", server.port]);

  // Close it when the channel closes
  // ignore: unawaited_futures
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
}

Future<HttpServer> _bindHttpServer() {
  return HttpServer.bind(
    "localhost",
    0,
  );
}

Future<HttpServer> _bindSecureHttpServer() {
  return HttpServer.bindSecure(
    "localhost",
    0,
    localHostSecurityContext(),
  );
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
      "*",
    );

    response.headers.set("X-Response-Header", "value");
    response.headers.contentType = ContentType.text;

    switch (request.uri.path) {
      case "/greeting":
        response.statusCode = HttpStatus.ok;
        response.write("Hello world!");
        break;

      case "/set_cookie":
        // Not tested in browser
        response.statusCode = HttpStatus.ok;
        response.cookies.add(new Cookie("x", "y"));
        break;

      case "/expect_cookie":
        // Not tested in browser
        final cookie = request.cookies.firstWhere(
          (cookie) => cookie.name == "expectedCookie",
          orElse: () => null,
        );
        if (cookie == null) {
          response.statusCode = HttpStatus.unauthorized;
        } else {
          response.statusCode = HttpStatus.ok;
        }
        break;

      case "/expect_authorization":
        response.headers.set("Access-Control-Allow-Credentials", "true");
        response.headers
            .set("Access-Control-Expose-Headers", "X-Response-Header");
        response.headers.set("Access-Control-Allow-Headers", "Authorization");

        // Is this a preflight?
        if (request.method == "OPTIONS") {
          response.statusCode = HttpStatus.ok;
          return;
        }

        final authorization =
            request.headers.value(HttpHeaders.authorizationHeader);

        if (authorization == "expectedAuthorization") {
          response.statusCode = HttpStatus.ok;
        } else {
          response.statusCode = HttpStatus.unauthorized;
        }
        break;

      case "/404":
        response.statusCode = HttpStatus.notFound;
        break;

      default:
        response.statusCode = HttpStatus.internalServerError;
        response.write("Invalid path '${request.uri.path}'");
        break;
    }
  } finally {
    await response.close();
  }
}

/// Communicates with VM, where [HttpServer] will be launched.
///
/// Used for testing the browser.
class _HybridExampleHttpServer implements ExampleHttpServer {
  static const _spawnUri = "src/test_suite/example_http_server.dart";

  final StreamChannel<List> _streamChannel;

  @override
  final int port;

  @override
  final StreamQueue<ExampleHttpRequest> requestsQueue;

  _HybridExampleHttpServer._(
      this._streamChannel, this.port, this.requestsQueue);

  void close() {
    _streamChannel.sink.close();
  }

  static Future<ExampleHttpServer> bind({bool secure = false}) async {
    // Get channel
    final channel = spawnHybridUri(_spawnUri);

    // Send "bind" message
    channel.sink.add([secure ? "bindSecure" : "bind"]);

    final requestsSink = StreamController<ExampleHttpRequest>();
    Completer completer = Completer<ExampleHttpServer>();
    channel.stream.listen(
      (args) {
        final type = args[0] as String;
        switch (type) {
          case "info":
            final port = (args[1] as num).toInt();

            final result = _HybridExampleHttpServer._(
              channel.cast<List>(),
              port,
              StreamQueue<ExampleHttpRequest>(requestsSink.stream),
            );
            completer.complete(result);
            completer = null;
            break;

          case "request":
            requestsSink.add(ExampleHttpRequest(
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

/// Implementation of [ExampleHttpServer] that uses [HttpServer.bind] directly.
class _NormalExampleHttpServer implements ExampleHttpServer {
  final HttpServer server;
  final StreamQueue<ExampleHttpRequest> requestsQueue;

  _NormalExampleHttpServer._(this.server, this.requestsQueue);

  @override
  int get port => server.port;

  @override
  void close() {
    server.close();
  }

  static Future<ExampleHttpServer> bind({bool secure = false}) async {
    final HttpServer server =
        await (secure ? _bindSecureHttpServer() : _bindHttpServer());
    final requestsController = StreamController<ExampleHttpRequest>();
    server.listen((request) async {
      if (request.method != "OPTIONS") {
        final body = await utf8.decodeStream(request);
        requestsController.add(ExampleHttpRequest(
          request.method,
          request.uri.toString(),
          body,
        ));
      }
      _handleHttpRequest(request);
    }, onDone: () {
      requestsController.close();
    });
    final requests = StreamQueue<ExampleHttpRequest>(
      requestsController.stream,
    );
    return _NormalExampleHttpServer._(server, requests);
  }
}
