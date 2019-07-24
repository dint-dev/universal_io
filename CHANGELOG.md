# 0.8.1
  * Fixed pubspec.yaml and documented Dart SDK 2.5 breaking changes.

# 0.8.0
  * Updated classes to Dart 2.5. See [Dart SDK documentation about the changes](https://github.com/dart-lang/sdk/blob/master/CHANGELOG.md).
    * Various APIs now return `Uint8List` instead of `List<int>`. Examples: `File`, `Socket`, `HttpClientResponse`.
    * Various other breaking changes such as `Cookie` constructor.

# 0.7.3
  * Fixed the following error thrown by the Dart build system in some cases: "Unsupported conditional import of dart:io found in universal_io|lib/io.dart".
  
# 0.7.2
  * Small fixes.
  
# 0.7.1
  * Fixed various bugs.
  * Improved the test suite.
  
# 0.7.0
  * Improved driver base classes and the test suite.
  
# 0.6.0
  * Major refactoring of IODriver API.

# 0.5.1
  * Fixed small bugs.
  
# 0.5.0
  * Fixed various bugs.
  * Re-organized source code.
  * Eliminated dependencies by doing IP parsing in this package.
  * Improved the test suite for drivers.