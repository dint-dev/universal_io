import 'package:universal_io/io.dart' as prefer_default;
import 'package:universal_io/prefer_sdk/io.dart' as prefer_sdk;
import 'package:universal_io/prefer_universal/io.dart' as prefer_universal;

void main() {
  // Ensure Dart2js visits the dependency
  print(prefer_default.HttpClient().toString());
  print(prefer_sdk.HttpClient().toString());
  print(prefer_universal.HttpClient().toString());
}
