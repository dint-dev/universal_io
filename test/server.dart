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
import 'dart:io';

import 'package:stream_channel/stream_channel.dart';

void hybridMain(StreamChannel streamChannel, Object message) async {
  final securityContext = SecurityContext();
  const testSuitePath = 'test';
  securityContext.useCertificateChain('$testSuitePath/localhost.crt');
  securityContext.usePrivateKey('$testSuitePath/localhost.key');

  final server = await HttpServer.bind('localhost', 0);
  print('Server #1 is listening at: http://localhost:${server.port}/');
  streamChannel.sink.add(server.port);

  final secureServer = await HttpServer.bindSecure(
    'localhost',
    0,
    securityContext,
  );
  print('Server #2 is listening at: https://localhost:${secureServer.port}/');
  streamChannel.sink.add(secureServer.port);

  try {
    final f0 = server.listen(_handleHttpRequest).asFuture();
    final f1 = secureServer.listen(_handleHttpRequest).asFuture();
    await Future.wait([f0, f1]);
  } finally {
    await Future.wait([server.close(), secureServer.close()]);
  }
}

void _handleHttpRequest(HttpRequest request) async {
  // Respond based on the path
  final requestBody = await utf8.decodeStream(request);
  final response = request.response;
  try {
    void preflight() {
      final userAgent = request.headers.value('User-Agent') ?? '';
      var origin = request.headers.value('Origin');
      if (origin == null) {
        if (!userAgent.contains('Dart')) {
          print('INVALID ORIGIN: $origin');
        }
        origin = '*';
      }
      response.headers.set('Access-Control-Allow-Origin', '*');
      response.headers.set('Access-Control-Allow-Methods', '*');
      response.headers.set('Access-Control-Expose-Headers', '*');
      final isCredentialsMode =
          request.uri.queryParameters['credentials'] == 'true';
      if (isCredentialsMode) {
        response.headers.set('Access-Control-Allow-Origin', origin);
        response.headers.set('Access-Control-Allow-Credentials', 'true');
        response.headers.set(
          'Access-Control-Allow-Methods',
          'DELETE, GET, HEAD, PATCH, POST, PUT',
        );
        response.headers.set(
          'Access-Control-Expose-Headers',
          'X-Request-Method, X-Request-Path, X-Request-Body, X-Response-Header',
        );
      }
    }

    // Set some response headers to reflect the request
    response.headers.set('X-Request-Method', request.method);
    response.headers.set('X-Request-Path', request.uri.path);
    response.headers.set('X-Request-Body', requestBody);
    response.headers.set('X-Response-Header', 'value');

    // Use "text/plain" content type for all responses
    response.headers.contentType = ContentType.text;

    response.statusCode = HttpStatus.ok;

    switch (request.uri.path) {
      case '/greeting':
        switch (request.method) {
          case 'OPTIONS':
            preflight();
            break;
          case 'GET':
            preflight();
            response.statusCode = HttpStatus.ok;
            response.write('Hello world! (${request.method})');
            break;
          default:
            preflight();
            response.statusCode = HttpStatus.methodNotAllowed;
            break;
        }

      case '/invalid_utf8':
        switch (request.method) {
          case 'OPTIONS':
            preflight();
            break;
          case 'GET':
            preflight();
            response.statusCode = HttpStatus.ok;
            response.add([0x80]);
            break;
          default:
            preflight();
            response.statusCode = HttpStatus.methodNotAllowed;
            break;
        }

      case '/report_method':
        switch (request.method) {
          case 'OPTIONS':
            preflight();
            break;
          default:
            preflight();
            response.statusCode = HttpStatus.ok;
            response.write('Method: ${request.method}');
            break;
        }

      case '/report_body':
        switch (request.method) {
          case 'OPTIONS':
            preflight();
            break;
          case 'POST':
            preflight();
            response.statusCode = HttpStatus.ok;
            response.write('Received: $requestBody');
            break;
          default:
            response.statusCode = HttpStatus.methodNotAllowed;
            break;
        }

      case '/streaming_response':
        switch (request.method) {
          case 'OPTIONS':
            preflight();
            break;
          case 'GET' || 'POST':
            preflight();
            response.bufferOutput = false;
            response.statusCode = HttpStatus.ok;
            response.headers.set('Cache-Control', 'no-cache');
            response.headers.chunkedTransferEncoding = true;
            response.writeln('First part.');
            await response.flush();
            await Future.delayed(const Duration(milliseconds: 500));

            response.writeln('Second part.');
            await response.flush();
            await Future.delayed(const Duration(milliseconds: 500));
            break;
          default:
            response.statusCode = HttpStatus.methodNotAllowed;
            break;
        }

      case '/server_sets_cookie':
        switch (request.method) {
          case 'OPTIONS':
            preflight();
            break;
          case 'GET':
            preflight();
            final name = request.uri.queryParameters['name']!;
            final value = request.uri.queryParameters['value']!;
            response.statusCode = HttpStatus.ok;
            response.cookies.add(Cookie(name, value));
            break;
          default:
            response.statusCode = HttpStatus.methodNotAllowed;
            break;
        }

      case '/server_receives_cookie':
        switch (request.method) {
          case 'OPTIONS':
            preflight();
            break;
          case 'GET':
            preflight();
            final name = request.uri.queryParameters['name']!;
            final value = request.uri.queryParameters['value']!;
            // Not tested in browser
            final ok = request.cookies.any(
              (cookie) => cookie.name == name && cookie.value == value,
            );
            if (ok) {
              response.statusCode = HttpStatus.ok;
            } else {
              response.statusCode = HttpStatus.unauthorized;
            }
            break;
          default:
            response.statusCode = HttpStatus.methodNotAllowed;
            break;
        }

      case '/report_authorization':
        switch (request.method) {
          case 'OPTIONS':
            preflight();
            response.headers.set('Access-Control-Allow-Credentials', 'true');
            response.headers.set(
              'Access-Control-Allow-Headers',
              'Authorization',
            );
            break;
          case 'POST':
            preflight();
            final authorization = request.headers.value(
              HttpHeaders.authorizationHeader,
            );

            if (authorization == 'example') {
              response.statusCode = HttpStatus.ok;
            } else {
              response.statusCode = HttpStatus.unauthorized;
            }
            response.write(authorization);
            break;
          default:
            response.statusCode = HttpStatus.methodNotAllowed;
            break;
        }

      default:
        preflight();
        response.statusCode = HttpStatus.notFound;
        response.write("Not found: ${request.uri.path}");
        break;
    }
  } finally {
    await response.close();
  }
}
