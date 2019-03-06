import 'dart:async';
import 'dart:convert';

import 'all.dart';
import '../common.dart';

/// [Stdin] allows both synchronous and asynchronous reads from the standard
/// input stream.
///
/// Mixing synchronous and asynchronous reads is undefined.
abstract class Stdin implements Stream<List<int>> {
  /// Read a line from stdin.
  ///
  /// Blocks until a full line is available.
  ///
  /// Lines my be terminated by either `<CR><LF>` or `<LF>`. On Windows in cases
  /// where the [stdioType] of stdin is [StdioType.termimal] the terminator may
  /// also be a single `<CR>`.
  ///
  /// Input bytes are converted to a string by [encoding].
  /// If [encoding] is omitted, it defaults to [systemEncoding].
  ///
  /// If [retainNewlines] is `false`, the returned String will not include the
  /// final line terminator. If `true`, the returned String will include the line
  /// terminator. Default is `false`.
  ///
  /// If end-of-file is reached after any bytes have been read from stdin,
  /// that data is returned without a line terminator.
  /// Returns `null` if no bytes preceded the end of input.
  String readLineSync(
      {Encoding encoding = systemEncoding, bool retainNewlines = false}) {
    const CR = 13;
    const LF = 10;
    final List<int> line = <int>[];
    // On Windows, if lineMode is disabled, only CR is received.
    bool crIsNewline = Platform.isWindows &&
        (stdioType(stdin) == StdioType.terminal) &&
        !lineMode;
    if (retainNewlines) {
      int byte;
      do {
        byte = readByteSync();
        if (byte < 0) {
          break;
        }
        line.add(byte);
      } while (byte != LF && !(byte == CR && crIsNewline));
      if (line.isEmpty) {
        return null;
      }
    } else if (crIsNewline) {
      // CR and LF are both line terminators, neither is retained.
      while (true) {
        int byte = readByteSync();
        if (byte < 0) {
          if (line.isEmpty) return null;
          break;
        }
        if (byte == LF || byte == CR) break;
        line.add(byte);
      }
    } else {
      // Case having to handle CR LF as a single unretained line terminator.
      outer:
      while (true) {
        int byte = readByteSync();
        if (byte == LF) break;
        if (byte == CR) {
          do {
            byte = readByteSync();
            if (byte == LF) break outer;

            line.add(CR);
          } while (byte == CR);
          // Fall through and handle non-CR character.
        }
        if (byte < 0) {
          if (line.isEmpty) return null;
          break;
        }
        line.add(byte);
      }
    }
    return encoding.decode(line);
  }

  /// Check if echo mode is enabled on [stdin].
  bool get echoMode;

  /// Enable or disable echo mode on [stdin].
  ///
  /// If disabled, input from to console will not be echoed.
  ///
  /// Default depends on the parent process, but usually enabled.
  ///
  /// On Windows this mode can only be enabled if [lineMode] is enabled as well.
  set echoMode(bool enabled);

  /// Check if line mode is enabled on [stdin].
  bool get lineMode;

  /// Enable or disable line mode on [stdin].
  ///
  /// If enabled, characters are delayed until a new-line character is entered.
  /// If disabled, characters will be available as typed.
  ///
  /// Default depends on the parent process, but usually enabled.
  ///
  /// On Windows this mode can only be disabled if [echoMode] is disabled as well.
  set lineMode(bool enabled);

  /// Whether connected to a terminal that supports ANSI escape sequences.
  ///
  /// Not all terminals are recognized, and not all recognized terminals can
  /// report whether they support ANSI escape sequences, so this value is a
  /// best-effort attempt at detecting the support.
  ///
  /// The actual escape sequence support may differ between terminals,
  /// with some terminals supporting more escape sequences than others,
  /// and some terminals even differing in behavior for the same escape
  /// sequence.
  ///
  /// The ANSI color selection is generally supported.
  ///
  /// Currently, a `TERM` environment variable containing the string `xterm`
  /// will be taken as evidence that ANSI escape sequences are supported.
  /// On Windows, only versions of Windows 10 after v.1511
  /// ("TH2", OS build 10586) will be detected as supporting the output of
  /// ANSI escape sequences, and only versions after v.1607 ("Anniversary
  /// Update", OS build 14393) will be detected as supporting the input of
  /// ANSI escape sequences.
  bool get supportsAnsiEscapes;

  /// Synchronously read a byte from stdin. This call will block until a byte is
  /// available.
  ///
  /// If at end of file, -1 is returned.
  int readByteSync();

  /// Returns true if there is a terminal attached to stdin.
  bool get hasTerminal {
    return false;
  }
}

/// [Stdout] represents the [IOSink] for either `stdout` or `stderr`.
///
/// It provides a *blocking* `IOSink`, so using this to write will block until
/// the output is written.
///
/// In some situations this blocking behavior is undesirable as it does not
/// provide the same non-blocking behavior as dart:io in general exposes.
/// Use the property [nonBlocking] to get an `IOSink` which has the non-blocking
/// behavior.
///
/// This class can also be used to check whether `stdout` or `stderr` is
/// connected to a terminal and query some terminal properties.
///
/// The [addError] API is inherited from  [StreamSink] and calling it will result
/// in an unhandled asynchronous error unless there is an error handler on
/// [done].
abstract class Stdout implements IOSink {
  /// Returns true if there is a terminal attached to stdout.
  bool get hasTerminal => false;

  /// Get the number of columns of the terminal.
  ///
  /// If no terminal is attached to stdout, a [StdoutException] is thrown. See
  /// [hasTerminal] for more info.
  int get terminalColumns {
    throw StdoutException("No terminal is attached");
  }

  /// Get the number of lines of the terminal.
  ///
  /// If no terminal is attached to stdout, a [StdoutException] is thrown. See
  /// [hasTerminal] for more info.
  int get terminalLines {
    throw StdoutException("No terminal is attached");
  }

  /// Whether connected to a terminal that supports ANSI escape sequences.
  ///
  /// Not all terminals are recognized, and not all recognized terminals can
  /// report whether they support ANSI escape sequences, so this value is a
  /// best-effort attempt at detecting the support.
  ///
  /// The actual escape sequence support may differ between terminals,
  /// with some terminals supporting more escape sequences than others,
  /// and some terminals even differing in behavior for the same escape
  /// sequence.
  ///
  /// The ANSI color selection is generally supported.
  ///
  /// Currently, a `TERM` environment variable containing the string `xterm`
  /// will be taken as evidence that ANSI escape sequences are supported.
  /// On Windows, only versions of Windows 10 after v.1511
  /// ("TH2", OS build 10586) will be detected as supporting the output of
  /// ANSI escape sequences, and only versions after v.1607 ("Anniversary
  /// Update", OS build 14393) will be detected as supporting the input of
  /// ANSI escape sequences.
  bool get supportsAnsiEscapes => false;

  /// Get a non-blocking `IOSink`.
  IOSink get nonBlocking;
}

class StdoutException implements IOException {
  final String message;
  final OSError osError;

  const StdoutException(this.message, [this.osError]);

  String toString() {
    return "StdoutException: $message${osError == null ? "" : ", $osError"}";
  }
}

class StdinException implements IOException {
  final String message;
  final OSError osError;

  const StdinException(this.message, [this.osError]);

  String toString() {
    return "StdinException: $message${osError == null ? "" : ", $osError"}";
  }
}

/// The type of object a standard IO stream is attached to.
class StdioType {
  static const StdioType terminal = StdioType._("terminal");
  static const StdioType pipe = StdioType._("pipe");
  static const StdioType file = StdioType._("file");
  static const StdioType other = StdioType._("other");

  @Deprecated("Use terminal instead")
  static const StdioType TERMINAL = terminal;
  @Deprecated("Use pipe instead")
  static const StdioType PIPE = pipe;
  @Deprecated("Use file instead")
  static const StdioType FILE = file;
  @Deprecated("Use other instead")
  static const StdioType OTHER = other;

  final String name;

  const StdioType._(this.name);

  String toString() => "StdioType: $name";
}

/// The standard input stream of data read by this program.
Stdin get stdin => IODriver.current.stdin;

/// The standard output stream of data written by this program.
///
/// The `addError` API is inherited from  `StreamSink` and calling it will
/// result in an unhandled asynchronous error unless there is an error handler
/// on `done`.
Stdout get stdout => IODriver.current.stdout;

/// The standard output stream of errors written by this program.
///
/// The `addError` API is inherited from  `StreamSink` and calling it will
/// result in an unhandled asynchronous error unless there is an error handler
/// on `done`.
Stdout get stderr => IODriver.current.stderr;

/// For a stream, returns whether it is attached to a file, pipe, terminal, or
/// something else.
StdioType stdioType(object) {
  return StdioType.other;
}
