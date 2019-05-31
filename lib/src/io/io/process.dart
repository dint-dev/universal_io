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

import 'dart:async';
import 'dart:convert';

import 'package:universal_io/src/driver/drivers_in_js.dart';

import '../io.dart';

int _exitCode = 0;

/// Get the global exit code for the Dart VM.
///
/// The exit code is global for the Dart VM and the last assignment to
/// exitCode from any isolate determines the exit code of the Dart VM
/// on normal termination.
///
/// See [exit] for more information on how to chose a value for the
/// exit code.
int get exitCode => _exitCode;

/// Set the global exit code for the Dart VM.
///
/// The exit code is global for the Dart VM and the last assignment to
/// exitCode from any isolate determines the exit code of the Dart VM
/// on normal termination.
///
/// Default value is `0`.
///
/// See [exit] for more information on how to chose a value for the
/// exit code.
set exitCode(int code) {
  if (code is! int) {
    throw ArgumentError("Integer value for exit code expected");
  }
  _exitCode = code;
}

/// Returns the PID of the current process.
int get pid => 0;

/// Exit the Dart VM process immediately with the given exit code.
///
/// This does not wait for any asynchronous operations to terminate. Using
/// [exit] is therefore very likely to lose data.
///
/// The handling of exit codes is platform specific.
///
/// On Linux and OS X an exit code for normal termination will always
/// be in the range [0..255]. If an exit code outside this range is
/// set the actual exit code will be the lower 8 bits masked off and
/// treated as an unsigned value. E.g. using an exit code of -1 will
/// result in an actual exit code of 255 being reported.
///
/// On Windows the exit code can be set to any 32-bit value. However
/// some of these values are reserved for reporting system errors like
/// crashes.
///
/// Besides this the Dart executable itself uses an exit code of `254`
/// for reporting compile time errors and an exit code of `255` for
/// reporting runtime error (unhandled exception).
///
/// Due to these facts it is recommended to only use exit codes in the
/// range [0..127] for communicating the result of running a Dart
/// program to the surrounding environment. This will avoid any
/// cross-platform issues.
void exit(int code) {
  if (code is! int) {
    throw ArgumentError("Integer value for exit code expected");
  }
  throw UnsupportedError("This embedder disallows calling dart:io's exit()");
}

/// Sleep for the duration specified in [duration].
///
/// Use this with care, as no asynchronous operations can be processed
/// in a isolate while it is blocked in a [sleep] call.
void sleep(Duration duration) {
  int milliseconds = duration.inMilliseconds;
  if (milliseconds < 0) {
    throw ArgumentError("sleep: duration cannot be negative");
  }
}

abstract class Process {
  Future<int> get exitCode;
  int get pid;
  Stream<List<int>> get stderr;
  IOSink get stdin;
  Stream<List<int>> get stdout;

  bool kill([ProcessSignal signal = ProcessSignal.sigterm]);

  ProcessResult runSync(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding}) {
    return ProcessDriver.current.runSync(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );
  }

  Future<Process> start(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      ProcessStartMode mode = ProcessStartMode.normal}) {
    return ProcessDriver.current.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
    );
  }

  static bool killPid(int pid, [ProcessSignal signal = ProcessSignal.sigterm]) {
    return false;
  }

  static Future<ProcessResult> run(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding}) {
    return ProcessDriver.current.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
      stdoutEncoding: stdoutEncoding,
      stderrEncoding: stderrEncoding,
    );
  }
}

class ProcessException implements IOException {
  /// Contains the executable provided for the process.
  final String executable;

  /// Contains the arguments provided for the process.
  final List<String> arguments;

  /// Contains the system message for the process exception if any.
  final String message;

  /// Contains the OS error code for the process exception if any.
  final int errorCode;

  const ProcessException(this.executable, this.arguments,
      [this.message = "", this.errorCode = 0]);
  String toString() {
    var msg = (message == null) ? 'OS error code: $errorCode' : message;
    var args = arguments.join(' ');
    return "ProcessException: $msg\n  Command: $executable $args";
  }
}

/// [ProcessInfo] provides methods for retrieving information about the
/// current process.
class ProcessInfo {
  /// The current resident set size of memory for the process.
  ///
  /// Note that the meaning of this field is platform dependent. For example,
  /// some memory accounted for here may be shared with other processes, or if
  /// the same page is mapped into a process's address space, it may be counted
  /// twice.
  static int get currentRss => throw UnimplementedError();

  /// The high-watermark in bytes for the resident set size of memory for the
  /// process.
  ///
  /// Note that the meaning of this field is platform dependent. For example,
  /// some memory accounted for here may be shared with other processes, or if
  /// the same page is mapped into a process's address space, it may be counted
  /// twice.
  static int get maxRss => throw UnimplementedError();
}

/// [ProcessResult] represents the result of running a non-interactive
/// process started with [Process.run] or [Process.runSync].
class ProcessResult {
  /// Exit code for the process.
  ///
  /// See [Process.exitCode] for more information in the exit code
  /// value.
  final int exitCode;

  /// Standard output from the process. The value used for the
  /// `stdoutEncoding` argument to `Process.run` determines the type. If
  /// `null` was used this value is of type `List<int>` otherwise it is
  /// of type `String`.
  final stdout;

  /// Standard error from the process. The value used for the
  /// `stderrEncoding` argument to `Process.run` determines the type. If
  /// `null` was used this value is of type `List<int>`
  /// otherwise it is of type `String`.
  final stderr;

  /// Process id of the process.
  final int pid;

  ProcessResult(this.pid, this.exitCode, this.stdout, this.stderr);
}

/// On Posix systems, [ProcessSignal] is used to send a specific signal
/// to a child process, see [:Process.kill:].
///
/// Some [ProcessSignal]s can also be watched, as a way to intercept the default
/// signal handler and implement another. See [ProcessSignal.watch] for more
/// information.
class ProcessSignal {
  static const ProcessSignal sighup = ProcessSignal._(1, "SIGHUP");
  static const ProcessSignal sigint = ProcessSignal._(2, "SIGINT");
  static const ProcessSignal sigquit = ProcessSignal._(3, "SIGQUIT");
  static const ProcessSignal sigill = ProcessSignal._(4, "SIGILL");
  static const ProcessSignal sigtrap = ProcessSignal._(5, "SIGTRAP");
  static const ProcessSignal sigabrt = ProcessSignal._(6, "SIGABRT");
  static const ProcessSignal sigbus = ProcessSignal._(7, "SIGBUS");
  static const ProcessSignal sigfpe = ProcessSignal._(8, "SIGFPE");
  static const ProcessSignal sigkill = ProcessSignal._(9, "SIGKILL");
  static const ProcessSignal sigusr1 = ProcessSignal._(10, "SIGUSR1");
  static const ProcessSignal sigsegv = ProcessSignal._(11, "SIGSEGV");
  static const ProcessSignal sigusr2 = ProcessSignal._(12, "SIGUSR2");
  static const ProcessSignal sigpipe = ProcessSignal._(13, "SIGPIPE");
  static const ProcessSignal sigalrm = ProcessSignal._(14, "SIGALRM");
  static const ProcessSignal sigterm = ProcessSignal._(15, "SIGTERM");
  static const ProcessSignal sigchld = ProcessSignal._(17, "SIGCHLD");
  static const ProcessSignal sigcont = ProcessSignal._(18, "SIGCONT");
  static const ProcessSignal sigstop = ProcessSignal._(19, "SIGSTOP");
  static const ProcessSignal sigtstp = ProcessSignal._(20, "SIGTSTP");
  static const ProcessSignal sigttin = ProcessSignal._(21, "SIGTTIN");
  static const ProcessSignal sigttou = ProcessSignal._(22, "SIGTTOU");
  static const ProcessSignal sigurg = ProcessSignal._(23, "SIGURG");
  static const ProcessSignal sigxcpu = ProcessSignal._(24, "SIGXCPU");
  static const ProcessSignal sigxfsz = ProcessSignal._(25, "SIGXFSZ");
  static const ProcessSignal sigvtalrm = ProcessSignal._(26, "SIGVTALRM");
  static const ProcessSignal sigprof = ProcessSignal._(27, "SIGPROF");
  static const ProcessSignal sigwinch = ProcessSignal._(28, "SIGWINCH");
  static const ProcessSignal sigpoll = ProcessSignal._(29, "SIGPOLL");
  static const ProcessSignal sigsys = ProcessSignal._(31, "SIGSYS");

  @Deprecated("Use sighup instead")
  static const ProcessSignal SIGHUP = sighup;
  @Deprecated("Use sigint instead")
  static const ProcessSignal SIGINT = sigint;
  @Deprecated("Use sigquit instead")
  static const ProcessSignal SIGQUIT = sigquit;
  @Deprecated("Use sigill instead")
  static const ProcessSignal SIGILL = sigill;
  @Deprecated("Use sigtrap instead")
  static const ProcessSignal SIGTRAP = sigtrap;
  @Deprecated("Use sigabrt instead")
  static const ProcessSignal SIGABRT = sigabrt;
  @Deprecated("Use sigbus instead")
  static const ProcessSignal SIGBUS = sigbus;
  @Deprecated("Use sigfpe instead")
  static const ProcessSignal SIGFPE = sigfpe;
  @Deprecated("Use sigkill instead")
  static const ProcessSignal SIGKILL = sigkill;
  @Deprecated("Use sigusr1 instead")
  static const ProcessSignal SIGUSR1 = sigusr1;
  @Deprecated("Use sigsegv instead")
  static const ProcessSignal SIGSEGV = sigsegv;
  @Deprecated("Use sigusr2 instead")
  static const ProcessSignal SIGUSR2 = sigusr2;
  @Deprecated("Use sigpipe instead")
  static const ProcessSignal SIGPIPE = sigpipe;
  @Deprecated("Use sigalrm instead")
  static const ProcessSignal SIGALRM = sigalrm;
  @Deprecated("Use sigterm instead")
  static const ProcessSignal SIGTERM = sigterm;
  @Deprecated("Use sigchld instead")
  static const ProcessSignal SIGCHLD = sigchld;
  @Deprecated("Use sigcont instead")
  static const ProcessSignal SIGCONT = sigcont;
  @Deprecated("Use sigstop instead")
  static const ProcessSignal SIGSTOP = sigstop;
  @Deprecated("Use sigtstp instead")
  static const ProcessSignal SIGTSTP = sigtstp;
  @Deprecated("Use sigttin instead")
  static const ProcessSignal SIGTTIN = sigttin;
  @Deprecated("Use sigttou instead")
  static const ProcessSignal SIGTTOU = sigttou;
  @Deprecated("Use sigurg instead")
  static const ProcessSignal SIGURG = sigurg;
  @Deprecated("Use sigxcpu instead")
  static const ProcessSignal SIGXCPU = sigxcpu;
  @Deprecated("Use sigxfsz instead")
  static const ProcessSignal SIGXFSZ = sigxfsz;
  @Deprecated("Use sigvtalrm instead")
  static const ProcessSignal SIGVTALRM = sigvtalrm;
  @Deprecated("Use sigprof instead")
  static const ProcessSignal SIGPROF = sigprof;
  @Deprecated("Use sigwinch instead")
  static const ProcessSignal SIGWINCH = sigwinch;
  @Deprecated("Use sigpoll instead")
  static const ProcessSignal SIGPOLL = sigpoll;
  @Deprecated("Use sigsys instead")
  static const ProcessSignal SIGSYS = sigsys;

  final String _name;

  const ProcessSignal._(int signalNumber, this._name);

  String toString() => _name;

  /// Watch for process signals.
  ///
  /// The following [ProcessSignal]s can be listened to:
  ///
  ///   * [ProcessSignal.sighup].
  ///   * [ProcessSignal.sigint]. Signal sent by e.g. CTRL-C.
  ///   * [ProcessSignal.sigterm]. Not available on Windows.
  ///   * [ProcessSignal.sigusr1]. Not available on Windows.
  ///   * [ProcessSignal.sigusr2]. Not available on Windows.
  ///   * [ProcessSignal.sigwinch]. Not available on Windows.
  ///
  /// Other signals are disallowed, as they may be used by the VM.
  ///
  /// A signal can be watched multiple times, from multiple isolates, where all
  /// callbacks are invoked when signaled, in no specific order.
  Stream<ProcessSignal> watch() => Stream<ProcessSignal>.empty();
}

/// Modes for running a new process.
class ProcessStartMode {
  /// Normal child process.
  static const normal = ProcessStartMode._internal(0);
  @Deprecated("Use normal instead")
  static const NORMAL = normal;

  /// Stdio handles are inherited by the child process.
  static const inheritStdio = ProcessStartMode._internal(1);
  @Deprecated("Use inheritStdio instead")
  static const INHERIT_STDIO = inheritStdio;

  /// Detached child process with no open communication channel.
  static const detached = ProcessStartMode._internal(2);
  @Deprecated("Use detached instead")
  static const DETACHED = detached;

  /// Detached child process with stdin, stdout and stderr still open
  /// for communication with the child.
  static const detachedWithStdio = ProcessStartMode._internal(3);
  @Deprecated("Use detachedWithStdio instead")
  static const DETACHED_WITH_STDIO = detachedWithStdio;

  static List<ProcessStartMode> get values => const <ProcessStartMode>[
        normal,
        inheritStdio,
        detached,
        detachedWithStdio
      ];
  final int _mode;

  const ProcessStartMode._internal(this._mode);
  String toString() =>
      const ["normal", "inheritStdio", "detached", "detachedWithStdio"][_mode];
}

class SignalException implements IOException {
  final String message;
  final osError;

  const SignalException(this.message, [this.osError]);

  String toString() {
    var msg = "";
    if (osError != null) {
      msg = ", osError: $osError";
    }
    return "SignalException: $message$msg";
  }
}
