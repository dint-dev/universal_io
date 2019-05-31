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
import 'dart:io';

import 'package:meta/meta.dart';
import 'package:zone_local/zone_local.dart';

import 'defaults_in_vm.dart';

export 'defaults_in_vm.dart';

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

abstract class FileSystemDriver {
  static FileSystemDriver get current => IODriver.current.fileSystemDriver;

  const FileSystemDriver();

  bool get isWatchSupported;

  Directory get systemTemp;

  Future<bool> isDirectory(String path);

  Future<bool> isFile(String path);

  Directory newDirectory(String path);

  File newFile(String path);

  FileSystemEntity newFileSystemEntity(String path);

  Link newLink(String path);
}

abstract class HttpClientDriver {
  static HttpClientDriver get current => IODriver.current.httpClientDriver;

  const HttpClientDriver();

  HttpClient newHttpClient({SecurityContext context});
}

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

abstract class InternetAddressDriver {
  const InternetAddressDriver();

  Future<List<InternetAddress>> lookupInternetAddress(
    String host, {
    InternetAddressType type = InternetAddressType.any,
  });

  Future<InternetAddress> reverseLookupInternetAddress(InternetAddress address);
}

/// A driver that implements 'dart:io' APIs.
abstract class IODriver {
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
  final SocketsDriver socketsDriver;

  const IODriver({
    @required this.fileSystemDriver,
    @required this.httpClientDriver,
    @required this.httpServerDriver,
    @required this.internetAddressDriver,
    @required this.platformDriver,
    @required this.processDriver,
    @required this.socketsDriver,
  });
}

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

abstract class ProcessDriver {
  static ProcessDriver get current => IODriver.current.processDriver;

  const ProcessDriver();

  Future<ProcessResult> run(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding});

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

  Future<Process> start(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      ProcessStartMode mode = ProcessStartMode.normal});
}

abstract class SocketsDriver {
  const SocketsDriver();

  Future<RawDatagramSocket> bindRawDatagramSocket(
    host,
    int port, {
    bool reuseAddress = true,
    bool reusePort = false,
    int ttl = 1,
  });

  Future<RawSecureServerSocket> bindRawSecureServerSocket(
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

  Future<RawServerSocket> bindRawServerSocket(
    address,
    int port, {
    int backlog = 0,
    bool v6Only = false,
    bool shared = false,
  });

  Future<RawSecureSocket> connectRawSecureSocket(
    host,
    int port, {
    SecurityContext context,
    bool onBadCertificate(X509Certificate certificate),
    List<String> supportedProtocols,
    Duration timeout,
  });

  Future<ConnectionTask<RawSecureSocket>> connectRawSecureSocketStart(
    host,
    int port, {
    SecurityContext context,
    bool onBadCertificate(X509Certificate certificate),
    List<String> supportedProtocols,
  });

  Future<RawSocket> connectRawSocket(
    host,
    int port, {
    sourceAddress,
    Duration timeout,
  });

  Future<ConnectionTask<RawSocket>> connectRawSocketStart(
    host,
    int port, {
    sourceAddress,
  });

  Future<List<NetworkInterface>> listNetworkInterfaces({
    bool includeLoopback = false,
    bool includeLinkLocal = false,
    InternetAddressType type = InternetAddressType.any,
  });

  Future<RawSecureSocket> newSecureRawSocket(
    RawSocket socket, {
    StreamSubscription<RawSocketEvent> subscription,
    host,
    SecurityContext context,
    bool onBadCertificate(X509Certificate certificate),
    List<String> supportedProtocols,
  });

  Future<RawSecureSocket> newSecureServerRawSocket(
    RawSocket socket,
    SecurityContext context, {
    StreamSubscription<RawSocketEvent> subscription,
    List<int> bufferedData,
    bool requestClientCertificate = false,
    bool requireClientCertificate = false,
    List<String> supportedProtocols,
  });
}
