import 'dart:typed_data';

/// Parses IPv4/IPv6 address.
List<int> parseIp(String source) {
  if (source == null) {
    throw ArgumentError.notNull();
  }
  // Find first '.' or ':'
  for (var i = 0; i < source.length; i++) {
    final c = source.substring(i, i + 1);
    switch (c) {
      case ":":
        return _parseIp6(source);
      case ".":
        return _parseIp4(source);
    }
  }
  // Not an IP address
  return throw ArgumentError.value(source, "source");
}

/// Parses IPv4 addresses such as "127.0.0.1"
List<int> _parseIp4(String source) {
  final bytes = source.split(".").map((number) => int.parse(number)).toList();
  if (bytes.length != 4) {
    throw ArgumentError.value(source);
  }
  return bytes;
}

/// Parses IPv6 addresses such as:
///    * "::"
///    * "1::2"
///    * "1:2:3:4:5:6:7:8"
///    * "0123:4567:89AB:CDEF:0123:4567:89AB:CDEF"
List<int> _parseIp6(String source) {
  final result = Uint8List(16);

  // Find '::' (a shorthand for a sequence of zeroes)
  final middle = source.indexOf("::");

  // Declare prefix and suffix
  List<String> prefixParts = const <String>[];
  List<String> suffixParts = const <String>[];

  // Determine prefix and suffix
  if (middle < 0) {
    // No '::'.
    // The prefix will contain the whole address.
    prefixParts = source.split(":");
  } else {
    // Do we have characters before '::'?
    if (middle != 0) {
      prefixParts = source.substring(0, middle).split(":");
    }
    // Do we have characters after '::'?
    if (middle + 2 != source.length) {
      suffixParts = source.substring(middle + 2).split(":");
    }
  }
  if (prefixParts.length + suffixParts.length > 8) {
    throw ArgumentError.value(source, "source", "too many numbers");
  }

  // Parse hex groups (max 2 bytes each) before '::'
  var i = 0;
  for (var item in prefixParts) {
    // Try to set two bytes
    try {
      var parsed = int.parse(item, radix: 16);
      result[i] = parsed >> 8;
      result[i + 1] = 0xFF & parsed;
    } catch (e) {
      throw ArgumentError.value(source, "source", "problem with '$item'");
    }

    // Increment byte index.
    i += 2;
  }

  // Parse hex groups (max 2 bytes each) after '::'
  i = 16 - suffixParts.length * 2;
  for (var item in suffixParts) {
    // Try to set two bytes
    try {
      var parsed = int.parse(item, radix: 16);
      result[i] = parsed >> 8;
      result[i + 1] = 0xFF & parsed;
    } catch (e) {
      throw ArgumentError.value(source, "source", "problem with '$item'");
    }

    // Increment byte index.
    i += 2;
  }

  // That's
  return result;
}

String stringFromIp(List<int> bytes) {
  if (bytes == null) {
    throw ArgumentError.notNull();
  }
  switch (bytes.length) {
    case 4:
      return bytes.map((item) => item.toString()).join(".");
    case 16:
      return _stringFromIp6(bytes);
    default:
      throw ArgumentError.value(bytes);
  }
}

String _stringFromIp6(List<int> bytes) {
  // ---------------------------
  // Find longest span of zeroes
  // ---------------------------

  // Longest seen span
  int longestStart;
  int longestLength = 0;

  // Current span
  int start;
  int length = 0;

  // Iterate
  for (var i = 0; i < 16; i++) {
    if (bytes[i] == 0) {
      // Zero byte
      if (start == null) {
        if (i % 2 == 0) {
          // First byte of a span
          start = i;
          length = 1;
        }
      } else {
        length++;
      }
    } else if (start != null) {
      // End of a span
      if (length > longestLength) {
        // Longest so far
        longestStart = start;
        longestLength = length;
      }
      start = null;
    }
  }
  if (start != null && length > longestLength) {
    // End of the longest span
    longestStart = start;
    longestLength = length;
  }

  // Longest length must be a whole group
  longestLength -= longestLength % 2;

  // Ignore longest zero span if it's less than 4 bytes.
  if (longestLength < 4) {
    longestStart = null;
  }

  // ----
  // Print
  // -----
  final sb = StringBuffer();
  var colon = false;
  for (var i = 0; i < 16; i++) {
    if (i == longestStart) {
      sb.write("::");
      i += longestLength - 1;
      colon = false;
      continue;
    }
    final byte = bytes[i];
    if (i % 2 == 0) {
      //
      // First byte of a group
      //
      if (colon) {
        sb.write(":");
      } else {
        colon = true;
      }
      if (byte != 0) {
        sb.write(byte.toRadixString(16));
      }
    } else {
      //
      // Second byte of a group
      //
      // If this is a single-digit number and the previous byte was non-zero,
      // we must add zero
      if (byte < 16 && bytes[i - 1] != 0) {
        sb.write("0");
      }
      sb.write(byte.toRadixString(16));
    }
  }
  return sb.toString();
}
