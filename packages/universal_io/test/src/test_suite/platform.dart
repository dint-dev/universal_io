import 'package:test/test.dart';
import 'package:universal_io/prefer_universal/io.dart';

import 'platform_impl_default.dart'
    if (dart.library.html) 'platform_impl_browser.dart';

void testPlatform() {
  group('Platform: ', () {
    test("pathSeparator == '/'", () {
      expect(Platform.pathSeparator, '/');
    }, testOn: 'posix');

    test("pathSeparator == '\'", () {
      expect(Platform.pathSeparator, r'\');
    }, testOn: 'windows');

    // Run tests that only work in browser
    testPlatformInBrowser();
  });
}
