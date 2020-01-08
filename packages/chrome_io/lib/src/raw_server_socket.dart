// Copyright 2019 terrier989 <terrier989@gmail.com>.
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

import 'package:meta/meta.dart';
import 'package:universal_io/driver_base.dart';
import 'package:universal_io/prefer_universal/io.dart';

import 'raw_socket.dart';
import 'third-party/chrome/chrome_common.dart' as chrome;
import 'third-party/chrome/chrome_sockets.dart' as chrome;

/// TCP server socket that uses Chrome Apps 'chrome.sockets.tcpServer' API.
class ChromeRawServerSocket extends BaseRawServerSocket {
  /// ID used by Chrome APIs.
  final int socketId;

  @override
  final InternetAddress address;

  @override
  final int port;

  ChromeRawServerSocket.fromChromeSocketId(
    this.socketId, {
    @required this.address,
    @required this.port,
  }) {
    if (socketId == null) {
      throw ArgumentError.notNull('socketId');
    }
    if (address == null) {
      throw ArgumentError.notNull('address');
    }
    if (port == null) {
      throw ArgumentError.notNull('port');
    }
  }

  @override
  Future<void> didClose() async {
    await chrome.sockets.tcpServer.close(socketId);
  }

  @override
  StreamSubscription<RawSocket> listen(void Function(RawSocket event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    final stream = chrome.sockets.tcpServer.onAccept.asyncMap(_accept);
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  /// For documentation, see [RawServerSocket.bind].
  static Future<ChromeRawServerSocket> bind(Object host, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) async {
    host ??= v6Only ? InternetAddress.anyIPv6 : InternetAddress.anyIPv4;
    final addresses = await InternetAddress.lookup(
      host,
      type: v6Only ? InternetAddressType.IPv6 : InternetAddressType.any,
    );
    final address = addresses.first;
    final info = await chrome.sockets.tcpServer.create();
    final socketId = info.socketId;
    await chrome.sockets.tcpServer.listen(socketId, address.address, port);
    return ChromeRawServerSocket.fromChromeSocketId(
      socketId,
      address: address,
      port: port,
    );
  }

  static Future<RawSocket> _accept(chrome.AcceptInfo info) async {
    final socketId = info.clientSocketId;
    final otherInfo = await chrome.sockets.tcp.getInfo(socketId);
    return ChromeRawSocket.fromChromeSocketId(
      socketId,
      address: InternetAddress(otherInfo.localAddress),
      port: otherInfo.localPort,
      remoteAddress: InternetAddress(otherInfo.peerAddress),
      remotePort: otherInfo.peerPort,
    );
  }
}
