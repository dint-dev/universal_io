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
import 'dart:io';

import 'package:stream_channel/stream_channel.dart';

void hybridMain(StreamChannel channel, Object messageObj) async {
  try {
    final message = messageObj as Map<String, Object>;
    final type = message['type'] as String;
    switch (type) {
      case 'env':
        channel.sink.add({
          'environment': Platform.environment,
        });
        break;
      case 'file':
        final path = message['path'] as String;
        final file = File(path);
        if (!file.existsSync()) {
          channel.sink.add({});
        } else {
          final data = await file.readAsBytes();
          channel.sink.add({
            'base64': base64Encode(data),
          });
        }
        break;
      default:
        throw StateError('Unsupported message type: $type');
    }
  } finally {
    await channel.sink.close();
  }
}
