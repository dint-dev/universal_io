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

@Timeout(Duration(seconds: 2))
library secure_socket_test;

import 'dart:convert';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';
import 'localhost_certificate.dart';

void testSecureSocket({bool secureServerSocket = true}) {
  test("SecurityContext()", () async {
    SecurityContext();
  });

  test("SecurityContext.defaultContext()", () async {
    SecurityContext.defaultContext;
  });

  group("SecureServerSocket", () {
    test("bind(...)", () async {
      final server = await SecureServerSocket.bind(
        InternetAddress.loopbackIPv6,
        0,
        SecurityContext.defaultContext,
      ).timeout(const Duration(seconds: 1));
      addTearDown(() {
        server.close();
      });
      expect(server.port, greaterThan(0));
      await server.close();
    });
  });

  group("SecureSocket", () {
    if (secureServerSocket) {
      test("communicates with SecureServerSocket (with a bad certificate)",
          () async {
        final server = await SecureServerSocket.bind(
          InternetAddress.loopbackIPv6,
          0,
          localHostSecurityContext(),
        ).timeout(const Duration(seconds: 1));

        addTearDown(() {
          server.close();
        });

        server.listen(expectAsync1((socket) async {
          socket.write("Hello from server");

          // We assume that everything arrives in a single read
          final received = await utf8.decodeStream(socket);
          expect(received, "Hello from client");
          await socket.close();
        }));

        expect(server.port, greaterThan(0));

        final client = await SecureSocket.connect(
          server.address,
          server.port,
          onBadCertificate: expectAsync1((certificate) => true),
        ).timeout(const Duration(seconds: 1));

        addTearDown(() {
          client.close();
        });

        final clientReceivedFuture = utf8.decodeStream(client);

        client.write("Hello from client");

        await client.close();

        expect(await clientReceivedFuture, "Hello from server");

        await server.close();
      });
    }
  });
}
