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

import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';

import 'package:meta/meta.dart';
import 'package:typed_data/typed_buffers.dart';
import 'package:universal_io/driver_base.dart';
import 'package:universal_io/io.dart';
import 'browser_http_client_exception.dart';
import 'browser_http_client.dart';

/// Used by [BrowserHttpClient].
class BrowserHttpClientResponse extends BaseHttpClientResponse {
  final HttpClient client;
  final HttpClientRequest request;
  final html.HttpRequest browserResponse;
  final Stream<List<int>> _body;

  @override
  final HttpHeaders headers = HttpHeadersImpl("1.0");

  BrowserHttpClientResponse(this.browserResponse, this._body,
      {@required this.client, @required this.request})
      : assert(browserResponse != null) {
    final headers = this.headers;
    browserResponse.responseHeaders.forEach((k, v) {
      headers.add(k, v);
    });
  }

  @override
  bool get isRedirect =>
      HttpStatus.temporaryRedirect == statusCode ||
          HttpStatus.movedPermanently == statusCode;

  @override
  String get reasonPhrase {
    return browserResponse.statusText;
  }

  int get statusCode => browserResponse.status;

  @override
  StreamSubscription<List<int>> listen(void onData(List<int> event),
      {Function onError, void onDone(), bool cancelOnError}) {
    return _body.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  Future<HttpClientResponse> redirect(
      [String method, Uri url, bool followLoops]) {
    final newUrl =
        url ?? Uri.parse(this.headers.value(HttpHeaders.locationHeader));
    return client.openUrl(method ?? request.method, newUrl).then((newRequest) {
      request.headers.forEach((name, value) {
        newRequest.headers.add(name, value);
      });
      newRequest.followRedirects = true;
      return newRequest.close();
    });
  }
}
