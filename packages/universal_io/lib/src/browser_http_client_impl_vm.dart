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

import 'dart:io';

/// Implemented by [HttpClient] in browsers.
///
/// This class makes it possible to enable [CORS credentials mode](https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials).
abstract class BrowserHttpClient implements HttpClient {
  /// Whether [CORS credentials mode](https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials)
  /// is enabled.
  BrowserHttpClientCredentialsMode credentialsMode =
      BrowserHttpClientCredentialsMode.omit;

  @Deprecated('Use credentialsMode instead')
  bool get useCredentialsMode =>
      credentialsMode == BrowserHttpClientCredentialsMode.include;

  @Deprecated('Use credentialsMode instead')
  set useCredentialsMode(bool value) {
    credentialsMode = value
        ? BrowserHttpClientCredentialsMode.include
        : BrowserHttpClientCredentialsMode.omit;
  }
}

/// Implemented by [HttpClientRequest] in browsers.
///
/// This class makes it possible to enable [CORS credentials mode](https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials).
abstract class BrowserHttpClientRequest implements HttpClientRequest {
  /// Whether [CORS credentials mode](https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials)
  /// is enabled.
  BrowserHttpClientCredentialsMode credentialsMode =
      BrowserHttpClientCredentialsMode.omit;

  BrowserHttpClientResponseType responseType =
      BrowserHttpClientResponseType.bytes;

  @Deprecated('Use credentialsMode instead')
  bool get useCredentialsMode =>
      credentialsMode == BrowserHttpClientCredentialsMode.include;

  @Deprecated('Use credentialsMode instead')
  set useCredentialsMode(bool value) {
    credentialsMode = value
        ? BrowserHttpClientCredentialsMode.include
        : BrowserHttpClientCredentialsMode.omit;
  }
}

/// Implemented by [HttpClientResponse] in browsers.
abstract class BrowserHttpClientResponse implements HttpClientResponse {}

/// Describes type of HTTP response body in browsers.
enum BrowserHttpClientResponseType {
  /// Response body is bytes.
  bytes,

  /// Response body is text.
  text,
}

/// Describes whether [CORS credentials mode](https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials)
/// should be enabled in browsers.
enum BrowserHttpClientCredentialsMode {
  /// Attempts to omit sending credentials.
  omit,

  /// Credentials are only sent to the same origin.
  sameOrigin,

  /// Enables CORS credentials mode.
  include,
}
