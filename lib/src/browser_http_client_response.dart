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

import 'package:universal_io/io.dart';

/// Implemented by [HttpClientResponse] when the application runs in browser.
abstract class BrowserHttpClientResponse extends HttpClientResponse {
  /// Response object of _XHR_ request.
  ///
  /// You need to finish reading this [HttpClientResponse] to get the final
  /// value.
  dynamic get browserResponse;
}
