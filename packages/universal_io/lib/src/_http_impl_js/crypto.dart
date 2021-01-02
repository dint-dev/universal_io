// ------------------------------------------------------------------
// THIS FILE WAS DERIVED FROM SOURCE CODE UNDER THE FOLLOWING LICENSE
// ------------------------------------------------------------------
//
// Copyright 2012, the Dart project authors. All rights reserved.
// Redistribution and use in source and binary forms, with or without
// modification, are permitted provided that the following conditions are
// met:
//     * Redistributions of source code must retain the above copyright
//       notice, this list of conditions and the following disclaimer.
//     * Redistributions in binary form must reproduce the above
//       copyright notice, this list of conditions and the following
//       disclaimer in the documentation and/or other materials provided
//       with the distribution.
//     * Neither the name of Google Inc. nor the names of its
//       contributors may be used to endorse or promote products derived
//       from this software without specific prior written permission.
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
// A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
// OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
// SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
// LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
// DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
// THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
// (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
// OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
// ---------------------------------------------------------
// THIS, DERIVED FILE IS LICENSE UNDER THE FOLLOWING LICENSE
// ---------------------------------------------------------
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

part of universal_io.http;

class _CryptoUtils {
  static const int PAD = 61; // '='
  static const int CR = 13; // '\r'
  static const int LF = 10; // '\n'
  static const int LINE_LENGTH = 76;

  static const String _encodeTable =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';

  static const String _encodeTableUrlSafe =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_';

  // Lookup table used for finding Base 64 alphabet index of a given byte.
  // -2 : Outside Base 64 alphabet.
  // -1 : '\r' or '\n'
  //  0 : = (Padding character).
  // >0 : Base 64 alphabet index of given byte.
  static const List<int> _decodeTable = [
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -1, -2, -2, -1, -2, -2, //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, 62, -2, 62, -2, 63, //
    52, 53, 54, 55, 56, 57, 58, 59, 60, 61, -2, -2, -2, 00, -2, -2, //
    -2, 00, 01, 02, 03, 04, 05, 06, 07, 08, 09, 10, 11, 12, 13, 14, //
    15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, -2, -2, -2, -2, 63, //
    -2, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, 37, 38, 39, 40, //
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50, 51, -2, -2, -2, -2, -2, //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, //
    -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2, -2
  ];

  static final Random _rng = Random.secure();

  static List<int> base64StringToBytes(String input,
      [bool ignoreInvalidCharacters = true]) {
    var len = input.length;
    if (len == 0) {
      return <int>[];
    }

    // Count '\r', '\n' and illegal characters, For illegal characters,
    // if [ignoreInvalidCharacters] is false, throw an exception.
    var extrasLen = 0;
    for (var i = 0; i < len; i++) {
      var c = _decodeTable[input.codeUnitAt(i)];
      if (c < 0) {
        extrasLen++;
        if (c == -2 && !ignoreInvalidCharacters) {
          throw FormatException('Invalid character: ${input[i]}');
        }
      }
    }

    if ((len - extrasLen) % 4 != 0) {
      throw FormatException('''Size of Base 64 characters in Input
          must be a multiple of 4. Input: $input''');
    }

    // Count pad characters, ignore illegal characters at the end.
    var padLength = 0;
    for (var i = len - 1; i >= 0; i--) {
      var currentCodeUnit = input.codeUnitAt(i);
      if (_decodeTable[currentCodeUnit] > 0) break;
      if (currentCodeUnit == PAD) padLength++;
    }
    var outputLen = (((len - extrasLen) * 6) >> 3) - padLength;
    var out = List<int>.filled(outputLen, 0);

    for (var i = 0, o = 0; o < outputLen;) {
      // Accumulate 4 valid 6 bit Base 64 characters into an int.
      var x = 0;
      for (var j = 4; j > 0;) {
        var c = _decodeTable[input.codeUnitAt(i++)];
        if (c >= 0) {
          x = ((x << 6) & 0xFFFFFF) | c;
          j--;
        }
      }
      out[o++] = x >> 16;
      if (o < outputLen) {
        out[o++] = (x >> 8) & 0xFF;
        if (o < outputLen) out[o++] = x & 0xFF;
      }
    }
    return out;
  }

  static String bytesToBase64(List<int> bytes,
      [bool urlSafe = false, bool addLineSeparator = false]) {
    var len = bytes.length;
    if (len == 0) {
      return '';
    }
    final lookup = urlSafe ? _encodeTableUrlSafe : _encodeTable;
    // Size of 24 bit chunks.
    final remainderLength = len.remainder(3);
    final chunkLength = len - remainderLength;
    // Size of base output.
    var outputLen = ((len ~/ 3) * 4) + ((remainderLength > 0) ? 4 : 0);
    // Add extra for line separators.
    if (addLineSeparator) {
      outputLen += ((outputLen - 1) ~/ LINE_LENGTH) << 1;
    }
    var out = Uint8List(outputLen);

    // Encode 24 bit chunks.
    var j = 0, i = 0, c = 0;
    while (i < chunkLength) {
      var x = ((bytes[i++] << 16) & 0xFFFFFF) |
          ((bytes[i++] << 8) & 0xFFFFFF) |
          bytes[i++];
      out[j++] = lookup.codeUnitAt(x >> 18);
      out[j++] = lookup.codeUnitAt((x >> 12) & 0x3F);
      out[j++] = lookup.codeUnitAt((x >> 6) & 0x3F);
      out[j++] = lookup.codeUnitAt(x & 0x3f);
      // Add optional line separator for each 76 char output.
      if (addLineSeparator && ++c == 19 && j < outputLen - 2) {
        out[j++] = CR;
        out[j++] = LF;
        c = 0;
      }
    }

    // If input length if not a multiple of 3, encode remaining bytes and
    // add padding.
    if (remainderLength == 1) {
      var x = bytes[i];
      out[j++] = lookup.codeUnitAt(x >> 2);
      out[j++] = lookup.codeUnitAt((x << 4) & 0x3F);
      out[j++] = PAD;
      out[j++] = PAD;
    } else if (remainderLength == 2) {
      var x = bytes[i];
      var y = bytes[i + 1];
      out[j++] = lookup.codeUnitAt(x >> 2);
      out[j++] = lookup.codeUnitAt(((x << 4) | (y >> 4)) & 0x3F);
      out[j++] = lookup.codeUnitAt((y << 2) & 0x3F);
      out[j++] = PAD;
    }

    return String.fromCharCodes(out);
  }

  static String bytesToHex(List<int> bytes) {
    var result = StringBuffer();
    for (var part in bytes) {
      result.write('${part < 16 ? '0' : ''}${part.toRadixString(16)}');
    }
    return result.toString();
  }

  static Uint8List getRandomBytes(int count) {
    final result = Uint8List(count);
    for (var i = 0; i < count; i++) {
      result[i] = _rng.nextInt(0xff);
    }
    return result;
  }
}
