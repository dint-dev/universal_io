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
  static final Set<String> _corsSimpleMethods = Set<String>.from(const [
    "GET",
    "HEAD",
    "POST",
  ]);
  final String method;
  final String url;
  final String origin;

  final bool corsCredentialsMode;

  @override
  final String message = null;

  @override
  final OSError osError = null;

  @override
  final InternetAddress address = null;

  @override
  final int port = null;

  BrowserHttpClientException(
      {@required this.method,
        @required this.url,
        @required this.origin,
        @required this.corsCredentialsMode});

  @override
  String toString() {
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

    addEntry("HTTP method: ", method);
    addEntry("URL: ", url);
    addEntry("Origin: ", origin);

    // Warn about possible problem with missing CORS headers
    if (BrowserHttpClient.isCrossOriginUrl(url, origin: origin) ||
        corsCredentialsMode) {
      sb.write("\n");
      sb.write("Cross-origin request!\n");
      sb.write("'CORS credentials mode' is ");
      if (corsCredentialsMode) {
        sb.write("enabled (cookies will be supported).\n");
      } else {
        sb.write("disabled (cookies will NOT be supported).\n");
      }
      sb.write("\n");
      sb.write("""
If the URL is correct and the server actually responded, did the response
include the following required CORS headers?\n""");

      sb.write("  * Access-Control-Allow-Origin: $origin\n");
      if (corsCredentialsMode) {
        sb.write(
            "    * Wildcard '*' is not allowed because of credentials mode!\n");
        sb.write("  * Access-Control-Allow-Credentials: true\n");
      } else {
        sb.write("    * Wildcard '*' is also acceptable.\n");
      }
      if (!_corsSimpleMethods.contains(method)) {
        sb.write("  * Access-Control-Allow-Methods: $method\n");
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