@TestOn("chrome")
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'package:async/async.dart';
import 'dart:async';

void main() {
  commonTests();
  browserTests();
}

String testHost = "localhost";
int testPort = 54321;
Uri testUrl = Uri.parse("http://$testHost:$testPort/path?q");

void commonTests() {
  group("HttpClient tests for all platforms:", () {
    test("GET failure", () async {
      final client = HttpClient();
      try {
        final request = await client.get(testHost, testPort, "/path?q");
        await request.close();
        fail("Connection should have failed.");
      } catch (e) {
        expect(e, const TypeMatcher<SocketException>());
      }
    });
    test("GET", () async {
      // Launch HTTP server
      final channel = await spawnHybridUri(Uri.parse("/test/http_server.dart"));
      final stream = channel.stream.asBroadcastStream();
      stream.listen((message) async {
        // Read port where the server is
        final port = (message as Map)["port"] as int;
        final url = Uri.parse("http://localhost:$port/path?q");

        // Send HTTP request
        final client = new HttpClient();
        final request = await client.getUrl(url);
        final response = await request.close();

        // Check that we received a correct-looking response
        expect(response, isNotNull);
        expect(response.headers["Content-Type"], isNotEmpty);
        final bytes = await collectBytes(response);
        expect(new String.fromCharCodes(bytes), equals("Hello!"));
      });
    });
  });
}

void browserTests() {
  group("HttpClient tests for browser:", () {
    test("methods: ", () async {
      final client = new HttpClient();
      Future testMethod(String method, Future<HttpClientRequest> f(),
          {String scheme: "http"}) async {
        final request = await f();
        final reason =
            "expected request: '${method.toUpperCase()} ${testUrl.toString()}'\nactual request: ${request.method} ${request.uri}";
        expect(request.method, equals(method.toUpperCase()), reason: reason);
        expect(request.uri.scheme, equals(scheme), reason: reason);
        expect(request.uri.host, equals(testUrl.host), reason: reason);
        expect(request.uri.port, equals(testUrl.port), reason: reason);
        expect(request.uri.path, equals(testUrl.path), reason: reason);
        expect(request.uri.fragment, equals(testUrl.fragment), reason: reason);
      }

      await testMethod(
          "delete", () => client.delete(testHost, testPort, "/path?q"),
          scheme: "https");
      await testMethod("get", () => client.get(testHost, testPort, "/path?q"),
          scheme: "https");
      await testMethod("head", () => client.head(testHost, testPort, "/path?q"),
          scheme: "https");
      await testMethod(
          "patch", () => client.patch(testHost, testPort, "/path?q"),
          scheme: "https");
      await testMethod("post", () => client.post(testHost, testPort, "/path?q"),
          scheme: "https");
      await testMethod("put", () => client.put(testHost, testPort, "/path?q"),
          scheme: "https");

      await testMethod("delete", () => client.deleteUrl(testUrl));
      await testMethod("get", () => client.getUrl(testUrl));
      await testMethod("head", () => client.headUrl(testUrl));
      await testMethod("patch", () => client.patchUrl(testUrl));
      await testMethod("post", () => client.postUrl(testUrl));
      await testMethod("put", () => client.putUrl(testUrl));
    });
  });
}
