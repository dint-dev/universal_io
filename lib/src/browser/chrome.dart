// MIT License
//
// Copyright (c) 2018 dart-universal_io authors.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:typed_data';

import 'package:raw/raw.dart';

import 'api/all.dart';
import 'browser.dart';
import 'chrome/chrome_common.dart';
import 'chrome/chrome_sockets.dart';

class ChromeIODriver extends BrowserIODriver {
  static Future<InternetAddress> _resolve(Object value) async {
    if (value is String) {
      final all = await InternetAddress.lookup(value);
      if (all.length == 0) {
        throw ArgumentError("host '$value' does not exist");
      }
      return all.first;
    }
    if (value is InternetAddress) {
      return value;
    }
    throw ArgumentError.value("value", value);
  }

  @override
  Future<RawDatagramSocket> bindRawDatagramSocket(Object host, int port,
      {bool reuseAddress = true, bool reusePort = false, int ttl = 1}) async {
    final address = await _resolve(host);
    final createInfo = await sockets.udp.create();
    final socketId = createInfo.socketId;
    try {
      final resultValue = await sockets.udp.bind(
        socketId,
        address.address,
        port,
      );
      if (resultValue < 0) {
        throw StateError(
          "Binding UDP socket to $host:$port failed with error code $resultValue",
        );
      }
      return ChromeRawDatagramSocket(
        socketId,
        address: address,
        port: port,
      );
    } catch (e) {
      await sockets.udp.close(socketId);
      rethrow;
    }
  }

  @override
  Future<RawServerSocket> bindRawServerSocket(Object host, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) async {
    final address = await _resolve(host);
    return ChromeRawServerSocket.bind(address, port);
  }

  @override
  Future<RawSocket> connectRawSocket(Object host, int port,
      {Object sourceAddress, Duration timeout}) async {
    final address = await _resolve(host);
    final sourceInternetAddress =
        sourceAddress == null ? null : await _resolve(sourceAddress);
    final createInfo = await sockets.tcp.create();
    final socketId = createInfo.socketId;
    try {
      final resultValue = await sockets.tcp.connect(
        socketId,
        address.address,
        port,
      );
      if (resultValue < 0) {
        throw StateError(
            "Creating TCP connection from '$sourceInternetAddress' to '$host:$port' failed with error code $resultValue");
      }
      return ChromeRawSocket(
        socketId,
        remoteAddress: address,
        remotePort: port,
      );
    } catch (e) {
      await sockets.udp.close(socketId);
      rethrow;
    }
  }
}

class ChromeRawDatagramSocket extends RawDatagramSocket {
  final int socketId;

  final StreamController<RawSocketEvent> eventStreamController =
      StreamController<RawSocketEvent>();

  Queue<Datagram> receivingQueue = Queue<Datagram>();

  @override
  final int port;

  @override
  final InternetAddress address;

  ChromeRawDatagramSocket(this.socketId, {this.address, this.port});

  @override
  void close() {
    sockets.udp.close(socketId);
  }

  @override
  Uint8List getRawOption(RawSocketOption option) {
    return null;
  }

  @override
  void joinMulticast(InternetAddress group, [NetworkInterface interface]) {
    throw UnimplementedError();
  }

  @override
  void leaveMulticast(InternetAddress group, [NetworkInterface interface]) {
    throw UnimplementedError();
  }

  @override
  StreamSubscription<RawSocketEvent> listen(void onData(RawSocketEvent event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return eventStreamController.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  @override
  Datagram receive() {
    return receivingQueue.removeFirst();
  }

  @override
  int send(List<int> buffer, InternetAddress address, int port) {
    sockets.udp.send(
        socketId, ArrayBuffer.fromBytes(buffer), address.toString(), port);
    return buffer.length;
  }

  @override
  void setRawOption(RawSocketOption option) {}
}

class ChromeRawServerSocket extends Stream<RawSocket>
    implements RawServerSocket {
  final int socketId;

  @override
  final InternetAddress address;

  @override
  final int port;

  ChromeRawServerSocket(this.socketId, this.address, this.port);

  @override
  Future<RawServerSocket> close() async {
    await sockets.tcpServer.close(socketId);
    return this;
  }

  @override
  StreamSubscription<RawSocket> listen(void onData(RawSocket event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return sockets.tcpServer.onAccept.map((info) {
      return ChromeRawSocket(info.clientSocketId, address: address, port: port);
    }).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  static Future<ChromeRawServerSocket> bind(
      InternetAddress address, int port) async {
    final info = await sockets.tcpServer.create();
    final socketId = info.socketId;
    await sockets.tcpServer.listen(socketId, address.address, port);
    return ChromeRawServerSocket(socketId, address, port);
  }
}

class ChromeRawSocket extends Stream<RawSocketEvent> implements RawSocket {
  static Map<int, ChromeRawSocket> _receivingSockets = <int, ChromeRawSocket>{};
  static bool isListeningChromeAPI = false;

  final int socketId;

  final StreamController<RawSocketEvent> _eventStreamController =
      StreamController<RawSocketEvent>();

  RawWriter _receivingBuffer = RawWriter.withCapacity(128);

  @override
  final int port;

  @override
  final InternetAddress address;

  @override
  bool readEventsEnabled;

  @override
  bool writeEventsEnabled;

  @override
  final int remotePort;

  @override
  final InternetAddress remoteAddress;

  ChromeRawSocket(this.socketId,
      {this.address, this.port, this.remotePort, this.remoteAddress}) {
    _receivingSockets[socketId] = this;
    _startReceiving();
  }

  @override
  int available() {
    return _receivingBuffer.length;
  }

  @override
  Future<RawSocket> close() async {
    _receivingSockets.remove(socketId);
    await sockets.tcp.close(socketId);
    return this;
  }

  @override
  Uint8List getRawOption(RawSocketOption option) {
    return null;
  }

  @override
  StreamSubscription<RawSocketEvent> listen(void onData(RawSocketEvent event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _eventStreamController.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  List<int> read([int len]) {
    final writer = this._receivingBuffer;
    final bytes = writer.toUint8ListView();
    if (len == null || len == writer.length) {
      this._receivingBuffer = RawWriter.withCapacity(64);
      return bytes;
    }
    final result = Uint8List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      len,
    );
    final remaining = Uint8List.view(
      bytes.buffer,
      bytes.offsetInBytes + len,
    );
    this._receivingBuffer = RawWriter.withUint8List(remaining);
    return result;
  }

  @override
  bool setOption(SocketOption option, bool enabled) {
    return false;
  }

  @override
  void setRawOption(RawSocketOption option) {}

  @override
  void shutdown(SocketDirection direction) {
    if (direction == SocketDirection.both) {
      close();
    }
  }

  @override
  int write(List<int> buffer, [int offset, int count]) {
    if (offset != null || count != null) {
      offset ??= 0;
      count ??= buffer.length - offset;
      final newBuffer = Uint8List(count);
      for (var i = 0; i < count; i++) {
        newBuffer[i] = buffer[offset + i];
      }
      buffer = newBuffer;
    }
    sockets.tcp.send(socketId, ArrayBuffer.fromBytes(buffer));
    return count ?? buffer.length;
  }

  static void _startReceiving() {
    if (isListeningChromeAPI) {
      return;
    }
    isListeningChromeAPI = true;
    sockets.tcp.onReceiveError.listen((event) {});
    sockets.tcp.onReceive.listen((event) {
      final socketId = event.socketId;
      final socket = _receivingSockets[socketId];
      if (socket is ChromeRawSocket) {
        socket._receivingBuffer.writeBytes(event.data.getBytes());
        socket._eventStreamController.add(RawSocketEvent.read);
      } else {
        print("Socket ID ${socketId} received data, but it's closed");
      }
    });
  }
}

class ChromeServerSocket extends Stream<Socket> implements ServerSocket {
  final int socketId;

  @override
  final InternetAddress address;

  @override
  final int port;

  ChromeServerSocket(this.socketId, this.address, this.port);

  @override
  Future<ServerSocket> close() async {
    await sockets.tcpServer.close(socketId);
    return this;
  }

  @override
  StreamSubscription<Socket> listen(void onData(Socket event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return sockets.tcpServer.onAccept.map((info) {
      return ChromeSocket(info.clientSocketId, address: address, port: port);
    }).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  static Future<ChromeRawServerSocket> bind(
      InternetAddress address, int port) async {
    final info = await sockets.tcpServer.create();
    final socketId = info.socketId;
    await sockets.tcpServer.listen(socketId, address.address, port);
    return ChromeRawServerSocket(socketId, address, port);
  }
}

class ChromeSocket extends Stream<List<int>> with IOSink implements Socket {
  static Map<int, ChromeSocket> _receivingSockets = <int, ChromeSocket>{};
  static bool isListeningChromeAPI = false;

  final int socketId;

  final StreamController<List<int>> _eventStreamController =
      StreamController<List<int>>();

  RawWriter _receivingBuffer = RawWriter.withCapacity(128);

  @override
  final int port;

  @override
  final InternetAddress address;

  @override
  final int remotePort;

  @override
  final InternetAddress remoteAddress;

  ChromeSocket(this.socketId,
      {this.address, this.port, this.remotePort, this.remoteAddress}) {
    _receivingSockets[socketId] = this;
    _startReceiving();
  }

  @override
  Future get done {
    return _eventStreamController.done;
  }

  @override
  void add(List<int> buffer) {
    sockets.tcp.send(socketId, ArrayBuffer.fromBytes(buffer));
  }

  @override
  void addError(error, [StackTrace stackTrace]) {
    _eventStreamController.addError(error, stackTrace);
  }

  @override
  Future addStream(Stream<List<int>> stream) {
    _eventStreamController.addStream(stream);
  }

  @override
  Future close() async {
    _receivingSockets.remove(socketId);
    await sockets.tcp.close(socketId);
  }

  @override
  void destroy() {
    close();
  }

  @override
  Future flush() async {}

  @override
  Uint8List getRawOption(RawSocketOption option) {
    return null;
  }

  @override
  StreamSubscription<List<int>> listen(void onData(List<int> data),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _eventStreamController.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  bool setOption(SocketOption option, bool enabled) {
    return false;
  }

  @override
  void setRawOption(RawSocketOption option) {}

  @override
  void write(Object obj) {
    add(utf8.encode(obj.toString()));
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    write(objects.join(separator));
  }

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }

  @override
  void writeln([Object obj = ""]) {
    write(obj);
    write("\n");
  }

  static void _startReceiving() {
    if (isListeningChromeAPI) {
      return;
    }
    isListeningChromeAPI = true;
    sockets.tcp.onReceiveError.listen((event) {});
    sockets.tcp.onReceive.listen((event) {
      final socketId = event.socketId;
      final socket = _receivingSockets[socketId];
      if (socket is ChromeRawSocket) {
        socket._eventStreamController.add(event.data.getBytes());
      } else {
        print("Socket ID ${socketId} received data, but it's closed");
      }
    });
  }
}
