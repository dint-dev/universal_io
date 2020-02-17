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
class _BrowserHttpClientResponse extends BaseHttpClientResponse
    with BrowserHttpClientResponse {
  final Stream<Uint8List> _body;

  _BrowserHttpClientResponse(
    _BrowserHttpClientRequest request,
    this.statusCode,
    this.reasonPhrase,
    this._body,
  ) : super(request);

  @override
  final String reasonPhrase;

  @override
  final int statusCode;

  @override
  StreamSubscription<Uint8List> listen(void Function(Uint8List event) onData,
      {Function onError, void Function() onDone, bool cancelOnError}) {
    return _body.listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }
}
