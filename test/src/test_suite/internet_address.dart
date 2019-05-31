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

@Timeout(Duration(seconds: 2))
library internet_address_test;

import 'package:test/test.dart';
import 'package:universal_io/io.dart';

void testInternetAddress() {
  group("InternetAddress", () {
    test("address", () {
      expect(InternetAddress("10.0.0.1").address, "10.0.0.1");
    });
    test("host", () {
      expect(InternetAddress("10.0.0.1").host, "10.0.0.1");
    });
    test("isLoopback", () {
      expect(InternetAddress("10.0.0.1").isLoopback, isFalse);
      expect(InternetAddress("127.0.0.1").isLoopback, isTrue);
      expect(InternetAddress("::").isLoopback, isFalse);
      expect(InternetAddress("::1").isLoopback, isTrue);
    });
    test("rawAddress", () {
      expect(InternetAddress("10.0.0.1").rawAddress, [10, 0, 0, 1]);
    });
  });
}
