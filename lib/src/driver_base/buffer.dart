import 'dart:typed_data';

class Buffer {
  int _start = 0;
  int _length = 0;
  Uint8List _buffer;

  int get length => _length;

  Uint8List read([int len]) {
    final availableLength = this._length;
    if (len == null) {
      len = this._length;
    } else if (len > availableLength) {
      len = availableLength;
    }
    final data = this._buffer;
    final result = Uint8List.view(
      data.buffer,
      data.offsetInBytes + _start,
      len,
    );
    this._start += len;
    this._length = availableLength - len;
    return result;
  }

  void write(List<int> written) {
    final writtenLength = written.length;
    if (writtenLength == 0) {
      return;
    }

    // Increment length
    final oldLength = this._length;
    final newLength = oldLength + writtenLength;
    this._length = newLength;

    //
    final oldBuffer = this._buffer;
    var newBuffer = oldBuffer;
    var start = this._start;
    if (oldBuffer == null) {
      // Allocate list for exactly N bytes
      this._buffer = Uint8List.fromList(written);
      this._length = writtenLength;
      return;
    } else if (oldBuffer.lengthInBytes - start < newLength) {
      // Find a big enough power of two
      var newCapacity = 32;
      while (newCapacity < newLength) {
        newCapacity *= 2;
      }

      // Move bytes
      newBuffer = Uint8List(newCapacity);
      for (var i = 0; i < oldLength; i++) {
        newBuffer[i] = oldBuffer[start + i];
      }
      start = 0;
      this._buffer = newBuffer;
      this._start = 0;
    }
    for (var i = 0; i < writtenLength; i++) {
      newBuffer[start + i] = written[i];
    }
  }
}
