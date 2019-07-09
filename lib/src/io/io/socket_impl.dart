// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------
// THIS, DERIVED FILE IS LICENSE UNDER THE FOLLOWING LICENSE
// ---------------------------------------------------------
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

import 'package:universal_io/driver_base.dart' show BaseIOSink;

import '../io.dart';
import 'socket.dart';

/// Internal [Socket] implementation that uses [RawSocket].
class SocketImpl<T extends RawSocket> extends Stream<Uint8List>
    with BaseIOSink
    implements Socket {
  final T rawSocket;

  final StreamController<List<int>> _streamController =
      StreamController<List<int>>();

  SocketImpl(this.rawSocket) {
    _streamController.onListen = () {
      final subscription = rawSocket.listen(
        (event) {
          if (event == RawSocketEvent.read) {
            _streamController.add(rawSocket.read());
          }
        },
        onError: _streamController.addError,
        onDone: _streamController.close,
      );
      _streamController.onPause = subscription.pause;
      _streamController.onResume = subscription.resume;
      _streamController.onCancel = subscription.cancel;
    };
  }

  @override
  InternetAddress get address => rawSocket.address;

  @override
  Future get done {
    return _streamController.done;
  }

  @override
  int get port => rawSocket.port;

  @override
  InternetAddress get remoteAddress => rawSocket.remoteAddress;

  @override
  int get remotePort => rawSocket.remotePort;

  @override
  void add(List<int> buffer) {
    rawSocket.write(buffer);
  }

  @override
  void addError(error, [StackTrace stackTrace]) {
    _streamController.addError(error, stackTrace);
  }

  @override
  Future close() async {
    // ignore: unawaited_futures
    _streamController.close();
    await rawSocket.close();
  }

  @override
  void destroy() {
    close();
  }

  @override
  Uint8List getRawOption(RawSocketOption option) =>
      rawSocket.getRawOption(option);

  @override
  StreamSubscription<Uint8List> listen(void onData(Uint8List data),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _streamController.stream.listen(
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
  void setRawOption(RawSocketOption option) {
    rawSocket.setRawOption(option);
  }

  static Future<Socket> connect(host, int port,
      {sourceAddress, Duration timeout}) async {
    final rawSocket = await RawSocket.connect(
      host,
      port,
      sourceAddress: sourceAddress,
      timeout: timeout,
    );
    return SocketImpl(rawSocket);
  }

  static Future<ConnectionTask<Socket>> startConnect(host, int port,
      {sourceAddress}) async {
    final rawSocketConnectTask = await RawSocket.startConnect(
      host,
      port,
      sourceAddress: sourceAddress,
    );
    final future =
        rawSocketConnectTask.socket.then((rawSocket) => SocketImpl(rawSocket));
    return _ConnectionTask<Socket>._(
        socket: future,
        onCancel: () {
          rawSocketConnectTask.cancel();
        });
  }
}

class _ConnectionTask<S> implements ConnectionTask<S> {
  final Future<S> socket;
  final void Function() _onCancel;

  _ConnectionTask._({Future<S> socket, void Function() onCancel()})
      : assert(socket != null),
        assert(onCancel != null),
        this.socket = socket,
        this._onCancel = onCancel;

  @override
  void cancel() {
    _onCancel();
  }
}
