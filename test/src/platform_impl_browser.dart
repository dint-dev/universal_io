import 'dart:html' hide Platform;

import 'package:test/test.dart';
import 'package:universal_io/prefer_universal/io.dart';

// Conditionally imported by 'env.dart'.
void testPlatformInBrowser() {
  if (window.navigator.languages!.isNotEmpty) {
    final locale = window.navigator.languages!.first;
    test("Platform.localeName == '$locale'", () {
      expect(Platform.localeName, locale);
    });
  }
}
