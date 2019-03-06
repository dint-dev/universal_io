/// Base class for all IO related exceptions.
abstract class IOException implements Exception {
  String toString() => "IOException";
}

/// An [OSError] object holds information about an error from the
/// operating system.
class OSError {
  /// Constant used to indicate that no OS error code is available.
  static const int noErrorCode = -1;

  /// Error message supplied by the operating system. This may be `null` or
  /// empty if no message is associated with the error.
  final String message;

  /// Error code supplied by the operating system.
  ///
  /// Will have the value [OSError.noErrorCode] if there is no error code
  /// associated with the error.
  final int errorCode;

  /// Creates an OSError object from a message and an errorCode.
  @pragma("vm:entry-point")
  const OSError([this.message = "", this.errorCode = noErrorCode]);

  /// Converts an OSError object to a string representation.
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write("OS Error");
    if (message.isNotEmpty) {
      sb..write(": ")..write(message);
      if (errorCode != noErrorCode) {
        sb..write(", errno = ")..write(errorCode.toString());
      }
    } else if (errorCode != noErrorCode) {
      sb..write(": errno = ")..write(errorCode.toString());
    }
    return sb.toString();
  }
}
