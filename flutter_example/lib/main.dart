import 'package:universal_io/io.dart' as prefer_default;

void main() {
  // Ensure Dart2js visits the dependency
  print(prefer_default.HttpClient().toString());
}
