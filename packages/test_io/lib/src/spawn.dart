import 'dart:convert';

import 'package:stream_channel/stream_channel.dart';
import 'dart:io';

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
