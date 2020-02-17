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
import 'dart:typed_data';

import 'package:universal_io/prefer_universal/io.dart';

class BaseDirectory extends BaseFileSystemEntity implements Directory {
  BaseDirectory(String path) : super(path);

  @override
  Directory get absolute => super.absolute;

  @override
  Future<Directory> create({bool recursive = false}) {
    throw BaseFileSystemEntity._writingNotAllowedException(path);
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
    throw BaseFileSystemEntity._notFoundException(path);
  }

  @override
  List<FileSystemEntity> listSync(
      {bool recursive = false, bool followLinks = true}) {
    throw UnimplementedError();
  }

  @override
  Future<Directory> rename(String newPath) {
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

class BaseFile extends BaseFileSystemEntity implements File {
  BaseFile(String path) : super(path);

  @override
  BaseFile get absolute => super.absolute;

  @override
  Future<File> copy(String newPath) {
    throw BaseFileSystemEntity._notFoundException(path);
  }

  @override
  File copySync(String newPath) {
    throw UnimplementedError();
  }

  @override
  Future<File> create({bool recursive = false}) {
    throw UnimplementedError();
  }

  @override
  void createSync({bool recursive = false}) {
    throw UnimplementedError();
  }

  @override
  Future<DateTime> lastAccessed() {
    throw UnimplementedError();
  }

  @override
  DateTime lastAccessedSync() {
    throw UnimplementedError();
  }

  @override
  Future<DateTime> lastModified() {
    throw UnimplementedError();
  }

  @override
  DateTime lastModifiedSync() {
    throw UnimplementedError();
  }

  @override
  Future<int> length() {
    throw BaseFileSystemEntity._notFoundException(path);
  }

  @override
  int lengthSync() {
    throw UnimplementedError();
  }

  @override
  Future<RandomAccessFile> open({FileMode mode = FileMode.read}) {
    throw BaseFileSystemEntity._notFoundException(path);
  }

  @override
  Stream<Uint8List> openRead([int start, int end]) {
    throw BaseFileSystemEntity._notFoundException(path);
  }

  @override
  RandomAccessFile openSync({FileMode mode = FileMode.read}) {
    throw UnimplementedError();
  }

  @override
  IOSink openWrite({FileMode mode = FileMode.write, Encoding encoding = utf8}) {
    throw BaseFileSystemEntity._writingNotAllowedException(path);
  }

  @override
  Future<Uint8List> readAsBytes() {
    throw BaseFileSystemEntity._notFoundException(path);
  }

  @override
  Uint8List readAsBytesSync() {
    throw UnimplementedError();
  }

  @override
  Future<List<String>> readAsLines({Encoding encoding = utf8}) {
    throw BaseFileSystemEntity._notFoundException(path);
  }

  @override
  List<String> readAsLinesSync({Encoding encoding = utf8}) {
    throw UnimplementedError();
  }

  @override
  Future<String> readAsString({Encoding encoding = utf8}) {
    throw BaseFileSystemEntity._notFoundException(path);
  }

  @override
  String readAsStringSync({Encoding encoding = utf8}) {
    throw UnimplementedError();
  }

  @override
  Future<File> rename(String newPath) {
    throw BaseFileSystemEntity._notFoundException(path);
  }

  @override
  BaseFile renameSync(String newPath) => super.renameSync(newPath);

  @override
  Future setLastAccessed(DateTime time) {
    throw UnimplementedError();
  }

  @override
  void setLastAccessedSync(DateTime time) {
    throw UnimplementedError();
  }

  @override
  Future setLastModified(DateTime time) {
    throw UnimplementedError();
  }

  @override
  void setLastModifiedSync(DateTime time) {
    throw UnimplementedError();
  }

  @override
  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) {
    throw BaseFileSystemEntity._writingNotAllowedException(path);
  }

  @override
  void writeAsBytesSync(List<int> bytes,
      {FileMode mode = FileMode.write, bool flush = false}) {
    throw UnimplementedError();
  }

  @override
  Future<File> writeAsString(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false}) {
    throw BaseFileSystemEntity._writingNotAllowedException(path);
  }

  @override
  void writeAsStringSync(String contents,
      {FileMode mode = FileMode.write,
      Encoding encoding = utf8,
      bool flush = false}) {
    throw UnimplementedError();
  }
}

class BaseFileSystemEntity implements FileSystemEntity {
  @override
  final String path;

  BaseFileSystemEntity(String path) : path = _trimRightSlash(path);

  @override
  FileSystemEntity get absolute {
    throw UnimplementedError();
  }

  @override
  bool get isAbsolute {
    return path.contains('..') && path.split('/').any((v) => v == '..');
  }

  @override
  Directory get parent {
    final i = path.lastIndexOf('/');
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
    throw BaseFileSystemEntity._notFoundException(path);
  }

  @override
  void deleteSync({bool recursive = false}) async {
    throw BaseFileSystemEntity._notFoundException(path);
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
    throw BaseFileSystemEntity._notFoundException(path);
  }

  @override
  FileSystemEntity renameSync(String newPath) {
    throw UnimplementedError();
  }

  @override
  Future<String> resolveSymbolicLinks() async {
    throw BaseFileSystemEntity._notFoundException(path);
  }

  @override
  String resolveSymbolicLinksSync() {
    throw UnimplementedError();
  }

  @override
  Future<FileStat> stat() async {
    throw BaseFileSystemEntity._notFoundException(path);
  }

  @override
  FileStat statSync() {
    throw UnimplementedError();
  }

  @override
  Stream<FileSystemEvent> watch(
      {int events = FileSystemEvent.all, bool recursive = false}) {
    throw BaseFileSystemEntity._notFoundException(path);
  }

  static FileSystemException _notFoundException(String path) {
    return FileSystemException(
        'file not found', path, OSError('file not found'));
  }

  static String _trimRightSlash(String s) {
    while (s.endsWith('/') && s.length > 1) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  static FileSystemException _writingNotAllowedException(String path) {
    return FileSystemException(
        'writing is not allowed', path, OSError('writing is not allowed'));
  }
}
