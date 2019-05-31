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
import 'dart:convert';

import 'package:universal_io/src/driver/drivers_in_js.dart';

import '../io.dart';

abstract class Directory extends FileSystemEntity {
  static Directory get systemTemp => FileSystemDriver.current.systemTemp;

  factory Directory(String path) {
    return FileSystemDriver.current.newDirectory(path);
  }

  Directory get absolute;

  Future<Directory> create({bool recursive = false});

  void createSync({bool recursive = false});

  Future<Directory> createTemp([String prefix]);

  Directory createTempSync([String prefix]);

  Stream<FileSystemEntity> list(
      {bool recursive = false, bool followLinks = true});

  List<FileSystemEntity> listSync(
      {bool recursive = false, bool followLinks = true});

  Directory renameSync(String newPath);

  String resolveSymbolicLinksSync();
}

abstract class File extends FileSystemEntity {
  factory File(String path) {
    return FileSystemDriver.current.newFile(path);
  }

  Future<File> copy(String newPath);

  Future<int> length();

  Future<RandomAccessFile> open({FileMode mode = FileMode.read});

  Stream<List<int>> openRead([int start, int end]);

  IOSink openWrite({FileMode mode = FileMode.write, Encoding encoding = utf8});

  Future<List<int>> readAsBytes();

  Future<List<String>> readAsLines({Encoding encoding = utf8});

  Future<String> readAsString({Encoding encoding = utf8});

  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false});

  Future<File> writeAsString(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false});
}

enum FileLock {
  shared,
  exclusive,
  blockingShared,
  blockingExclusive,
}

enum FileMode {
  append,
  read,
  write,
  writeOnly,
  writeOnlyAppend,
}

class FileStat {
  final DateTime accessed;
  final DateTime changed;
  final int mode;
  final DateTime modified;
  final int size;
  final FileSystemEntityType type;

  FileStat._(
      {this.accessed,
      this.changed,
      this.mode,
      this.modified,
      this.size,
      this.type});

  String modeString() => throw UnimplementedError();

  Future<FileStat> stat(String path) {
    return FileSystemEntity(path).stat();
  }
}

class FileSystemCreateEvent extends FileSystemEvent {
  FileSystemCreateEvent() : super._();

  int get type => FileSystemEvent.create;
}

class FileSystemDeleteEvent extends FileSystemEvent {
  FileSystemDeleteEvent() : super._();

  int get type => FileSystemEvent.delete;
}

abstract class FileSystemEntity {
  static bool get isWatchSupported => FileSystemDriver.current.isWatchSupported;

  factory FileSystemEntity(String path) {
    return FileSystemDriver.current.newFileSystemEntity(path);
  }

  FileSystemEntity get absolute;

  Directory get parent => Directory(parentOf(path));

  String get path;

  Uri get uri => Uri.file(path);

  Future<FileSystemEntity> delete({bool recursive = false});

  void deleteSync({bool recursive = false});

  Future<bool> exists();

  bool existsSync();

  Future<FileSystemEntity> rename(String newPath);

  FileSystemEntity renameSync(String newPath);

  Future<String> resolveSymbolicLinks();

  String resolveSymbolicLinksSync();

  Future<FileStat> stat();

  FileStat statSync();

  Stream<FileSystemEvent> watch(
      {int events = FileSystemEvent.all, bool recursive = false});

  static Future<bool> isDirectory(String path) {
    return FileSystemDriver.current.isDirectory(path);
  }

  static Future<bool> isFile(String path) {
    return FileSystemDriver.current.isFile(path);
  }

  static String parentOf(String path) {
    final i = path.lastIndexOf(Platform.pathSeparator);
    if (i < 0) {
      return null;
    }
    return path.substring(0, i);
  }
}

enum FileSystemEntityType {
  directory,
  file,
  link,
  notFound,
}

abstract class FileSystemEvent {
  static const int create = 1 << 0;
  static const int modify = 1 << 1;
  static const int delete = 1 << 2;
  static const int move = 1 << 3;
  static const int all = create | modify | delete | move;

  final bool isDirectory;
  final String path;
  final int type;

  FileSystemEvent._({this.isDirectory, this.path, this.type});
}

class FileSystemException extends IOException {
  final String message;
  final String path;
  final OSError osError;
  FileSystemException([this.message = "", this.path = "", this.osError]);
  @override
  String toString() => "FileSystemException('$message', '$path')";
}

class FileSystemModifyEvent extends FileSystemEvent {
  FileSystemModifyEvent() : super._();

  int get type => FileSystemEvent.modify;
}

class FileSystemMoveEvent extends FileSystemEvent {
  FileSystemMoveEvent() : super._();

  int get type => FileSystemEvent.move;
}

abstract class Link extends FileSystemEntity {
  factory Link(String path) {
    return FileSystemDriver.current.newLink(path);
  }
}

abstract class RandomAccessFile {
  Future<void> close();

  Future<RandomAccessFile> flush(int length);

  Future<RandomAccessFile> lock(
      [FileLock mode = FileLock.exclusive, int start = 0, int end = -1]);

  Future<int> position();

  Future<List<int>> read(int bytes);

  Future<int> readByte();

  Future<RandomAccessFile> setPosition(int position);

  Future<RandomAccessFile> truncate(int length);

  Future<RandomAccessFile> unlock([int start = 0, int end = -1]);

  Future<RandomAccessFile> writeByte(int byte);

  Future<RandomAccessFile> writeFrom(List<int> buffer,
      [int start = 0, int end]);

  Future<RandomAccessFile> writeString(String string,
      {Encoding encoding = utf8});
}
