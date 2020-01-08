import 'package:stream_channel/stream_channel.dart';
import 'dart:io';
import 'dart:convert';

void hybridMain(StreamChannel channel, Object message) {
  channel.sink.add({
    'environment': Platform.environment,
  });
  channel.sink.close();
}
