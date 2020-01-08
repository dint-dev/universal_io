import 'dart:async';

import 'package:test/test.dart' as test;
import '../test_io.dart';

Future<Map<String, String>> getEnvironmentalVariables() async {
  // Send request to the VM
  final channel = test.spawnHybridUri(
    'package:test_io/src/spawn/get_environment.dart',
  );

  // Wait for JSON response
  final data = await channel.stream.first as Map;

  // Build environmental variables
  final result = <String, String>{};
  for (var entry in data['environment'].entries) {
    result[entry.key] = entry.value as String;
  }
  return result;
}
