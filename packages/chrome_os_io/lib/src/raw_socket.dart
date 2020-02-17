// Copyright 2019 terrier989@gmail.com.
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

part of chrome_os_io;

/// TLS socket that uses Chrome Apps 'chrome.sockets.tcp' API.
class ChromeRawSecureSocket extends ChromeRawSocket implements RawSecureSocket {
  ChromeRawSecureSocket(int socketId,
      {@required InternetAddress address,
      @required int port,
      @required int remotePort,
      @required InternetAddress remoteAddress})
      : super.fromChromeSocketId(
          socketId,
          address: address,
          port: port,
          remotePort: remotePort,
          remoteAddress: remoteAddress,
        );

  @override
  X509Certificate get peerCertificate {
    throw UnimplementedError();
  }

  @override
  String get selectedProtocol {
    throw UnimplementedError();
  }

  @override
  void renegotiate(
      {bool useSessionCache = true,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false}) {
    throw UnimplementedError();
  }
}

/// TCP socket that uses Chrome Apps 'chrome.sockets.tcp' API.
class ChromeRawSocket extends BaseRawSocket {
  /// Maps socket ID to socket.
  ///
  /// Used by the static methods [_onError] and [_onData].
  static final Map<int, ChromeRawSocket> _receivingSockets =
      <int, ChromeRawSocket>{};

  /// Used to ensure that the static method [_registerStaticListeners] is called only once.
  static bool _hasInvokedRegisterStaticListeners = false;

  /// ID used by Chrome APIs.
  final int socketId;

  @override
  final int port;

  @override
  final InternetAddress address;

  @override
  final int remotePort;

  @override
  final InternetAddress remoteAddress;

  ChromeRawSocket.fromChromeSocketId(
    this.socketId, {
    @required this.address,
    @required this.port,
    @required this.remotePort,
    @required this.remoteAddress,
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
    if (remotePort == null) {
      throw ArgumentError.notNull('remotePort');
    }
    if (remoteAddress == null) {
      throw ArgumentError.notNull('remoteAddress');
    }
    _receivingSockets[socketId] = this;
    _registerStaticListeners();
  }

  @override
  Future<void> didShutdown() async {
    await chrome.sockets.tcp.close(socketId);
  }

  @override
  int didWrite(List<int> buffer) {
    chrome.sockets.tcp.send(socketId, chrome.ArrayBuffer.fromBytes(buffer));
    return buffer.length;
  }

  /// For documentation, see [RawSocket.connect].
  static Future<RawSocket> connect(Object host, int port,
      {Object sourceAddress, Duration timeout}) async {
    final address = await resolveHostOrInternetAddress(host);
    InternetAddress sourceInternetAddress;
    if (sourceAddress != null) {
      sourceInternetAddress = await resolveHostOrInternetAddress(
        sourceInternetAddress,
      );
    }
    final createInfo = await chrome.sockets.tcp.create();
    final socketId = createInfo.socketId;
    try {
      final resultValue = await chrome.sockets.tcp.connect(
        socketId,
        address.address,
        port,
      );
      if (resultValue < 0) {
        throw SocketException(
          "Creating TCP connection from '$sourceInternetAddress' to '$host:$port' failed with error code $resultValue",
        );
      }
      return ChromeRawSocket.fromChromeSocketId(
        socketId,
        address: address,
        port: port,
        remoteAddress: address,
        remotePort: port,
      );
    } catch (e) {
      await chrome.sockets.udp.close(socketId);
      rethrow;
    }
  }

  /// A static callback used by [_registerStaticListeners].
  ///
  /// Passes data to the correct [RawSocket] instance.
  static void _onData(chrome.ReceiveInfo event) {
    final socketId = event.socketId;
    final data = event.data.getBytes();
    final socket = _receivingSockets[socketId];
    if (socket == null) {
      print(
        "Socket ${socketId} received ${data.length} bytes, but it's closed",
      );
      return;
    }
    socket.dispatchReadEvent(data);
  }

  /// A static callback used by [_registerStaticListeners].
  ///
  /// Passes the error to the correct [RawSocket] instance.
  static void _onError(chrome.ReceiveErrorInfo event) {
    final socketId = event.socketId;
    final errorCode = event.resultCode;
    final osError = OSError('Socket error at socket $socketId', errorCode);
    final error = SocketException(
      'Socket error at socket $socketId',
      osError: osError,
    );
    final socket = _receivingSockets[event.socketId];
    if (socket == null) {
      print("Socket ${socketId} received an error, but it's closed");
      return;
    }
    socket.dispatchStreamError(error);
  }

  /// Calls the following Chrome APIs:
  ///   * sockets.tcp.onReceiveError.listen(...)
  ///   * sockets.tcp.onReceive.listen(...)
  static void _registerStaticListeners() {
    if (_hasInvokedRegisterStaticListeners) {
      return;
    }
    _hasInvokedRegisterStaticListeners = true;
    chrome.sockets.tcp.onReceiveError.listen(_onError);
    chrome.sockets.tcp.onReceive.listen(_onData);
  }
}
