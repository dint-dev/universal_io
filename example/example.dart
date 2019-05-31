import 'package:universal_io/io.dart';

void main() async {
  // Use 'dart:io' HttpClient API.
  //
  // This works automatically in:
  //   * Browser (where usage of standard 'dart:io' would not even compile)
  //   * Flutter and VM
  final httpClient = HttpClient();
  final request = await httpClient.getUrl(Uri.parse("http://google.com"));
  final response = await request.close();
  print(response.toString());
}
