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
    final server = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    addTearDown(() {
      server.close();
    });

    final client = await RawDatagramSocket.bind(
      InternetAddress.loopbackIPv4,
      0,
    );
    final clientPort = client.port;
    final clientAddress = client.address;
    addTearDown(() {
      client.close();
    });

    // -------------------
    // Server expectations
    // -------------------
    final serverDone = () async {
      // Collect a timeline of UDP events
      final timeline = await _RawDatagramSocketTimeline.collect(server);

      // Is the events correct?
      expect(
          timeline.events,
          [
            RawSocketEvent.write,
            RawSocketEvent.read,
            RawSocketEvent.closed,
          ],
          reason: "UDP server observed an unexpected sequence of events");

      // Are the received datagrams correct?
      expect(timeline.datagrams, hasLength(1));
      final datagram = timeline.datagrams.single;
      expect(datagram, isNotNull);
      expect(datagram.port, clientPort);
      expect(datagram.address, clientAddress);
      expect(utf8.decode(datagram.data), "This was sent by the client");
    }();

    // -------------------
    // Client expectations
    // -------------------
    final clientDone = () async {
      // Start collecting a timeline of UDP events
      final timelineFuture = _RawDatagramSocketTimeline.collect(client);

      // Send a greeting
      final data = utf8.encode("This was sent by the client");
      final result = client.send(
        data,
        server.address,
        server.port,
      );
      expect(result, data.length);

      // Wait for the timeline to be ready
      final timeline = await timelineFuture;

      // Are the events correct?
      expect(
          timeline.events,
          [
            RawSocketEvent.write,
            RawSocketEvent.closed,
          ],
          reason: "UDP client observed an unexpected sequence of events");
    }();

    // Wait both tests to finish
    await Future.wait(<Future>[
      serverDone,
      clientDone,
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
      // Wait for the first TCP connection,
      // then stop listening for TCP connections.
      final socket = await server.first;
      await server.close();

      // Start collecting timeline of TCP events
      final timelineFuture = _RawSocketTimeline.collect(socket);

      // Send a greeting
      final data = utf8.encode("This was sent by the server");
      final result = socket.write(data);
      expect(result, data.length);

      // Wait for the timeline to be ready
      final timeline = await timelineFuture;

      // Are the events correct?
      expect(
          timeline.events,
          [
            RawSocketEvent.read,
            RawSocketEvent.write,
            RawSocketEvent.readClosed,
            RawSocketEvent.closed,
          ],
          reason: "TCP server observed an unexpected sequence of events");

      // Is the received data correct?
      expect(timeline.received, "This was sent by the client");
    }();

    // -------------------
    // Client expectations
    // -------------------
    final clientDone = () async {
      // Start collecting timeline of TCP events
      final socket = client;
      final timelineFuture = _RawSocketTimeline.collect(socket);

      // Send a greeting
      final data = utf8.encode("This was sent by the client");
      final result = socket.write(data);
      expect(result, data.length);
      await Future.delayed(const Duration(milliseconds: 100));
      await socket.close();

      // Wait for the timeline to be ready
      final timeline = await timelineFuture;

      // Are the events correct?
      expect(
          timeline.events,
          [
            RawSocketEvent.write,
            RawSocketEvent.read,
            RawSocketEvent.closed,
          ],
          reason: "TCP client observed an unexpected sequence of events");

      // Is the received data correct?
      expect(timeline.received, "This was sent by the server");
    }();

    // Wait both tests to finish
    await Future.wait(<Future>[
      serverDone,
      clientDone,
    ]);
  });
}

/// A helper that builds a timeline of [RawDatagramSocket] events.
class _RawDatagramSocketTimeline {
  final List<RawSocketEvent> events;
  final List<Datagram> datagrams;

  _RawDatagramSocketTimeline(this.events, this.datagrams);

  /// Collects all events during the period (default: 200 milliseconds).
  static Future<_RawDatagramSocketTimeline> collect(RawDatagramSocket socket,
      {Duration timeout = const Duration(milliseconds: 500)}) async {
    // Create a timer that will close the socket
    var isClosed = false;
    Timer(timeout, () {
      if (!isClosed) {
        socket.close();
      }
    });

    // Collect events and datagrams
    final events = <RawSocketEvent>[];
    final datagrams = <Datagram>[];
    try {
      await for (var event in socket) {
        if (event == RawSocketEvent.read) {
          datagrams.add(socket.receive());
        }
        events.add(event);
      }
    } finally {
      isClosed = true;
    }

    // OK, return the timeline
    return _RawDatagramSocketTimeline(events, datagrams);
  }
}

/// A helper that builds a timeline of [RawSocket] events.
class _RawSocketTimeline {
  final List<RawSocketEvent> events;
  final String received;

  _RawSocketTimeline(this.events, this.received);

  /// Collects all events during the period (default: 200 milliseconds).
  static Future<_RawSocketTimeline> collect(RawSocket socket,
      {Duration timeout = const Duration(milliseconds: 500)}) async {
    // Create a timer that will close the socket.
    var isClosed = false;
    Timer(timeout, () {
      if (!isClosed) {
        socket.close();
      }
    });

    // Collect events and data.
    final events = <RawSocketEvent>[];
    final data = <int>[];
    try {
      await for (var event in socket) {
        if (event == RawSocketEvent.read) {
          data.addAll(socket.read());
        }
        events.add(event);
      }
    } finally {
      isClosed = true;
    }

    // Decode UTF-8.
    final content = utf8.decode(data);

    // OK, return the timeline
    return _RawSocketTimeline(events, content);
  }
}
