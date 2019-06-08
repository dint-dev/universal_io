import 'package:universal_io/io.dart';
import 'package:test/test.dart';
import 'dart:html';

void testPlatformInBrowser() {
  if (window.navigator.languages.isNotEmpty) {
    final locale = window.navigator.languages.first;
    test("Platform.localeName == '$locale'", () {
      expect(Platform.localeName, locale);
    });
  }
}
