// Copyright 'dart-universal_io' project authors.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

@TestOn("browser")
@Timeout(Duration(seconds: 20))
import 'package:test/test.dart';

import 'src/test_suite/suite.dart';

void main() {
  group("Test suite in browsers:", () {
    runTestSuite(
      isBrowser: true,
      httpClient: true,
    );
  });
}
