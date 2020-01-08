[![Pub Package](https://img.shields.io/pub/v/noddejs_io.svg)](https://pub.dartlang.org/packages/nodejs_io)
[![Github Actions CI](https://github.com/dart-io-packages/universal_io/workflows/Dart%20CI/badge.svg)](https://github.com/dart-io-packages/universal_io/actions?query=workflow%3A%22Dart+CI%22)

# Getting started
In _pubspec.yaml_:
```yaml
dependencies:
  nodejs_io: ^0.1.0
```

In _main.dart_:
```dart
import 'package:nodejs_io/nodejs_io.dart';
import 'package:universal_io/io.dart';

void main() async {
  nodeIODriver.enable();

  // 'dart:io' works now!
  final socket = await Socket.connect("localhost", 8080);
}
```