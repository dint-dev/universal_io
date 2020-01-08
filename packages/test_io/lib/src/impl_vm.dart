import 'dart:io';
import '../test_io.dart';

Future<void> getEnvironmentalVariables() {
  return Future<Map<String, String>>.value(Platform.environment);
}
