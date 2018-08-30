# Overview
  * A [Dart](https://dartlang.org) package that supports a subset of 'dart:io' in all platforms
    (browser, VM, and Flutter).
  * Currently, the package supports:
      * `FileSystemEntity` and related classes
        * In browser, access to all directories and files is denied.
        * You can override behavior inside a zone.
      * `HTTPClient`
        * In browser, a notable difference to VM/Flutter is that a connection to the server is
        established only after the `HttpClientRequest.close()` has been invoked.
      * `Platform`
        * You can override behavior inside a zone.

## License
Licensed under the [MIT License](LICENSE). Some of the source code was adopted from the original 'dart:io' in [Dart SDK](https://github.com/dart-lang/sdk).