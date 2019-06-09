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

import '../io.dart';
import 'common.dart';
import 'security_context.dart';
import 'socket.dart';
import 'socket_impl.dart';

/// An exception that happens in the handshake phase of establishing
/// a secure network connection, when looking up or verifying a
/// certificate.
class CertificateException extends TlsException {
  const CertificateException([String message = "", OSError osError])
      : super._("CertificateException", message, osError);
}

/// An exception that happens in the handshake phase of establishing
/// a secure network connection.
class HandshakeException extends TlsException {
  const HandshakeException([String message = "", OSError osError])
      : super._("HandshakeException", message, osError);
}

/// The RawSecureServerSocket is a server socket, providing a stream of low-level
/// [RawSecureSocket]s.
///
/// See [RawSecureSocket] for more info.
class RawSecureServerSocket extends Stream<RawSecureSocket> {
  final bool requestClientCertificate;
  final bool requireClientCertificate;
  final List<String> supportedProtocols;

  final RawServerSocket _serverSocket;

  RawSecureServerSocket._(
    this._serverSocket, {
    this.requestClientCertificate,
    this.requireClientCertificate,
    this.supportedProtocols,
  });

  /// Returns the address used by this socket.
  InternetAddress get address => _serverSocket.address;

  /// Returns the port used by this socket.
  int get port => _serverSocket.port;

  /// Closes the socket. The returned future completes when the socket
  /// is fully closed and is no longer bound.
  Future<RawSecureServerSocket> close() async {
    await _serverSocket.close();
    return this;
  }

  StreamSubscription<RawSecureSocket> listen(void onData(RawSecureSocket s),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _serverSocket.asyncMap((socket) {
      return RawSecureSocket.secure(socket);
    }).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
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
      bool shared = false}) async {
    final serverSocket = await RawServerSocket.bind(
      address,
      port,
      backlog: backlog,
      v6Only: v6Only,
    );
    return RawSecureServerSocket._(
      serverSocket,
      requestClientCertificate: requestClientCertificate,
      requireClientCertificate: requireClientCertificate,
      supportedProtocols: supportedProtocols,
    );
  }
}

/// RawSecureSocket provides a secure (SSL or TLS) network connection.
/// Client connections to a server are provided by calling
/// RawSecureSocket.connect.  A secure server, created with
/// [RawSecureServerSocket], also returns RawSecureSocket objects representing
/// the server end of a secure connection.
/// The certificate provided by the server is checked
/// using the trusted certificates set in the SecurityContext object.
/// The default [SecurityContext] object contains a built-in set of trusted
/// root certificates for well-known certificate authorities.
abstract class RawSecureSocket implements RawSocket {
  /// Get the peer certificate for a connected RawSecureSocket.  If this
  /// RawSecureSocket is the server end of a secure socket connection,
  /// [peerCertificate] will return the client certificate, or null, if no
  /// client certificate was received.  If it is the client end,
  /// [peerCertificate] will return the server's certificate.
  X509Certificate get peerCertificate;

  /// The protocol which was selected during protocol negotiation.
  ///
  /// Returns null if one of the peers does not have support for ALPN, did not
  /// specify a list of supported ALPN protocols or there was no common
  /// protocol between client and server.
  String get selectedProtocol;

  /// Renegotiate an existing secure connection, renewing the session keys
  /// and possibly changing the connection properties.
  ///
  /// This repeats the SSL or TLS handshake, with options that allow clearing
  /// the session cache and requesting a client certificate.
  void renegotiate(
      {bool useSessionCache = true,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false});

  /// Constructs a new secure client socket and connect it to the given
  /// host on the given port. The returned [Future] is completed with the
  /// RawSecureSocket when it is connected and ready for subscription.
  ///
  /// The certificate provided by the server is checked using the trusted
  /// certificates set in the SecurityContext object If a certificate and key are
  /// set on the client, using [SecurityContext.useCertificateChain] and
  /// [SecurityContext.usePrivateKey], and the server asks for a client
  /// certificate, then that client certificate is sent to the server.
  ///
  /// [onBadCertificate] is an optional handler for unverifiable certificates.
  /// The handler receives the [X509Certificate], and can inspect it and
  /// decide (or let the user decide) whether to accept
  /// the connection or not.  The handler should return true
  /// to continue the [RawSecureSocket] connection.
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negotiation with the
  /// server.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [RawSecureSocket.selectedProtocol].
  static Future<RawSecureSocket> connect(host, int port,
      {SecurityContext context,
      bool onBadCertificate(X509Certificate certificate),
      List<String> supportedProtocols,
      Duration timeout}) {
    return IODriver.current.rawSecureSocketDriver.connect(
      host,
      port,
      context: context,
      onBadCertificate: onBadCertificate,
      supportedProtocols: supportedProtocols,
      timeout: timeout,
    );
  }

  /// Takes an already connected [socket] and starts client side TLS
  /// handshake to make the communication secure. When the returned
  /// future completes the [RawSecureSocket] has completed the TLS
  /// handshake. Using this function requires that the other end of the
  /// connection is prepared for TLS handshake.
  ///
  /// If the [socket] already has a subscription, pass the existing
  /// subscription in the [subscription] parameter. The [secure]
  /// operation will take over the subscription by replacing the
  /// handlers with it own secure processing. The caller must not touch
  /// this subscription anymore. Passing a paused subscription is an
  /// error.
  ///
  /// If the [host] argument is passed it will be used as the host name
  /// for the TLS handshake. If [host] is not passed the host name from
  /// the [socket] will be used. The [host] can be either a [String] or
  /// an [InternetAddress].
  ///
  /// Calling this function will _not_ cause a DNS host lookup. If the
  /// [host] passed is a [String] the [InternetAddress] for the
  /// resulting [SecureSocket] will have this passed in [host] as its
  /// host value and the internet address of the already connected
  /// socket as its address value.
  ///
  /// See [connect] for more information on the arguments.
  ///
  static Future<RawSecureSocket> secure(RawSocket socket,
      {StreamSubscription<RawSocketEvent> subscription,
      host,
      SecurityContext context,
      bool onBadCertificate(X509Certificate certificate),
      List<String> supportedProtocols}) {
    socket.readEventsEnabled = false;
    socket.writeEventsEnabled = false;
    return IODriver.current.rawSecureSocketDriver.secure(
      socket,
      subscription: subscription,
      host: (host != null ? host : socket.address.host),
      context: context,
      onBadCertificate: onBadCertificate,
      supportedProtocols: supportedProtocols,
    );
  }

  /// Takes an already connected [socket] and starts server side TLS
  /// handshake to make the communication secure. When the returned
  /// future completes the [RawSecureSocket] has completed the TLS
  /// handshake. Using this function requires that the other end of the
  /// connection is going to start the TLS handshake.
  ///
  /// If the [socket] already has a subscription, pass the existing
  /// subscription in the [subscription] parameter. The [secureServer]
  /// operation will take over the subscription by replacing the
  /// handlers with it own secure processing. The caller must not touch
  /// this subscription anymore. Passing a paused subscription is an
  /// error.
  ///
  /// If some of the data of the TLS handshake has already been read
  /// from the socket this data can be passed in the [bufferedData]
  /// parameter. This data will be processed before any other data
  /// available on the socket.
  ///
  /// See [RawSecureServerSocket.bind] for more information on the
  /// arguments.
  ///
  static Future<RawSecureSocket> secureServer(
      RawSocket socket, SecurityContext context,
      {StreamSubscription<RawSocketEvent> subscription,
      List<int> bufferedData,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false,
      List<String> supportedProtocols}) {
    socket.readEventsEnabled = false;
    socket.writeEventsEnabled = false;
    return IODriver.current.rawSecureSocketDriver.secureServer(
      socket,
      context,
      subscription: subscription,
      bufferedData: bufferedData,
      requestClientCertificate: requestClientCertificate,
      requireClientCertificate: requireClientCertificate,
      supportedProtocols: supportedProtocols,
    );
  }

  /// Like [connect], but returns a [Future] that completes with a
  /// [ConnectionTask] that can be cancelled if the [RawSecureSocket] is no
  /// longer needed.
  static Future<ConnectionTask<RawSecureSocket>> startConnect(host, int port,
      {SecurityContext context,
      bool onBadCertificate(X509Certificate certificate),
      List<String> supportedProtocols}) {
    return IODriver.current.rawSecureSocketDriver.startConnect(
      host,
      port,
      context: context,
      onBadCertificate: onBadCertificate,
      supportedProtocols: supportedProtocols,
    );
  }
}

/// The [SecureServerSocket] is a server socket, providing a stream of high-level
/// [Socket]s.
///
/// See [SecureSocket] for more info.
class SecureServerSocket extends Stream<SecureSocket> {
  final RawSecureServerSocket _rawSecureServerSocket;

  SecureServerSocket._(this._rawSecureServerSocket);

  /// Returns the address used by this socket.
  InternetAddress get address => _rawSecureServerSocket.address;

  /// Returns the port used by this socket.
  int get port => _rawSecureServerSocket.port;

  /// Closes the socket. The returned future completes when the socket
  /// is fully closed and is no longer bound.
  Future<SecureServerSocket> close() async {
    await _rawSecureServerSocket.close();
    return this;
  }

  StreamSubscription<SecureSocket> listen(void onData(SecureSocket socket),
      {Function onError, void onDone(), bool cancelOnError}) {
    final stream = _rawSecureServerSocket
        .asyncMap((rawSocket) => SecureSocketImpl(rawSocket));
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

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
}

/// A high-level class for communicating securely over a TCP socket, using
/// TLS and SSL. The [SecureSocket] exposes both a [Stream] and an
/// [IOSink] interface, making it ideal for using together with
/// other [Stream]s.
abstract class SecureSocket extends Stream<List<int>> implements Socket {
  /// Get the peer certificate for a connected SecureSocket.  If this
  /// SecureSocket is the server end of a secure socket connection,
  /// [peerCertificate] will return the client certificate, or null, if no
  /// client certificate was received.  If it is the client end,
  /// [peerCertificate] will return the server's certificate.
  X509Certificate get peerCertificate {
    throw UnimplementedError();
  }

  /// The protocol which was selected during ALPN protocol negotiation.
  ///
  /// Returns null if one of the peers does not have support for ALPN, did not
  /// specify a list of supported ALPN protocols or there was no common
  /// protocol between client and server.
  String get selectedProtocol {
    throw UnimplementedError();
  }

  /// Renegotiate an existing secure connection, renewing the session keys
  /// and possibly changing the connection properties.
  ///
  /// This repeats the SSL or TLS handshake, with options that allow clearing
  /// the session cache and requesting a client certificate.
  void renegotiate(
      {bool useSessionCache = true,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false}) {
    throw UnimplementedError();
  }

  /// Constructs a new secure client socket and connects it to the given
  /// [host] on port [port]. The returned Future will complete with a
  /// [SecureSocket] that is connected and ready for subscription.
  ///
  /// The certificate provided by the server is checked
  /// using the trusted certificates set in the SecurityContext object.
  /// The default SecurityContext object contains a built-in set of trusted
  /// root certificates for well-known certificate authorities.
  ///
  /// [onBadCertificate] is an optional handler for unverifiable certificates.
  /// The handler receives the [X509Certificate], and can inspect it and
  /// decide (or let the user decide) whether to accept
  /// the connection or not.  The handler should return true
  /// to continue the [SecureSocket] connection.
  ///
  /// [supportedProtocols] is an optional list of protocols (in decreasing
  /// order of preference) to use during the ALPN protocol negotiation with the
  /// server.  Example values are "http/1.1" or "h2".  The selected protocol
  /// can be obtained via [SecureSocket.selectedProtocol].
  ///
  /// The argument [timeout] is used to specify the maximum allowed time to wait
  /// for a connection to be established. If [timeout] is longer than the system
  /// level timeout duration, a timeout may occur sooner than specified in
  /// [timeout]. On timeout, a [SocketException] is thrown and all ongoing
  /// connection attempts to [host] are cancelled.
  static Future<SecureSocket> connect(host, int port,
      {SecurityContext context,
      bool onBadCertificate(X509Certificate certificate),
      List<String> supportedProtocols,
      Duration timeout}) {
    return RawSecureSocket.connect(host, port,
            context: context,
            onBadCertificate: onBadCertificate,
            supportedProtocols: supportedProtocols,
            timeout: timeout)
        .then((rawSocket) => SecureSocketImpl(rawSocket));
  }

  /// Takes an already connected [socket] and starts client side TLS
  /// handshake to make the communication secure. When the returned
  /// future completes the [SecureSocket] has completed the TLS
  /// handshake. Using this function requires that the other end of the
  /// connection is prepared for TLS handshake.
  ///
  /// If the [socket] already has a subscription, this subscription
  /// will no longer receive and events. In most cases calling
  /// `pause` on this subscription before starting TLS handshake is
  /// the right thing to do.
  ///
  /// The given [socket] is closed and may not be used anymore.
  ///
  /// If the [host] argument is passed it will be used as the host name
  /// for the TLS handshake. If [host] is not passed the host name from
  /// the [socket] will be used. The [host] can be either a [String] or
  /// an [InternetAddress].
  ///
  /// Calling this function will _not_ cause a DNS host lookup. If the
  /// [host] passed is a [String] the [InternetAddress] for the
  /// resulting [SecureSocket] will have the passed in [host] as its
  /// host value and the internet address of the already connected
  /// socket as its address value.
  ///
  /// See [connect] for more information on the arguments.
  ///
  static Future<SecureSocket> secure(Socket socket,
      {host,
      SecurityContext context,
      bool onBadCertificate(X509Certificate certificate)}) async {
    final rawSocket = (socket as SocketImpl).rawSocket;
    final rawSecureSocket = await RawSecureSocket.secure(
      rawSocket,
      onBadCertificate: onBadCertificate,
    );
    return SecureSocketImpl(rawSecureSocket);
  }

  /// Takes an already connected [socket] and starts server side TLS
  /// handshake to make the communication secure. When the returned
  /// future completes the [SecureSocket] has completed the TLS
  /// handshake. Using this function requires that the other end of the
  /// connection is going to start the TLS handshake.
  ///
  /// If the [socket] already has a subscription, this subscription
  /// will no longer receive and events. In most cases calling
  /// [:pause:] on this subscription before starting TLS handshake is
  /// the right thing to do.
  ///
  /// If some of the data of the TLS handshake has already been read
  /// from the socket this data can be passed in the [bufferedData]
  /// parameter. This data will be processed before any other data
  /// available on the socket.
  ///
  /// See [SecureServerSocket.bind] for more information on the
  /// arguments.
  ///
  static Future<SecureSocket> secureServer(
      Socket socket, SecurityContext context,
      {List<int> bufferedData,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false,
      List<String> supportedProtocols}) async {
    final rawSocket = (socket as SocketImpl).rawSocket;
    final rawSecureSocket = await RawSecureSocket.secureServer(
      rawSocket,
      context,
      bufferedData: bufferedData,
      requestClientCertificate: requestClientCertificate,
      requireClientCertificate: requireClientCertificate,
      supportedProtocols: supportedProtocols,
    );
    return SecureSocketImpl(rawSecureSocket);
  }

  /// Like [connect], but returns a [Future] that completes with a
  /// [ConnectionTask] that can be cancelled if the [SecureSocket] is no
  /// longer needed.
  static Future<ConnectionTask<SecureSocket>> startConnect(host, int port,
      {SecurityContext context,
      bool onBadCertificate(X509Certificate certificate),
      List<String> supportedProtocols}) {
    throw UnimplementedError();
  }
}

/// A secure networking exception caused by a failure in the
///  TLS/SSL protocol.
class TlsException implements IOException {
  final String type;
  final String message;
  final OSError osError;

  @pragma("vm:entry-point")
  const TlsException([String message = "", OSError osError])
      : this._("TlsException", message, osError);

  const TlsException._(this.type, this.message, this.osError);

  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write(type);
    if (message.isNotEmpty) {
      sb.write(": $message");
      if (osError != null) {
        sb.write(" ($osError)");
      }
    } else if (osError != null) {
      sb.write(": $osError");
    }
    return sb.toString();
  }
}

/// X509Certificate represents an SSL certificate, with accessors to
/// get the fields of the certificate.
abstract class X509Certificate {
  X509Certificate._();

  /// The DER encoded bytes of the certificate.
  Uint8List get der;

  DateTime get endValidity;

  String get issuer;

  /// The PEM encoded String of the certificate.
  String get pem;

  /// The SHA1 hash of the certificate.
  Uint8List get sha1;
  DateTime get startValidity;
  String get subject;
}
