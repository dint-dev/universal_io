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
  static bool _isCorsRequired(HttpClientRequest request) {
    if (!_isCrossOriginUrl(request.uri.toString())) {
      return false;
    }
    if (request.headers.value(HttpHeaders.authorizationHeader) != null) {
      return true;
    }
    return false;
  }

  /// Tells whether the request is cross-origin.
  static bool _isCrossOriginUrl(String url, {String origin}) {
    origin ??= html.window.origin;

    // Add '/' so 'http://example.com' and 'http://example.com.other.com'
    // will be different.
    if (!origin.endsWith("/")) {
      origin = "$origin/";
    }

    if (!url.endsWith('/')) {
      url = '$url/';
    }

    return !url.startsWith(origin);
  }

  /// Can be used to disable verbose messages.
  static bool verbose = true;

  static final Set<String> _corsSimpleMethods = const {
    "GET",
    "HEAD",
    "POST",
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
    if (_isCrossOriginUrl(url, origin: origin) ||
        browserCredentialsMode == BrowserHttpClientCredentialsMode.include) {
      sb.write("\n");
      sb.write("Cross-origin request!\n");
      if (browserCredentialsMode == BrowserHttpClientCredentialsMode.include) {
        sb.write("XmlHttpRequest 'credentials mode' is enabled.\n");
        sb.write("\n");
        sb.write("Did the server send the following mandatory headers?\n");
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
        sb.write("""
XmlHttpRequest 'credentials mode' is disabled. It affects cookies and headers.
You can enable 'credentials mode' with:

    if (httpRequest is BrowserHttpClientRequest) {
      httpRequest.credentialsMode = BrowserCredentialsMode.include;
    }
""");
      }
      sb.write("\n");
      sb.write("\nDid the server send the following mandatory headers?\n");
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
    // Write a line
    for (var i = 0; i < 80; i++) {
      sb.write("-");
    }
    sb.write("\n");
    return sb.toString();
  }
}
