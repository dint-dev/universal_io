// Copyright 'dart-universal_io' project authors.
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

import 'package:meta/meta.dart';
import 'package:universal_io/io.dart';

import 'browser_http_client.dart';

class BrowserHttpClientException implements SocketException {
  /// Can be used to disable verbose messages.
  static bool verbose = true;

  static final Set<String> _corsSimpleMethods = Set<String>.from(const [
    "GET",
    "HEAD",
    "POST",
  ]);

  final String method;
  final String url;
  final String origin;
  final HttpHeaders headers;

  final bool corsCredentialsMode;

  @override
  final String message = null;

  @override
  final OSError osError = null;

  @override
  final InternetAddress address = null;

  @override
  final int port = null;

  BrowserHttpClientException({
    @required this.method,
    @required this.url,
    @required this.origin,
    @required this.headers,
    @required this.corsCredentialsMode,
  });

  @override
  String toString() {
    if (!verbose) {
      return "XMLHttpRequest error";
    }
    final sb = StringBuffer();
    for (var i = 0; i < 80; i++) {
      sb.write("-");
    }
    sb.write("\n");
    sb.write("""
BrowserHttpClient received an error from XMLHttpRequest (which doesn't tell
reason for the error).\n""");
    // Write a line
    sb.write("\n");

    // Write key details
    void addEntry(String key, String value) {
      sb.write(key.padRight(20));
      sb.write(value);
      sb.write("\n");
    }

    final headerNames = <String>[];
    headers.forEach((name, values) {
      headerNames.add(name);
    });
    headerNames.sort();

    addEntry("HTTP method: ", method);
    addEntry("URL: ", url);
    addEntry("Origin: ", origin);

    // Warn about possible problem with missing CORS headers
    if (BrowserHttpClient.isCrossOriginUrl(url, origin: origin) ||
        corsCredentialsMode) {
      sb.write("\n");
      sb.write("Cross-origin request!\n");
      sb.write("'CORS 'credentials' mode' is ");
      if (corsCredentialsMode) {
        sb.write("enabled.\n");
      } else {
        sb.write("disabled.\n");
        sb.write("""
This means that the browser will not send authentication (cookies, etc.) to the server.

Want to enable credentials mode?
Enable it with: request.headers.set('Authorization', null)""");
      }
      sb.write("\nDid the server send the following mandatory headers?\n");

      // Access-Control-Allow-Credentials
      if (corsCredentialsMode) {
        sb.write("  * Access-Control-Allow-Credentials: true\n");
        sb.write("  * Access-Control-Allow-Origin: $origin\n");
        sb.write("    * In credentials mode, '*' would fail!\n");
        sb.write("  * Access-Control-Allow-Methods: $method\n");
        sb.write("    * In credentials mode, '*' would fail!\n");
        if (headerNames.isNotEmpty) {
          final joined = headerNames.join(', ');
          sb.write("  * Access-Control-Allow-Headers: $joined\n");
          sb.write("    * In credentials mode, '*' would fail!\n");
        }
      } else {
        sb.write("  * Access-Control-Allow-Credentials: true\n");
        sb.write("  * Access-Control-Allow-Origin: $origin\n");
        sb.write("    * OR '*'\n");
        if (!_corsSimpleMethods.contains(method)) {
          sb.write("  * Access-Control-Allow-Methods: $method\n");
          sb.write("    * OR '*'\n");
        }
        if (headerNames.isNotEmpty) {
          final joined = headerNames.join(', ');
          sb.write("  * Access-Control-Allow-Headers: $joined\n");
          sb.write("    * OR '*'\n");
        }
      }
    }
    // Write a line
    for (var i = 0; i < 80; i++) {
      sb.write("-");
    }
    sb.write("\n");
    return sb.toString();
  }
}
