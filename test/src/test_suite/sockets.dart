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
library sockets_test;

import 'dart:async';
import 'dart:convert';

import 'package:async/async.dart';
import 'package:test/test.dart';
import 'package:universal_io/io.dart';

void testSockets({int times = 1}) {
  final f = () {
    testRawDatagramSocket();
    testRawSocket();
  };
  if (times == 1) {
    f();
  } else {
    // To deal with non-deterministic behavior,
    // we run the same test many times.
    for (var i = 0; i < 10; i++) {
      group("Repeat #$i", () {
        f();
      });
    }
  }
}

void testRawDatagramSocket() {
  test("RawDatagramSocket", () async {
    // ----------------
    // Bind two sockets
    // ----------------
    final socket0 = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() {
      socket0.close();
    });

    final socket1 = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
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
        expect(utf8.decode(datagram.data), "S1/M0");
        expect(datagram.address, peerSocket.address);
        expect(datagram.port, peerSocket.port);
      }

      // Send a message
      {
        final data = utf8.encode("S0/M0");
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
        expect(utf8.decode(datagram.data), "S1/M1");
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
        final data = utf8.encode("S1/M0");
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
        expect(utf8.decode(datagram.data), "S0/M0");
        expect(datagram.address, peerSocket.address);
        expect(datagram.port, peerSocket.port);
      }

      // Send a message
      {
        final data = utf8.encode("S1/M1");
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
}

void testRawSocket() {
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
  });
}
