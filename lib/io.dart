library universal_io;

export 'dart:io' if (dart.library.html) 'src/browser/api/all.dart';
