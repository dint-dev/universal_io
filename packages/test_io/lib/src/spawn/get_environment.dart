import 'package:stream_channel/stream_channel.dart';
import 'dart:io';

void hybridMain(StreamChannel channel, Object message) {
  channel.sink.add({
    'environment': Platform.environment,
  });
  channel.sink.close();
}
