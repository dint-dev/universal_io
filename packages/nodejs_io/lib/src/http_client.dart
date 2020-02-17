// Copyright 2019 terrier989@gmail.com.
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

part of nodejs_io;

class _NodeJsHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext context) {
    return _NodeJsHttpClient();
  }
}

class _NodeJsHttpClient extends BaseHttpClient {
  @override
  Future<HttpClientRequest> didOpenUrl(String method, Uri url) async {
    final impl = node_http.StreamedRequest(method, url);
    return _NodeJsHttpClientRequest(this, method, url, impl);
  }
}

class _NodeJsHttpClientRequest extends BaseHttpClientRequest {
  final node_http.StreamedRequest impl;

  _NodeJsHttpClientRequest(
      _NodeJsHttpClient client, String method, Uri uri, this.impl)
      : super(client, method, uri);

  Future<node_http.StreamedResponse> _response;

  void _commitHeaders() {
    if (_response != null) {
      return;
    }
    headers.forEach((key, values) {
      for (var value in values) {
        impl.headers[key] = value;
      }
    });
    final nodeClient = node_http.NodeClient();
    _response = nodeClient.send(
      impl,
    );
  }

  @override
  set followRedirects(bool value) {
    impl.followRedirects = value;
  }

  @override
  set maxRedirects(int value) {
    impl.maxRedirects = value;
  }

  @override
  void didAdd(List<int> data) {
    _commitHeaders();
    impl.sink.add(data);
  }

  @override
  Future<HttpClientResponse> didClose() async {
    _commitHeaders();
    impl.sink.close();
    final nodeResponse = await _response;
    final response = _NodeJsHttpClientResponse(this);
    response.statusCode = nodeResponse.statusCode;
    response.reasonPhrase = nodeResponse.reasonPhrase;
    response.isRedirect = nodeResponse.isRedirect;
    for (var entry in nodeResponse.headers.entries) {
      response.headers.set(entry.key, entry.value);
    }
    response.stream = nodeResponse.stream.map((data) {
      if (data is Uint8List) {
        return data;
      }
      return Uint8List.fromList(data);
    });
    return response;
  }
}

class _NodeJsHttpClientResponse extends BaseHttpClientResponse {
  @override
  int statusCode;

  @override
  final HttpHeaders headers = HttpHeadersImpl('1.1');

  Stream<Uint8List> stream;

  @override
  String reasonPhrase;

  @override
  bool isRedirect;

  _NodeJsHttpClientResponse(_NodeJsHttpClientRequest request) : super(request);

  @override
  StreamSubscription<Uint8List> listen(
    void Function(Uint8List event) onData, {
    Function onError,
    void Function() onDone,
    bool cancelOnError,
  }) {
    return stream.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
