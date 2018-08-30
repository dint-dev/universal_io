import 'dart:async';
import 'dart:convert';

import 'io.dart';

class IODriver {
  static IODriver current = new IODriver();

  final PlatformInfo platformInfo;

  IODriver({this.platformInfo: const PlatformInfo()});

  bool get isWatchSupported => false;

  Directory newDirectory(String path) => throw new UnimplementedError();

  File newFile(String path) => throw new UnimplementedError();

  FileSystemEntity newFileSystemEntity(String path) =>
      throw new UnimplementedError();

  Link newLink(String path) => throw new UnimplementedError();

  Future<ProcessResult> run(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment: true,
      bool runInShell: false,
      Encoding stdoutEncoding: systemEncoding,
      Encoding stderrEncoding: systemEncoding}) {
    throw new UnimplementedError();
  }

  ProcessResult runSync(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment: true,
      bool runInShell: false,
      Encoding stdoutEncoding: systemEncoding,
      Encoding stderrEncoding: systemEncoding}) {
    throw new UnimplementedError();
  }

  Future<Process> start(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment: true,
      bool runInShell: false,
      ProcessStartMode mode: ProcessStartMode.normal}) {
    throw new UnimplementedError();
  }

  Stdin get stdin => throw new UnimplementedError();

  Stdout get stdout => throw new UnimplementedError();

  Directory get systemTemp => throw new UnimplementedError();
}

class PlatformInfo {
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

  const PlatformInfo({
    this.numberOfProcessors: 1,
    this.pathSeparator: "/",
    this.localeName: "en",
    this.operatingSystem: "",
    this.operatingSystemVersion: "",
    this.localHostname: "",
    this.environment: const <String, String>{},
    this.executable: "",
    this.resolvedExecutable: "",
    this.script: null,
    this.executableArguments: const <String>[],
    this.packageRoot: "",
    this.packageConfig: "",
    this.version: "2.0.0",
  });
}
