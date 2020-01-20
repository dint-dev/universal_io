import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart' as test;
import 'dart:typed_data';

Future<Map<String, String>> getEnvironmentalVariables() async {
  // Send request to the VM
  final channel = test.spawnHybridUri(
    'package:test_io/src/spawn.dart',
    message: {
      'type': 'env',
    },
  );

  // Wait for JSON response
  final responseMessage = await channel.stream.first as Map;

  // Build environmental variables
  return Map<String, String>.from(responseMessage['environment'] as Map);
}

Future<Uint8List> readFileAsBytes(String path) async {
  // Send request to the VM
  final channel = test.spawnHybridUri(
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
