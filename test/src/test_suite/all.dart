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

import 'package:test/test.dart';

import 'http_client.dart';
import 'http_server.dart';
import 'platform.dart';
import 'process.dart';
import 'raw_datagram_socket.dart';
import 'secure_socket.dart';
import 'server_socket.dart';
import 'socket.dart';

export 'http_client.dart';
export 'http_server.dart';
export 'internet_address.dart';
export 'platform.dart';
export 'process.dart';
export 'raw_datagram_socket.dart';
export 'secure_socket.dart';
export 'server_socket.dart';
export 'socket.dart';

void testAll({bool isBrowser = false, bool hybrid = false}) {
  testPlatform();
  testHttpClient(isBrowser: isBrowser, hybrid: hybrid);
  testHttpServer();
  testProcess();
  testSockets();
}

void testSockets({
  bool rawDatagramSocket = true,
  bool serverSocket = true,
  bool socket = true,
  bool secureServerSocket = true,
  bool secureSocket = true,
  int times = 1,
}) {
  if (rawDatagramSocket || socket || serverSocket || secureSocket || secureServerSocket) {
    final f = () {
      if (rawDatagramSocket) {
        testRawDatagramSocket();
      }
      if (serverSocket) {
        testRawServerSocket();
      }
      if (socket) {
        testRawSocket(serverSocket: serverSocket);
      }
      if (secureSocket) {
        testSecureSocket(secureServerSocket: secureServerSocket);
      }
    };
    if (times == 1) {
      f();
    } else {
      for (var i = 0; i < times; i++) {
        group("Repeat #$i", f);
      }
    }
  }
}
