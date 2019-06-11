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
import 'dart:html' as html;

import 'package:universal_io/driver_base.dart';

import 'browser_http_client.dart';
import 'browser_http_client_request.dart';

/// Used by [BrowserHttpClient].
class BrowserHttpClientResponse extends BaseHttpClientResponse {
  final html.HttpRequest _xhr;
  final Stream<List<int>> _body;

  BrowserHttpClientResponse(BrowserHttpClient client, BrowserHttpClientRequest request, this._xhr, this._body)
      : assert(_xhr != null), super(client, request) {
    final headers = this.headers;
    _xhr.responseHeaders.forEach((name, value) {
      headers.add(name, value);
    });
  }

  @override
  String get reasonPhrase {
    return _xhr.statusText;
  }

  int get statusCode => _xhr.status;

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
}
