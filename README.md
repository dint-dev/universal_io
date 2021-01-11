[![Pub Package](https://img.shields.io/pub/v/universal_io.svg)](https://pub.dartlang.org/packages/universal_io)
[![Github Actions CI](https://github.com/dint-dev/universal_io/workflows/Dart%20CI/badge.svg)](https://github.com/dint-dev/universal_io/actions?query=workflow%3A%22Dart+CI%22)

# Overview
A cross-platform _dart:io_ that works in all platforms (browsers, Flutter, and VM).

The API is exactly the same API as _dart:io_. You can simply replace _dart:io_ imports with
_package:universal_io/io.dart_.

Licensed under the [Apache License 2.0](LICENSE).
Much of the source code is derived [from Dart SDK](https://github.com/dart-lang/sdk/tree/master/sdk/lib/io),
which was obtained under the BSD-style license of Dart SDK. See LICENSE file for details.

## Links
  * [Pub package](https://pub.dev/packages/universal_io)
  * [Issue tracker](https://github.com/dint-dev/universal_io/issues)
  * [Create a pull request](https://github.com/dint-dev/universal_io/pull/new/master)

## Similar packages
  * [universal_html](https://pub.dev/packages/universal_html) (cross-platform _dart:html_)


# Getting started
### pubspec.yaml
```yaml
dependencies:
  universal_io: ^2.0.0
```

### main.dart

```dart
import 'package:universal_io/io.dart';

Future<void> main() async {
  // HttpClient works
  final httpClient = HttpClient();
  final request = await httpClient.getUrl(Uri.parse("http://google.com"));
  final response = await request.close();
}
```

In some situations, Dart development tools (your IDE) may give warnings, but your application
will compile fine. You can try to eliminate warnings by importing
`"package:universal_io/prefer_universal/io.dart"` or `"package:universal_io/prefer_sdk/io.dart"`


# Browser driver
## HTTP client
HTTP client is implemented using [XMLHttpRequest (XHR)](https://developer.mozilla.org/en/docs/Web/API/XMLHttpRequest)
(in _dart:html_, the class is [HttpRequest](https://api.dart.dev/stable/2.7.1/dart-html/HttpRequest-class.html)).

XHR causes the following differences with _dart:io_:
  * HTTP connection is created only after `request.close()` has been called.
  * Same-origin policy limitations. For making cross-origin requests, see documentation below.

### Cross-origin requests
If any cross-origin request fails, error message contains a detailed description how to fix
possible issues like missing cross-origin headers. The error messages look like:

```
BrowserHttpClient received an error from XMLHttpRequest (which doesn't tell
reason for the error).

HTTP method:      PUT
HTTP URL:         http://destination.com/path/example
Origin:           http://source.com
Cross-origin:     true
Credentials mode: true

Cross-origin request!
CORS 'credentials mode' is disabled (the browser will not send cookies).
You can enable 'credentials mode' with:

    if (httpRequest is BrowserHttpClientRequest) {
      httpRequest.credentialsMode = BrowserHttpClientCredentialsMode.include;
    }

Did the server send the following mandatory headers?
  * Access-Control-Allow-Origin: http://source.com
    * OR '*'
  * Access-Control-Allow-Methods: PUT
```

Sometimes when you do cross-origin requests in browsers, you want to use
[CORS "credentials mode"](https://developer.mozilla.org/en-US/docs/Web/HTTP/CORS). This can be
achieved with the following pattern:
```dart
Future<void> main() async {
    final client = HttpClient();
    final request = client.getUrl(Url.parse('http://host/path'));
    if (request is BrowserHttpClientRequest) {
      request.browserCredentialsMode = true;
    }
    final response = await request.close();
    // ...
}
```

### Streaming text responses
The underlying XMLHttpRequest (XHR) API supports response streaming only when _responseType_ is
"text". If HTTP request header "Accept" contains only text MIMEs ("text/plain", etc.), this package
uses _responseType_ "text".

You can manually set response type:
```dart
Future<void> main() async {
    // ...

    // Change response type
    if (request is BrowserHttpClientRequest) {
      request.browserResponseType = 'text';
    }

    // Stream chunks
    final response = await request.close();
    response.listen((chunk) {
      // ...
    });
}
```

## Platform
The [implementation](https://github.com/dint-dev/universal_io/blob/master/packages/universal_io/lib/src/driver/default_impl_browser.dart)
supports APIs such as:
  * `Platform.isWindows`
  * `Platform.operatingSystem`
  * `Platform.locale`