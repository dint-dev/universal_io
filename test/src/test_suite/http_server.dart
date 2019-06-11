import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

void testHttpServer({bool httpClient = true}) {
  group("HttpServer", () {
    test("HttpServer.bind(null, 12345) should fail", () async {
      await expectLater(
        () => HttpServer.bind(null, 12345),
        throwsArgumentError,
      );
    });

    test("HttpServer.bind('localhost', null) should fail", () async {
      await expectLater(
        () => HttpServer.bind('localhost', null),
        throwsArgumentError,
      );
    });

    test("HttpServer.bind('localhost', 12345) should succeed", () async {
      final server = await HttpServer.bind('localhost', 12345);
      expect(server, isNotNull);
      expect(server.port, 12345);
      // ignore: unawaited_futures
      server.close();
      expect(await server.toList(), []);
    });

    test("HttpServer.bind(InternetAddress.loopbackIPv4, 0) should succeed",
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      expect(server, isNotNull);
      expect(server.port, greaterThan(0));
      // ignore: unawaited_futures
      server.close();
      expect(await server.toList(), []);
    });

    test("HttpServer.bind(InternetAddress.loopbackIPv6, 0) should succeed",
        () async {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv6, 0);
      expect(server, isNotNull);
      expect(server.port, greaterThan(0));
      // ignore: unawaited_futures
      server.close();
      expect(await server.toList(), []);
    });

    test(
        "HttpServer.bindSecure(InternetAddress.loopbackIPv6, 0, context) should succeed",
        () async {
      final context = SecurityContext.defaultContext;
      final server = await HttpServer.bindSecure(
        InternetAddress.loopbackIPv6,
        0,
        context,
      );
      expect(server, isNotNull);
      expect(server.port, greaterThan(0));
      // ignore: unawaited_futures
      server.close();
      expect(await server.toList(), []);
    });

    if (httpClient) {
      test("Should respond to HttpClient", () async {
        final server = await HttpServer.bind("127.0.0.1", 0);
        expect(server, isNotNull);
        try {
          await _runTest(server, scheme: "http");
        } finally {
          await server.close(force: true);
        }
      });

      test("bindSecure(...): responds to HttpClient", () async {
        final securityContext = SecurityContext();
        securityContext
            .useCertificateChain("test/src/test_suite/localhost.crt");
        securityContext.usePrivateKey("test/src/test_suite/localhost.key");

        final server = await HttpServer.bindSecure(
          "127.0.0.1",
          0,
          securityContext,
        );
        expect(server, isNotNull);
        try {
          await _runTest(server, scheme: "https");
        } finally {
          await server.close(force: true);
        }
      });
    }
  });
}

Future<void> _runTest(HttpServer server, {@required String scheme}) async {
  final port = server.port;
  expect(port, greaterThan(0));

  server.listen(expectAsync1((request) async {
    final requestBody = await utf8.decodeStream(request);
    expect(
      request.uri.toString(),
      "/path?query",
    );
    expect(request.headers.value("X-Request-Header0"), "request-value0");
    expect(request.headers.value("X-Request-Header1"), "request-value1");
    expect(requestBody, "request body");

    // Write response
    final response = request.response;
    response.headers.set("X-Response-Header0", "response-value0");
    response.headers.set("X-Response-Header1", "response-value1");
    response.write("response body");
    await response.close();
  }));

  final client = HttpClient();
  client.badCertificateCallback = (certificate, host, port) {
    return true;
  };

  final requestUri = Uri.parse("$scheme://localhost:$port/path?query");
  final request = await client.postUrl(requestUri);
  request.headers.set("X-Request-Header0", "request-value0");
  request.headers.set("X-Request-Header1", "request-value1");
  request.write("request body");
  final response = await request.close();
  final responseBody = await utf8.decodeStream(response);
  expect(response.statusCode, 200);
  expect(response.headers.value("X-Response-Header0"), "response-value0");
  expect(response.headers.value("X-Response-Header1"), "response-value1");
  expect(responseBody, "response body");
}
