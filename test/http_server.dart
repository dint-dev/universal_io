import "package:stream_channel/stream_channel.dart";
import 'dart:io';
import 'dart:async';

Future<void> hybridMain(StreamChannel channel, Object message) async {
  // Start server
  final serverAndPort = await _bindServer();

  // Announce TCP port where we are listening
  channel.sink.add({"port": serverAndPort.port});

  serverAndPort.server.listen((request) {
    request.response
      ..write("Hello!")
      ..close();
  });
}

class _ServerAndPort {
  final HttpServer server;
  final int port;
  _ServerAndPort(this.server, this.port);
}

Future<_ServerAndPort> _bindServer() async {
  final start = 54321;
  final end = 54321 + 10;
  for (var port = start; port < end; port++) {
    try {
      final server = await HttpServer.bind(
        InternetAddress.loopbackIPv4,
        port,
      );
      return new _ServerAndPort(server, port);
    } catch (e) {
      // Do nothing
    }
  }
  return null;
}
