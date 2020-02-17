// Copyright 2019 terrier989@gmail.com.
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

import 'dart:convert';

import 'package:nodejs_io/nodejs_io.dart';
import 'package:test/test.dart';
import 'package:universal_io/driver.dart';
import 'package:universal_io/prefer_universal/io.dart';

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
