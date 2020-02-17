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

import '../io_impl_js.dart';
import 'file.dart';

/// The type of an entity on the file system, such as a file, directory, or link.
///
/// These constants are used by the [FileSystemEntity] class
/// to indicate the object's type.
///

class FileSystemEntityType {
  static const file = FileSystemEntityType._internal(0);
  @Deprecated('Use file instead')
  static const FILE = file;

  static const directory = FileSystemEntityType._internal(1);
  @Deprecated('Use directory instead')
  static const DIRECTORY = directory;

  static const link = FileSystemEntityType._internal(2);
  @Deprecated('Use link instead')
  static const LINK = link;

  static const notFound = FileSystemEntityType._internal(3);
  @Deprecated('Use notFound instead')
  static const NOT_FOUND = notFound;

  final int _type;

  const FileSystemEntityType._internal(this._type);

  @override
  String toString() => const ['file', 'directory', 'link', 'notFound'][_type];
}

/// A FileStat object represents the result of calling the POSIX stat() function
/// on a file system object.  It is an immutable object, representing the
/// snapshotted values returned by the stat() call.
class FileStat {
  /// The time of the last change to the data or metadata of the file system
  /// object.
  ///
  /// On Windows platforms, this is instead the file creation time.
  final DateTime changed;

  /// The time of the last change to the data of the file system object.
  final DateTime modified;

  /// The time of the last access to the data of the file system object.
  ///
  /// On Windows platforms, this may have 1 day granularity, and be
  /// out of date by an hour.
  final DateTime accessed;

  /// The type of the underlying file system object.
  ///
  /// [FileSystemEntityType.notFound] if [stat] or [statSync] failed.
  final FileSystemEntityType type;

  /// The mode of the file system object.
  ///
  /// Permissions are encoded in the lower 16 bits of this number, and can be
  /// decoded using the [modeString] getter.
  final int mode;

  /// The size of the file system object.
  final int size;

  const FileStat._internalNotFound()
      : changed = null,
        modified = null,
        accessed = null,
        type = FileSystemEntityType.notFound,
        mode = 0,
        size = -1;

  /// Calls the operating system's `stat()` function (or equivalent) on [path].
  ///
  /// Returns a [FileStat] object containing the data returned by `stat()`.
  /// If the call fails, returns a [FileStat] object with [FileStat.type] set to
  /// [FileSystemEntityType.notFound] and the other fields invalid.
  static FileStat statSync(String path) {
    final overrides = IOOverrides.current;
    if (overrides == null) {
      throw UnimplementedError();
    }
    return overrides.statSync(path);
  }

  /// Asynchronously calls the operating system's `stat()` function (or
  /// equivalent) on [path].
  ///
  /// Returns a [Future] which completes with the same results as [statSync].
  static Future<FileStat> stat(String path) {
    final overrides = IOOverrides.current;
    if (overrides == null) {
      throw UnimplementedError();
    }
    return overrides.stat(path);
  }

  @override
  String toString() => '''
FileStat: type $type
          changed $changed
          modified $modified
          accessed $accessed
          mode ${modeString()}
          size $size''';

  /// Returns the mode value as a human-readable string.
  ///
  /// The string is in the format "rwxrwxrwx", reflecting the user, group, and
  /// world permissions to read, write, and execute the file system object, with
  /// "-" replacing the letter for missing permissions.  Extra permission bits
  /// may be represented by prepending "(suid)", "(guid)", and/or "(sticky)" to
  /// the mode string.
  String modeString() {
    var permissions = mode & 0xFFF;
    var codes = const ['---', '--x', '-w-', '-wx', 'r--', 'r-x', 'rw-', 'rwx'];
    var result = [];
    if ((permissions & 0x800) != 0) result.add('(suid) ');
    if ((permissions & 0x400) != 0) result.add('(guid) ');
    if ((permissions & 0x200) != 0) result.add('(sticky) ');
    result
      ..add(codes[(permissions >> 6) & 0x7])
      ..add(codes[(permissions >> 3) & 0x7])
      ..add(codes[permissions & 0x7]);
    return result.join();
  }
}

/// The common super class for [File], [Directory], and [Link] objects.
///
/// [FileSystemEntity] objects are returned from directory listing
/// operations. To determine if a FileSystemEntity is a [File], a
/// [Directory], or a [Link] perform a type check:
///
///     if (entity is File) (entity as File).readAsStringSync();
///
/// You can also use the [type] or [typeSync] methods to determine
/// the type of a file system object.
///
/// Most methods in this class occur in synchronous and asynchronous pairs,
/// for example, [exists] and [existsSync].
/// Unless you have a specific reason for using the synchronous version
/// of a method, prefer the asynchronous version to avoid blocking your program.
///
/// Here's the exists method in action:
///
///     entity.exists().then((isThere) {
///       isThere ? print('exists') : print('non-existent');
///     });
///
///
/// ## Other resources
///
/// * [Dart by
///   Example](https://www.dartlang.org/dart-by-example/#files-directories-and-symlinks)
///   provides additional task-oriented code samples that show how to use various
///   API from the [Directory] class and the [File] class, both subclasses of
///   FileSystemEntity.
///
/// * [I/O for Command-Line
///   Apps](https://www.dartlang.org/docs/dart-up-and-running/ch03.html#dartio---io-for-command-line-apps),
///   a section from _A Tour of the Dart Libraries_ covers files and directories.
///
/// * [Write Command-Line Apps](https://www.dartlang.org/docs/tutorials/cmdline/),
///   a tutorial about writing command-line apps, includes information about
///   files and directories.
abstract class FileSystemEntity {
  String get path;

  /// Returns a [Uri] representing the file system entity's location.
  ///
  /// The returned URI's scheme is always "file" if the entity's [path] is
  /// absolute, otherwise the scheme will be empty.
  Uri get uri => Uri.file(path);

  /// Checks whether the file system entity with this path exists. Returns
  /// a [:Future<bool>:] that completes with the result.
  ///
  /// Since FileSystemEntity is abstract, every FileSystemEntity object
  /// is actually an instance of one of the subclasses [File],
  /// [Directory], and [Link].  Calling [exists] on an instance of one
  /// of these subclasses checks whether the object exists in the file
  /// system object exists and is of the correct type (file, directory,
  /// or link).  To check whether a path points to an object on the
  /// file system, regardless of the object's type, use the [type]
  /// static method.
  ///
  Future<bool> exists();

  /// Synchronously checks whether the file system entity with this path
  /// exists.
  ///
  /// Since FileSystemEntity is abstract, every FileSystemEntity object
  /// is actually an instance of one of the subclasses [File],
  /// [Directory], and [Link].  Calling [existsSync] on an instance of
  /// one of these subclasses checks whether the object exists in the
  /// file system object exists and is of the correct type (file,
  /// directory, or link).  To check whether a path points to an object
  /// on the file system, regardless of the object's type, use the
  /// [typeSync] static method.
  bool existsSync();

  /// Renames this file system entity.
  ///
  /// Returns a `Future<FileSystemEntity>` that completes with a
  /// [FileSystemEntity] instance for the renamed file system entity.
  ///
  /// If [newPath] identifies an existing entity of the same type, that entity
  /// is replaced. If [newPath] identifies an existing entity of a different
  /// type, the operation fails and the future completes with an exception.
  Future<FileSystemEntity> rename(String newPath);

  /// Synchronously renames this file system entity.
  ///
  /// Returns a [FileSystemEntity] instance for the renamed entity.
  ///
  /// If [newPath] identifies an existing entity of the same type, that entity
  /// is replaced. If [newPath] identifies an existing entity of a different
  /// type, the operation fails and an exception is thrown.
  FileSystemEntity renameSync(String newPath);

  /// Resolves the path of a file system object relative to the
  /// current working directory.
  ///
  /// Resolves all symbolic links on the path and resolves all `..` and `.` path
  /// segments.
  ///
  /// [resolveSymbolicLinks] uses the operating system's native
  /// file system API to resolve the path, using the `realpath` function
  /// on linux and OS X, and the `GetFinalPathNameByHandle` function on
  /// Windows. If the path does not point to an existing file system object,
  /// `resolveSymbolicLinks` throws a `FileSystemException`.
  ///
  /// On Windows the `..` segments are resolved _before_ resolving the symbolic
  /// link, and on other platforms the symbolic links are _resolved to their
  /// target_ before applying a `..` that follows.
  ///
  /// To ensure the same behavior on all platforms resolve `..` segments before
  /// calling `resolveSymbolicLinks`. One way of doing this is with the `Uri`
  /// class:
  ///
  ///     var path = Uri.parse('.').resolveUri(new Uri.file(input)).toFilePath();
  ///     if (path == '') path = '.';
  ///     new File(path).resolveSymbolicLinks().then((resolved) {
  ///       print(resolved);
  ///     });
  ///
  /// since `Uri.resolve` removes `..` segments. This will result in the Windows
  /// behavior.
  Future<String> resolveSymbolicLinks();

  /// Resolves the path of a file system object relative to the
  /// current working directory.
  ///
  /// Resolves all symbolic links on the path and resolves all `..` and `.` path
  /// segments.
  ///
  /// [resolveSymbolicLinksSync] uses the operating system's native
  /// file system API to resolve the path, using the `realpath` function
  /// on linux and OS X, and the `GetFinalPathNameByHandle` function on
  /// Windows. If the path does not point to an existing file system object,
  /// `resolveSymbolicLinksSync` throws a `FileSystemException`.
  ///
  /// On Windows the `..` segments are resolved _before_ resolving the symbolic
  /// link, and on other platforms the symbolic links are _resolved to their
  /// target_ before applying a `..` that follows.
  ///
  /// To ensure the same behavior on all platforms resolve `..` segments before
  /// calling `resolveSymbolicLinksSync`. One way of doing this is with the `Uri`
  /// class:
  ///
  ///     var path = Uri.parse('.').resolveUri(new Uri.file(input)).toFilePath();
  ///     if (path == '') path = '.';
  ///     var resolved = new File(path).resolveSymbolicLinksSync();
  ///     print(resolved);
  ///
  /// since `Uri.resolve` removes `..` segments. This will result in the Windows
  /// behavior.
  String resolveSymbolicLinksSync();

  /// Calls the operating system's stat() function on the [path] of this
  /// [FileSystemEntity].
  ///
  /// Identical to [:FileStat.stat(this.path):].
  ///
  /// Returns a [:Future<FileStat>:] object containing the data returned by
  /// stat().
  ///
  /// If the call fails, completes the future with a [FileStat] object
  /// with `.type` set to [FileSystemEntityType.notFound] and the other fields
  /// invalid.
  Future<FileStat> stat() => FileStat.stat(path);

  /// Synchronously calls the operating system's stat() function on the
  /// [path] of this [FileSystemEntity].
  ///
  /// Identical to [:FileStat.statSync(this.path):].
  ///
  /// Returns a [FileStat] object containing the data returned by stat().
  ///
  /// If the call fails, returns a [FileStat] object with `.type` set to
  /// [FileSystemEntityType.notFound] and the other fields invalid.
  FileStat statSync() => FileStat.statSync(path);

  /// Deletes this [FileSystemEntity].
  ///
  /// If the [FileSystemEntity] is a directory, and if [recursive] is false,
  /// the directory must be empty. Otherwise, if [recursive] is true, the
  /// directory and all sub-directories and files in the directories are
  /// deleted. Links are not followed when deleting recursively. Only the link
  /// is deleted, not its target.
  ///
  /// If [recursive] is true, the [FileSystemEntity] is deleted even if the type
  /// of the [FileSystemEntity] doesn't match the content of the file system.
  /// This behavior allows [delete] to be used to unconditionally delete any file
  /// system object.
  ///
  /// Returns a [:Future<FileSystemEntity>:] that completes with this
  /// [FileSystemEntity] when the deletion is done. If the [FileSystemEntity]
  /// cannot be deleted, the future completes with an exception.
  Future<FileSystemEntity> delete({bool recursive = false}) =>
      throw UnimplementedError();

  /// Synchronously deletes this [FileSystemEntity].
  ///
  /// If the [FileSystemEntity] is a directory, and if [recursive] is false,
  /// the directory must be empty. Otherwise, if [recursive] is true, the
  /// directory and all sub-directories and files in the directories are
  /// deleted. Links are not followed when deleting recursively. Only the link
  /// is deleted, not its target.
  ///
  /// If [recursive] is true, the [FileSystemEntity] is deleted even if the type
  /// of the [FileSystemEntity] doesn't match the content of the file system.
  /// This behavior allows [deleteSync] to be used to unconditionally delete any
  /// file system object.
  ///
  /// Throws an exception if the [FileSystemEntity] cannot be deleted.
  void deleteSync({bool recursive = false}) => throw UnimplementedError();

  /// Start watching the [FileSystemEntity] for changes.
  ///
  /// The implementation uses platform-dependent event-based APIs for receiving
  /// file-system notifications, thus behavior depends on the platform.
  ///
  ///   * `Windows`: Uses `ReadDirectoryChangesW`. The implementation only
  ///     supports watching directories. Recursive watching is supported.
  ///   * `Linux`: Uses `inotify`. The implementation supports watching both
  ///     files and directories. Recursive watching is not supported.
  ///     Note: When watching files directly, delete events might not happen
  ///     as expected.
  ///   * `OS X`: Uses `FSEvents`. The implementation supports watching both
  ///     files and directories. Recursive watching is supported.
  ///
  /// The system will start listening for events once the returned [Stream] is
  /// being listened to, not when the call to [watch] is issued.
  ///
  /// The returned value is an endless broadcast [Stream], that only stops when
  /// one of the following happens:
  ///
  ///   * The [Stream] is canceled, e.g. by calling `cancel` on the
  ///      [StreamSubscription].
  ///   * The [FileSystemEntity] being watched, is deleted.
  ///   * System Watcher exits unexpectedly. e.g. On `Windows` this happens when
  ///     buffer that receive events from `ReadDirectoryChangesW` overflows.
  ///
  /// Use `events` to specify what events to listen for. The constants in
  /// [FileSystemEvent] can be or'ed together to mix events. Default is
  /// [FileSystemEvent.all].
  ///
  /// A move event may be reported as seperate delete and create events.
  Stream<FileSystemEvent> watch(
      {int events = FileSystemEvent.all, bool recursive = false}) {
    final overrides = IOOverrides.current;
    if (overrides == null) {
      throw UnimplementedError();
    }
    return overrides.fsWatch(path, events, recursive);
  }

  /// Checks whether two paths refer to the same object in the
  /// file system.
  ///
  /// Returns a [:Future<bool>:] that completes with the result.
  ///
  /// Comparing a link to its target returns false, as does comparing two links
  /// that point to the same target.  To check the target of a link, use
  /// Link.target explicitly to fetch it.  Directory links appearing
  /// inside a path are followed, though, to find the file system object.
  ///
  /// Completes the returned Future with an error if one of the paths points
  /// to an object that does not exist.
  static Future<bool> identical(String path1, String path2) {
    var overrides = IOOverrides.current;
    if (overrides == null) {
      throw UnimplementedError();
    }
    return overrides.fseIdentical(path1, path2);
  }

  static final RegExp _absoluteWindowsPathPattern =
      RegExp(r'^(\\\\|[a-zA-Z]:[/\\])');

  /// Returns a [bool] indicating whether this object's path is absolute.
  ///
  /// On Windows, a path is absolute if it starts with \\\\ or a drive letter
  /// between a and z (upper or lower case) followed by :\\ or :/.
  /// On non-Windows, a path is absolute if it starts with /.
  bool get isAbsolute {
    if (Platform.isWindows) {
      return path.startsWith(_absoluteWindowsPathPattern);
    } else {
      return path.startsWith('/');
    }
  }

  /// Returns a [FileSystemEntity] whose path is the absolute path to [this].
  ///
  /// The type of the returned instance is the type of [this].
  ///
  /// The absolute path is computed by prefixing
  /// a relative path with the current working directory, and returning
  /// an absolute path unchanged.
  FileSystemEntity get absolute;

  /// Synchronously checks whether two paths refer to the same object in the
  /// file system.
  ///
  /// Comparing a link to its target returns false, as does comparing two links
  /// that point to the same target.  To check the target of a link, use
  /// Link.target explicitly to fetch it.  Directory links appearing
  /// inside a path are followed, though, to find the file system object.
  ///
  /// Throws an error if one of the paths points to an object that does not
  /// exist.
  static bool identicalSync(String path1, String path2) {
    var overrides = IOOverrides.current;
    if (overrides == null) {
      throw UnimplementedError();
    }
    return overrides.fseIdenticalSync(path1, path2);
  }

  /// Test if [watch] is supported on the current system.
  ///
  /// OS X 10.6 and below is not supported.
  static bool get isWatchSupported {
    final overrides = IOOverrides.current;
    if (overrides == null) {
      throw UnimplementedError();
    }
    return overrides.fsWatchIsSupported();
  }

  /// Finds the type of file system object that a path points to.
  ///
  /// Returns a [:Future<FileSystemEntityType>:] that completes with the same
  /// results as [typeSync].
  static Future<FileSystemEntityType> type(String path,
      {bool followLinks = true}) {
    final overrides = IOOverrides.current;
    if (overrides == null) {
      throw UnimplementedError();
    }
    return overrides.fseGetType(path, followLinks);
  }

  /// Synchronously finds the type of file system object that a path points to.
  ///
  /// Returns a [FileSystemEntityType].
  ///
  /// Returns [FileSystemEntityType.link] only if [followLinks] is false and if
  /// [path] points to a link.
  ///
  /// Returns [FileSystemEntityType.notFound] if [path] does not point to a file
  /// system object or if any other error occurs in looking up the path.
  static FileSystemEntityType typeSync(String path, {bool followLinks = true}) {
    final overrides = IOOverrides.current;
    if (overrides == null) {
      throw UnimplementedError();
    }
    return overrides.fseGetTypeSync(path, followLinks);
  }

  /// Checks if type(path, followLinks: false) returns FileSystemEntityType.link.
  static Future<bool> isLink(String path) => type(path, followLinks: true)
      .then((type) => (type == FileSystemEntityType.link));

  /// Checks if type(path) returns FileSystemEntityType.file.
  static Future<bool> isFile(String path) => type(path, followLinks: true)
      .then((type) => (type == FileSystemEntityType.file));

  /// Checks if type(path) returns FileSystemEntityType.directory.
  static Future<bool> isDirectory(String path) => type(path, followLinks: true)
      .then((type) => (type == FileSystemEntityType.directory));

  /// Synchronously checks if typeSync(path, followLinks: false) returns
  /// FileSystemEntityType.link.
  static bool isLinkSync(String path) =>
      (typeSync(path, followLinks: true) == FileSystemEntityType.link);

  /// FileSystemEntityType.file.
  static bool isFileSync(String path) =>
      (typeSync(path, followLinks: true) == FileSystemEntityType.file);

  /// Synchronously checks if typeSync(path) returns
  /// FileSystemEntityType.directory.
  static bool isDirectorySync(String path) =>
      (typeSync(path, followLinks: true) == FileSystemEntityType.directory);

  // Finds the next-to-last component when dividing at path separators.
  static final RegExp _parentRegExp = Platform.isWindows
      ? RegExp(r'[^/\\][/\\]+[^/\\]')
      : RegExp(r'[^/]/+[^/]');

  /// Removes the final path component of a path, using the platform's
  /// path separator to split the path.
  ///
  /// Will not remove the root component of a Windows path, like "C:\\" or
  /// "\\\\server_name\\". Ignores trailing path separators, and leaves no
  /// trailing path separators.
  static String parentOf(String path) {
    var rootEnd = -1;
    if (Platform.isWindows) {
      if (path.startsWith(_absoluteWindowsPathPattern)) {
        // Root ends at first / or \ after the first two characters.
        rootEnd = path.indexOf(RegExp(r'[/\\]'), 2);
        if (rootEnd == -1) return path;
      } else if (path.startsWith('\\') || path.startsWith('/')) {
        rootEnd = 0;
      }
    } else if (path.startsWith('/')) {
      rootEnd = 0;
    }
    // Ignore trailing slashes.
    // All non-trivial cases have separators between two non-separators.
    var pos = path.lastIndexOf(_parentRegExp);
    if (pos > rootEnd) {
      return path.substring(0, pos + 1);
    } else if (rootEnd > -1) {
      return path.substring(0, rootEnd + 1);
    } else {
      return '.';
    }
  }

  /// The directory containing [this].
  Directory get parent => Directory(parentOf(path));
}

/// Base event class emitted by [FileSystemEntity.watch].
class FileSystemEvent {
  /// Bitfield for [FileSystemEntity.watch], to enable [FileSystemCreateEvent]s.
  static const int create = 1 << 0;
  @Deprecated('Use create instead')
  static const int CREATE = 1 << 0;

  /// Bitfield for [FileSystemEntity.watch], to enable [FileSystemModifyEvent]s.
  static const int modify = 1 << 1;
  @Deprecated('Use modify instead')
  static const int MODIFY = 1 << 1;

  /// Bitfield for [FileSystemEntity.watch], to enable [FileSystemDeleteEvent]s.
  static const int delete = 1 << 2;
  @Deprecated('Use delete instead')
  static const int DELETE = 1 << 2;

  /// Bitfield for [FileSystemEntity.watch], to enable [FileSystemMoveEvent]s.
  static const int move = 1 << 3;
  @Deprecated('Use move instead')
  static const int MOVE = 1 << 3;

  /// Bitfield for [FileSystemEntity.watch], for enabling all of [create],
  /// [modify], [delete] and [move].
  static const int all = create | modify | delete | move;
  @Deprecated('Use all instead')
  static const int ALL = create | modify | delete | move;

  /// The type of event. See [FileSystemEvent] for a list of events.
  final int type;

  /// The path that triggered the event.
  ///
  /// Depending on the platform and the FileSystemEntity, the path may be
  /// relative.
  final String path;

  /// Is `true` if the event target was a directory.
  ///
  /// Note that if the file has been deleted by the time the event has arrived,
  /// this will always be `false` on Windows. In particular, it will always be
  /// `false` for `delete` events.
  final bool isDirectory;

  FileSystemEvent._(this.type, this.path, this.isDirectory);
}

/// File system event for newly created file system objects.
class FileSystemCreateEvent extends FileSystemEvent {
  FileSystemCreateEvent._(path, isDirectory)
      : super._(FileSystemEvent.create, path, isDirectory);

  @override
  String toString() => "FileSystemCreateEvent('$path')";
}

/// File system event for modifications of file system objects.
class FileSystemModifyEvent extends FileSystemEvent {
  /// If the content was changed and not only the attributes, [contentChanged]
  /// is `true`.
  final bool contentChanged;

  FileSystemModifyEvent._(path, isDirectory, this.contentChanged)
      : super._(FileSystemEvent.modify, path, isDirectory);

  @override
  String toString() =>
      "FileSystemModifyEvent('$path', contentChanged=$contentChanged)";
}

/// File system event for deletion of file system objects.
class FileSystemDeleteEvent extends FileSystemEvent {
  FileSystemDeleteEvent._(path, isDirectory)
      : super._(FileSystemEvent.delete, path, isDirectory);

  @override
  String toString() => "FileSystemDeleteEvent('$path')";
}

/// File system event for moving of file system objects.
class FileSystemMoveEvent extends FileSystemEvent {
  /// If the underlying implementation is able to identify the destination of
  /// the moved file, [destination] will be set. Otherwise, it will be `null`.
  final String destination;

  FileSystemMoveEvent._(path, isDirectory, this.destination)
      : super._(FileSystemEvent.move, path, isDirectory);

  @override
  String toString() {
    var buffer = StringBuffer();
    buffer.write("FileSystemMoveEvent('$path'");
    if (destination != null) buffer.write(", '$destination'");
    buffer.write(')');
    return buffer.toString();
  }
}
