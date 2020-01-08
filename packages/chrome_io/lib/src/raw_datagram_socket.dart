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
import 'package:universal_io/driver.dart';
import 'package:universal_io/driver_base.dart';
import 'package:universal_io/prefer_universal/io.dart';

import 'third-party/chrome/chrome_common.dart' as chrome;
import 'third-party/chrome/chrome_sockets.dart' as chrome;

/// [RawDatagramSocket] that uses Chrome Apps 'chrome.sockets.udp' API.
class ChromeRawDatagramSocket extends BaseRawDatagramSocket {
  /// ID used by Chrome APIs.
  final int socketId;

  @override
  final int port;

  @override
  final InternetAddress address;

  ChromeRawDatagramSocket.fromChromeSocketId(this.socketId,
      {@required this.address, @required this.port}) {
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
  Future didClose() async {
    await chrome.sockets.udp.close(socketId);
  }

  @override
  int didSend(List<int> data, InternetAddress address, int port) {
    chrome.sockets.udp.send(
      socketId,
      chrome.ArrayBuffer.fromBytes(data),
      address.address,
      port,
    );
    return data.length;
  }

  /// For documentation, see [RawDatagramSocket.bind].
  static Future<RawDatagramSocket> bind(Object host, int port,
      {bool reuseAddress = true, bool reusePort = false, int ttl = 1}) async {
    final address = await resolveHostOrInternetAddress(host);
    final createInfo = await chrome.sockets.udp.create();
    final socketId = createInfo.socketId;
    try {
      final resultValue = await chrome.sockets.udp.bind(
        socketId,
        address.address,
        port,
      );
      if (resultValue < 0) {
        throw StateError(
          'Binding UDP socket to $host:$port failed with error code $resultValue',
        );
      }
      return ChromeRawDatagramSocket.fromChromeSocketId(
        socketId,
        address: address,
        port: port,
      );
    } catch (e) {
      await chrome.sockets.udp.close(socketId);
      rethrow;
    }
  }
}
