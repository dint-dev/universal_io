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

// -----------------------------------------------------------------------------
// PURPOSE OF THIS FILE
// -----------------------------------------------------------------------------
//
// When 'universal_io/io.dart' had a conditional export:
//   export 'src/io/io.dart' if (dart.library.io) 'dart:io';
//
// We observed 'package:build' throwing:
//   Invalid argument(s): Unsupported conditional import of `dart:io` found in
//   universal_io|lib/io.dart.
//
// For more information, see:
//   * Source code: https://github.com/dart-lang/build/blob/master/build_modules/lib/src/module_library.dart
//   * Commit code review: https://github.com/dart-lang/build/pull/1793
//
// This file solves the problem.
//
export 'dart:io';

export 'io/cors_vm.dart';
