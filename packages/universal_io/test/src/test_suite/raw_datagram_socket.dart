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

import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:universal_io/prefer_universal/io.dart';

void testRawDatagramSocket() {
  group('RawDatagramSocket', () {
    test('RawDatagramSocket.bind(null, 12345) should fail', () async {
      await expectLater(
        () => RawDatagramSocket.bind(null, 12345),
        throwsA(const TypeMatcher<ArgumentError>()),
      );
    });

    test("RawDatagramSocket.bind('localhost', null) should fail", () async {
      await expectLater(
        () => RawDatagramSocket.bind('localhost', null),
        throwsA(const TypeMatcher<ArgumentError>()),
      );
    });

    test("RawDatagramSocket.bind('localhost', 12345) should succeed", () async {
      final socket = await RawDatagramSocket.bind(
        'localhost',
        12345,
      ).timeout(Duration(seconds: 5));
      addTearDown(() {
        socket.close();
      });

      expect(socket.port, 12345);
      socket.close();
      expect(await socket.toList(), [RawSocketEvent.closed]);
    });

    test(
        'RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 12345): should succeed',
        () async {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      ).timeout(Duration(seconds: 5));
      addTearDown(() {
        socket.close();
      });

      expect(socket.port, greaterThan(0));
      socket.close();
      expect(await socket.toList(), [RawSocketEvent.closed]);
    });

    test(
        'RawDatagramSocket.bind(InternetAddress.loopbackIPv4, 0) should succeed',
        () async {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      ).timeout(Duration(seconds: 5));
      addTearDown(() {
        socket.close();
      });

      expect(socket.port, greaterThan(0));
      socket.close();
      expect(await socket.toList(), [RawSocketEvent.closed]);
    });

    test(
        'RawDatagramSocket.bind(InternetAddress.loopbackIPv6, 12345) should succeed',
        () async {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv6,
        12345,
      ).timeout(Duration(seconds: 5));
      addTearDown(() {
        socket.close();
      });

      expect(socket.port, 12345);
      socket.close();
      expect(await socket.toList(), [RawSocketEvent.closed]);
    }, tags: ['ipv6']);

    test(
        'RawDatagramSocket.bind(InternetAddress.loopbackIPv6, 0) should succeed',
        () async {
      final socket = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv6,
        0,
      ).timeout(Duration(seconds: 5));
      addTearDown(() {
        socket.close();
      });

      expect(socket.port, greaterThan(0));
      socket.close();
      expect(await socket.toList(), [RawSocketEvent.closed]);
    }, tags: ['ipv6']);

    test('Two sockets communicate with each other', () async {
      // ----------------
      // Bind two sockets
      // ----------------
      final socket0 = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      ).timeout(Duration(seconds: 5));
      addTearDown(() {
        socket0.close();
      });

      final socket1 = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      ).timeout(Duration(seconds: 5));
      ;
      addTearDown(() {
        socket1.close();
      });

      // --------
      // Socket 0
      // --------
      final socket0Done = () async {
        final thisSocket = socket0;
        final peerSocket = socket1;
        final events = StreamQueue<RawSocketEvent>(thisSocket);

        // Receive a message
        {
          expect(await events.next, RawSocketEvent.write);
          final datagram = thisSocket.receive();
          expect(utf8.decode(datagram.data), 'S1/M0');
          expect(datagram.address, peerSocket.address);
          expect(datagram.port, peerSocket.port);
        }

        // Send a message
        {
          final data = utf8.encode('S0/M0');
          final result = thisSocket.send(
            data,
            peerSocket.address,
            peerSocket.port,
          );
          expect(result, data.length);
          expect(await events.next, RawSocketEvent.read);
        }

        // Receive a message
        {
          expect(await events.next, RawSocketEvent.read);
          final datagram = thisSocket.receive();
          expect(utf8.decode(datagram.data), 'S1/M1');
          expect(datagram.address, peerSocket.address);
          expect(datagram.port, peerSocket.port);
        }

        // Close server
        {
          socket0.close();
          expect(await events.rest.toList(), [RawSocketEvent.closed]);
        }
      }();

      // --------
      // Socket 1
      // --------
      final socket1Done = () async {
        final thisSocket = socket1;
        final peerSocket = socket0;
        final events = StreamQueue<RawSocketEvent>(thisSocket);

        // Send a message
        {
          final data = utf8.encode('S1/M0');
          final result = thisSocket.send(
            data,
            peerSocket.address,
            peerSocket.port,
          );
          expect(result, data.length);

          // The first message should fire 'write'
          expect(await events.next, RawSocketEvent.write);
        }

        // Receive a message
        {
          expect(await events.next, RawSocketEvent.read);
          final datagram = thisSocket.receive();
          expect(utf8.decode(datagram.data), 'S0/M0');
          expect(datagram.address, peerSocket.address);
          expect(datagram.port, peerSocket.port);
        }

        // Send a message
        {
          final data = utf8.encode('S1/M1');
          final result = thisSocket.send(
            data,
            peerSocket.address,
            peerSocket.port,
          );
          expect(result, data.length);
        }

        // Close the socket
        {
          thisSocket.close();
          expect(await events.rest.toList(), [RawSocketEvent.closed]);
        }
      }();

      // Wait both tests to finish
      await Future.wait(<Future>[
        socket0Done,
        socket1Done,
      ]);
    });
  });
}
