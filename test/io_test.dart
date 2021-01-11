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

@TestOn('dart-vm')
@Timeout(Duration(seconds: 5))
library vm_test;

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:test/test.dart';

import 'src/all.dart';

void main() {
  runServer();

  group('Test suite in VM:', () {
    testAll();
  });

  testBrowser('chrome');

  // if (Platform.isMacOS) {
  //   testBrowser('safari');
  // }

  // testBrowser('firefox');
}

void testBrowser(String name) {
  test('Test suite in "$name" (in a separate process, only failures reported): $name', () async {
    final process = await Process.start('dart', ['test', '--platform=$name', 'test/browser.dart']);
    process.stdout.listen((data) {
      stdout.add(data);
    });
    process.stderr.listen((data) {
      stderr.add(data);
    });
    final exitCode = await process.exitCode;
    if (exitCode!=0) {
      fail('Exit code: $exitCode');
    }
  }, timeout: Timeout(const Duration(minutes: 2)));
}

void runServer() {
  late Process process;
  setUpAll(() async {
    process = await Process.start(
      'dart',
      [
        'run',
        'test/server.dart',
      ],
    );
    final serverStartedCompleter = Completer<void>();
    final collectedStdout = <int>[];
    process.stdout.listen((data) {
      collectedStdout.addAll(data);
      try {
        final s = utf8.decode(collectedStdout);
        if (s.contains('SERVER STARTED AT: localhost:$serverPort\n')) {
          serverStartedCompleter.complete();
        }
      } catch (e) {
        // Ignore
      }
      stdout.add(data);
    });
    process.stderr.listen((data) {
      stdout.add(data);
    });
    await Future.any([
      serverStartedCompleter.future,
      process.exitCode,
    ]);
  });
  setUp(() async {
    try {
      await process.exitCode.timeout(Duration(milliseconds: 1));
      fail('Server process has exited with code: $exitCode');
    } on TimeoutException {
      // Ignore
    }
  });
  tearDownAll(() {
    process.kill();
  });
}
