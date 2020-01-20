import 'dart:io';
import 'dart:typed_data';

Future<Map<String, String>> getEnvironmentalVariables() {
  return Future<Map<String, String>>.value(Platform.environment);
}

Future<Uint8List> readFileAsBytes(String path) async {
  final file = File(path);
  if (!file.existsSync()) {
    return null;
  }
  return file.readAsBytes();
}
