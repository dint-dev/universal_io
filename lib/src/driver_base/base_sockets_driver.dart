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

import 'package:universal_io/driver.dart';
import 'package:universal_io/io.dart';

class BaseSocketsDriver extends SocketsDriver {
  const BaseSocketsDriver();

  @override
  Future<List<NetworkInterface>> listNetworkInterfaces(
      {bool includeLoopback = false,
      bool includeLinkLocal = false,
      InternetAddressType type = InternetAddressType.any}) {
    throw UnimplementedError();
  }

  @override
  Future<RawDatagramSocket> bindRawDatagramSocket(host, int port,
      {bool reuseAddress = true, bool reusePort = false, int ttl = 1}) {
    throw UnimplementedError();
  }

  @override
  Future<RawSecureServerSocket> bindRawSecureServerSocket(
      address, int port, SecurityContext context,
      {int backlog = 0,
      bool v6Only = false,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false,
      List<String> supportedProtocols,
      bool shared = false}) {
    throw UnimplementedError();
  }

  @override
  Future<RawSecureSocket> connectRawSecureSocket(host, int port,
      {SecurityContext context,
      bool onBadCertificate(X509Certificate certificate),
      List<String> supportedProtocols,
      Duration timeout}) {
    throw UnimplementedError();
  }

  @override
  Future<ConnectionTask<RawSecureSocket>> connectRawSecureSocketStart(
      host, int port,
      {SecurityContext context,
      bool onBadCertificate(X509Certificate certificate),
      List<String> supportedProtocols}) {
    throw UnimplementedError();
  }

  @override
  Future<RawServerSocket> bindRawServerSocket(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    throw UnimplementedError();
  }

  @override
  Future<RawSocket> connectRawSocket(host, int port,
      {sourceAddress, Duration timeout}) {
    throw UnimplementedError();
  }

  @override
  Future<ConnectionTask<RawSocket>> connectRawSocketStart(host, int port,
      {sourceAddress}) {
    throw UnimplementedError();
  }

  @override
  Future<RawSecureSocket> newSecureRawSocket(RawSocket socket,
      {StreamSubscription<RawSocketEvent> subscription,
      host,
      SecurityContext context,
      bool onBadCertificate(X509Certificate certificate),
      List<String> supportedProtocols}) {
    throw UnimplementedError();
  }

  @override
  Future<RawSecureSocket> newSecureServerRawSocket(
      RawSocket socket, SecurityContext context,
      {StreamSubscription<RawSocketEvent> subscription,
      List<int> bufferedData,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false,
      List<String> supportedProtocols}) {
    throw UnimplementedError();
  }

  /// Driver implementation can use this method to evaluate parameters of type
  /// "a string or [InternetAddress]" (e.g. [RawSocket.connect]) into
  /// [InternetAddress].
  ///
  /// If the evaluation fails, this method throws [ArgumentError].
  static Future<InternetAddress> resolveHostOrInternetAddress(
      Object host) async {
    if (host is InternetAddress) {
      return host;
    } else if (host is String) {
      final addresses = await InternetAddress.lookup(host);
      if (addresses.isEmpty) {
        throw ArgumentError("Host '$host' could not be resolved.");
      }
      return addresses.first;
    } else {
      throw ArgumentError.value(host);
    }
  }

  @override
  Future<Socket> connectSocket(host, int port,
      {sourceAddress, Duration timeout}) {
    throw UnimplementedError();
  }

  @override
  Future<ConnectionTask<Socket>> startConnectSocket(host, int port,
      {sourceAddress}) {
    throw UnimplementedError();
  }
}
