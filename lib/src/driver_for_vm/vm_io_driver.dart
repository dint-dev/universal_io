import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:io' as dart_io;
import 'dart:typed_data';

import 'package:universal_io/src/driver/drivers_in_vm.dart';

// -----------------------------------------------------------------------------
// This file is used lib/src/driver/customization_in_vm.dart
// -----------------------------------------------------------------------------

const vmIODriver = IODriver.requireAll(
  fileSystemDriver: VMFileSystemDriver(),
  internetAddressDriver: VMInternetAddressDriver(),
  httpClientDriver: VMHttpClientDriver(),
  httpServerDriver: VMHttpServerDriver(),
  networkInterfaceDriver: VMNetworkInterfaceDriver(),
  platformDriver: VMPlatformDriver(),
  processDriver: VMProcessDriver(),
  rawDatagramSocketDriver: VMRawDatagramSocketDriver(),
  rawSocketDriver: VMRawSocketDriver(),
  rawServerSocketDriver: VMRawServerSocketDriver(),
  rawSecureSocketDriver: VMRawSecureSocketDriver(),
  rawSecureServerSocketDriver: VMRawSecureServerSocketDriver(),
);

class VMFileSystemDriver implements FileSystemDriver {
  const VMFileSystemDriver();

  @override
  Directory get currentDirectory {
    return Directory.current;
  }

  @override
  set currentDirectory(Directory value) {
    Directory.current = value;
  }

  @override
  bool get isWatchSupported => FileSystemEntity.isWatchSupported;

  @override
  Directory get systemTempDirectory {
    return Directory.systemTemp;
  }

  @override
  Future<bool> identicalPaths(String path0, String path1) {
    return FileSystemEntity.identical(path0, path1);
  }

  @override
  bool identicalPathsSync(String path0, String path1) {
    return FileSystemEntity.identicalSync(path0, path1);
  }

  @override
  Future<bool> isDirectory(String path) {
    return FileSystemEntity.isDirectory(path);
  }

  @override
  bool isDirectorySync(String path) {
    return FileSystemEntity.isDirectorySync(path);
  }

  @override
  Future<bool> isFile(String path) {
    return FileSystemEntity.isFile(path);
  }

  @override
  bool isFileSync(String path) {
    return FileSystemEntity.isFileSync(path);
  }

  @override
  Future<bool> isLink(String path) {
    return FileSystemEntity.isLink(path);
  }

  @override
  bool isLinkSync(String path) {
    return FileSystemEntity.isLinkSync(path);
  }

  @override
  Directory newDirectory(String path) {
    return Directory(path);
  }

  @override
  Directory newDirectoryFromRawPath(Uint8List rawPath) {
    return Directory.fromRawPath(rawPath);
  }

  @override
  File newFile(String path) {
    return File(path);
  }

  @override
  File newFileFromRawPath(Uint8List rawPath) {
    return File.fromRawPath(rawPath);
  }

  @override
  Link newLink(String path) {
    return Link(path);
  }

  @override
  Link newLinkFromRawPath(Uint8List rawPath) {
    return Link.fromRawPath(rawPath);
  }

  @override
  Future<FileStat> stat(String path) {
    return FileStat.stat(path);
  }

  @override
  FileStat statSync(String path) {
    return FileStat.statSync(path);
  }

  @override
  Future<FileSystemEntityType> type(String path, {bool followLinks}) {
    return FileSystemEntity.type(path, followLinks: followLinks);
  }

  @override
  FileSystemEntityType typeSync(String path, {bool followLinks}) {
    return FileSystemEntity.typeSync(path, followLinks: followLinks);
  }

  @override
  Stream<FileSystemEvent> watch(String path,
      {int events = FileSystemEvent.all, bool recursive = false}) async* {
    switch (await FileSystemEntity.type(path)) {
      case FileSystemEntityType.directory:
        yield* (File(path).watch(events: events, recursive: recursive));
        break;
      case FileSystemEntityType.link:
        yield* (File(path).watch(events: events, recursive: recursive));
        break;
      default:
        yield* (File(path).watch(events: events, recursive: recursive));
    }
  }
}

class VMHttpClientDriver implements HttpClientDriver {
  const VMHttpClientDriver();

  @override
  HttpClient newHttpClient({SecurityContext context}) {
    return HttpClient(context: context);
  }
}

class VMHttpServerDriver implements HttpServerDriver {
  const VMHttpServerDriver();

  @override
  Future<HttpServer> bindHttpServer(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    return HttpServer.bind(
      address,
      port,
      backlog: backlog,
      v6Only: v6Only,
      shared: shared,
    );
  }
}

class VMInternetAddressDriver implements InternetAddressDriver {
  const VMInternetAddressDriver();

  @override
  Future<List<InternetAddress>> lookup(String host,
      {InternetAddressType type = InternetAddressType.any}) {
    return InternetAddress.lookup(host, type: type);
  }

  @override
  Future<InternetAddress> reverseLookup(InternetAddress address) {
    return address.reverse();
  }
}

class VMNetworkInterfaceDriver extends NetworkInterfaceDriver {
  const VMNetworkInterfaceDriver();

  @override
  Future<List<NetworkInterface>> listNetworkInterfaces(
      {bool includeLoopback = false,
      bool includeLinkLocal = false,
      InternetAddressType type = InternetAddressType.any}) {
    return NetworkInterface.list(
      includeLoopback: includeLoopback,
      includeLinkLocal: includeLinkLocal,
      type: type,
    );
  }
}

class VMPlatformDriver implements PlatformDriver {
  const VMPlatformDriver();

  @override
  Map<String, String> get environment => Platform.environment;

  @override
  String get executable => Platform.executable;

  @override
  List<String> get executableArguments => Platform.executableArguments;

  @override
  String get localeName => Platform.localeName;

  @override
  String get localHostname => Platform.localHostname;

  @override
  int get numberOfProcessors => Platform.numberOfProcessors;

  @override
  String get operatingSystem => Platform.operatingSystem;

  @override
  String get operatingSystemVersion => Platform.operatingSystemVersion;

  @override
  String get packageConfig => Platform.packageConfig;

  @override
  String get packageRoot => null;

  @override
  String get pathSeparator => Platform.pathSeparator;

  @override
  String get resolvedExecutable =>
      Platform.resolvedExecutable; // API was removed in Dart 2.

  @override
  Uri get script => Platform.script;

  @override
  Stdout get stderr => dart_io.stderr;

  @override
  Stdin get stdin => dart_io.stdin;

  @override
  Stdout get stdout => dart_io.stdout;

  @override
  String get version => Platform.version;
}

class VMProcessDriver implements ProcessDriver {
  const VMProcessDriver();

  @override
  Future<ProcessResult> run(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding}) {
    return Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stderrEncoding: stderrEncoding,
      stdoutEncoding: stderrEncoding,
    );
  }

  @override
  ProcessResult runSync(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding}) {
    return Process.runSync(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stderrEncoding: stderrEncoding,
      stdoutEncoding: stderrEncoding,
    );
  }

  @override
  Future<Process> start(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      ProcessStartMode mode = ProcessStartMode.normal}) {
    return Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      mode: mode,
    );
  }
}

class VMRawDatagramSocketDriver implements RawDatagramSocketDriver {
  const VMRawDatagramSocketDriver();

  @override
  Future<RawDatagramSocket> bind(host, int port,
      {bool reuseAddress = true, bool reusePort = false, int ttl = 1}) {
    return RawDatagramSocket.bind(
      host,
      port,
      reuseAddress: reuseAddress,
      reusePort: reusePort,
      ttl: ttl,
    );
  }
}

class VMRawSecureServerSocketDriver extends RawSecureServerSocketDriver {
  const VMRawSecureServerSocketDriver();

  @override
  Future<RawSecureServerSocket> bind(address, int port, SecurityContext context,
      {int backlog = 0,
      bool v6Only = false,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false,
      List<String> supportedProtocols,
      bool shared = false}) {
    return RawSecureServerSocket.bind(
      address,
      port,
      context,
      backlog: backlog,
      v6Only: v6Only,
      requestClientCertificate: requestClientCertificate,
      requireClientCertificate: requireClientCertificate,
    );
  }
}

class VMRawSecureSocketDriver extends RawSecureSocketDriver {
  const VMRawSecureSocketDriver();

  @override
  Future<RawSecureSocket> connect(host, int port,
      {SecurityContext context,
      bool onBadCertificate(X509Certificate certificate),
      List<String> supportedProtocols,
      Duration timeout}) {
    return RawSecureSocket.connect(
      host,
      port,
      context: context,
      onBadCertificate: onBadCertificate,
      supportedProtocols: supportedProtocols,
      timeout: timeout,
    );
  }

  @override
  Future<RawSecureSocket> secure(RawSocket socket,
      {StreamSubscription<RawSocketEvent> subscription,
      host,
      SecurityContext context,
      bool onBadCertificate(X509Certificate certificate),
      List<String> supportedProtocols}) {
    return RawSecureSocket.secure(
      socket,
      subscription: subscription,
      host: host,
      context: context,
      onBadCertificate: onBadCertificate,
      supportedProtocols: supportedProtocols,
    );
  }

  @override
  Future<RawSecureSocket> secureServer(
      RawSocket socket, SecurityContext context,
      {StreamSubscription<RawSocketEvent> subscription,
      List<int> bufferedData,
      bool requestClientCertificate = false,
      bool requireClientCertificate = false,
      List<String> supportedProtocols}) {
    return RawSecureSocket.secureServer(socket, context);
  }

  @override
  Future<ConnectionTask<RawSecureSocket>> startConnect(host, int port,
      {SecurityContext context,
      bool onBadCertificate(X509Certificate certificate),
      List<String> supportedProtocols}) {
    return RawSecureSocket.startConnect(
      host,
      port,
      context: context,
      onBadCertificate: onBadCertificate,
      supportedProtocols: supportedProtocols,
    );
  }
}

class VMRawServerSocketDriver implements RawServerSocketDriver {
  const VMRawServerSocketDriver();

  @override
  Future<RawServerSocket> bind(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    return RawServerSocket.bind(
      address,
      port,
      backlog: backlog,
      v6Only: v6Only,
      shared: shared,
    );
  }
}

class VMRawSocketDriver implements RawSocketDriver {
  const VMRawSocketDriver();

  @override
  Future<RawSocket> connect(host, int port, {sourceAddress, Duration timeout}) {
    return RawSocket.connect(
      host,
      port,
      sourceAddress: sourceAddress,
      timeout: timeout,
    );
  }

  @override
  Future<ConnectionTask<RawSocket>> startConnect(host, int port,
      {sourceAddress}) {
    return RawSocket.startConnect(
      host,
      port,
      sourceAddress: sourceAddress,
    );
  }
}
