import 'package:universal_io/prefer_universal/io.dart';

void main() async {
  // Use 'dart:io' HttpClient API.
  final httpClient = HttpClient();
  final request = await httpClient.getUrl(Uri.parse("http://google.com"));
  final response = await request.close();
  print(response.toString());
}
