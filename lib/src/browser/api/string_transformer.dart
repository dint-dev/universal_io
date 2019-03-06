import 'dart:convert';

/// The current system encoding.
///
/// This is used for converting from bytes to and from Strings when
/// communicating on stdin, stdout and stderr.
///
/// On Windows this will use the currently active code page for the conversion.
/// On all other systems it will always use UTF-8.
const SystemEncoding systemEncoding = SystemEncoding();

/// The system encoding is the current code page on Windows and UTF-8 on Linux
/// and Mac.
class SystemEncoding extends Encoding {
  /// Creates a const SystemEncoding.
  ///
  /// Users should use the top-level constant, [systemEncoding].
  const SystemEncoding();

  String get name => 'system';

  List<int> encode(String input) => encoder.convert(input);

  String decode(List<int> encoded) => decoder.convert(encoded);

  Converter<String, List<int>> get encoder {
    return const Utf8Encoder();
  }

  Converter<List<int>, String> get decoder {
    return const Utf8Decoder();
  }
}
