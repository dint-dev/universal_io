import 'package:nodejs_io/nodejs_io.dart';
import 'package:universal_io/io.dart';

Future<void> main() async {
  // Enable Chrome IO Driver
  nodeJsIODriver.enable();

  // Open TCP server
  final server = await ServerSocket.bind('localhost', 0);
  server.listen((socket) {
    // ...
  });

  // Open TCP client
  final client = await Socket.connect('localhost', server.port);

  // ...

  await client.close();
}
