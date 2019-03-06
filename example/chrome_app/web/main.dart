import 'package:universal_io/io.dart';
import 'package:universal_io/io_driver.dart';
import 'dart:html';

void main() {
  IODriver.zoneLocal.defaultValue = ChromeIODriver();
  {
    final button = querySelector("#RawDatagramSocket-send");
    final element = querySelector("#RawDatagramSocket-received");
    var n = 0;
    button.onClick.listen((event) async {
      n++;
      final host = "localhost";
      final receiverPort = 4242;
      final senderPort = 4343;

      // Create sockets
      final receiver = await RawDatagramSocket.bind(host, receiverPort);
      final sender = await RawDatagramSocket.bind(host, senderPort);

      // Listen for messages
      receiver.listen((event) {
        if (event == RawSocketEvent.read) {
          final receivedN = receiver.receive().data.single;
          element.text += "RawDatagramSocket received click #$receivedN";
          receiver.close();
        }
      });

      // Send a message
      element.text += "RawDatagramSocket sent click $n\n";
      sender.send([n], InternetAddress(host), receiverPort);
      sender.close();
    });
  }

  {
    final button = querySelector("#RawServerSocket-send");
    final element = querySelector("#RawServerSocket-received");
    var n = 0;
    button.onClick.listen((event) async {
      n++;
      final host = "localhost";
      final receiverPort = 4242;

      // Create sockets
      final receiver = await RawServerSocket.bind(host, receiverPort);
      final sender = await RawSocket.connect(host, receiverPort);

      // Listen for messages
      receiver.listen((socket) {
        socket.listen((event) {
          if (event == RawSocketEvent.read) {
            final receivedN = socket.read(1).single;
            element.text += "RawServerSocket received click #$receivedN";
            receiver.close();
            sender.close();
            socket.close();
          }
        });
      });

      // Send a message
      element.text += "RawSocket sent click $n\n";
      sender.write([n]);
      await sender.close();
    });
  }

  {
    final button = querySelector("#ServerSocket-send");
    final element = querySelector("#ServerSocket-received");
    var n = 0;
    button.onClick.listen((event) async {
      n++;
      final host = "localhost";
      final receiverPort = 4242;

      // Create sockets
      final receiver = await ServerSocket.bind(host, receiverPort);
      final sender = await Socket.connect(host, receiverPort);

      // Listen for messages
      receiver.listen((socket) {
        socket.listen((data) {
          final receivedN = data.single;
          element.text += "ServerSocket received click #$receivedN";
          receiver.close();
          sender.close();
          socket.close();
        });
      });

      // Send a message
      element.text += "Socket sent click $n\n";
      sender.add([n]);
      await sender.close();
    });
  }
}
