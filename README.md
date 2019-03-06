# Introduction
A [Dart](https://dartlang.org) package that supports a subset of [dart:io](https://api.dartlang.org/stable/2.1.1/dart-io/dart-io-library.html)
in all platforms, including the browser (where _dart:io_ normally doesn't work).

Typically you just import "package:universal_io/io.dart" (instead of "dart:io").
In browser, the library exports its own implementation of 'dart:io'.
In the Dart VM and Flutter, the library exports the standard _dart:io_.

Licensed under the MIT License.
Much of the source code was adopted from the original 'dart:io' in [Dart SDK](https://github.com/dart-lang/sdk),
which was licensed under a BSD-style license. See [LICENSE](LICENSE) for all licenses.

## Development
  * Participate in the development at: [github.com/terrier989/dart-universal_io](https://github.com/terrier989/dart-universal_io)

## Implemented features of 'dart:io'
  * __Platform__
    * Information such as operating system and locale.
  * __HttpClient__
    * Implemented using _dart:html_ _HttpRequest_.
    * Due to limitations of the browser platform, the connection to the server is established only
      after `HttpClientRequest` method `close()` has been called.
  * __Files__
    * By default, access to all directories and files is denied.
  * __InternetAddress__
    * Implemented using [package:ip](https://pub.dartlang.org/packages/ip).
  * __Sockets__
    * By default, binding/connecting throws _UnimplementedError_.
    * _ChromeIODriver_
      * Implements sockets using [chrome.sockets.tcp](https://developer.chrome.com/apps/sockets_tcp)
        and [chrome.sockets.udp](https://developer.chrome.com/apps/sockets_udp).
        These APIs are only available to Chrome OS Apps.
      * The following socket classes are implemented:
        * RawDatagramSocket
        * RawServerSocket
        * RawSocket
        * ServerSocket
        * Socket
      
# Getting started
## Add dependency
In `pubspec.yaml`:
```yaml
dependencies:
  universal_io: ^0.1.2
```

## Override behavior
```dart
import 'dart:async';

import 'package:universal_io/io.dart';
import 'package:universal_io/io_driver.dart';

void main() async {
  // Set IO driver
  IODriver.zoneLocal.defaultValue = new MyDriver();

  // Do something
  final socket = await Socket.connect("google.com", 80);
  socket.close();
}

class MyDriver extends BrowserIODriver {
  @override
  Future<Socket> connectSocket(host, int port,
      {sourceAddress, Duration timeout}) {
    print("Attempting to connect to '$host:$port'");
    return super.connectSocket(host, port);
  }
}
```

## Use Chrome OS driver
```dart
import 'package:universal_io/io.dart';
import 'package:universal_io/io_driver.dart';

void main() async {
  // Use Chrome OS driver for IO
  IODriver.zoneLocal.defaultValue = new ChromeIODriver();
  
  // ...
}
```