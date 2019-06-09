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

import 'dart:async';
import 'dart:collection';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:universal_io/io.dart';

abstract class BaseRawDatagramSocket extends Stream<RawSocketEvent>
    implements RawDatagramSocket {
  final _streamController = StreamController<RawSocketEvent>();
  final _queue = Queue<Datagram>();

  @override
  bool readEventsEnabled = true;

  @override
  bool writeEventsEnabled = true;

  @override
  bool broadcastEnabled = false;

  @override
  bool multicastLoopback = true;

  @override
  int multicastHops = 1;

  @override
  NetworkInterface multicastInterface;

  BaseRawDatagramSocket() {
    this.readEventsEnabled = true;
    this.writeEventsEnabled = true;
    this.broadcastEnabled = false;
    this.multicastHops = 1;
  }

  @override
  void close() {
    internallyClose();
    _streamController.add(RawSocketEvent.closed);
  }

  @override
  Uint8List getRawOption(RawSocketOption option) {
    throw OSError(
        "getRawSocketOption(...) is unsupported by the socket implementation");
  }

  @protected
  void internallyAddReceived(Datagram datagram) {
    _streamController.add(RawSocketEvent.read);
    _queue.add(datagram);
  }

  @protected
  void internallyAddReceivedError(Object error) {
    _streamController.addError(error);
  }

  @protected
  void internallyClose();

  @protected
  int internallySend(List<int> buffer, InternetAddress address, int port);

  @override
  void joinMulticast(InternetAddress group, [NetworkInterface interface]) {}

  @override
  void leaveMulticast(InternetAddress group, [NetworkInterface interface]) {}

  @override
  StreamSubscription<RawSocketEvent> listen(void onData(RawSocketEvent event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _streamController.stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Datagram receive() => _queue.removeFirst();

  @override
  int send(List<int> buffer, InternetAddress address, int port) {
    if (writeEventsEnabled) {
      _streamController.add(RawSocketEvent.write);
      writeEventsEnabled = false;
    }
    return internallySend(buffer, address, port);
  }

  @override
  void setRawOption(RawSocketOption option) {
    throw OSError(
        "setRawSocketOption(...) is unsupported by the socket implementation");
  }
}
