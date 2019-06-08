import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'dart:convert';
import 'package:meta/meta.dart';
import 'dart:async';

void testHttpServer() {
  group("HttpServer", () {
    test("bind(...)", () async {
      final httpServer = await HttpServer.bind("127.0.0.1", 0);
      expect(httpServer, isNotNull);
      try {
        await _runTest(httpServer, scheme: "http");
      } finally {
        await httpServer.close(force: true);
      }
    });

    test("bindSecure(...)", () async {
      final securityContext = SecurityContext();
      securityContext.useCertificateChain("test/src/test_suite/localhost.crt");
      securityContext.usePrivateKey("test/src/test_suite/localhost.key");

      final httpServer = await HttpServer.bindSecure(
        "127.0.0.1",
        0,
        securityContext,
      );
      expect(httpServer, isNotNull);
      try {
        await _runTest(httpServer, scheme: "https");
      } finally {
        await httpServer.close(force: true);
      }
    });
  });
}

Future<void> _runTest(HttpServer httpServer, {@required String scheme}) async {
  final port = httpServer.port;
  expect(port, greaterThan(0));

  httpServer.listen(expectAsync1((request) async {
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
