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

class BrowserDirectory extends BrowserFileSystemEntity implements Directory {
  BrowserDirectory(String path) : super(path);

  @override
  Directory get absolute {
    throw UnimplementedError();
  }

  @override
  Future<Directory> create({bool recursive = false}) {
    throw BrowserFileSystemEntity._writingNotAllowedException(path);
  }

  @override
  void createSync({bool recursive = false}) {
    throw UnimplementedError();
  }

  @override
  Future<Directory> createTemp([String prefix]) {
    throw UnimplementedError();
  }

  @override
  Directory createTempSync([String prefix]) {
    throw UnimplementedError();
  }

  @override
  Stream<FileSystemEntity> list(
      {bool recursive = false, bool followLinks = true}) {
    throw BrowserFileSystemEntity._notFoundException(path);
  }

  @override
  List<FileSystemEntity> listSync(
      {bool recursive = false, bool followLinks = true}) {
    throw UnimplementedError();
  }

  @override
  Directory renameSync(String newPath) {
    throw UnimplementedError();
  }

  @override
  String resolveSymbolicLinksSync() {
    throw UnimplementedError();
  }
}

class BrowserFile extends BrowserFileSystemEntity implements File {
  BrowserFile(String path) : super(path);

  @override
  Future<File> copy(String newPath) {
    throw BrowserFileSystemEntity._notFoundException(path);
  }

  @override
  Future<int> length() {
    throw BrowserFileSystemEntity._notFoundException(path);
  }

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) {
    throw BrowserFileSystemEntity._notFoundException(path);
  }

  @override
  Stream<List<int>> openRead([int start, int end]) {
    throw BrowserFileSystemEntity._notFoundException(path);
  }

  @override
  IOSink openWrite({FileMode mode = FileMode.write, Encoding encoding = utf8}) {
    throw BrowserFileSystemEntity._writingNotAllowedException(path);
  }

  @override
  Future<List<int>> readAsBytes() {
    throw BrowserFileSystemEntity._notFoundException(path);
  }

  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) {
    throw BrowserFileSystemEntity._notFoundException(path);
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) {
    throw BrowserFileSystemEntity._notFoundException(path);
  }

  @override
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) {
    throw BrowserFileSystemEntity._writingNotAllowedException(path);
  }

  @override
  Future<File> writeAsString(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false}) {
    throw BrowserFileSystemEntity._writingNotAllowedException(path);
  }
}

class BrowserFileSystemEntity implements FileSystemEntity {
  @override
  final String path;

  BrowserFileSystemEntity(String path) : this.path = _trimRightSlash(path);

  @override
  FileSystemEntity get absolute {
    throw UnimplementedError();
  }

  @override
  Directory get parent {
    final i = path.lastIndexOf("/");
    if (i < 0) {
      return null;
    }
    return Directory(path.substring(0, i));
  }

  @override
  Uri get uri {
    return Uri.parse(path);
  }

  @override
  Future<FileSystemEntity> delete({bool recursive = false}) async {
    throw BrowserFileSystemEntity._notFoundException(path);
  }

  @override
  void deleteSync({bool recursive = false}) {
    throw UnimplementedError();
  }

  @override
  Future<bool> exists() async {
    return false;
  }

  @override
  bool existsSync() {
    throw UnimplementedError();
  }

  @override
  Future<FileSystemEntity> rename(String newPath) async {
    throw BrowserFileSystemEntity._notFoundException(path);
  }

  @override
  FileSystemEntity renameSync(String newPath) {
    throw UnimplementedError();
  }

  @override
  Future<String> resolveSymbolicLinks() async {
    throw BrowserFileSystemEntity._notFoundException(path);
  }

  @override
  String resolveSymbolicLinksSync() {
    throw UnimplementedError();
  }

  @override
  Future<FileStat> stat() async {
    throw BrowserFileSystemEntity._notFoundException(path);
  }

  @override
  FileStat statSync() {
    throw UnimplementedError();
  }

  @override
  Stream<FileSystemEvent> watch(
      {int events = FileSystemEvent.all, bool recursive = false}) {
    throw BrowserFileSystemEntity._notFoundException(path);
  }

  static FileSystemException _notFoundException(String path) {
    return FileSystemException(
        "file not found", path, OSError("file not found"));
  }

  static String _trimRightSlash(String s) {
    while (s.endsWith("/") && s.length > 1) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  static FileSystemException _writingNotAllowedException(String path) {
    return FileSystemException(
        "writing is not allowed", path, OSError("writing is not allowed"));
  }
}
