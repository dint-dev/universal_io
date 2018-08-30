// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of universal_io;

/**
 * Base class for all IO related exceptions.
 */
abstract class IOException implements Exception {
  String toString() => "IOException";
}

/**
 * An [OSError] object holds information about an error from the
 * operating system.
 */
class OSError {
  /** Constant used to indicate that no OS error code is available. */
  static const int noErrorCode = -1;

  /// Error message supplied by the operating system. This may be `null` or
  /// empty if no message is associated with the error.
  final String message;

  /// Error code supplied by the operating system.
  ///
  /// Will have the value [OSError.noErrorCode] if there is no error code
  /// associated with the error.
  final int errorCode;

  /** Creates an OSError object from a message and an errorCode. */
  @pragma("vm:entry-point")
  const OSError([this.message = "", this.errorCode = noErrorCode]);

  /** Converts an OSError object to a string representation. */
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write("OS Error");
    if (!message.isEmpty) {
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
