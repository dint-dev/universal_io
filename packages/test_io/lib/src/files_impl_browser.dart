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

import 'package:test/test.dart' show spawnHybridUri;

Future<Uint8List> readFileAsBytes(String path) async {
  // Send request to the VM
  final channel = spawnHybridUri(
    'package:test_io/src/spawn.dart',
    message: {
      'type': 'file',
      'path': path,
    },
  );

  // Wait for JSON response
  final responseMessage = await channel.stream.first as Map;

  // Build environmental variables
  final base64Encoded = responseMessage['base64'];
  if (base64Encoded == null) {
    return null;
  }
  return base64Decode(base64Encoded as String);
}
