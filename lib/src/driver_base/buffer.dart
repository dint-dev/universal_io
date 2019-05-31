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

import 'dart:typed_data';

import 'package:raw/raw.dart';

/// Buffer is a helper for buffering data.
class Buffer {
  RawWriter _receivingBuffer = RawWriter.withCapacity(128);

  /// Returns the number of bytes available for reading.
  int get length => _receivingBuffer.length;

  /// Removes the buffer from memory.
  void close() {
    _receivingBuffer = null;
  }

  /// Reads the specified amount of bytes from the buffer.
  /// If the length is `null`, reads all bytes.
  List<int> read([int len]) {
    final writer = this._receivingBuffer;
    final bytes = writer.toUint8ListView();
    if (len == null || len == writer.length) {
      this._receivingBuffer = RawWriter.withCapacity(64);
      return bytes;
    }
    final result = Uint8List.view(
      bytes.buffer,
      bytes.offsetInBytes,
      len,
    );
    final remaining = Uint8List.view(
      bytes.buffer,
      bytes.offsetInBytes + len,
    );
    this._receivingBuffer = RawWriter.withUint8List(remaining);
    return result;
  }

  /// Writes bytes to the buffer.
  int write(List<int> data, [int index = 0, int length]) {
    _receivingBuffer.writeBytes(data, index, length);
    return length ?? data.length;
  }
}
