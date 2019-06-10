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
import 'dart:convert';
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:universal_io/src/io/io.dart';
import 'package:zone_local/zone_local.dart';

import 'customization_in_js.dart';

export 'customization_in_js.dart';

// ----------
// IMPORTANT:
//
// Almost identical copy of this file exists in:
//   * 'drivers_in_js.dart'
//   * 'drivers_in_vm.dart'
//
// Please copy-paste changes to both files!
//
// The purpose is to make everything available in the VM. We would run into
// conflicts with 'dart:io' without two files.
//
// Only imports are different.
// --

/// Implements static members of [FileSystemEntity], [File], [Directory],
/// [Link], and [FileStat] as well as some instance members.
///
/// TODO: Refactor?
abstract class FileSystemDriver {
  static FileSystemDriver get current => IODriver.current.fileSystemDriver;

  const FileSystemDriver();

  /// For [Directory.current].
  Directory get currentDirectory;

  /// For [Directory.current].
  set currentDirectory(Directory directory);

  bool get isWatchSupported;

  /// For [Directory.systemTemp].
  Directory get systemTempDirectory;

  Future<bool> identicalPaths(String path0, String path1);

  bool identicalPathsSync(String path0, String path1);

  /// For [FileSystemEntity.isDirectory].
  Future<bool> isDirectory(String path);

  /// For [FileSystemEntity.isDirectorySync].
  bool isDirectorySync(String path);

  /// For [FileSystemEntity.isFile].
  Future<bool> isFile(String path);

  /// For [FileSystemEntity.isFileSync].
  bool isFileSync(String path);

  /// For [FileSystemEntity.isLink].
  Future<bool> isLink(String path);

  /// For [FileSystemEntity.isLinkSync].
  bool isLinkSync(String path);

  /// For [Directory].
  Directory newDirectory(String path);

  /// For [Directory.fromRawPath].
  Directory newDirectoryFromRawPath(Uint8List rawPath);

  /// For [File].
  File newFile(String path);

  /// For [File.fromRawPath].
  File newFileFromRawPath(Uint8List rawPath);

  /// For [Link].
  Link newLink(String path);

  Link newLinkFromRawPath(Uint8List rawPath);

  /// For [FileStat.stat].
  Future<FileStat> stat(String path);

  /// For [FileStat.statSync].
  FileStat statSync(String path);

  /// For [FileSystemEntity.type].
  Future<FileSystemEntityType> type(String path, {bool followLinks});

  /// For [FileSystemEntity.typeSync].
  FileSystemEntityType typeSync(String path, {bool followLinks});

  /// For [FileSystemEntity.watch].
  Stream<FileSystemEvent> watch(String path,
      {int events = FileSystemEvent.all, bool recursive = false});
}

/// Implements static members of [HttpClient].
abstract class HttpClientDriver {
  static HttpClientDriver get current => IODriver.current.httpClientDriver;

  const HttpClientDriver();

  HttpClient newHttpClient({SecurityContext context});
}

/// Implements static members of [HttpServer].
abstract class HttpServerDriver {
  const HttpServerDriver();

  Future<HttpServer> bindHttpServer(
    address,
    int port, {
    int backlog = 0,
    bool v6Only = false,
    bool shared = false,
  });
}

/// Implements:
///   * [InternetAddress.lookup]
///   * [InternetAddress.reverse]
abstract class InternetAddressDriver {
  const InternetAddressDriver();

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
    // ignore: unnecessary_cast
    defaultValue: defaultIODriver as IODriver,
  );

  /// Returns the driver used by the current zone.
  static IODriver get current {
    return zoneLocal.value;
  }

  final FileSystemDriver fileSystemDriver;
  final HttpClientDriver httpClientDriver;
  final HttpServerDriver httpServerDriver;
  final InternetAddressDriver internetAddressDriver;
  final PlatformDriver platformDriver;
  final ProcessDriver processDriver;
  final RawDatagramSocketDriver rawDatagramSocketDriver;
  final RawSocketDriver rawSocketDriver;
  final RawServerSocketDriver rawServerSocketDriver;
  final RawSecureSocketDriver rawSecureSocketDriver;
  final RawSecureServerSocketDriver rawSecureServerSocketDriver;
  final NetworkInterfaceDriver networkInterfaceDriver;

  /// Constructs a new driver.
  const IODriver({
    this.fileSystemDriver,
    this.httpClientDriver,
    this.httpServerDriver,
    this.internetAddressDriver,
    this.platformDriver,
    this.processDriver,
    this.networkInterfaceDriver,
    this.rawDatagramSocketDriver,
    this.rawSocketDriver,
    this.rawServerSocketDriver,
    this.rawSecureSocketDriver,
    this.rawSecureServerSocketDriver,
  });

  /// Like the default constructor, but all parameters have been annotated with
  /// @required.
  const IODriver.requireAll({
    @required this.fileSystemDriver,
    @required this.httpClientDriver,
    @required this.httpServerDriver,
    @required this.internetAddressDriver,
    @required this.platformDriver,
    @required this.processDriver,
    @required this.networkInterfaceDriver,
    @required this.rawDatagramSocketDriver,
    @required this.rawSocketDriver,
    @required this.rawServerSocketDriver,
    @required this.rawSecureSocketDriver,
    @required this.rawSecureServerSocketDriver,
  });

  void enable() {
    IODriver.zoneLocal.freezeDefaultValue(this);
  }

  /// Returns a new instance where null fields have been replaced with values
  /// from the argument.
  IODriver withMissingFeaturesFrom(IODriver driver) {
    return IODriver.requireAll(
      fileSystemDriver: fileSystemDriver ?? driver.fileSystemDriver,
      httpClientDriver: httpClientDriver ?? driver.httpClientDriver,
      httpServerDriver: httpServerDriver ?? driver.httpServerDriver,
      internetAddressDriver:
          internetAddressDriver ?? driver.internetAddressDriver,
      platformDriver: platformDriver ?? driver.platformDriver,
      processDriver: processDriver ?? driver.processDriver,
      networkInterfaceDriver:
          networkInterfaceDriver ?? driver.networkInterfaceDriver,
      rawDatagramSocketDriver:
          rawDatagramSocketDriver ?? driver.rawDatagramSocketDriver,
      rawSocketDriver: rawSocketDriver ?? driver.rawSocketDriver,
      rawServerSocketDriver:
          rawServerSocketDriver ?? driver.rawServerSocketDriver,
      rawSecureSocketDriver:
          rawSecureSocketDriver ?? driver.rawSecureSocketDriver,
      rawSecureServerSocketDriver:
          rawSecureServerSocketDriver ?? driver.rawSecureServerSocketDriver,
    );
  }
}

/// Implements static members of [NetworkInterface].
abstract class NetworkInterfaceDriver {
  const NetworkInterfaceDriver();

  Future<List<NetworkInterface>> listNetworkInterfaces({
    bool includeLoopback = false,
    bool includeLinkLocal = false,
    InternetAddressType type = InternetAddressType.any,
  });
}

/// Implements static members of [Platform].
class PlatformDriver {
  static PlatformDriver get current => IODriver.current.platformDriver;

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

  const PlatformDriver({
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
abstract class ProcessDriver {
  static ProcessDriver get current => IODriver.current.processDriver;

  const ProcessDriver();

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
abstract class RawDatagramSocketDriver {
  const RawDatagramSocketDriver();

  /// For [RawDatagramSocket.bind].
  Future<RawDatagramSocket> bind(
    host,
    int port, {
    bool reuseAddress = true,
    bool reusePort = false,
    int ttl = 1,
  });
}

/// Implements static members of [RawSecureServerSocket].
abstract class RawSecureServerSocketDriver {
  const RawSecureServerSocketDriver();

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
  });
}

/// Implements static members of [RawSecureSocket].
abstract class RawSecureSocketDriver {
  const RawSecureSocketDriver();

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
abstract class RawServerSocketDriver {
  const RawServerSocketDriver();

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
abstract class RawSocketDriver {
  const RawSocketDriver();

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

class _ConnectionTask<S> implements ConnectionTask<S> {
  @override
  final Future<S> socket;
  final void Function() _onCancel;

  _ConnectionTask({Future<S> socket, void Function() onCancel})
      : assert(socket != null),
        assert(onCancel != null),
        this.socket = socket,
        this._onCancel = onCancel;

  @override
  void cancel() {
    _onCancel();
  }
}
