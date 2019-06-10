import 'package:test/test.dart';
import 'package:universal_io/io.dart';

import 'platform_impl_default.dart'
    if (dart.library.html) 'platform_impl_browser.dart';

void testPlatform() {
  group("Platform: ", () {
    final isWindows = Platform.isWindows;
    final expectedPathSeparator = isWindows ? r"\" : "/";
    test("pathSeparator == '$expectedPathSeparator'", () {
      expect(Platform.pathSeparator, expectedPathSeparator);
    });

    // Run tests that only work in browser
    testPlatformInBrowser();
  }, timeout: Timeout(Duration(seconds: 1)));
}
