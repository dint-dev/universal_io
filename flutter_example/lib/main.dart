import 'package:universal_io/io.dart' as prefer_default;
// ignore: deprecated_member_use
import 'package:universal_io/prefer_sdk/io.dart' as prefer_sdk;
// ignore: deprecated_member_use
import 'package:universal_io/prefer_universal/io.dart' as prefer_universal;

void main() {
  // Ensure Dart2js visits the dependency
  print(prefer_default.HttpClient().toString());
  print(prefer_sdk.HttpClient().toString());
  print(prefer_universal.HttpClient().toString());
}
