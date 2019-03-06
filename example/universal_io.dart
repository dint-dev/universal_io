import 'dart:async';

import 'package:universal_io/io.dart';
import 'package:universal_io/io_driver.dart';

void main() async {
  // Set IO driver
  IODriver.zoneLocal.defaultValue = ExampleIODriver();

  // You can now use 'dart:io' APIs
  final socket = await Socket.connect("google.com", 80);
  await socket.close();
}

class ExampleIODriver extends IODriver {
  // An example of altering behavior of a socket API
  @override
  Future<Socket> connectSocket(host, int port,
      {sourceAddress, Duration timeout}) async {
    print("Attempting to connect to '$host:$port'");
    return super.connectSocket(host, port);
  }
}
