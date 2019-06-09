import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:universal_io/utils.dart';

void main() {
  group("Uint8ListBuffer", () {
    test("add(chunk)", () {
      final buffer = Uint8ListBuffer();
      expect(buffer.length, 0);
      expect(buffer.read(), _equalsUint8List([]));

      // Write []
      buffer.add(<int>[]);
      expect(buffer.length, 0);
      expect(buffer.read(), _equalsUint8List([]));

      // Write [1]
      buffer.add(<int>[1]);
      expect(buffer.length, 1);
      expect(buffer.read(), _equalsUint8List([1]));

      // Write [1,2], [], [3], [4]
      buffer.add(<int>[1, 2]);
      buffer.add(<int>[]);
      buffer.add(<int>[3]);
      buffer.add(<int>[4]);

      // Result
      expect(buffer.length, 4);
      expect(buffer.read(), _equalsUint8List([1, 2, 3, 4]));
    });

    test("add(chunk), n-1 bytes (n=2^k)", () {
      for (var n in [8, 16, 32, 64, 128, 256, 512]) {
        final buffer = Uint8ListBuffer();

        // Write 2 bytes
        // These will be copied to the new buffer.
        buffer.add(<int>[1, 2]);

        // Write N-3 bytes
        buffer.add(List<int>.generate(n - 3, (i) => 2 + i + 1));

        // Verify N-1 bytes
        expect(buffer.length, n - 1);
        expect(buffer.read(preview: true), _equalsUint8List(_range(1, n - 1)));

        // Write one more byte, so the length will become N
        buffer.add([n % 256]);
        expect(buffer.length, n);
        expect(buffer.read(), _equalsUint8List(_range(1, n)));
      }
    });

    test("add(chunk), n+1 bytes (n=2^k)", () {
      for (var n in [16, 32, 64, 128, 256, 512]) {
        final buffer = Uint8ListBuffer();
        buffer.add(<int>[1, 2]);
        buffer.add(List.generate(n - 1, (i) => 2 + i + 1));
        expect(buffer.length, n + 1);
        expect(buffer.read(preview: true), _equalsUint8List(_range(1, n + 1)));
      }
    });

    test("addStream(stream)", () async {
      final stream = Stream<List<int>>.fromIterable(<List<int>>[
        <int>[1],
        <int>[2, 3],
      ]);
      final buffer = Uint8ListBuffer();

      // Add stream
      final future = buffer.addStream(stream);
      expect(buffer.read(), _equalsUint8List([]));

      // Wait for the stream to be added
      await future;

      // Was the stream added?
      expect(buffer.read(), _equalsUint8List([1, 2, 3]));
    });

    test("read()", () {
      // Empty buffer
      final buffer = Uint8ListBuffer();

      // read()
      expect(buffer.read(), <int>[]);

      // Add bytes
      buffer.add(<int>[1]);
      buffer.add(<int>[2, 3, 4]);
      buffer.add(<int>[]);
      buffer.add(<int>[5]);

      // read()
      expect(buffer.read(), _equalsUint8List([1, 2, 3, 4, 5]));
    });

    test(
        "read() after a single add(copyNotNeeded:true) returns the same reference",
        () {
      final buffer = Uint8ListBuffer();

      // Define input
      final input = Uint8List(1024);

      // Write
      buffer.add(input, copyNotNeeded: true);

      // Returns the same reference?
      expect(buffer.read(), same(input));
    });

    test("read(preview:true)", () {
      final buffer = Uint8ListBuffer();
      buffer.add(<int>[1, 2, 3, 4, 5]);
      expect(buffer.read(preview: true), _equalsUint8List([1, 2, 3, 4, 5]));
      expect(buffer.read(preview: true), _equalsUint8List([1, 2, 3, 4, 5]));
    });

    test(
        "read(maxLength:N) after a single add(copyNotNeeded:true) returns the same reference",
        () {
      final buffer = Uint8ListBuffer();
      final written = Uint8List(5);
      for (var i = 0; i < written.length; i++) {
        written[i] = i + 1;
      }
      buffer.add(written, copyNotNeeded: true);
      expect(buffer.read(maxLength: 5), same(written));
    });

    test("read(maxLength:N)", () {
      // Empty buffer
      final buffer = Uint8ListBuffer();

      // Read
      expect(buffer.read(maxLength: 0), _equalsUint8List([]));
      expect(buffer.read(maxLength: 1), _equalsUint8List([]));

      // Add bytes
      buffer.add(<int>[1, 2, 3, 4, 5]);

      // Read
      expect(buffer.read(maxLength: 0), _equalsUint8List([]));
      expect(buffer.read(maxLength: 1), _equalsUint8List([1]));
      expect(buffer.read(maxLength: 2), _equalsUint8List([2, 3]));
      expect(buffer.read(maxLength: 3), _equalsUint8List([4, 5]));
    });

    test("read(maxLength:N), whole buffer", () {
      final buffer = Uint8ListBuffer();
      buffer.add(<int>[1, 2, 3, 4, 5]);
      expect(buffer.length, 5);
      expect(buffer.read(maxLength: 5), _equalsUint8List([1, 2, 3, 4, 5]));
      expect(buffer.length, 0);
    });

    test("read(maxLength:N, preview:true), with preview", () {
      final buffer = Uint8ListBuffer();
      buffer.add(<int>[1, 2, 3, 4, 5]);
      expect(buffer.length, 5);
      expect(
        buffer.read(maxLength: 0, preview: true),
        _equalsUint8List([]),
      );
      expect(
        buffer.read(maxLength: 1, preview: true),
        _equalsUint8List([1]),
      );
      expect(
        buffer.read(maxLength: 2, preview: true),
        _equalsUint8List([1, 2]),
      );
      expect(
        buffer.read(maxLength: 3, preview: true),
        _equalsUint8List([1, 2, 3]),
      );
      expect(
        buffer.read(maxLength: 4, preview: true),
        _equalsUint8List([1, 2, 3, 4]),
      );
      expect(
        buffer.read(maxLength: 5, preview: true),
        _equalsUint8List([1, 2, 3, 4, 5]),
      );
      expect(buffer.length, 5);
    });

    test("readUff8", () {
      final buffer = Uint8ListBuffer();
      buffer.add(utf8.encode("abc"));
      expect(buffer.length, 3);
      expect(buffer.readUtf8(preview: true), "abc");
      expect(buffer.length, 3);
      expect(buffer.readUtf8(), "abc");
      expect(buffer.length, 0);
    });

    test("readUff8Incomplete, 1 byte", () {
      final buffer = Uint8ListBuffer();
      buffer.add(utf8.encode("abc"));
      expect(buffer.length, 3);
      expect(buffer.readUtf8Incomplete(preview: true), "abc");
      expect(buffer.length, 3);
      expect(buffer.readUtf8Incomplete(), "abc");
      expect(buffer.length, 0);
    });

    test("readUff8Incomplete, 2 byte rune", () {
      // Define the rune
      final writtenString = "¢";
      final writtenData = utf8.encode(writtenString);
      expect(writtenData, hasLength(2));

      // Create a buffer
      final buffer = Uint8ListBuffer();

      // Write a single-byte character
      buffer.add(utf8.encode("a"));

      // Write byte 0, try to read
      buffer.add(writtenData.sublist(0, 1));
      expect(buffer.readUtf8Incomplete(), "a");
      expect(buffer.readUtf8Incomplete(), "");

      // Write byte 1
      buffer.add(writtenData.sublist(1, 2));

      // Finally we can read the rune
      expect(buffer.readUtf8Incomplete(), writtenString);
      expect(buffer.length, 0);
    });

    test("readUff8Incomplete, 4 byte rune", () {
      // Define the rune
      final writtenString = "𐍈";
      final writtenData = utf8.encode(writtenString);
      expect(writtenData, hasLength(4));

      // Create a buffer
      final buffer = Uint8ListBuffer();

      // Write a single-byte character
      buffer.add(utf8.encode("a"));

      // Write byte 0, try to read
      buffer.add(writtenData.sublist(0, 1));
      expect(buffer.readUtf8Incomplete(), "a");
      expect(buffer.readUtf8Incomplete(), "");

      // Write byte 1, try to read
      buffer.add(writtenData.sublist(1, 2));
      expect(buffer.readUtf8Incomplete(), "");

      // Write byte 2, try to read
      buffer.add(writtenData.sublist(2, 3));
      expect(buffer.readUtf8Incomplete(), "");

      // Write byte 3
      buffer.add(writtenData.sublist(3, 4));

      // Finally we can read the rune
      expect(buffer.readUtf8Incomplete(), writtenString);
      expect(buffer.length, 0);
    });
  });
}

Matcher _equalsUint8List(List<int> data) {
  return allOf(TypeMatcher<Uint8List>(), equals(data));
}

List<int> _range(int from, int to) {
  return List<int>.generate(to - from + 1, (i) => (from + i) % 256);
}
