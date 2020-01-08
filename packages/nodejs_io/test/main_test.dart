import 'package:nodejs_io/nodejs_io.dart';
import 'package:test/test.dart';
import 'package:universal_io/driver.dart';
import 'package:universal_io/prefer_universal/io.dart';
import 'dart:convert';

void main() {
  setUp(() {
    IODriver.zoneLocal.defaultValue = nodeJsIODriver;
  });

  test('HttpClient / HttpServer', () async {
    final httpServer = await HttpServer.bind('localhost', 8989);
    httpServer.listen((request) async {
      expect(request.method, 'POST');
      expect(request.uri.path, '/path');
      expect(request.headers.value('request-header'), 'value');

      // Request bodies can't be read at the moment. :/
//      final requestBody = await utf8.decodeStream(request);
//      expect(requestBody, 'request-body');

      request.response.statusCode = 500;
      request.response.headers.set('response-header', 'value');
      request.response.write('response-body');
      await request.response.close();
    });
    addTearDown(() async {
      return httpServer.close();
    });
    final httpClient = HttpClient();
    final httpRequest = await httpClient.post(
      httpServer.address.address,
      httpServer.port,
      '/path',
    );
    httpRequest.headers.set('request-header', 'value');
    httpRequest.write('request-body');
    final httpResponse = await httpRequest.close();
    expect(httpResponse.statusCode, 500);
    expect(httpResponse.headers.value('response-header'), 'value');
    final responseBody = await utf8.decodeStream(httpResponse);
    expect(responseBody, 'response-body');
  });
}
