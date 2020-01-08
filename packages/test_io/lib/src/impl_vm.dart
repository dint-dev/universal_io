import 'dart:io';

Future<void> getEnvironmentalVariables() {
  return Future<Map<String, String>>.value(Platform.environment);
}
