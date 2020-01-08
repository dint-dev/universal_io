import 'dart:io';

/// Implemented by [HttpClient] in browsers.
///
/// This class makes it possible to enable [CORS credentials mode](https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials).
abstract class BrowserLikeHttpClient implements HttpClient {
  /// Whether [CORS credentials mode](https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials)
  /// is enabled.
  bool useCorsCredentials = false;
}

/// Implemented by [HttpClientRequest] in browsers.
///
/// This class makes it possible to enable [CORS credentials mode](https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials).
abstract class BrowserLikeHttpClientRequest implements HttpClientRequest {
  /// Whether [CORS credentials mode](https://developer.mozilla.org/en-US/docs/Web/API/Request/credentials)
  /// is enabled.
  bool useCorsCredentials = false;
}
