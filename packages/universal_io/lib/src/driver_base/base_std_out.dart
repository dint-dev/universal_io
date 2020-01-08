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

import 'package:universal_io/driver_base.dart';
import 'package:universal_io/prefer_universal/io.dart';

class BaseStdout extends BaseIOSink implements Stdout {
  @override
  Encoding encoding = systemEncoding;

  @override
  Future get done {
    return Future.value(null);
  }

  @override
  bool get hasTerminal {
    return false;
  }

  @override
  IOSink get nonBlocking {
    return this;
  }

  @override
  bool get supportsAnsiEscapes {
    return false;
  }

  @override
  int get terminalColumns {
    throw StdoutException("Does not have terminal");
  }

  @override
  int get terminalLines {
    throw StdoutException("Does not have terminal");
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
  void write(Object obj) {
    add(utf8.encode(obj.toString()));
  }

  @override
  void writeAll(Iterable objects, [String separator = ""]) {
    for (var object in objects) {
      write(object);
    }
  }

  @override
  void writeCharCode(int charCode) {
    write(String.fromCharCode(charCode));
  }

  @override
  void writeln([Object obj = ""]) {
    write(obj);
    write("\n");
  }
}
