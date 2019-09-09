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
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:universal_io/driver_base.dart' show Uint8ListBuffer;
import 'package:universal_io/prefer_universal/io.dart';

abstract class BaseRawSocket extends Stream<RawSocketEvent>
    implements RawSocket {
  @override
  bool readEventsEnabled = true;

  @override
  bool writeEventsEnabled = true;

  /// Has reading been closed?
  bool _closedRead = false;

  /// Has writing been closed?
  bool _closedWrite = false;

  /// Received bytes.
  final Uint8ListBuffer _buffer = Uint8ListBuffer();

  /// Received stream of events and errors.
  final StreamController<RawSocketEvent> _streamController =
      StreamController<RawSocketEvent>();

  BaseRawSocket();

  @override
  int available() => _buffer.length;

  @override
  Future<RawSocket> close() async {
    await shutdown(SocketDirection.both);
    return this;
  }

  /// A protected method only for implementations.
  ///
  /// Called after both reading and writing has been shutdown.
  ///
  /// This method is guaranteed to be called only once during the socket
  /// lifetime.
  @protected
  FutureOr<void> didShutdown();

  /// A protected method only for implementations.
  ///
  /// Called when reading has been shutdown.
  ///
  /// This method is guaranteed to be called exactly once during the socket
  /// lifetime. This method is called before [didShutdown].
  @protected
  FutureOr<void> didShutdownReading() async {}

  /// A protected method only for implementations.
  ///
  /// Called when writing has been shutdown.
  ///
  /// This method is guaranteed to be called exactly once during the socket
  /// lifetime. This method is called before [didShutdown].
  @protected
  FutureOr<void> didShutdownWriting() async {}

  /// A protected method only for implementations.
  ///
  /// Called when valid data is written.
  ///
  /// This method will not be called if writing is disabled.
  @protected
  int didWrite(List<int> data);

  /// A protected method only for implementations.
  @protected
  void dispatchStreamError(Object error) {
    _streamController.addError(error);
  }

  /// A protected method only for implementations.
  @protected
  void dispatchReadEvent(List<int> data) {
    if (_closedRead) {
      return;
    }
    _streamController.add(RawSocketEvent.read);
    _buffer.add(data);
  }

  @override
  Uint8List getRawOption(RawSocketOption option) {
    throw UnimplementedError();
  }

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
  Uint8List read([int len]) {
    return _buffer.read(maxLength: len);
  }

  @override
  bool setOption(SocketOption option, bool enabled) {
    return false;
  }

  @override
  void setRawOption(RawSocketOption option) {
    throw UnimplementedError();
  }

  @override
  void shutdown(SocketDirection direction) {
    _shutdown(direction);
  }

  @override
  int write(List<int> buffer, [int offset, int count]) {
    if (_closedWrite) {
      return 0;
    }
    offset ??= 0;
    count ??= buffer.length - offset;
    if (offset != 0 || count != buffer.length) {
      buffer = buffer.sublist(offset, offset + count);
    }

    // Add event if writeEventsEnabled is enabled
    if (writeEventsEnabled) {
      writeEventsEnabled = false;
      _streamController.add(RawSocketEvent.write);
    }

    // Write
    return didWrite(buffer);
  }

  /// Used by [close] and [shutdown].
  Future _shutdown(SocketDirection direction) async {
    bool isStatedChanged = false;
    if (direction == SocketDirection.both ||
        direction == SocketDirection.send) {
      if (!_closedWrite) {
        _closedWrite = true;
        isStatedChanged = true;
        await didShutdownWriting();
      }
    }
    if (direction == SocketDirection.both ||
        direction == SocketDirection.receive) {
      if (!_closedRead) {
        _closedRead = true;
        isStatedChanged = true;
        await didShutdownReading();
        if (direction == SocketDirection.receive) {
          _streamController.add(RawSocketEvent.readClosed);
        }
        await _streamController.close();
      }
    }
    if (isStatedChanged && _closedRead && _closedWrite) {
      _streamController.add(RawSocketEvent.closed);
      await didShutdown();
    }
  }
}
