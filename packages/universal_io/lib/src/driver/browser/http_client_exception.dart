// Copyright 2020 terrier989@gmail.com.
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

part of universal_io.browser_driver;

class _BrowserHttpClientException implements SocketException {
  /// Can be used to disable verbose messages.
  static bool verbose = true;

  static final Set<String> _corsSimpleMethods = const {
    'GET',
    'HEAD',
    'POST',
  };

  final String method;
  final String url;
  final String origin;
  final HttpHeaders headers;

  final BrowserHttpClientCredentialsMode browserCredentialsMode;

  @override
  final String message = null;

  @override
  final OSError osError = null;

  @override
  final InternetAddress address = null;

  @override
  final int port = null;

  _BrowserHttpClientException({
    @required this.method,
    @required this.url,
    @required this.origin,
    @required this.headers,
    @required this.browserCredentialsMode,
  });

  @override
  String toString() {
    if (!verbose) {
      return 'XMLHttpRequest error';
    }
    final sb = StringBuffer();
    for (var i = 0; i < 80; i++) {
      sb.write('-');
    }
    sb.write('\n');
    sb.write('''
BrowserHttpClient sent a XMLHttpRequest, which failed.
Browsers do not tell reasons for request failures. It may have been a problem in
the server-side or a problem in the client-side - we can not know.\n''');
    // Write a line
    sb.write('\n');

    // Write key details
    void addEntry(String key, String value) {
      sb.write(key.padRight(20));
      sb.write(value);
      sb.write('\n');
    }

    final parsedUrl = Uri.parse(url);
    addEntry('Request HTTP method: ', method);
    addEntry('Request URL: ', url);
    addEntry('Request URL origin: ', parsedUrl.origin);
    addEntry('Browser origin: ', origin);

    // Warn about possible problem with missing CORS headers
    if (parsedUrl.origin != html.window.origin) {

      // List of header name that the server may need to whitelist
      final allowHeadersList = <String>[];
      headers.forEach((name, values) {
        allowHeadersList.add(name);
      });
      allowHeadersList.sort();
      final allowHeaders = allowHeadersList.isEmpty ? '' : allowHeadersList.join(', ');

      sb.write('\n');
      sb.write('Cross-origin request!\n');
      if (browserCredentialsMode == BrowserHttpClientCredentialsMode.include) {
        sb.write("XmlHttpRequest 'credentials mode' is enabled.\n");
        sb.write('\n');
        sb.write('Did the server send the following mandatory headers?\n');
        sb.write('  * Access-Control-Allow-Credentials: true\n');
        sb.write('  * Access-Control-Allow-Origin: $origin\n');
        sb.write("    * In credentials mode, '*' would fail!\n");
        sb.write('  * Access-Control-Allow-Methods: $method\n');
        sb.write("    * In credentials mode, '*' would fail!\n");
        if (allowHeaders.isNotEmpty) {
          sb.write('  * Access-Control-Allow-Headers: $allowHeaders\n');
          sb.write("    * In credentials mode, '*' would fail!\n");
        }
      } else {
        sb.write("""
XmlHttpRequest 'credentials mode' is disabled. It affects cookies and headers.
If you think you need to enable 'credentials mode', do the following:

    final httpClientRequest = ...;
    if (httpClientRequest is BrowserHttpClientRequest) {
      httpClientRequest.credentialsMode = BrowserHttpClientCredentialsMode.include;
    }
""");
      }
      sb.write('\n');
      sb.write('\nDid the server send the following mandatory headers?\n');
      sb.write('  * Access-Control-Allow-Credentials: true\n');
      sb.write('  * Access-Control-Allow-Origin: $origin\n');
      sb.write("    * OR '*'\n");
      if (!_corsSimpleMethods.contains(method)) {
        sb.write('  * Access-Control-Allow-Methods: $method\n');
        sb.write("    * OR '*'\n");
      }
      if (allowHeaders.isNotEmpty) {
        sb.write('  * Access-Control-Allow-Headers: $allowHeaders\n');
        sb.write("    * OR '*'\n");
      }
    }
    // Write a line
    for (var i = 0; i < 80; i++) {
      sb.write('-');
    }
    sb.write('\n');
    return sb.toString();
  }
}
