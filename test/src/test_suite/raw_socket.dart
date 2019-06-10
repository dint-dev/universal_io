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
library raw_socket_test;

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

void testRawSocket() {
  group("RawSocket", () {
    test("RawSocket.connect('localhost', badPort) should fail", () {
      expect(
        () => RawSocket.connect("localhost", 23456),
        throwsA(TypeMatcher<SocketException>()),
      );
    });
  });
  group("Socket", () {
    test("Socket.connect('localhost', badPort) should fail", () {
      expect(
        () => Socket.connect("localhost", 23456),
        throwsA(TypeMatcher<SocketException>()),
      );
    });
  });
}

void testRawSocketAndRawServerSocket() {
  test("RawSocket + RawServerSocket", () async {
    // ----------------
    // Bind two sockets
    // ----------------
    final server = await RawServerSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() {
      server.close();
    });

    final client = await RawSocket.connect(
      server.address,
      server.port,
    );
    addTearDown(() {
      client.close();
    });

    // -------------------
    // Server expectations
    // -------------------
    final serverDone = () async {
      // Wait for the first TCP connection.
      final socket = await server.first;
      final events = StreamQueue<RawSocketEvent>(socket);

      // Close server
      await server.close();

      // Receive a message
      expect(await events.next, RawSocketEvent.read);
      expect(utf8.decode(socket.read()), "Client/0");

      // Send a message
      {
        final data = utf8.encode("Server/0");
        final result = socket.write(data);
        expect(result, data.length);
        expect(await events.next, RawSocketEvent.write);
      }

      // Receive 'readClosed'
      expect(await events.next, RawSocketEvent.readClosed);

      // Close socket
      await socket.close();
      expect(await events.rest.toList(), [RawSocketEvent.closed]);
    }();

    // -------------------
    // Client expectations
    // -------------------
    final clientDone = () async {
      // Start collecting timeline of TCP events
      final socket = client;
      final events = StreamQueue<RawSocketEvent>(socket);

      // Send a message
      {
        final data = utf8.encode("Client/0");
        final result = socket.write(data);
        expect(result, data.length);
        expect(await events.next, RawSocketEvent.write);
      }

      // Receive a message
      expect(await events.next, RawSocketEvent.read);
      expect(utf8.decode(socket.read()), "Server/0");

      // Close the socket
      await socket.close();
      expect(await events.rest.toList(), [
        RawSocketEvent.closed,
      ]);
    }();

    // Wait both tests to finish
    await Future.wait(<Future>[
      serverDone,
      clientDone,
    ]);
  }, timeout: Timeout(Duration(seconds: 1)));
}
