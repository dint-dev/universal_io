// Copyright 2020 terrier989@gmail.com.
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
library process_test;

import 'dart:convert';

import 'package:test/test.dart';
import 'package:universal_io/prefer_universal/io.dart';

void testProcess({bool isPosix = true}) {
  group('Process', () {
    if (isPosix) {
      test("Process.start('echo', ['Hello world!'])", () async {
        final process = await Process.start('echo', ['Hello world!']);

        final exitCode = await process.exitCode;
        expect(exitCode, 0);

        final result = await utf8.decodeStream(process.stdout);
        expect(result, 'Hello world!\n');
      });

      test("Process.run('echo', ['Hello world!'])", () async {
        final result = await Process.run('echo', ['Hello world!']);
        expect(result.exitCode, 0);
        expect(result.stdout, 'Hello world!\n');
      });
    }
  }, timeout: Timeout(Duration(seconds: 1)));
}
