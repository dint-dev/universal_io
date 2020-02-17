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

import 'dart:convert';
import 'dart:typed_data';

import 'files_impl_vm.dart' if (dart.library.js) 'files_impl_browser.dart'
    as impl;

/// Reads file as a string. Unlike _dart:io_ [File](https://api.dartlang.org/stable/2.7.0/dart-io/Platform/file.html),
/// this method works in browsers too.
Future<String> readFileAsString(String path) {
  return scriptRelativeFileAsBytes(path).then(
    (value) => value == null ? null : utf8.decode(value),
  );
}

/// Reads file as bytes. Unlike _dart:io_ [File](https://api.dartlang.org/stable/2.7.0/dart-io/Platform/file.html),
/// this method works in browsers too.
Future<Uint8List> scriptRelativeFileAsBytes(String path) {
  return impl.readFileAsBytes(path);
}
