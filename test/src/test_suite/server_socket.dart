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

import 'package:test/test.dart';
import 'package:universal_io/io.dart';

void testRawServerSocket() {
  group("RawServerSocket", () {
    test("RawServerSocket.bind(null, 12345) should fail", () async {
      await expectLater(
        () => RawServerSocket.bind(null, 12345),
        throwsArgumentError,
      );
    });

    test("RawServerSocket.bind('localhost', null) should fail", () async {
      await expectLater(
        () => RawServerSocket.bind('localhost', null),
        throwsArgumentError,
      );
    });

    test("RawServerSocket.bind('localhost', 12345) should succeed", () async {
      final server = await RawServerSocket.bind(
        'localhost',
        12345,
      );
      addTearDown(() {
        server.close();
      });

      expect(server.port, 12345);
      // ignore: unawaited_futures
      server.close();
      expect(await server.toList(), []);
    });

    test("RawServerSocket.bind(InternetAddress.loopbackIPv4, 0) should succeed",
        () async {
      final server = await RawServerSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      addTearDown(() {
        server.close();
      });

      expect(server.port, greaterThan(0));
      // ignore: unawaited_futures
      server.close();
      expect(await server.toList(), []);
    });

    test("RawServerSocket.bind(InternetAddress.loopbackIPv6, 0) should succeed",
        () async {
      final server = await RawServerSocket.bind(
        InternetAddress.loopbackIPv6,
        0,
      );
      addTearDown(() {
        server.close();
      });

      expect(server.port, greaterThan(0));
      // ignore: unawaited_futures
      server.close();
      expect(await server.toList(), []);
    }, tags: ["ipv6"]);
  });

  group("ServerSocket", () {
    test("ServerSocket.bind(null, 12345) should fail", () async {
      await expectLater(
        () => ServerSocket.bind(null, 12345),
        throwsArgumentError,
      );
    });

    test("ServerSocket.bind('localhost', null) should fail", () async {
      await expectLater(
        () => ServerSocket.bind('localhost', null),
        throwsArgumentError,
      );
    });

    test("ServerSocket.bind('localhost', 12345) should succeed", () async {
      final server = await ServerSocket.bind('localhost', 12345);
      addTearDown(() {
        server.close();
      });

      expect(server.port, 12345);
      // ignore: unawaited_futures
      server.close();
      expect(await server.toList(), []);
    });

    test("ServerSocket.bind(InternetAddress.loopbackIPv4, 0) should succeed",
        () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() {
        server.close();
      });

      expect(server.port, greaterThan(0));
      // ignore: unawaited_futures
      server.close();
      expect(await server.toList(), []);
    });

    test("ServerSocket.bind(InternetAddress.loopbackIPv6, 0) should succeed",
        () async {
      final server = await ServerSocket.bind(InternetAddress.loopbackIPv6, 0);
      addTearDown(() {
        server.close();
      });

      expect(server.port, greaterThan(0));
      // ignore: unawaited_futures
      server.close();
      expect(await server.toList(), []);
    }, tags: ["ipv6"]);
  });
}
