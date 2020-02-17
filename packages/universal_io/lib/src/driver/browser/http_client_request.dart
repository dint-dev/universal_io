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

/// Used by [_BrowserHttpClient].
class _BrowserHttpClientRequest extends BaseHttpClientRequest
    with BrowserHttpClientRequest {
  final Completer<HttpClientResponse> _completer =
      Completer<HttpClientResponse>();

  final _buffer = Uint8ListBuffer();

  _BrowserHttpClientRequest(_BrowserHttpClient client, String method, Uri uri)
      : assert(client != null),
        assert(method != null),
        assert(uri != null),
        super(client, method, uri) {
    credentialsMode = client.credentialsMode;
    final userAgent = client.userAgent;
    if (userAgent != null) {
      headers.add("User-Agent", userAgent);
    }
  }

  @override
  HttpConnectionInfo get connectionInfo => null;

  @override
  void didAdd(List<int> event) {
    _buffer.add(event);
  }

  @override
  Future<HttpClientResponse> didClose() {
    if (cookies.isNotEmpty) {
      _completer.completeError(StateError(
        "Attempted to send cookies, but XMLHttpRequest does not support them.",
      ));
      return _completer.future;
    }
    try {
      final xhr = html.HttpRequest();

      // Set method and URI
      final uriString = uri.toString();
      xhr.open(method, uriString);

      // Set response body type
      xhr.responseType = 'arraybuffer';

      if (responseType == BrowserHttpClientResponseType.text) {
        xhr.responseType = '';
      }

      // Timeout
      final timeout = this.client.connectionTimeout;
      if (timeout != null) {
        xhr.timeout = timeout.inMilliseconds;
      }

      // Credentials mode?
      var credentialsMode = this.credentialsMode;
      switch (credentialsMode) {
        case BrowserHttpClientCredentialsMode.omit:
          break;
        case BrowserHttpClientCredentialsMode.sameOrigin:
          break;
        case BrowserHttpClientCredentialsMode.include:
          xhr.withCredentials = true;
          break;
        case BrowserHttpClientCredentialsMode.automatic:
          if (_BrowserHttpClientException._isCorsRequired(this)) {
            xhr.withCredentials = true;
          }
          break;
      }

      // Copy headers to html.HttpRequest
      headers.forEach((name, values) {
        for (var value in values) {
          xhr.setRequestHeader(name, value);
        }
      });

      final headersCompleter = this._completer;
      final controller = StreamController<Uint8List>();
      var bodySeenLength = 0;

      void completeHeaders() {
        if (headersCompleter.isCompleted) {
          return;
        }

        // Create HttpClientResponse
        final httpClientResponse = _BrowserHttpClientResponse(
          this,
          xhr.status,
          xhr.statusText,
          controller.stream,
        );

        final headers = httpClientResponse.headers;
        xhr.responseHeaders.forEach((name, value) {
          headers.add(name, value);
        });

        // Complete the future
        headersCompleter.complete(httpClientResponse);
      }

      void addChunk() {
        // Close stream
        if (!headersCompleter.isCompleted || controller.isClosed) {
          return;
        }
        final body = xhr.response;
        if (body == null) {
          return;
        } else if (body is String) {
          final chunk = body.substring(bodySeenLength);
          bodySeenLength = body.length;
          controller.add(Utf8Encoder().convert(chunk));
        } else if (body is ByteBuffer) {
          final chunk = Uint8List.view(body, bodySeenLength);
          bodySeenLength = body.lengthInBytes;
          controller.add(chunk);
        } else {
          throw StateError('response is: $body');
        }
      }

      xhr.onReadyStateChange.listen((event) {
        switch (xhr.readyState) {
          case html.HttpRequest.HEADERS_RECEIVED:
            // Complete future
            completeHeaders();
            break;
        }
      });

      xhr.onProgress.listen((html.ProgressEvent event) {
        // Complete future
        addChunk();
      });

      xhr.onLoad.first.then((event) {
        addChunk();
        controller.close();
      });

      xhr.onTimeout.first.then((event) {
        if (!headersCompleter.isCompleted) {
          headersCompleter.completeError(TimeoutException('Timeout'));
        } else {
          controller.addError(TimeoutException('Timeout'));
          controller.close();
        }
      });

      final origin = html.window.origin;
      xhr.onError.first.then((html.ProgressEvent event) {
        // The underlying XMLHttpRequest API doesn't expose any specific
        // information about the error itself.
        //
        // We gather the information that we have and try to produce a
        // descriptive exception.
        final error = _BrowserHttpClientException(
          method: method,
          url: uriString,
          origin: origin,
          headers: headers,
          browserCredentialsMode: credentialsMode,
        );

        if (!headersCompleter.isCompleted) {
          // Complete future
          headersCompleter.completeError(error, StackTrace.current);
        } else if (!controller.isClosed) {
          // Close stream
          controller.addError(error);
          controller.close();
        }
      });

      if (_buffer.length > 0) {
        // Send with body
        xhr.send(_buffer.read());
      } else {
        // Send without body
        xhr.send();
      }
    } catch (e) {
      // Something went wrong
      _completer.completeError(e);
    }
    return _completer.future;
  }
}
