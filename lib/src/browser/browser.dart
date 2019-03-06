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

import 'api/all.dart';
import 'common.dart';
import 'files.dart';

export 'chrome.dart' show ChromeIODriver;

class BrowserIODriver extends IODriver {
  @override
  final Stdout stderr = BrowserStdout();

  @override
  final Stdout stdout = BrowserStdout();

  BrowserIODriver({PlatformInfo platformInfo = const PlatformInfo()})
      : super(platformInfo: platformInfo);

  bool get isWatchSupported => false;

  @override
  Future<List<NetworkInterface>> listNetworkInterfaces(
      {bool includeLoopback = false,
      bool includeLinkLocal = false,
      InternetAddressType type = InternetAddressType.any}) async {
    return <NetworkInterface>[];
  }

  @override
  Future<List<InternetAddress>> lookupInternetAddresses(String host,
      {InternetAddressType type = InternetAddressType.any}) {
    throw UnimplementedError();
  }

  @override
  Directory newDirectory(String path) {
    return BrowserDirectory(path);
  }

  @override
  File newFile(String path) {
    return BrowserFile(path);
  }

  @override
  FileSystemEntity newFileSystemEntity(String path) {
    return BrowserFileSystemEntity(path);
  }

  @override
  Future<InternetAddress> reverseLookupInternetAddress(
      InternetAddress address) {
    throw UnimplementedError();
  }
}

class BrowserStdout extends Stdout {
  @override
  Encoding encoding = systemEncoding;

  @override
  Future get done {
    return Future.value(null);
  }

  @override
  IOSink get nonBlocking {
    return this;
  }

  @override
  void add(List<int> data) {}

  @override
  void addError(error, [StackTrace stackTrace]) {}

  @override
  Future addStream(Stream<List<int>> stream) {
    return stream.listen((data) {
      add(data);
    }).asFuture();
  }

  @override
  Future close() {
    return Future.value(null);
  }

  @override
  Future flush() {
    return Future.value(null);
  }

  @override
  void write(Object obj) {}

  @override
  void writeAll(Iterable objects, [String separator = ""]) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  void writeln([Object obj = ""]) {
    print(obj);
  }
}
