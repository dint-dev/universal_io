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

/// Cross-platform implementation of 'dart:io'.
///
/// To deal with limitations of conditional imports/exports in Dart, developers
/// can choose from three slightly libraries:
///   * 'package:universal_io/prefer_sdk/io.dart'
///     * Exports SDK version by default
///   * 'package:universal_io/prefer_universal/io.dart'
///     * Exports non-SDK version by default
///   * 'package:universal_io/io.dart'
///     * Exports either one of the above libraries.
library universal_io;

export 'prefer_sdk/io.dart';
