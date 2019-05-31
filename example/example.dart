import 'package:universal_io/io.dart';

void main() async {
  // Use 'dart:io' HttpClient API
  //
  // This works automatically in:
  //   * Browser (where standard 'dart:io' would fail)
  //   * Flutter and VM
  final httpClient = new HttpClient();
  final request = await httpClient.getUrl(Uri.parse("http://google.com"));
  final response = await request.close();
  print("Google.com HTTP status: ${response.statusCode}");
}