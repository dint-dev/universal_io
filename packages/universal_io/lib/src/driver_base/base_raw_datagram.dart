// Copyright 2020 terrier989@gmail.com.
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
import 'package:universal_io/prefer_universal/io.dart';

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
    readEventsEnabled = true;
    writeEventsEnabled = true;
    broadcastEnabled = false;
    multicastHops = 1;
  }

  @mustCallSuper
  @override
  void close() {
    if (_streamController.isClosed) {
      return;
    }
    _streamController.add(RawSocketEvent.closed);
    _streamController.close();
    didClose();
  }

  /// A protected method only for implementations.
  @protected
  void didClose();

  /// A protected method only for implementations.
  ///
  /// This method is called when a valid datagram is sent.
  @protected
  int didSend(List<int> buffer, InternetAddress address, int port);

  /// A protected method only for implementations.
  ///
  /// Dispatches an error.
  @protected
  void dispatchError(Object error) {
    _streamController.addError(error);
  }

  /// A protected method only for implementations.
  ///
  /// Dispatches [RawSocketEvent.readClosed].
  @protected
  void dispatchReadClosedEvent() {
    _streamController.add(RawSocketEvent.readClosed);
  }

  /// A protected method only for implementations.
  ///
  /// Dispatches [RawSocketEvent.read] and adds datagram to the queue.
  @protected
  void dispatchReadEvent(Datagram datagram) {
    _streamController.add(RawSocketEvent.read);
    _queue.add(datagram);
  }

  @override
  Uint8List getRawOption(RawSocketOption option) {
    throw OSError(
      'getRawSocketOption(...) is unsupported by $this',
    );
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
  StreamSubscription<RawSocketEvent> listen(
      void Function(RawSocketEvent event) onData,
      {Function onError,
      void Function() onDone,
      bool cancelOnError}) {
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
    return didSend(buffer, address, port);
  }

  @override
  void setRawOption(RawSocketOption option) {
    throw OSError(
      'setRawSocketOption(...) is unsupported by $this',
    );
  }
}
