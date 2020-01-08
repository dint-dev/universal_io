import 'package:chrome_io/chrome_io.dart';
import 'package:universal_io/io.dart';

void main() async {
  // Enable Chrome IO Driver
  chromeIODriver.enable();

  // Open TCP server
  final server = await ServerSocket.bind("localhost", 0);
  server.listen((socket) {
    // ...
  });

  // Open TCP client
  final client = await Socket.connect("localhost", server.port);
  // ...
}
