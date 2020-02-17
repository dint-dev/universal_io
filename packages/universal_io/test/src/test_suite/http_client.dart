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

import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:universal_io/prefer_sdk/io.dart' as prefer_sdk;
import 'package:universal_io/prefer_universal/io.dart';
import 'package:universal_io/prefer_universal/io.dart' as prefer_universal;

import 'example_http_server.dart';

void testHttpClient({bool isBrowser = false, bool hybrid = false}) {
  group('HttpClient:', () {
    group('in "package:universal_io/prefer_sdk/io.dart":', () {
      final httpClient = prefer_sdk.HttpClient();
      if (isBrowser) {
        test('does implement BrowserHttpClient', () async {
          expect(httpClient, isA<BrowserHttpClient>());
          if (httpClient is prefer_sdk.BrowserHttpClient) {
            expect(
              httpClient.credentialsMode,
              prefer_sdk.BrowserHttpClientCredentialsMode.automatic,
            );
            httpClient.credentialsMode =
                prefer_sdk.BrowserHttpClientCredentialsMode.include;
            expect(
              httpClient.credentialsMode,
              prefer_sdk.BrowserHttpClientCredentialsMode.include,
            );
          }
        });
        test('request does implement BrowserHttpClientRequest', () async {
          final request =
              await prefer_sdk.HttpClient().openUrl('GET', Uri.parse('/'));
          expect(request, isA<prefer_sdk.BrowserHttpClientRequest>());
          if (request is prefer_sdk.BrowserHttpClientRequest) {
            expect(
              request.credentialsMode,
              prefer_sdk.BrowserHttpClientCredentialsMode.automatic,
            );
            request.credentialsMode =
                prefer_sdk.BrowserHttpClientCredentialsMode.include;
            expect(
              request.credentialsMode,
              prefer_sdk.BrowserHttpClientCredentialsMode.include,
            );
          }
        });
      } else {
        test('does NOT implement BrowserHttpClient', () async {
          expect(httpClient, isNot(isA<BrowserHttpClient>()));
        });
      }
    });

    group('in "package:universal_io/prefer_universal/io.dart":', () {
      final httpClient = prefer_universal.HttpClient();
      if (isBrowser) {
        test('does implement BrowserHttpClient', () async {
          expect(httpClient, isA<BrowserHttpClient>());
          if (httpClient is prefer_universal.BrowserHttpClient) {
            expect(
              httpClient.credentialsMode,
              prefer_universal.BrowserHttpClientCredentialsMode.automatic,
            );
            httpClient.credentialsMode =
                prefer_universal.BrowserHttpClientCredentialsMode.include;
            expect(
              httpClient.credentialsMode,
              prefer_universal.BrowserHttpClientCredentialsMode.include,
            );
          }
        });
        test('request does implement BrowserHttpClientRequest', () async {
          final request = await prefer_universal.HttpClient()
              .openUrl('GET', Uri.parse('/'));
          expect(request, isA<prefer_universal.BrowserHttpClientRequest>());
          if (request is prefer_universal.BrowserHttpClientRequest) {
            expect(
              request.credentialsMode,
              prefer_universal.BrowserHttpClientCredentialsMode.automatic,
            );
            request.credentialsMode =
                prefer_universal.BrowserHttpClientCredentialsMode.include;
            expect(
              request.credentialsMode,
              prefer_universal.BrowserHttpClientCredentialsMode.include,
            );
          }
        });
      } else {
        test('does NOT implement BrowserHttpClient', () {
          expect(httpClient, isNot(isA<BrowserHttpClient>()));
        });
      }
    });

    test('Non-existing server leads to SocketException', () async {
      final httpClient = HttpClient();
      final httpRequestFuture =
          httpClient.getUrl(Uri.parse('http://localhost:23456'));
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

    test('GET', () async {
      await _testClient(
        method: 'GET',
        path: '/greeting',
        expectedBody: 'Hello world! (GET)',
        hybrid: hybrid,
      );
    });

    test('GET (multiple chunks)', () async {
      // Wait for the server to be listening
      final server = await ExampleHttpServer.bind(hybrid: hybrid);
      addTearDown(() {
        server.close();
      });

      // Send HTTP request
      final client = HttpClient();
      final request = await client.openUrl(
        'GET',
        Uri.parse('http://localhost:${server.port}/slow'),
      );
      if (request is BrowserHttpClientRequest) {
        request.responseType = BrowserHttpClientResponseType.text;
      }
      final response = await request.close();
      final list = await response.toList();

      // Check that the data arrived in multiple parts.
      expect(list, hasLength(greaterThanOrEqualTo(2)));

      // Check that the content is correct.
      final bytes = list.fold(<int>[], (a, b) => a..addAll(b));
      expect(utf8.decode(bytes), 'First part.\nSecond part.\n');
    });

    test('POST', () async {
      await _testClient(
        method: 'POST',
        path: '/greeting',
        requestBody: 'Hello from client',
        expectedBody: 'Hello world! (POST)',
        hybrid: hybrid,
      );
    });

    test('Status 404', () async {
      await _testClient(
        method: 'GET',
        path: '/404',
        expectedStatus: 404,
        hybrid: hybrid,
      );
    });

    test('Receives cookies (except in browser)', () async {
      final response = await _testClient(
        method: 'GET',
        path: '/set_cookie',
        headers: {
          'Cookie': Cookie('x', 'v').toString(),
        },
        hybrid: hybrid,
      );

      expect(response.statusCode, HttpStatus.ok);
      if (isBrowser) {
        expect(response.cookies, []);
      } else {
        expect(response.cookies, hasLength(1));
        expect(response.cookies.single.name, 'x');
        expect(response.cookies.single.value, 'y');
      }
    });

    test('Sends cookies (except in browser)', () async {
      var expectedStatus = HttpStatus.ok;
      if (isBrowser) {
        expectedStatus = HttpStatus.unauthorized;
      }
      await _testClient(
        method: 'GET',
        path: '/expect_cookie',
        headers: {
          'Cookie': Cookie('expectedCookie', 'value').toString(),
        },
        expectedStatus: expectedStatus,
        hybrid: hybrid,
      );
    });

    test("Sends 'Authorization' header", () async {
      await _testClient(
        method: 'POST',
        path: '/expect_authorization',
        headers: {
          HttpHeaders.authorizationHeader: 'expectedAuthorization',
        },
        expectedStatus: HttpStatus.ok,
        expectedBody: 'expectedAuthorization',
        hybrid: hybrid,
      );
    });

    // ------
    // DELETE
    // ------
    test('client.delete(...)', () async {
      await _testClientMethodWithoutUri(
        method: 'DELETE',
        openUrl: (client, host, port, path) => client.delete(host, port, path),
        hybrid: hybrid,
      );
    });

    test('client.deleteUrl(...)', () async {
      await _testClient(
        method: 'DELETE',
        path: '/greeting',
        openUrl: (client, uri) => client.deleteUrl(uri),
        expectedBody: 'Hello world! (DELETE)',
        hybrid: hybrid,
      );
    });

    // ---
    // GET
    // ---

    test('client.get(...)', () async {
      await _testClientMethodWithoutUri(
        method: 'GET',
        openUrl: (client, host, port, path) => client.get(host, port, path),
        hybrid: hybrid,
      );
    });

    test('client.getUrl(...)', () async {
      await _testClient(
        method: 'GET',
        path: '/greeting',
        openUrl: (client, uri) => client.getUrl(uri),
        expectedBody: 'Hello world! (GET)',
        hybrid: hybrid,
      );
    });

    // ----
    // HEAD
    // ----

    test('client.head(...)', () async {
      await _testClientMethodWithoutUri(
        method: 'HEAD',
        openUrl: (client, host, port, path) => client.head(host, port, path),
        hybrid: hybrid,
      );
    });

    test('client.headUrl(...)', () async {
      await _testClient(
        method: 'HEAD',
        path: '/greeting',
        openUrl: (client, uri) => client.headUrl(uri),
        expectedBody: '', // <-- HEAD response doesn't have body
        hybrid: hybrid,
      );
    });

    // -----
    // PATCH
    // -----

    test('client.patch(...)', () async {
      await _testClientMethodWithoutUri(
        method: 'PATCH',
        openUrl: (client, host, port, path) => client.patch(host, port, path),
        hybrid: hybrid,
      );
    });

    test('client.patchUrl(...)', () async {
      await _testClient(
        method: 'PATCH',
        path: '/greeting',
        openUrl: (client, uri) => client.patchUrl(uri),
        expectedBody: 'Hello world! (PATCH)',
        hybrid: hybrid,
      );
    });

    // ----
    // POST
    // ----

    test('client.post(...)', () async {
      await _testClientMethodWithoutUri(
        method: 'POST',
        openUrl: (client, host, port, path) => client.post(host, port, path),
        hybrid: hybrid,
      );
    });

    test('client.postUrl(...)', () async {
      await _testClient(
        method: 'POST',
        path: '/greeting',
        openUrl: (client, uri) => client.postUrl(uri),
        expectedBody: 'Hello world! (POST)',
        hybrid: hybrid,
      );
    });

    // ---
    // PUT
    // ---

    test('client.put(...)', () async {
      await _testClientMethodWithoutUri(
        method: 'PUT',
        openUrl: (client, host, port, path) => client.put(host, port, path),
        hybrid: hybrid,
      );
    });

    test('client.putUrl(...)', () async {
      await _testClient(
        method: 'PUT',
        path: '/greeting',
        openUrl: (client, uri) => client.putUrl(uri),
        expectedBody: 'Hello world! (PUT)',
        hybrid: hybrid,
      );
    });

    test('TLS connection to a self-signed server fails', () async {
      final server = await ExampleHttpServer.bind(hybrid: hybrid);
      addTearDown(() {
        server.close();
      });
      final client = HttpClient();
      final port = server.port;
      final uri = Uri.parse('https://localhost:$port/greeting');
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
          'TLS connection to a self-signed server succeeds with'
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
        final uri = Uri.parse('https://localhost:$port/greeting');
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
  Map<String, String> headers = const <String, String>{},

  /// Request body
  String requestBody,

  /// Expected status
  int expectedStatus = 200,

  /// Expected response body.
  String expectedBody,

  /// Function for opening HTTP request
  Future<HttpClientRequest> Function(HttpClient client, Uri uri) openUrl,

  /// Use hybrid server?
  @required bool hybrid,

  /// Are we expecting XMLHttpRequest error?
  bool xmlHttpRequestError = false,
}) async {
  if (method == null) {
    throw ArgumentError.notNull('method');
  }
  if (path == null) {
    throw ArgumentError.notNull('path');
  }

  // Wait for the server to be listening
  final server = await ExampleHttpServer.bind(hybrid: hybrid);
  addTearDown(() {
    server.close();
  });

  // Send HTTP request
  final client = HttpClient();
  HttpClientRequest request;
  final host = 'localhost';
  final port = server.port;
  final uri = Uri.parse('http://$host:$port$path');
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
  headers.forEach((name, value) {
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
  expect(response.statusCode, expectedStatus);

  // Check response headers
  expect(response.headers.value('X-Response-Header'), 'value');

  // Check response body
  if (expectedBody != null) {
    expect(actualResponseBody, expectedBody);
  }

  // Check the request that the server received
  expect(
      await server.requestsQueue.hasNext
          .timeout(const Duration(milliseconds: 200)),
      isTrue);
  final requestInfo = await server.requestsQueue.next;
  expect(requestInfo.method, method);
  expect(requestInfo.uri, '$path');
  expect(requestInfo.body, requestBody ?? '');

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
    throw ArgumentError.notNull('method');
  }

  // Wait for the server to be listening
  final server = await ExampleHttpServer.bind(hybrid: hybrid);
  addTearDown(() {
    server.close();
  });

  // Create a HTTP client
  final client = HttpClient();

  // Create a HTTP request
  final host = 'localhost';
  final port = server.port;
  final path = '/greeting';
  final request = await openUrl(client, host, port, path);

  // Test that the request seems correct
  expect(request.uri.scheme, 'http');
  expect(request.uri.host, 'localhost');
  expect(request.uri.port, port);
  expect(request.uri.path, path);

  // Close request
  final response = await request.close();
  await utf8.decodeStream(response.cast<List<int>>());
  expect(response.statusCode, 200);
}
