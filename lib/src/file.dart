part of universal_io;

abstract class Directory extends FileSystemEntity {
  static Directory get systemTemp => IODriver.current.systemTemp;

  factory Directory(String path) {
    return IODriver.current.newDirectory(path);
  }

  Future<Directory> createTemp([String prefix]);

  Stream<FileSystemEntity> list(
      {bool recursive: false, bool followLinks: true});
}

abstract class File extends FileSystemEntity {
  factory File(String path) {
    return IODriver.current.newFile(path);
  }

  Future<File> copy(String newPath);

  Future<int> length();

  Future<RandomAccessFile> open({FileMode mode: FileMode.read});

  Stream<List<int>> openRead([int start, int end]);

  IOSink openWrite({FileMode mode: FileMode.write, Encoding encoding: utf8});

  Future<List<int>> readAsBytes();

  Future<List<String>> readAsLines({Encoding encoding: utf8});

  Future<String> readAsString();

  Future<File> writeAsBytes(List<int> bytes,
      {FileMode mode: FileMode.write, bool flush: false});

  Future<File> writeAsString(String contents,
      {FileMode mode: FileMode.write,
      Encoding encoding: utf8,
      bool flush: false});
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

  String modeString() => throw new UnimplementedError();

  Future<FileStat> stat(String path) {
    return new FileSystemEntity(path).stat();
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
  static bool get isWatchSupported => IODriver.current.isWatchSupported;

  factory FileSystemEntity(String path) {
    return IODriver.current.newFileSystemEntity(path);
  }

  Directory get parent => new Directory(parentOf(path));

  String get path;

  Uri get uri => new Uri.file(path);

  Future<FileSystemEntity> delete({bool recursive: false});

  Future<bool> exists();

  Future<FileSystemEntity> rename(String newPath);

  Future<String> resolveSymbolicLinks();

  Future<FileStat> stat();

  Stream<FileSystemEvent> watch(
      {int events: FileSystemEvent.all, bool recursive: false});

  static Future<bool> isDirectory(String path) {
    throw new UnimplementedError();
  }

  static Future<bool> isFile(String path) {
    throw new UnimplementedError();
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
    return IODriver.current.newLink(path);
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
      {Encoding encoding: utf8});
}
