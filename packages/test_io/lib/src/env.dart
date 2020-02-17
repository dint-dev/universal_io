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

import 'package:test_io/test_io.dart';

import 'env_impl_vm.dart' if (dart.library.js) 'env_impl_browser.dart' as impl;

/// Returns environmental variables. Unlike _dart:io_ [Platform.environment](https://api.dartlang.org/stable/2.7.0/dart-io/Platform/environment.html),
/// this method works in browsers too.
///
/// Optional parameter `includeFiles` can be used to give a list of files that
/// contain environmental variables overriding previous ones. Any file that
/// doesn't exist is ignored. The files should have the following format:
/// ```
/// K0=V0
/// K1=V1
/// KN=VN
/// ```
Future<Map<String, String>> getEnvironmentalVariables({
  List<String> includeFiles,
}) async {
  var environment = await impl.getEnvironmentalVariables();
  if (includeFiles != null) {
    environment = Map<String, String>.from(environment);
    if (includeFiles is List) {
      for (var path in includeFiles) {
        if (path is String) {
          final file = await readFileAsString(path);
          if (file != null) {
            final lines = file.split('\n');
            for (var line in lines) {
              line = line.trim();
              if (line.isEmpty) {
                continue;
              }
              final i = line.indexOf('=');
              final key = line.substring(0, i);
              final value = line.substring(i + 1);
              environment[key] = value;
            }
          }
        }
      }
    }
  }
  return environment;
}
