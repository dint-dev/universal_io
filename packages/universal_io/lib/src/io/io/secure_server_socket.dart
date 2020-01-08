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

import '../io.dart';
import 'secure_socket_impl.dart';
import 'security_context.dart';
import 'socket.dart';

/// The [SecureServerSocket] is a server socket, providing a stream of high-level
/// [Socket]s.
///
/// See [SecureSocket] for more info.
class SecureServerSocket extends Stream<SecureSocket> {
  final RawSecureServerSocket _socket;

  SecureServerSocket._(this._socket);

  /// Returns a future for a [SecureServerSocket]. When the future
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
  /// If [port] has the value [:0:] an ephemeral port will be chosen by
  /// the system. The actual port used can be retrieved using the
  /// [port] getter.
  ///
  /// The optional argument [backlog] can be used to specify the listen
  /// backlog for the underlying OS listen setup. If [backlog] has the
  /// value of [:0:] (the default) a reasonable value will be chosen by
  /// the system.
  ///
  /// Incoming client connections are promoted to secure connections, using
  /// the server certificate and key set in [context].
  ///
  /// [address] must be given as a numeric address, not a host name.
  ///
  /// To request or require that clients authenticate by providing an SSL (TLS)
  /// client certificate, set the optional parameter [requestClientCertificate]
  /// or [requireClientCertificate] to true.  Requiring a certificate implies
  /// requesting a certificate, so setting both is redundant.
  /// To check whether a client certificate was received, check
  /// SecureSocket.peerCertificate after connecting.  If no certificate
  /// was received, the result will be null.
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negogiation with
  /// clients.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [SecureSocket.selectedProtocol].
  ///
  /// The optional argument [shared] specifies whether additional
  /// SecureServerSocket objects can bind to the same combination of `address`,
  /// `port` and `v6Only`.  If `shared` is `true` and more `SecureServerSocket`s
  /// from this isolate or other isolates are bound to the port, then the
  /// incoming connections will be distributed among all the bound
  /// `SecureServerSocket`s. Connections can be distributed over multiple
  /// isolates this way.
  static Future<SecureServerSocket> bind(
      address, int port, SecurityContext context,
      {int backlog = 0,
      bool v6Only = false,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false,
      List<String> supportedProtocols,
      bool shared = false}) {
    return RawSecureServerSocket.bind(address, port, context,
            backlog: backlog,
            v6Only: v6Only,
            requestClientCertificate: requestClientCertificate,
            requireClientCertificate: requireClientCertificate,
            supportedProtocols: supportedProtocols,
            shared: shared)
        .then((serverSocket) => SecureServerSocket._(serverSocket));
  }

  StreamSubscription<SecureSocket> listen(void onData(SecureSocket socket),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _socket.asyncMap((rawSocket) => SecureSocketImpl(rawSocket)).listen(
          onData,
          onError: onError,
          onDone: onDone,
          cancelOnError: cancelOnError,
        );
  }

  /// Returns the port used by this socket.
  int get port => _socket.port;

  /// Returns the address used by this socket.
  InternetAddress get address => _socket.address;

  /// Closes the socket. The returned future completes when the socket
  /// is fully closed and is no longer bound.
  Future<SecureServerSocket> close() => _socket.close().then((_) => this);
}

/// The RawSecureServerSocket is a server socket, providing a stream of low-level
/// [RawSecureSocket]s.
///
/// See [RawSecureSocket] for more info.
class RawSecureServerSocket extends Stream<RawSecureSocket> {
  final RawServerSocket _socket;
  StreamController<RawSecureSocket> _controller;
  StreamSubscription<RawSocket> _subscription;
  final SecurityContext _context;
  final bool requestClientCertificate;
  final bool requireClientCertificate;
  final List<String> supportedProtocols;
  bool _closed = false;

  RawSecureServerSocket._(
      this._socket,
      this._context,
      this.requestClientCertificate,
      this.requireClientCertificate,
      this.supportedProtocols) {
    _controller = StreamController<RawSecureSocket>(
        sync: true,
        onListen: _onSubscriptionStateChange,
        onPause: _onPauseStateChange,
        onResume: _onPauseStateChange,
        onCancel: _onSubscriptionStateChange);
  }

  /// Returns a future for a [RawSecureServerSocket]. When the future
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
  /// If [port] has the value [:0:] an ephemeral port will be chosen by
  /// the system. The actual port used can be retrieved using the
  /// [port] getter.
  ///
  /// The optional argument [backlog] can be used to specify the listen
  /// backlog for the underlying OS listen setup. If [backlog] has the
  /// value of [:0:] (the default) a reasonable value will be chosen by
  /// the system.
  ///
  /// Incoming client connections are promoted to secure connections,
  /// using the server certificate and key set in [context].
  ///
  /// [address] must be given as a numeric address, not a host name.
  ///
  /// To request or require that clients authenticate by providing an SSL (TLS)
  /// client certificate, set the optional parameters requestClientCertificate or
  /// requireClientCertificate to true.  Require implies request, so one doesn't
  /// need to specify both.  To check whether a client certificate was received,
  /// check SecureSocket.peerCertificate after connecting.  If no certificate
  /// was received, the result will be null.
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negotiation with
  /// clients.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [RawSecureSocket.selectedProtocol].
  ///
  /// The optional argument [shared] specifies whether additional
  /// RawSecureServerSocket objects can bind to the same combination of
  /// `address`, `port` and `v6Only`.  If `shared` is `true` and more
  /// `RawSecureServerSocket`s from this isolate or other isolates are bound to
  /// the port, then the incoming connections will be distributed among all the
  /// bound `RawSecureServerSocket`s. Connections can be distributed over
  /// multiple isolates this way.
  static Future<RawSecureServerSocket> bind(
      address, int port, SecurityContext context,
      {int backlog = 0,
      bool v6Only = false,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false,
      List<String> supportedProtocols,
      bool shared = false}) {
    return RawServerSocket.bind(address, port,
            backlog: backlog, v6Only: v6Only, shared: shared)
        .then((serverSocket) => RawSecureServerSocket._(
            serverSocket,
            context,
            requestClientCertificate,
            requireClientCertificate,
            supportedProtocols));
  }

  StreamSubscription<RawSecureSocket> listen(void onData(RawSecureSocket s),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _controller.stream.listen(onData,
        onError: onError, onDone: onDone, cancelOnError: cancelOnError);
  }

  /// Returns the port used by this socket.
  int get port => _socket.port;

  /// Returns the address used by this socket.
  InternetAddress get address => _socket.address;

  /// Closes the socket. The returned future completes when the socket
  /// is fully closed and is no longer bound.
  Future<RawSecureServerSocket> close() {
    _closed = true;
    return _socket.close().then((_) => this);
  }

  void _onData(RawSocket connection) {
    try {
      connection.remotePort;
    } catch (e) {
      // If connection is already closed, remotePort throws an exception.
      // Do nothing - connection is closed.
      return;
    }
    RawSecureSocket.secureServer(connection, _context,
            requestClientCertificate: requestClientCertificate,
            requireClientCertificate: requireClientCertificate,
            supportedProtocols: supportedProtocols)
        .then((RawSecureSocket secureConnection) {
      if (_closed) {
        secureConnection.close();
      } else {
        _controller.add(secureConnection);
      }
    }).catchError((e, s) {
      if (!_closed) {
        _controller.addError(e, s);
      }
    });
  }

  void _onPauseStateChange() {
    if (_controller.isPaused) {
      _subscription.pause();
    } else {
      _subscription.resume();
    }
  }

  void _onSubscriptionStateChange() {
    if (_controller.hasListener) {
      _subscription = _socket.listen(_onData,
          onError: _controller.addError, onDone: _controller.close);
    } else {
      close();
    }
  }
}
