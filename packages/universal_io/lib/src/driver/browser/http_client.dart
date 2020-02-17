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

/// Browser implementation of _dart:io_ [HttpClient].
class _BrowserHttpClient extends BaseHttpClient with BrowserHttpClient {
  @override
  Future<HttpClientRequest> didOpenUrl(String method, Uri url) {
    if (url.host == null) {
      throw ArgumentError.value(url, 'url', "Host can't be null");
    }
    var scheme = url.scheme;
    var needsNewUrl = false;
    if (scheme == null) {
      scheme = 'https';
      needsNewUrl = true;
    } else {
      switch (scheme) {
        case '':
          scheme = 'https';
          needsNewUrl = true;
          break;
        case 'http':
          break;
        case 'https':
          break;
        default:
          throw ArgumentError.value("Unsupported scheme '$scheme'");
      }
    }
    if (needsNewUrl) {
      url = Uri(
        scheme: scheme,
        userInfo: url.userInfo,
        host: url.host,
        port: url.port,
        query: url.query,
        fragment: url.fragment,
      );
    }
    final request = _BrowserHttpClientRequest(this, method, url);
    return Future<HttpClientRequest>.value(request);
  }
}
