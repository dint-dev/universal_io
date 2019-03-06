// MIT License
//
// Copyright (c) 2018 dart-universal_io authors.
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in all
// copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
// SOFTWARE.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../../util.dart';
import 'platform_info.dart';
export 'platform_info.dart';

class IODriver {
  static final ZoneLocal<IODriver> zoneLocal =
      ZoneLocal<IODriver>(defaultValue: IODriver());

  static IODriver get current {
    return zoneLocal.current;
  }

  final PlatformInfo platformInfo;

  IODriver({PlatformInfo platformInfo})
      : this.platformInfo = platformInfo ?? PlatformInfo.fromEnvironment();

  bool get isWatchSupported => throw UnimplementedError();

  Stdout get stderr {
    throw UnimplementedError();
  }

  Stdin get stdin {
    throw UnimplementedError();
  }

  Stdout get stdout {
    throw UnimplementedError();
  }

  Directory get systemTemp {
    throw UnimplementedError();
  }

  Future<RawDatagramSocket> bindRawDatagramSocket(host, int port,
      {bool reuseAddress = true, bool reusePort = false, int ttl = 1}) {
    throw UnimplementedError();
  }

  Future<RawServerSocket> bindRawServerSocket(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    throw UnimplementedError();
  }

  Future<ServerSocket> bindServerSocket(address, int port,
      {int backlog = 0, bool v6Only = false, bool shared = false}) {
    throw UnimplementedError();
  }

  Future<RawSocket> connectRawSocket(host, int port,
      {sourceAddress, Duration timeout}) {
    throw UnimplementedError();
  }

  Future<Socket> connectSocket(host, int port,
      {sourceAddress, Duration timeout}) {
    throw UnimplementedError();
  }

  Future<bool> isDirectory(String path) {
    throw UnimplementedError();
  }

  Future<bool> isFile(String path) {
    throw UnimplementedError();
  }

  Future<List<NetworkInterface>> listNetworkInterfaces(
      {bool includeLoopback = false,
      bool includeLinkLocal = false,
      InternetAddressType type = InternetAddressType.any}) {
    throw UnimplementedError();
  }

  Future<List<InternetAddress>> lookupInternetAddresses(String host,
      {InternetAddressType type = InternetAddressType.any}) {
    throw UnimplementedError();
  }

  Directory newDirectory(String path) {
    throw UnimplementedError();
  }

  File newFile(String path) {
    throw UnimplementedError();
  }

  FileSystemEntity newFileSystemEntity(String path) {
    throw UnimplementedError();
  }

  InternetAddress newInternetAddress(String value) {
    throw UnimplementedError();
  }

  Link newLink(String path) {
    throw UnimplementedError();
  }

  Future<InternetAddress> reverseLookupInternetAddress(
      InternetAddress address) {
    throw UnimplementedError();
  }

  Future<ProcessResult> run(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding}) {
    throw UnimplementedError();
  }

  ProcessResult runSync(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding}) {
    throw UnimplementedError();
  }

  Future<Process> start(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      ProcessStartMode mode = ProcessStartMode.normal}) {
    throw UnimplementedError();
  }

  Future<ConnectionTask<RawSocket>> startConnectRawSocket(host, int port,
      {sourceAddress}) {
    throw UnimplementedError();
  }

  Future<ConnectionTask<Socket>> startConnectSocket(host, int port,
      {sourceAddress}) {
    throw UnimplementedError();
  }
}
