import 'dart:html';

import 'package:chrome_os_io/chrome_os_io.dart';
import 'package:universal_io/io.dart';

void main() {
  chromeIODriver.enable();
  window.onLoad.listen((_) {
    _onLoad();
  });
}

final _host = InternetAddress("127.0.0.1");

void _initializeRawDatagramButton() {
  const receiverPort = 4242;
  const senderPort = 4343;
  final button = querySelector("#RawDatagramSocket-send");
  final element = querySelector("#RawDatagramSocket-received");
  RawDatagramSocket receiver;
  var n = 0;
  button.onClick.listen((event) async {
    n++;
    if (receiver == null) {
      // Create sockets
      receiver = await RawDatagramSocket.bind(_host, receiverPort);

      // Listen for messages
      receiver.listen((event) {
        if (event == RawSocketEvent.read) {
          final receivedN = receiver.receive().data.single;
          element.text += "RawDatagramSocket received click #$receivedN";
        }
      });
    }

    // Send a message
    element.text += "RawDatagramSocket sent click $n\n";
    final sender = await RawDatagramSocket.bind(_host, senderPort);
    sender.send([n], _host, receiverPort);
    sender.close();
  });
}

void _initializeRawServerSocketButton() {
  const receiverPort = 4201;
  final button = querySelector("#RawServerSocket-send");
  final element = querySelector("#RawServerSocket-received");
  RawServerSocket receiver;
  var n = 0;
  button.onClick.listen((event) async {
    n++;
    if (receiver == null) {
      // Create sockets
      receiver = await RawServerSocket.bind(_host, receiverPort);

      // Listen for messages
      receiver.listen((socket) {
        socket.listen((event) {
          if (event == RawSocketEvent.read) {
            final receivedN = socket.read(1).single;
            element.text += "RawServerSocket received click #$receivedN";
            socket.close();
          }
        });
      });
    }

    // Send a message
    element.text += "RawSocket sent click $n\n";
    final sender = await RawSocket.connect(_host, receiverPort);
    sender.write([n]);
    await sender.close();
  });
}

void _initializeServerSocketButton() {
  const receiverPort = 4202;
  final button = querySelector("#ServerSocket-send");
  final element = querySelector("#ServerSocket-received");
  ServerSocket receiver;
  var n = 0;
  button.onClick.listen((event) async {
    n++;
    if (receiver == null) {
      // Create sockets
      receiver = await ServerSocket.bind(_host, receiverPort);

      // Listen for messages
      receiver.listen((socket) {
        socket.listen((data) {
          final receivedN = data.single;
          element.text += "ServerSocket received click #$receivedN";
          socket.close();
        });
      });
    }

    // Send a message
    element.text += "Socket sent click $n\n";
    final sender = await Socket.connect(_host, receiverPort);
    sender.add([n]);
    await sender.close();
  });
}

void _onLoad() {
  chromeIODriver.enable();
  _initializeRawDatagramButton();
  _initializeRawServerSocketButton();
  _initializeServerSocketButton();
}
