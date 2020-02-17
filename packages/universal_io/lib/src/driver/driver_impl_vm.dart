// Copyright 2020 terrier989@gmail.com.
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
import 'dart:convert';
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:zone_local/zone_local.dart';

import 'default_impl_vm.dart';

export 'default_impl_vm.dart';

/// Implements static members of [HttpServer].
///
/// Note that [HttpServer] constructor uses Dart SDK implementation
/// (requires socket drivers) if driver is not available.
abstract class HttpServerOverrides {
  Future<HttpServer> bind(
    address,
    int port, {
    int backlog = 0,
    bool v6Only = false,
    bool shared = false,
  });

  Future<HttpServer> bindSecure(
    address,
    int port,
    SecurityContext context, {
    int backlog = 0,
    bool v6Only = false,
    bool requestClientCertificate = false,
    bool shared = false,
  });
}

/// Implements:
///   * [InternetAddress.lookup]
///   * [InternetAddress.reverse]
abstract class InternetAddressOverrides {
  Future<List<InternetAddress>> lookup(
    String host, {
    InternetAddressType type = InternetAddressType.any,
  });

  Future<InternetAddress> reverseLookup(InternetAddress address);
}

/// Implements 'dart:io' APIs.
class IODriver {
  /// Access to zone-local instance of [IODriver].
  static final ZoneLocal<IODriver> zoneLocal = ZoneLocal<IODriver>(
    defaultValue: defaultIODriver,
  );

  /// Returns the driver used by the current zone.
  static IODriver get current {
    return zoneLocal.value;
  }

  final HttpOverrides httpOverrides;
  final IOOverrides ioOverrides;
  final HttpServerOverrides httpServerOverrides;
  final InternetAddressOverrides internetAddressOverrides;
  final PlatformOverrides platformOverrides;
  final ProcessOverrides processOverrides;
  final RawDatagramSocketOverrides rawDatagramSocketOverrides;
  final RawSocketOverrides rawSocketOverrides;
  final RawServerSocketOverrides rawServerSocketOverrides;
  final RawSecureSocketOverrides rawSecureSocketOverrides;
  final RawSecureServerSocketOverrides rawSecureServerSocketOverrides;
  final NetworkInterfaceOverrides networkInterfaceOverrides;

  /// Constructs a new driver.
  IODriver({
    @required IODriver parent,
    HttpOverrides httpOverrides,
    IOOverrides ioOverrides,
    HttpServerOverrides httpServerOverrides,
    InternetAddressOverrides internetAddressOverrides,
    PlatformOverrides platformOverrides,
    ProcessOverrides processOverrides,
    NetworkInterfaceOverrides networkInterfaceOverrides,
    RawDatagramSocketOverrides rawDatagramSocketOverrides,
    RawSocketOverrides rawSocketOverrides,
    RawServerSocketOverrides rawServerSocketOverrides,
    RawSecureSocketOverrides rawSecureSocketOverrides,
    RawSecureServerSocketOverrides rawSecureServerSocketOverrides,
  })  : httpOverrides = httpOverrides ?? parent?.httpOverrides,
        ioOverrides = ioOverrides ?? parent?.ioOverrides,
        httpServerOverrides =
            httpServerOverrides ?? parent?.httpServerOverrides,
        internetAddressOverrides = parent?.internetAddressOverrides,
        platformOverrides = platformOverrides ?? parent?.platformOverrides,
        processOverrides = processOverrides ?? parent?.processOverrides,
        networkInterfaceOverrides =
            networkInterfaceOverrides ?? parent?.networkInterfaceOverrides,
        rawDatagramSocketOverrides =
            rawDatagramSocketOverrides ?? parent?.rawDatagramSocketOverrides,
        rawSocketOverrides = rawSocketOverrides ?? parent?.rawSocketOverrides,
        rawServerSocketOverrides =
            rawServerSocketOverrides ?? parent?.rawServerSocketOverrides,
        rawSecureSocketOverrides =
            rawSecureSocketOverrides ?? parent?.rawSecureSocketOverrides,
        rawSecureServerSocketOverrides = rawSecureServerSocketOverrides ??
            parent?.rawSecureServerSocketOverrides;

  void enable() {
    HttpOverrides.global = httpOverrides;
    IOOverrides.global = ioOverrides;
    IODriver.zoneLocal.defaultValue = this;
  }
}

/// Implements static members of [NetworkInterface].
abstract class NetworkInterfaceOverrides {
  /// Returns the driver used by the current zone.
  static NetworkInterfaceOverrides get current {
    return IODriver.current.networkInterfaceOverrides;
  }

  Future<List<NetworkInterface>> list({
    bool includeLoopback = false,
    bool includeLinkLocal = false,
    InternetAddressType type = InternetAddressType.any,
  });
}

/// Implements static members of [Platform].
class PlatformOverrides {
  static PlatformOverrides get current => IODriver.current.platformOverrides;

  final int numberOfProcessors;
  final String pathSeparator;
  final String localeName;
  final String operatingSystem;
  final String operatingSystemVersion;
  final String localHostname;
  final Map<String, String> environment;
  final String executable;
  final String resolvedExecutable;
  final Uri script;
  final List<String> executableArguments;
  final String packageRoot;
  final String packageConfig;
  final String version;
  final Stdin stdin;
  final Stdout stdout;
  final Stdout stderr;

  PlatformOverrides({
    this.numberOfProcessors = 1,
    this.pathSeparator = "/",
    this.localeName = "en",
    this.operatingSystem = "",
    this.operatingSystemVersion = "",
    this.localHostname = "",
    this.environment = const <String, String>{},
    this.executable = "",
    this.resolvedExecutable = "",
    this.script,
    this.executableArguments = const <String>[],
    this.packageRoot = "",
    this.packageConfig = "",
    this.version = "2.0.0",
    this.stdin,
    this.stdout,
    this.stderr,
  });
}

/// Implements static members of [Process].
abstract class ProcessOverrides {
  ProcessOverrides();

  /// For [Process.run].
  Future<ProcessResult> run(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding}) async {
    final process = await start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
    );
    final exitCode = await process.exitCode;
    var stdout;
    if (stdoutEncoding == null) {
      final buffer = BytesBuilder();
      process.stdout.listen((data) {
        buffer.add(data);
      });
      stdout = buffer.toBytes();
    } else {
      stdout = await stdoutEncoding.decodeStream(process.stdout);
    }
    var stderr;
    if (stderrEncoding == null) {
      final buffer = BytesBuilder();
      process.stderr.listen((data) {
        buffer.add(data);
      });
      stderr = buffer.toBytes();
    } else {
      stderr = await stderrEncoding.decodeStream(process.stderr);
    }
    return ProcessResult(process.pid, exitCode, stdout, stderr);
  }

  /// For [Process.runSync].
  ProcessResult runSync(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding}) {
    throw UnsupportedError(
      "Sync 'dart:io' APIs are not supported in the browser.",
    );
  }

  /// For [Process.start].
  Future<Process> start(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      ProcessStartMode mode = ProcessStartMode.normal});
}

/// Implements static members of [RawDatagramSocket].
abstract class RawDatagramSocketOverrides {
  /// For [RawDatagramSocket.bind].
  Future<RawDatagramSocket> bind(
    host,
    int port, {
    bool reuseAddress = true,
    bool reusePort = false,
    int ttl = 1,
  });
}

class RawSecureServerSocketOverrides {
  /// Used by [RawSecureServerSocket].
  ///
  /// Default implementation returns a class that uses [RawServerSocket] and
  /// [RawSecureSocket.secureServer].
  Future<RawSecureServerSocket> bind(
    address,
    int port,
    SecurityContext context, {
    int backlog = 0,
    bool v6Only = false,
    bool requestClientCertificate = false,
    bool requireClientCertificate = false,
    List<String> supportedProtocols,
    bool shared = false,
  }) async {
    final socket = await RawServerSocket.bind(
      address,
      port,
      backlog: backlog,
      v6Only: v6Only,
    );
    return _RawSecureServerSocket(
      socket,
      context,
      requestClientCertificate: requestClientCertificate,
      requireClientCertificate: requireClientCertificate,
      supportedProtocols: supportedProtocols,
    );
  }
}

/// Implements static members of [RawSecureSocket].
abstract class RawSecureSocketOverrides {
  SecurityContext get defaultSecurityContext => _BrowserSecurityContext();

  /// For [RawSecureSocket.connect].
  Future<RawSecureSocket> connect(
    host,
    int port, {
    SecurityContext context,
    bool onBadCertificate(X509Certificate certificate),
    List<String> supportedProtocols,
    Duration timeout,
  }) async {
    final connectionTask = await startConnect(
      host,
      port,
      context: context,
      onBadCertificate: onBadCertificate,
      supportedProtocols: supportedProtocols,
    );
    if (timeout == null) {
      return connectionTask.socket;
    }
    return connectionTask.socket.timeout(timeout, onTimeout: () {
      connectionTask.cancel();
      throw TimeoutException("RawSecureSocket.connect(...) timeout");
    });
  }

  /// Used by [SecurityContext].
  ///
  /// Default implementation returns a [SecurityContext] that will throw
  /// if used.
  SecurityContext newSecurityContext({bool withTrustedRoots = false}) {
    return _BrowserSecurityContext();
  }

  /// For [RawSecureSocket.secure].
  Future<RawSecureSocket> secure(
    RawSocket socket, {
    StreamSubscription<RawSocketEvent> subscription,
    host,
    SecurityContext context,
    bool onBadCertificate(X509Certificate certificate),
    List<String> supportedProtocols,
  });

  /// For [RawSecureSocket.secureServer].
  Future<RawSecureSocket> secureServer(
    RawSocket socket,
    SecurityContext context, {
    StreamSubscription<RawSocketEvent> subscription,
    List<int> bufferedData,
    bool requestClientCertificate = false,
    bool requireClientCertificate = false,
    List<String> supportedProtocols,
  });

  /// For [RawSecureSocket.startConnect].
  Future<ConnectionTask<RawSecureSocket>> startConnect(
    host,
    int port, {
    SecurityContext context,
    bool onBadCertificate(X509Certificate certificate),
    List<String> supportedProtocols,
  }) async {
    final socketConnectionTask = await RawSocket.startConnect(host, port);
    final secureSocketFuture = socketConnectionTask.socket.then((rawSocket) {
      return secure(
        rawSocket,
        host: host,
        context: context,
        onBadCertificate: onBadCertificate,
        supportedProtocols: supportedProtocols,
      );
    });
    return _ConnectionTask(
      socket: secureSocketFuture,
      onCancel: () {
        socketConnectionTask.cancel();
      },
    );
  }
}

/// Implements static members of [RawServerSocket] and [ServerSocket].
abstract class RawServerSocketOverrides {
  /// For [RawServerSocket.bind].
  Future<RawServerSocket> bind(
    address,
    int port, {
    int backlog = 0,
    bool v6Only = false,
    bool shared = false,
  });
}

/// Implements static members of [RawSocket] and [Socket].
abstract class RawSocketOverrides {
  /// For [RawSocket.connect].
  Future<RawSocket> connect(
    host,
    int port, {
    sourceAddress,
    Duration timeout,
  }) async {
    final connectionTask = await startConnect(
      host,
      port,
      sourceAddress: sourceAddress,
    );
    if (timeout == null) {
      return connectionTask.socket;
    }
    return connectionTask.socket.timeout(timeout, onTimeout: () {
      connectionTask.cancel();
      throw TimeoutException("RawSocket.connect(...) timeout");
    });
  }

  /// For [RawSocket.startConnect].
  Future<ConnectionTask<RawSocket>> startConnect(
    host,
    int port, {
    sourceAddress,
  });
}

/// Implements [SecurityContext] that throws when any method is used.
class _BrowserSecurityContext implements SecurityContext {
  _BrowserSecurityContext();

  @override
  void setAlpnProtocols(List<String> protocols, bool isServer) {
    throw UnimplementedError();
  }

  @override
  void setClientAuthorities(String file, {String password}) {
    throw UnimplementedError();
  }

  @override
  void setClientAuthoritiesBytes(List<int> authCertBytes, {String password}) {
    throw UnimplementedError();
  }

  @override
  void setTrustedCertificates(String file, {String password}) {
    throw UnimplementedError();
  }

  @override
  void setTrustedCertificatesBytes(List<int> certBytes, {String password}) {
    throw UnimplementedError();
  }

  @override
  void useCertificateChain(String file, {String password}) {
    throw UnimplementedError();
  }

  @override
  void useCertificateChainBytes(List<int> chainBytes, {String password}) {
    throw UnimplementedError();
  }

  @override
  void usePrivateKey(String file, {String password}) {
    throw UnimplementedError();
  }

  @override
  void usePrivateKeyBytes(List<int> keyBytes, {String password}) {
    throw UnimplementedError();
  }
}

class _ConnectionTask<S> implements ConnectionTask<S> {
  @override
  final Future<S> socket;
  final void Function() _onCancel;

  _ConnectionTask(
      {@required Future<S> socket, @required void Function() onCancel})
      : assert(socket != null),
        assert(onCancel != null),
        this.socket = socket,
        this._onCancel = onCancel;

  @override
  void cancel() {
    _onCancel();
  }
}

/// Implements [RawSecureServerSocket] using [RawSecureSocket.secureServer].
class _RawSecureServerSocket extends Stream<RawSecureSocket>
    implements RawSecureServerSocket {
  final RawServerSocket _socket;
  final SecurityContext _context;

  @override
  final bool requestClientCertificate;

  @override
  final bool requireClientCertificate;

  @override
  final List<String> supportedProtocols;

  _RawSecureServerSocket(
    this._socket,
    this._context, {
    @required this.requestClientCertificate,
    @required this.requireClientCertificate,
    @required this.supportedProtocols,
  });

  @override
  InternetAddress get address => _socket.address;

  @override
  int get port => _socket.port;

  @override
  Future<RawSecureServerSocket> close() async {
    await _socket.close();
    return this;
  }

  @override
  StreamSubscription<RawSecureSocket> listen(
      void onData(RawSecureSocket socket),
      {Function onError,
      void onDone(),
      bool cancelOnError}) {
    return _socket.asyncMap((rawSocket) {
      return RawSecureSocket.secureServer(
        rawSocket,
        _context,
        requireClientCertificate: requireClientCertificate,
        requestClientCertificate: requestClientCertificate,
        supportedProtocols: supportedProtocols,
      );
    }).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
