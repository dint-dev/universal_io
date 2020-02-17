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

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

/// This was implemented because classes in 'package:typed_data/buffer.dart' are
/// append-only.
class Uint8ListBuffer implements Sink<List<int>>, StreamConsumer<List<int>> {
  final Uint8List _empty = Uint8List(0);
  int _start = 0;
  int _length = 0;
  Uint8List _buffer;

  bool _isClosed = false;

  int get length => _length;

  /// Writes bytes in the queue.
  ///
  /// If the [copyNotNeeded] is true, the buffer may optimize operation by
  /// not copying the input.
  @override
  void add(List<int> input, {bool copyNotNeeded = false}) {
    if (_isClosed) {
      throw StateError('close() has been invoked');
    }
    final inputLength = input.length;
    if (inputLength == 0) {
      return;
    }

    // Is this the first write?
    var buffer = _buffer;
    if (buffer == null) {
      if (copyNotNeeded && input is Uint8List) {
        _buffer = input;
      } else {
        _buffer = Uint8List.fromList(input);
      }
      _start = 0;
      _length = input.length;
      return;
    }

    // Do we need to expand the buffer?
    var start = _start;
    final oldLength = _length;
    final newLength = oldLength + inputLength;
    if (buffer.lengthInBytes < start + newLength) {
      // Choose a big enough capacity
      // (that's a power of two)
      var newCapacity = 32;
      while (newCapacity < newLength) {
        newCapacity *= 2;
      }

      // Copy bytes
      final newBuffer = Uint8List(newCapacity);
      for (var i = 0; i < oldLength; i++) {
        newBuffer[i] = buffer[start + i];
      }

      // Update variables/fields
      buffer = newBuffer;
      start = 0;
      _buffer = buffer;
      _start = start;
    }
    _length = newLength;

    final oldEnd = start + oldLength;
    for (var i = 0; i < inputLength; i++) {
      buffer[oldEnd + i] = input[i];
    }
  }

  @override
  Future addStream(Stream<List> stream) async {
    await for (var chunk in stream) {
      add(chunk);
    }
  }

  @override
  Future close() {
    _isClosed = true;
    return Future.value();
  }

  /// Returns the first position of the byte, starting at [start] (inclusive).
  /// Returns -1 if the byte is not found.
  int indexOfByte(int input, [start = 0]) {
    final buffer = _buffer;
    final start = _start;
    final end = start + _length;
    if (start >= end) {
      throw ArgumentError.value(
          start, 'start', 'Buffer has only $_length bytes');
    }
    for (var i = start; i < end; i++) {
      if (buffer[i] == input) {
        return i - start;
      }
    }
    return -1;
  }

  /// Returns the last position of the byte, starting at [start] (inclusive, null
  /// means length-1). Returns -1 if the byte is not found.
  int lastIndexOfByte(int input, [int start]) {
    final buffer = _buffer;
    final bufferStart = _start;
    if (start == null) {
      start = _length - 1;
    } else if (start >= _length) {
      throw ArgumentError.value(
          start, 'start', 'Buffer has only $_length bytes');
    }
    for (var i = bufferStart + start; i >= bufferStart; i--) {
      if (buffer[i] == input) {
        return i - bufferStart;
      }
    }
    return -1;
  }

  bool startsWith(List<int> input, [int start = 0]) {
    if (start + input.length > _length) {
      return false;
    }
    final buffer = _buffer;
    final bufferStart = _start + 1;
    for (var i = 0; i < input.length; i++) {
      if (buffer[bufferStart + i] != input[i]) {
        return false;
      }
    }
    return true;
  }

  /// Removes bytes from the beginning of the buffer and returns them.
  ///
  /// Optional argument [maxLength] defines the maximum length of the returned list.
  /// If it's null, all written bytes will be removed.
  ///
  /// If [maxLength] is greater than available bytes, the method
  /// returns only the available bytes.
  ///
  /// If [preview] is true, the method will keep the bytes in the buffer.
  Uint8List read({int maxLength, preview = false}) {
    final availableLength = _length;
    if (availableLength == 0 || maxLength == 0) {
      return _empty;
    }
    var length = availableLength;
    if (maxLength != null && maxLength < length) {
      length = maxLength;
    }
    final start = _start;
    if (!preview) {
      _start = start + length;
      _length = availableLength - length;
    }
    final data = _buffer;
    if (length == data.length) {
      if (!preview) {
        _buffer = null;
      }
      return data;
    }
    final result = Uint8List.view(
      data.buffer,
      data.offsetInBytes + start,
      length,
    );
    return result;
  }

  /// Reads an UTF-8 string.
  ///
  /// The method will throw [FormatException] if the content is not valid UTF-8.
  String readUtf8({bool preview = false}) {
    final start = _start;
    final length = _length;
    final result = const Utf8Decoder().convert(_buffer, start, start + length);
    if (!preview) {
      _start = start + length;
      _length = 0;
    }
    return result;
  }

  /// Reads an UTF-8 string. A possible incomplete UTF-8 rune in the end of the
  /// buffer will be left in the buffer.
  ///
  /// The method will throw [FormatException] if the content is not valid UTF-8.
  String readUtf8Incomplete({int maxLengthInBytes, bool preview = false}) {
    var availableLength = _length;
    if (availableLength == 0) {
      return '';
    }
    if (maxLengthInBytes != null && maxLengthInBytes < availableLength) {
      availableLength = maxLengthInBytes;
    }
    final start = _start;
    final incompleteRuneLength = _lengthOfIncompleteUtf8Rune(
      _buffer,
      start,
      start + availableLength,
    );
    if (incompleteRuneLength == availableLength) {
      return '';
    }
    final end = start + availableLength - incompleteRuneLength;
    final result = const Utf8Decoder().convert(_buffer, start, end);
    if (!preview) {
      discard(end - start);
    }
    return result;
  }

  /// Discards N first bytes.
  void discard(int n) {
    _start += n;
    _length -= n;
  }

  /// Returns length for UTF-8 decoder. If bytes end with the an incomplete
  /// UTF-8 rune (e.g. only two bytes of three-byte rune), subtracts it from the
  /// length.
  static int _lengthOfIncompleteUtf8Rune(List<int> buffer,
      [int start, int end]) {
    assert(start >= 0);
    assert(end <= buffer.length);
    end ??= buffer.length;
    for (var i = 1; i < 5; i++) {
      final byteIndex = end - i;
      if (byteIndex < start) {
        return end - start;
      }
      final byte = buffer[byteIndex];
      final runeLength = _utf8RuneLengthFromFirstByte(byte);
      if (runeLength == 0) {
        // Not a rune start
        continue;
      }
      if (runeLength == i) {
        // The buffer ends with a complete rune
        return 0;
      }
      if (runeLength < 0) {
        // Invalid
        return 0;
      }
      // The buffer ends with an incomplete rune
      return i;
    }
    // The buffer ends with non-UTF8 content
    return 0;
  }

  static int _utf8RuneLengthFromFirstByte(int byte) {
    if (0x80 & byte == 0) {
      return 1;
    }
    if (0x40 & byte == 0) {
      return 0;
    }
    if (0x20 & byte == 0) {
      return 2;
    }
    if (0x10 & byte == 0) {
      return 3;
    }
    if (0x08 & byte == 0) {
      return 4;
    }
    return -1;
  }
}
