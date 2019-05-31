# Introduction
A cross-platform version of [dart:io](https://api.dartlang.org/stable/2.1.1/dart-io/dart-io-library.html).

You can just replace usages of "dart:io" with "package:universal_io/io.dart". This is what happens:
  * __In browser (and other Javascript targets)__:
    * Exports our copy "dart:io" APIs. The only changes are related to delegation to _IODriver_.
    * Some "dart:io" features, such as _HttpClient_, work by default in browsers. Others only work
      with a driver (see below).
  * __In Flutter and Dart VM__:
    * Exports the standard _"dart:io"_.
    * This is accomplished with conditional imports, which is an undocumented feature of Dart.

## License
Licensed under the [Apache License 2.0](LICENSE).
Much of the source code was adopted from the original 'dart:io' in [Dart SDK](https://github.com/dart-lang/sdk),
which was licensed under a BSD-style license.

## Issues
  * Found issues? Report them at the [Github issue tracker](https://github.com/gohilla/dart-universal_io/issues).
  * Have a fix? [Create a pull request](https://github.com/gohilla/dart-universal_io/pull/new/master)!

# Getting started
## 1.Add a dependency
In `pubspec.yaml`:
```yaml
dependencies:
  universal_io: ^0.4.0
```

## 2. Choose a driver (optional)
  * VM/Flutter?
    * Library "package:universal_io/io.dart" will automatically export _dart:io_ for you.
  * Browser?
    * _BrowserIODriver_ is automatically used when compiling with _Dart2js_ / _devc_. Most
      importantly, it implements  _HttpClient_ (with restrictions imposed by browsers).
    * If you need things like sockets or unrestricted _HttpClient_, choose one of the options below.
  * Chrome OS App?
    * [universal_io_driver_chrome_os](https://github.com/terrier989/dart-universal_io_driver_chrome_os)
  * Node.JS? Google Cloud Functions?
    * [universal_io_driver_node](https://github.com/terrier989/dart-universal_io_driver_node)
  * A backend + GRPC messaging?
    * [universal_io_driver_grpc](https://github.com/terrier989/dart-universal_io_driver_grpc)

## 3. Use

```dart
import 'package:universal_io/io.dart';

void main() async {
  // Use 'dart:io' HttpClient API.
  //
  // This works automatically in:
  //   * Browser (where usage of standard 'dart:io' would not even compile)
  //   * Flutter and VM
  final httpClient = new HttpClient();
  final request = await httpClient.getUrl(Uri.parse("http://google.com"));
  final response = await request.close();
}

```

# Manual
## Default driver behavior
### HTTP client
In browser, HTTP client is implemented using _dart:html_ _HttpRequest_, which uses 
[XmlHttpRequest](https://developer.mozilla.org/en/docs/Web/API/XMLHttpRequest).

If a cross-origin request fails, error message contains a detailed description how to fix
possible issues like missing cross-origin headers.

For example:
```
BrowserHttpClient received an error from XMLHttpRequest (which doesn't tell
reason for the error).

HTTP method:   PUT
URL:           http://destination.com
Origin:        http://source.com

Cross-origin request!
CORS credentials mode' is disabled (cookies will NOT be supported).

If the URL is correct and the server actually responded, did the response
include the following required CORS headers?
  * Access-Control-Allow-Origin: http://source.com
    * Wildcard '*' is also acceptable.
  * Access-Control-Allow-Methods: PUT
```

### InternetAddress
  * Implemented using [package:ip](https://github.com/gohilla/dart-ip).

### Platform
  * In browser, variables are determined by browser APIs such as _navigator.userAgent_.
  * Elsewhere (e.g. Node.JS), appears like Linux environment.

### Files
  * Any attempt to use these APIs will throw _UnimplementedError_.

### Socket classes and HttpServer
  * Any attempt to use these APIs will throw _UnimplementedError_.

## Writing your own driver?
```dart
import 'package:universal_io/io.dart';
import 'package:universal_io/driver.dart';
import 'package:universal_io/driver_base.dart';

void main() {
  IODriver.zoneLocal.freezeDefault(const ExampleDriver());
  
  // Now the APIs will use your driver.
  final file = new File();
  print(file is ExampleFile);
}

class ExampleDriver extends BaseDriver {
  const ExampleDriver() : super(fileSystemDriver:const MyFileSystemDriver());
}

class ExampleFileSystemDriver extends BaseFileSystemDriver {
  const ExampleFileSystemDriver();

  @override
  File newFile(String path) {
    return new ExampleFile();
  }
}

class ExampleFile extends BaseFile {
  // ...
}
```