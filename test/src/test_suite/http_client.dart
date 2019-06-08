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
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:stream_channel/stream_channel.dart';

void testHttpClient({bool isBrowser = false}) {
  group("HttpClient:", () {
    test("GET", () async {
      await _testClient(
        method: "GET",
        path: "/greeting",
        responseBody: "Hello world!",
      );
    });

    test("POST", () async {
      await _testClient(
        method: "POST",
        path: "/greeting",
        requestBody: "Hello from client",
        responseBody: "Hello world!",
      );
    });

    test("Status 404", () async {
      await _testClient(
        method: "GET",
        path: "/404",
        status: 404,
      );
    });

    // ------
    // DELETE
    // ------
    test("client.delete(...)", () async {
      await _testClientMethodWithoutUri(
        method: "DELETE",
        openUrl: (client, host, port, path) => client.delete(host, port, path),
      );
    });

    test("client.deleteUrl(...)", () async {
      await _testClient(
        method: "DELETE",
        path: "/greeting",
        openUrl: (client, uri) => client.deleteUrl(uri),
        responseBody: "Hello world!",
      );
    });

    // ---
    // GET
    // ---

    test("client.get(...)", () async {
      await _testClientMethodWithoutUri(
        method: "GET",
        openUrl: (client, host, port, path) => client.get(host, port, path),
      );
    });

    test("client.getUrl(...)", () async {
      await _testClient(
        method: "GET",
        path: "/greeting",
        openUrl: (client, uri) => client.getUrl(uri),
        responseBody: "Hello world!",
      );
    });

    // ----
    // HEAD
    // ----

    test("client.head(...)", () async {
      await _testClientMethodWithoutUri(
        method: "HEAD",
        openUrl: (client, host, port, path) => client.head(host, port, path),
      );
    });

    test("client.headUrl(...)", () async {
      await _testClient(
        method: "HEAD",
        path: "/greeting",
        openUrl: (client, uri) => client.headUrl(uri),
        responseBody: "", // <-- HEAD response doesn't have body
      );
    });

    // -----
    // PATCH
    // -----

    test("client.patch(...)", () async {
      await _testClientMethodWithoutUri(
        method: "PATCH",
        openUrl: (client, host, port, path) => client.patch(host, port, path),
      );
    });

    test("client.patchUrl(...)", () async {
      await _testClient(
        method: "PATCH",
        path: "/greeting",
        openUrl: (client, uri) => client.patchUrl(uri),
        responseBody: "Hello world!",
      );
    });

    // ----
    // POST
    // ----

    test("client.post(...)", () async {
      await _testClientMethodWithoutUri(
        method: "POST",
        openUrl: (client, host, port, path) => client.post(host, port, path),
      );
    });

    test("client.postUrl(...)", () async {
      await _testClient(
        method: "POST",
        path: "/greeting",
        openUrl: (client, uri) => client.postUrl(uri),
        responseBody: "Hello world!",
      );
    });

    // ---
    // PUT
    // ---

    test("client.put(...)", () async {
      await _testClientMethodWithoutUri(
        method: "PUT",
        openUrl: (client, host, port, path) => client.put(host, port, path),
      );
    });

    test("client.putUrl(...)", () async {
      await _testClient(
        method: "PUT",
        path: "/greeting",
        openUrl: (client, uri) => client.putUrl(uri),
        responseBody: "Hello world!",
      );
    });

    test("TLS connection to a self-signed server fails", () async {
      final server = await _TestHttpServer.bind();
      addTearDown(() {
        server.close();
      });
      final client = HttpClient();
      final port = server.port;
      final uri = Uri.parse("https://localhost:$port/greeting");
      if (isBrowser) {
        // In browser, request is sent only after it's closed.
        final request = await client.getUrl(uri);
        expect(() => request.close(), throwsA(TypeMatcher<SocketException>()));
      } else {
        expect(() => client.getUrl(uri),
            throwsA(TypeMatcher<HandshakeException>()));
      }
    });

    if (!isBrowser) {
      test(
          "TLS connection to a self-signed server succeeds with"
          " the help of 'badCertificateCallback'", () async {
        final server = await _TestHttpServer.bind(secure: true);
        addTearDown(() {
          server.close();
        });
        final client = HttpClient();
        client.badCertificateCallback = (certificate, host, port) {
          return true;
        };
        final port = server.port;
        final uri = Uri.parse("https://localhost:$port/greeting");
        final request = await client.getUrl(uri);
        final response = await request.close();
        expect(response.statusCode, 200);
      });
    }
  });
}

/// Tests methods like 'client.get(host,port,path)'.
///
/// These should default to TLS.
Future _testClientMethodWithoutUri({
  @required String method,
  @required
      Future<HttpClientRequest> openUrl(
          HttpClient client, String host, int port, String path),
}) async {
  if (method == null) {
    throw ArgumentError.notNull("method");
  }

  // Wait for the server to be listening
  final server = await _TestHttpServer.bind();
  addTearDown(() {
    server.close();
  });

  // Create a HTTP client
  final client = HttpClient();

  // Create a HTTP request
  final host = "localhost";
  final port = server.port;
  final path = "/greeting";
  final request = await openUrl(client, host, port, path);

  // Test that the request seems correct
  expect(request.uri.scheme, "http");
  expect(request.uri.host, "localhost");
  expect(request.uri.port, port);
  expect(request.uri.path, path);

  // Close request
  final response = await request.close();
  await utf8.decodeStream(response);
  expect(response.statusCode, 200);
}

Future _testClient({
  @required String method,
  @required String path,
  String requestBody,
  int status = 200,
  String responseBody,
  Future<HttpClientRequest> openUrl(HttpClient client, Uri uri),
}) async {
  if (method == null) {
    throw ArgumentError.notNull("method");
  }
  if (path == null) {
    throw ArgumentError.notNull("path");
  }

  // Wait for the server to be listening
  final server = await _TestHttpServer.bind();
  addTearDown(() {
    server.close();
  });

  // Send HTTP request
  final client = HttpClient();
  HttpClientRequest request;
  final host = "localhost";
  final port = server.port;
  final uri = Uri.parse("http://$host:$port$path");
  if (openUrl != null) {
    // Use a custom method
    // (we test their correctness)
    request =
        await openUrl(client, uri).timeout(const Duration(milliseconds: 500));
  } else {
    // Use 'openUrl'
    request = await client
        .openUrl(method, uri)
        .timeout(const Duration(milliseconds: 500));
  }

  // If HTTP method supports a request body,
  // write it.
  if (requestBody != null) {
    request.write(requestBody);
  }

  // Close HTTP request
  final response =
      await request.close().timeout(const Duration(milliseconds: 500));
  final actualResponseBody = await utf8
      .decodeStream(response)
      .timeout(const Duration(milliseconds: 500));

  // Check response status code
  expect(response, isNotNull);
  expect(response.statusCode, status);

  // Check response body
  if (responseBody != null) {
    expect(actualResponseBody, responseBody);
  }

  // Check request
  expect(
      await server.requestsQueue.hasNext
          .timeout(const Duration(milliseconds: 200)),
      isTrue);
  final requestInfo = await server.requestsQueue.next;
  expect(requestInfo.method, method);
  expect(requestInfo.uri, "$path");
  expect(requestInfo.body, requestBody ?? "");

  // Check response headers
  expect(response.headers.value("X-Response-Header"), "value");
}

class _TestHttpRequest {
  final String method;
  final String uri;
  final String body;
  _TestHttpRequest(this.method, this.uri, this.body);
}

class _TestHttpServer {
  static const _spawnUri = "src/test_suite/http_client_spawn_server.dart";

  final StreamChannel<List> _streamChannel;
  final int port;
  final StreamQueue<_TestHttpRequest> requestsQueue;

  _TestHttpServer._(this._streamChannel, this.port, this.requestsQueue);

  void close() {
    _streamChannel.sink.close();
  }

  static Future<_TestHttpServer> bind({bool secure = false}) async {
    // Get channel
    final channel = spawnHybridUri(_spawnUri);

    // Send "bind" message
    channel.sink.add([secure ? "bindSecure" : "bind"]);

    final requestsSink = StreamController<_TestHttpRequest>();
    Completer completer = Completer<_TestHttpServer>();
    channel.stream.listen(
      (args) {
        final type = args[0] as String;
        switch (type) {
          case "info":
            final port = (args[1] as num).toInt();

            final result = _TestHttpServer._(
              channel.cast<List>(),
              port,
              StreamQueue<_TestHttpRequest>(requestsSink.stream),
            );
            completer.complete(result);
            completer = null;
            break;

          case "request":
            requestsSink.add(_TestHttpRequest(
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
