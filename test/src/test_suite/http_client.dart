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
import 'package:test/test.dart';
import 'package:universal_io/prefer_universal/io.dart';

import 'example_http_server.dart';

void testHttpClient({bool isBrowser = false, bool hybrid = false}) {
  group("HttpClient:", () {
    test("Non-existing server leads to SocketException", () async {
      final httpClient = HttpClient();
      final httpRequestFuture =
          httpClient.getUrl(Uri.parse("http://localhost:23456"));
      if (!isBrowser) {
        await expectLater(
            () => httpRequestFuture, throwsA(TypeMatcher<SocketException>()));
        return;
      }
      final httpRequest = await httpRequestFuture;
      final httpResponseFuture = httpRequest.close();
      await expectLater(
          () => httpResponseFuture, throwsA(TypeMatcher<SocketException>()));
    });
    test("GET", () async {
      await _testClient(
        method: "GET",
        path: "/greeting",
        responseBody: "Hello world!",
        hybrid: hybrid,
      );
    });

    test("POST", () async {
      await _testClient(
        method: "POST",
        path: "/greeting",
        requestBody: "Hello from client",
        responseBody: "Hello world!",
        hybrid: hybrid,
      );
    });

    test("Status 404", () async {
      await _testClient(
        method: "GET",
        path: "/404",
        status: 404,
        hybrid: hybrid,
      );
    });

    test("Receives cookies (except in browser)", () async {
      final response = await _testClient(
        method: "GET",
        path: "/set_cookie",
        requestHeaders: {
          "Cookie": Cookie("x", "v").toString(),
        },
        hybrid: hybrid,
      );

      expect(response.statusCode, HttpStatus.ok);
      if (isBrowser) {
        expect(response.cookies, []);
      } else {
        expect(response.cookies, hasLength(1));
        expect(response.cookies.single.name, "x");
        expect(response.cookies.single.value, "y");
      }
    });

    test("Sends cookies (except in browser)", () async {
      var status = HttpStatus.ok;
      if (isBrowser) {
        status = HttpStatus.unauthorized;
      }
      await _testClient(
        method: "GET",
        path: "/expect_cookie",
        requestHeaders: {
          "Cookie": Cookie("expectedCookie", "value").toString(),
        },
        status: status,
        hybrid: hybrid,
      );
    });

    test("Sends 'Authorization' header", () async {
      final response = await _testClient(
        method: "POST",
        path: "/expect_authorization",
        requestHeaders: {
          HttpHeaders.authorizationHeader: "expectedAuthorization",
        },
        hybrid: hybrid,
      );
      expect(response.statusCode, HttpStatus.ok);
    });

    // ------
    // DELETE
    // ------
    test("client.delete(...)", () async {
      await _testClientMethodWithoutUri(
        method: "DELETE",
        openUrl: (client, host, port, path) => client.delete(host, port, path),
        hybrid: hybrid,
      );
    });

    test("client.deleteUrl(...)", () async {
      await _testClient(
        method: "DELETE",
        path: "/greeting",
        openUrl: (client, uri) => client.deleteUrl(uri),
        responseBody: "Hello world!",
        hybrid: hybrid,
      );
    });

    // ---
    // GET
    // ---

    test("client.get(...)", () async {
      await _testClientMethodWithoutUri(
        method: "GET",
        openUrl: (client, host, port, path) => client.get(host, port, path),
        hybrid: hybrid,
      );
    });

    test("client.getUrl(...)", () async {
      await _testClient(
        method: "GET",
        path: "/greeting",
        openUrl: (client, uri) => client.getUrl(uri),
        responseBody: "Hello world!",
        hybrid: hybrid,
      );
    });

    // ----
    // HEAD
    // ----

    test("client.head(...)", () async {
      await _testClientMethodWithoutUri(
        method: "HEAD",
        openUrl: (client, host, port, path) => client.head(host, port, path),
        hybrid: hybrid,
      );
    });

    test("client.headUrl(...)", () async {
      await _testClient(
        method: "HEAD",
        path: "/greeting",
        openUrl: (client, uri) => client.headUrl(uri),
        responseBody: "", // <-- HEAD response doesn't have body
        hybrid: hybrid,
      );
    });

    // -----
    // PATCH
    // -----

    test("client.patch(...)", () async {
      await _testClientMethodWithoutUri(
        method: "PATCH",
        openUrl: (client, host, port, path) => client.patch(host, port, path),
        hybrid: hybrid,
      );
    });

    test("client.patchUrl(...)", () async {
      await _testClient(
        method: "PATCH",
        path: "/greeting",
        openUrl: (client, uri) => client.patchUrl(uri),
        responseBody: "Hello world!",
        hybrid: hybrid,
      );
    });

    // ----
    // POST
    // ----

    test("client.post(...)", () async {
      await _testClientMethodWithoutUri(
        method: "POST",
        openUrl: (client, host, port, path) => client.post(host, port, path),
        hybrid: hybrid,
      );
    });

    test("client.postUrl(...)", () async {
      await _testClient(
        method: "POST",
        path: "/greeting",
        openUrl: (client, uri) => client.postUrl(uri),
        responseBody: "Hello world!",
        hybrid: hybrid,
      );
    });

    // ---
    // PUT
    // ---

    test("client.put(...)", () async {
      await _testClientMethodWithoutUri(
        method: "PUT",
        openUrl: (client, host, port, path) => client.put(host, port, path),
        hybrid: hybrid,
      );
    });

    test("client.putUrl(...)", () async {
      await _testClient(
        method: "PUT",
        path: "/greeting",
        openUrl: (client, uri) => client.putUrl(uri),
        responseBody: "Hello world!",
        hybrid: hybrid,
      );
    });

    test("TLS connection to a self-signed server fails", () async {
      final server = await ExampleHttpServer.bind(hybrid: hybrid);
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
        final server =
            await ExampleHttpServer.bind(secure: true, hybrid: hybrid);
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

Future<HttpClientResponse> _testClient({
  /// Request method
  @required String method,

  /// Request path
  @required String path,

  /// Request headers
  Map<String, String> requestHeaders = const <String, String>{},

  /// Request body
  String requestBody,

  /// Expected status
  int status = 200,

  /// Expected response body.
  String responseBody,

  /// Function for opening HTTP request
  Future<HttpClientRequest> openUrl(HttpClient client, Uri uri),

  /// Use hybrid server?
  @required bool hybrid,

  /// Are we expecting XMLHttpRequest error?
  bool xmlHttpRequestError = false,
}) async {
  if (method == null) {
    throw ArgumentError.notNull("method");
  }
  if (path == null) {
    throw ArgumentError.notNull("path");
  }

  // Wait for the server to be listening
  final server = await ExampleHttpServer.bind(hybrid: hybrid);
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
    request = await openUrl(
      client,
      uri,
    ).timeout(const Duration(seconds: 5));
  } else {
    // Use 'openUrl'
    request =
        await client.openUrl(method, uri).timeout(const Duration(seconds: 5));
  }

  // Set headers
  requestHeaders.forEach((name, value) {
    request.headers.set(name, value);
  });

  // If HTTP method supports a request body,
  // write it.
  if (requestBody != null) {
    request.write(requestBody);
  }

  // Do we expect XMLHttpRequest error?
  if (xmlHttpRequestError) {
    expect(() => request.close(), throwsA(TypeMatcher<SocketException>()));
    return null;
  }

  // Close HTTP request
  final response =
      await request.close().timeout(const Duration(milliseconds: 500));
  final actualResponseBody = await utf8
      .decodeStream(response.cast<List<int>>())
      .timeout(const Duration(seconds: 5));

  // Check response status code
  expect(response, isNotNull);
  expect(response.statusCode, status);

  // Check response headers
  expect(response.headers.value("X-Response-Header"), "value");

  // Check response body
  if (responseBody != null) {
    expect(actualResponseBody, responseBody);
  }

  // Check the request that the server received
  expect(
      await server.requestsQueue.hasNext
          .timeout(const Duration(milliseconds: 200)),
      isTrue);
  final requestInfo = await server.requestsQueue.next;
  expect(requestInfo.method, method);
  expect(requestInfo.uri, "$path");
  expect(requestInfo.body, requestBody ?? "");

  return response;
}

typedef OpenUrlFunction = Future<HttpClientRequest> Function(
  HttpClient client,
  String host,
  int port,
  String path,
);

/// Tests methods like 'client.get(host,port,path)'.
///
/// These should default to TLS.
Future _testClientMethodWithoutUri({
  @required String method,
  @required OpenUrlFunction openUrl,
  @required bool hybrid,
}) async {
  if (method == null) {
    throw ArgumentError.notNull("method");
  }

  // Wait for the server to be listening
  final server = await ExampleHttpServer.bind(hybrid: hybrid);
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
  await utf8.decodeStream(response.cast<List<int>>());
  expect(response.statusCode, 200);
}
