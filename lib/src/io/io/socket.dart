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

import 'package:universal_io/src/driver/drivers_in_js.dart';
import 'package:universal_io/src/io/io/socket_impl.dart';

import '../io.dart';
import 'internet_address.dart';

// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Returned by the `startConnect` methods on client-side socket types `S`,
/// `ConnectionTask<S>` allows cancelling an attempt to connect to a host.
class ConnectionTask<S> {
  /// A `Future` that completes with value that `S.connect()` would return
  /// unless [cancel] is called on this [ConnectionTask].
  ///
  /// If [cancel] is called, the `Future` completes with a [SocketException]
  /// error whose message indicates that the connection attempt was cancelled.
  final Future<S> socket;
  final void Function() _onCancel;

  ConnectionTask._({Future<S> socket, void Function() onCancel()})
      : assert(socket != null),
        assert(onCancel != null),
        this.socket = socket,
        this._onCancel = onCancel;

  /// Cancels the connection attempt.
  ///
  /// This also causes the [socket] `Future` to complete with a
  /// [SocketException] error.
  void cancel() {
    _onCancel();
  }
}

/// Datagram package. Data send to and received from datagram sockets
/// contains the internet address and port of the destination or source
/// togeter with the data.
class Datagram {
  List<int> data;
  InternetAddress address;
  int port;

  Datagram(this.data, this.address, this.port);
}

/// A [NetworkInterface] represents an active network interface on the current
/// system. It contains a list of [InternetAddress]es that are bound to the
/// interface.
abstract class NetworkInterface {
  /// Whether [list] is supported.
  ///
  /// [list] is currently unsupported on Android.
  static bool get listSupported => false;

  /// Get a list of [InternetAddress]es currently bound to this
  /// [NetworkInterface].
  List<InternetAddress> get addresses;

  /// Get the index of the [NetworkInterface].
  int get index;

  /// Get the name of the [NetworkInterface].
  String get name;

  /// Query the system for [NetworkInterface]s.
  ///
  /// If [includeLoopback] is `true`, the returned list will include the
  /// loopback device. Default is `false`.
  ///
  /// If [includeLinkLocal] is `true`, the list of addresses of the returned
  /// [NetworkInterface]s, may include link local addresses. Default is `false`.
  ///
  /// If [type] is either [InternetAddressType.IPv4] or
  /// [InternetAddressType.IPv6] it will only lookup addresses of the
  /// specified type. Default is [InternetAddressType.any].
  static Future<List<NetworkInterface>> list(
      {bool includeLoopback = false,
      bool includeLinkLocal = false,
      InternetAddressType type = InternetAddressType.any}) {
    return IODriver.current.networkInterfaceDriver.listNetworkInterfaces(
        includeLoopback: includeLoopback,
        includeLinkLocal: includeLinkLocal,
        type: type);
  }
}

/// The [RawDatagramSocket] is a low-level interface to an UDP socket,
/// exposing the raw events signaled by the system. It's a [Stream] of
/// [RawSocketEvent]s.
///
/// Note that the event [RawSocketEvent.readClosed] will never be
/// received as an UDP socket cannot be closed by a remote peer.
abstract class RawDatagramSocket extends Stream<RawSocketEvent> {
  /// Set or get, if the [RawDatagramSocket] should listen for
  /// [RawSocketEvent.read] events. Default is [:true:].
  bool readEventsEnabled;

  /// Set or get, if the [RawDatagramSocket] should listen for
  /// [RawSocketEvent.write] events. Default is [:true:].  This is a
  /// one-shot listener, and writeEventsEnabled must be set to true
  /// again to receive another write event.
  bool writeEventsEnabled;

  /// Set or get, whether multicast traffic is looped back to the host.
  ///
  /// By default multicast loopback is enabled.
  bool multicastLoopback;

  /// Set or get, the maximum network hops for multicast packages
  /// originating from this socket.
  ///
  /// For IPv4 this is referred to as TTL (time to live).
  ///
  /// By default this value is 1 causing multicast traffic to stay on
  /// the local network.
  int multicastHops;

  /// Set or get, the network interface used for outgoing multicast packages.
  ///
  /// A value of `null`indicate that the system chooses the network
  /// interface to use.
  ///
  /// By default this value is `null`
  @Deprecated("This property is not implemented. Use getRawOption and "
      "setRawOption instead.")
  NetworkInterface multicastInterface;

  /// Set or get, whether IPv4 broadcast is enabled.
  ///
  /// IPv4 broadcast needs to be enabled by the sender for sending IPv4
  /// broadcast packages. By default IPv4 broadcast is disabled.
  ///
  /// For IPv6 there is no general broadcast mechanism. Use multicast
  /// instead.
  bool broadcastEnabled;

  /// Returns the address used by this socket.
  InternetAddress get address;

  /// Returns the port used by this socket.
  int get port;

  /// Close the datagram socket.
  void close();

  /// Use [getRawOption] to get low level information about the [RawSocket]. See
  /// [RawSocketOption] for available options.
  ///
  /// Returns [RawSocketOption.value] on success.
  ///
  /// Throws an [OSError] on failure.
  Uint8List getRawOption(RawSocketOption option);

  /// Join a multicast group.
  ///
  /// If an error occur when trying to join the multicast group an
  /// exception is thrown.
  void joinMulticast(InternetAddress group, [NetworkInterface interface]);

  /// Leave a multicast group.
  ///
  /// If an error occur when trying to join the multicase group an
  /// exception is thrown.
  void leaveMulticast(InternetAddress group, [NetworkInterface interface]);

  /// Receive a datagram. If there are no datagrams available `null` is
  /// returned.
  ///
  /// The maximum length of the datagram that can be received is 65503 bytes.
  Datagram receive();

  /// Send a datagram.
  ///
  /// Returns the number of bytes written. This will always be either
  /// the size of [buffer] or `0`.
  int send(List<int> buffer, InternetAddress address, int port);

  /// Use [setRawOption] to customize the [RawSocket]. See [RawSocketOption] for
  /// available options.
  ///
  /// Throws an [OSError] on failure.
  void setRawOption(RawSocketOption option);

  /// Creates a new raw datagram socket binding it to an address and
  /// port.
  static Future<RawDatagramSocket> bind(host, int port,
      {bool reuseAddress = true, bool reusePort = false, int ttl = 1}) async {
    return IODriver.current.rawDatagramSocketDriver.bind(
      host,
      port,
      reuseAddress: reuseAddress,
      reusePort: reusePort,
      ttl: ttl,
    );
  }
}

/// A [RawServerSocket] represents a listening socket, and provides a
/// stream of low-level [RawSocket] objects, one for each connection
/// made to the listening socket.
///
/// See [RawSocket] for more info.
abstract class RawServerSocket implements Stream<RawSocket> {
  /// Returns the address used by this socket.
  InternetAddress get address;

  /// Returns the port used by this socket.
  int get port;

  /// Closes the socket. The returned future completes when the socket
  /// is fully closed and is no longer bound.
  Future<RawServerSocket> close();

  /// Returns a future for a [:RawServerSocket:]. When the future
  /// completes the server socket is bound to the given [address] and
  /// [port] and has started listening on it.
  ///
  /// The [address] can either be a [String] or an
  /// [InternetAddress]. If [address] is a [String], [bind] will
  /// perform a [InternetAddress.lookup] and use the first value in the
  /// list. To listen on the loopback adapter, which will allow only
  /// incoming connections from the local host, use the value
  /// [InternetAddress.loopbackIPv4] or
  /// [InternetAddress.loopbackIPv6]. To allow for incoming
  /// connection from the network use either one of the values
  /// [InternetAddress.anyIPv4] or [InternetAddress.anyIPv6] to
  /// bind to all interfaces or the IP address of a specific interface.
  ///
  /// If an IP version 6 (IPv6) address is used, both IP version 6
  /// (IPv6) and version 4 (IPv4) connections will be accepted. To
  /// restrict this to version 6 (IPv6) only, use [v6Only] to set
  /// version 6 only.
  ///
  /// If [port] has the value [:0:] an ephemeral port will
  /// be chosen by the system. The actual port used can be retrieved
  /// using the [:port:] getter.
  ///
  /// The optional argument [backlog] can be used to specify the listen
  /// backlog for the underlying OS listen setup. If [backlog] has the
  /// value of [:0:] (the default) a reasonable value will be chosen by
  /// the system.
  ///
  /// The optional argument [shared] specifies whether additional RawServerSocket
  /// objects can bind to the same combination of `address`, `port` and `v6Only`.
  /// If `shared` is `true` and more `RawServerSocket`s from this isolate or
  /// other isolates are bound to the port, then the incoming connections will be
  /// distributed among all the bound `RawServerSocket`s. Connections can be
  /// distributed over multiple isolates this way.
  static Future<RawServerSocket> bind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    return IODriver.current.rawServerSocketDriver.bind(
      address,
      port,
      backlog: backlog,
      v6Only: v6Only,
      shared: shared,
    );
  }
}

/// The [RawSocket] is a low-level interface to a socket, exposing the raw
/// events signaled by the system. It's a [Stream] of [RawSocketEvent]s.
abstract class RawSocket implements Stream<RawSocketEvent> {
  /// Set or get, if the [RawSocket] should listen for [RawSocketEvent.read]
  /// events. Default is [:true:].
  bool readEventsEnabled;

  /// Set or get, if the [RawSocket] should listen for [RawSocketEvent.write]
  /// events. Default is [:true:].
  /// This is a one-shot listener, and writeEventsEnabled must be set
  /// to true again to receive another write event.
  bool writeEventsEnabled;

  /// Returns the [InternetAddress] used to connect this socket.
  InternetAddress get address;

  /// Returns the port used by this socket.
  int get port;

  /// Returns the remote [InternetAddress] connected to by this socket.
  InternetAddress get remoteAddress;

  /// Returns the remote port connected to by this socket.
  int get remotePort;

  /// Returns the number of received and non-read bytes in the socket that
  /// can be read.
  int available();

  /// Closes the socket. Returns a Future that completes with [this] when the
  /// underlying connection is completely destroyed.
  ///
  /// Calling [close] will never throw an exception
  /// and calling it several times is supported. Calling [close] can result in
  /// a [RawSocketEvent.readClosed] event.
  Future<RawSocket> close();

  /// Use [getRawOption] to get low level information about the [RawSocket]. See
  /// [RawSocketOption] for available options.
  ///
  /// Returns the [RawSocketOption.value] on success.
  ///
  /// Throws an [OSError] on failure.
  Uint8List getRawOption(RawSocketOption option);

  /// Read up to [len] bytes from the socket. This function is
  /// non-blocking and will only return data if data is available. The
  /// number of bytes read can be less then [len] if fewer bytes are
  /// available for immediate reading. If no data is available [:null:]
  /// is returned.
  List<int> read([int len]);

  /// Use [setOption] to customize the [RawSocket]. See [SocketOption] for
  /// available options.
  ///
  /// Returns [:true:] if the option was set successfully, false otherwise.
  bool setOption(SocketOption option, bool enabled);

  /// Use [setRawOption] to customize the [RawSocket]. See [RawSocketOption] for
  /// available options.
  ///
  /// Throws an [OSError] on failure.
  void setRawOption(RawSocketOption option);

  /// Shutdown the socket in the [direction]. Calling [shutdown] will never
  /// throw an exception and calling it several times is supported. Calling
  /// shutdown with either [SocketDirection.both] or [SocketDirection.receive]
  /// can result in a [RawSocketEvent.readClosed] event.
  void shutdown(SocketDirection direction);

  /// Writes up to [count] bytes of the buffer from [offset] buffer offset to
  /// the socket. The number of successfully written bytes is returned. This
  /// function is non-blocking and will only write data if buffer space is
  /// available in the socket.
  ///
  /// The default value for [offset] is 0, and the default value for [count] is
  /// [:buffer.length - offset:].
  int write(List<int> buffer, [int offset, int count]);

  /// Creates a new socket connection to the host and port and returns a [Future]
  /// that will complete with either a [RawSocket] once connected or an error
  /// if the host-lookup or connection failed.
  ///
  /// [host] can either be a [String] or an [InternetAddress]. If [host] is a
  /// [String], [connect] will perform a [InternetAddress.lookup] and try
  /// all returned [InternetAddress]es, until connected. Unless a
  /// connection was established, the error from the first failing connection is
  /// returned.
  ///
  /// The argument [sourceAddress] can be used to specify the local
  /// address to bind when making the connection. `sourceAddress` can either
  /// be a `String` or an `InternetAddress`. If a `String` is passed it must
  /// hold a numeric IP address.
  ///
  /// The argument [timeout] is used to specify the maximum allowed time to wait
  /// for a connection to be established. If [timeout] is longer than the system
  /// level timeout duration, a timeout may occur sooner than specified in
  /// [timeout]. On timeout, a [SocketException] is thrown and all ongoing
  /// connection attempts to [host] are cancelled.
  static Future<RawSocket> connect(host, int port,
      {sourceAddress, Duration timeout}) {
    return IODriver.current.rawSocketDriver.connect(
      host,
      port,
      sourceAddress: sourceAddress,
      timeout: timeout,
    );
  }

  /// Like [connect], but returns a [Future] that completes with a
  /// [ConnectionTask] that can be cancelled if the [RawSocket] is no
  /// longer needed.
  static Future<ConnectionTask<RawSocket>> startConnect(host, int port,
      {sourceAddress}) {
    return IODriver.current.rawSocketDriver
        .startConnect(host, port, sourceAddress: sourceAddress);
  }
}

/// Events for the [RawSocket].
class RawSocketEvent {
  static const RawSocketEvent read = RawSocketEvent._(0);
  static const RawSocketEvent write = RawSocketEvent._(1);
  static const RawSocketEvent readClosed = RawSocketEvent._(2);
  static const RawSocketEvent closed = RawSocketEvent._(3);

  @Deprecated("Use read instead")
  static const RawSocketEvent READ = read;
  @Deprecated("Use write instead")
  static const RawSocketEvent WRITE = write;
  @Deprecated("Use readClosed instead")
  static const RawSocketEvent READ_CLOSED = readClosed;
  @Deprecated("Use closed instead")
  static const RawSocketEvent CLOSED = closed;

  final int _value;

  const RawSocketEvent._(this._value);

  String toString() {
    return const [
      'RawSocketEvent.read',
      'RawSocketEvent.write',
      'RawSocketEvent.readClosed',
      'RawSocketEvent.closed'
    ][_value];
  }
}

/// The [RawSocketOption] is used as a parameter to [Socket.setRawOption] and
/// [RawSocket.setRawOption] to set customize the behaviour of the underlying
/// socket.
///
/// It allows for fine grained control of the socket options, and its values will
/// be passed to the underlying platform's implementation of setsockopt and
/// getsockopt.
class RawSocketOption {
  /// Socket option for IP_MULTICAST_IF.
  static int get IPv4MulticastInterface => 0x4;

  /// Socket option for IPV6_MULTICAST_IF.
  static int get IPv6MulticastInterface => 0x10;

  /// Socket level option for IPPROTO_IP.
  static int get levelIPv4 => 0x2;

  /// Socket level option for IPPROTO_IPV6.
  static int get levelIPv6 => 0x8;

  /// Socket level option for SOL_SOCKET.
  static int get levelSocket => 0x1;

  /// Socket level option for IPPROTO_TCP.
  static int get levelTcp => 0x20;

  /// Socket level option for IPPROTO_UDP.
  static int get levelUdp => 0x40;

  /// The level for the option to set or get.
  ///
  /// See also:
  ///   * [RawSocketOption.levelSocket]
  ///   * [RawSocketOption.levelIPv4]
  ///   * [RawSocketOption.levelIPv6]
  ///   * [RawSocketOption.levelTcp]
  ///   * [RawSocketOption.levelUdp]
  final int level;

  /// The option to set or get.
  final int option;

  /// The raw data to set, or the array to write the current option value into.
  ///
  /// This list must be the correct length for the expected option. For most
  /// options that take int or bool values, the length should be 4. For options
  /// that expect a struct (such as an in_addr_t), the length should be the
  /// correct length for that struct.
  final Uint8List value;

  /// Creates a RawSocketOption for getRawOption andSetRawOption.
  ///
  /// All arguments are required and must not be null.
  ///
  /// The level and option arguments correspond to level and optname arguments
  /// on the get/setsockopt native calls.
  ///
  /// The value argument and its length correspond to the optval and length
  /// arguments on the native call.
  ///
  /// For a [getRawOption] call, the value parameter will be updated after a
  /// successful call (although its length will not be changed).
  ///
  /// For a [setRawOption] call, the value parameter will be used set the
  /// option.
  const RawSocketOption(this.level, this.option, this.value);

  /// Convenience constructor for creating a bool based RawSocketOption.
  factory RawSocketOption.fromBool(int level, int option, bool value) =>
      RawSocketOption.fromInt(level, option, value == true ? 1 : 0);

  /// Convenience constructor for creating an int based RawSocketOption.
  factory RawSocketOption.fromInt(int level, int option, int value) {
    if (value == null) {
      value = 0;
    }
    final Uint8List list = Uint8List(4);
    final buffer = ByteData.view(list.buffer);
    buffer.setInt32(0, value);
    return RawSocketOption(level, option, list);
  }
}

/// A [ServerSocket] represents a listening socket, and provides a
/// stream of [Socket] objects, one for each connection made to the
/// listening socket.
///
/// See [Socket] for more info.
class ServerSocket extends Stream<Socket> {
  final RawServerSocket _rawServerSocket;

  ServerSocket._(this._rawServerSocket);

  /// Returns the address used by this socket.
  InternetAddress get address => _rawServerSocket.address;

  /// Returns the port used by this socket.
  int get port => _rawServerSocket.port;

  /// Closes the socket. The returned future completes when the socket
  /// is fully closed and is no longer bound.
  Future<ServerSocket> close() async {
    await _rawServerSocket.close();
    return this;
  }

  @override
  StreamSubscription<Socket> listen(void onData(Socket event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _rawServerSocket.map((rawSocket) {
      return SocketImpl(rawSocket);
    }).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  /// Returns a future for a [:ServerSocket:]. When the future
  /// completes the server socket is bound to the given [address] and
  /// [port] and has started listening on it.
  ///
  /// The [address] can either be a [String] or an
  /// [InternetAddress]. If [address] is a [String], [bind] will
  /// perform a [InternetAddress.lookup] and use the first value in the
  /// list. To listen on the loopback adapter, which will allow only
  /// incoming connections from the local host, use the value
  /// [InternetAddress.loopbackIPv4] or
  /// [InternetAddress.loopbackIPv6]. To allow for incoming
  /// connection from the network use either one of the values
  /// [InternetAddress.anyIPv4] or [InternetAddress.anyIPv6] to
  /// bind to all interfaces or the IP address of a specific interface.
  ///
  /// If an IP version 6 (IPv6) address is used, both IP version 6
  /// (IPv6) and version 4 (IPv4) connections will be accepted. To
  /// restrict this to version 6 (IPv6) only, use [v6Only] to set
  /// version 6 only.
  ///
  /// If [port] has the value [:0:] an ephemeral port will be chosen by
  /// the system. The actual port used can be retrieved using the
  /// [port] getter.
  ///
  /// The optional argument [backlog] can be used to specify the listen
  /// backlog for the underlying OS listen setup. If [backlog] has the
  /// value of [:0:] (the default) a reasonable value will be chosen by
  /// the system.
  ///
  /// The optional argument [shared] specifies whether additional ServerSocket
  /// objects can bind to the same combination of `address`, `port` and `v6Only`.
  /// If `shared` is `true` and more `ServerSocket`s from this isolate or other
  /// isolates are bound to the port, then the incoming connections will be
  /// distributed among all the bound `ServerSocket`s. Connections can be
  /// distributed over multiple isolates this way.
  static Future<ServerSocket> bind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) async {
    final rawServerSocket = await RawServerSocket.bind(
      address,
      port,
      backlog: backlog,
      v6Only: v6Only,
      shared: shared,
    );
    return ServerSocket._(rawServerSocket);
  }
}

/// A high-level class for communicating over a TCP socket.
///
/// The [Socket] exposes both a [Stream] and a [IOSink] interface, making it
/// ideal for using together with other [Stream]s.
abstract class Socket implements Stream<List<int>>, IOSink {
  /// Returns the [InternetAddress] used to connect this socket.
  InternetAddress get address;

  Future get done;

  /// Returns the port used by this socket.
  int get port;

  /// Returns the remote [InternetAddress] connected to by this socket.
  InternetAddress get remoteAddress;

  /// Returns the remote port connected to by this socket.
  int get remotePort;

  Future close();

  /// Destroy the socket in both directions. Calling [destroy] will make the
  /// send a close event on the stream and will no longer react on data being
  /// piped to it.
  ///
  /// Call [close](inherited from [IOSink]) to only close the [Socket]
  /// for sending data.
  void destroy();

  /// Use [getRawOption] to get low level information about the [RawSocket]. See
  /// [RawSocketOption] for available options.
  ///
  /// Returns the [RawSocketOption.value] on success.
  ///
  /// Throws an [OSError] on failure.
  Uint8List getRawOption(RawSocketOption option);

  /// Use [setOption] to customize the [RawSocket]. See [SocketOption] for
  /// available options.
  ///
  /// Returns [:true:] if the option was set successfully, false otherwise.
  bool setOption(SocketOption option, bool enabled);

  /// Use [setRawOption] to customize the [RawSocket]. See [RawSocketOption] for
  /// available options.
  ///
  /// Throws an [OSError] on failure.
  void setRawOption(RawSocketOption option);

  /// Creates a new socket connection to the host and port and returns a [Future]
  /// that will complete with either a [Socket] once connected or an error
  /// if the host-lookup or connection failed.
  ///
  /// [host] can either be a [String] or an [InternetAddress]. If [host] is a
  /// [String], [connect] will perform a [InternetAddress.lookup] and try
  /// all returned [InternetAddress]es, until connected. Unless a
  /// connection was established, the error from the first failing connection is
  /// returned.
  ///
  /// The argument [sourceAddress] can be used to specify the local
  /// address to bind when making the connection. `sourceAddress` can either
  /// be a `String` or an `InternetAddress`. If a `String` is passed it must
  /// hold a numeric IP address.
  ///
  /// The argument [timeout] is used to specify the maximum allowed time to wait
  /// for a connection to be established. If [timeout] is longer than the system
  /// level timeout duration, a timeout may occur sooner than specified in
  /// [timeout]. On timeout, a [SocketException] is thrown and all ongoing
  /// connection attempts to [host] are cancelled.
  static Future<Socket> connect(host, int port,
      {sourceAddress, Duration timeout}) async {
    final IOOverrides overrides = IOOverrides.current;
    if (overrides == null) {
      return SocketImpl.connect(
        host,
        port,
        sourceAddress: sourceAddress,
        timeout: timeout,
      );
    }
    return overrides.socketConnect(
      host,
      port,
      sourceAddress: sourceAddress,
      timeout: timeout,
    );
  }

  /// Like [connect], but returns a [Future] that completes with a
  /// [ConnectionTask] that can be cancelled if the [Socket] is no
  /// longer needed.
  static Future<ConnectionTask<Socket>> startConnect(host, int port,
      {sourceAddress}) async {
    final IOOverrides overrides = IOOverrides.current;
    if (overrides == null) {
      final socketFuture = connect(host, port, sourceAddress: sourceAddress);
      final task = ConnectionTask._(
          socket: socketFuture,
          onCancel: () {
            socketFuture.then((socket) {
              socket.close();
            });
          });
      return task;
    }
    return overrides.socketStartConnect(
      host,
      port,
      sourceAddress: sourceAddress,
    );
  }
}

/// The [SocketDirection] is used as a parameter to [Socket.close] and
/// [RawSocket.close] to close a socket in the specified direction(s).
class SocketDirection {
  static const SocketDirection receive = SocketDirection._(0);
  static const SocketDirection send = SocketDirection._(1);
  static const SocketDirection both = SocketDirection._(2);

  @Deprecated("Use receive instead")
  static const SocketDirection RECEIVE = receive;
  @Deprecated("Use send instead")
  static const SocketDirection SEND = send;
  @Deprecated("Use both instead")
  static const SocketDirection BOTH = both;

  final _value;

  const SocketDirection._(this._value);
}

class SocketException implements IOException {
  final String message;
  final OSError osError;
  final InternetAddress address;
  final int port;

  const SocketException(this.message, {this.osError, this.address, this.port});

  const SocketException.closed()
      : message = 'Socket has been closed',
        osError = null,
        address = null,
        port = null;

  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write("SocketException");
    if (message.isNotEmpty) {
      sb.write(": $message");
      if (osError != null) {
        sb.write(" ($osError)");
      }
    } else if (osError != null) {
      sb.write(": $osError");
    }
    if (address != null) {
      sb.write(", address = ${address.host}");
    }
    if (port != null) {
      sb.write(", port = $port");
    }
    return sb.toString();
  }
}

/// The [SocketOption] is used as a parameter to [Socket.setOption] and
/// [RawSocket.setOption] to set customize the behaviour of the underlying
/// socket.
class SocketOption {
  /// Enable or disable no-delay on the socket. If tcpNoDelay is enabled, the
  /// socket will not buffer data internally, but instead write each data chunk
  /// as an individual TCP packet.
  ///
  /// tcpNoDelay is disabled by default.
  static const SocketOption tcpNoDelay = SocketOption._(0);

  final _value;

  const SocketOption._(this._value);
}
