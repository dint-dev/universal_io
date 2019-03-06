import 'dart:async';
import 'dart:convert';

import 'all.dart';
import '../common.dart';

abstract class Process {
  Future<int> get exitCode;

  int get pid;

  Stream<List<int>> get stderr;

  IOSink get stdin;

  Stream<List<int>> get stdout;

  bool kill([ProcessSignal signal = ProcessSignal.sigterm]);

  static bool killPid(int pid, [ProcessSignal signal = ProcessSignal.sigterm]) {
    return false;
  }

  ProcessResult runSync(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding}) {
    return IODriver.current.runSync(
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
    return IODriver.current.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      environment: environment,
      includeParentEnvironment: includeParentEnvironment,
      runInShell: runInShell,
    );
  }

  static Future<ProcessResult> run(String executable, List<String> arguments,
      {String workingDirectory,
      Map<String, String> environment,
      bool includeParentEnvironment = true,
      bool runInShell = false,
      Encoding stdoutEncoding = systemEncoding,
      Encoding stderrEncoding = systemEncoding}) {
    return IODriver.current.run(
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

class ProcessResult {
  final int exitCode;
  final int pid;
  final dynamic stderr;
  final dynamic stdout;

  ProcessResult(this.pid, this.exitCode, this.stdout, this.stderr);
}

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
  static const ProcessSignal sigpipe = ProcessSignal._(13, "SIGKPIPE");
  static const ProcessSignal sigalrm = ProcessSignal._(14, "SIGALRM");
  static const ProcessSignal sigterm = ProcessSignal._(15, "SIGTERM");
  static const ProcessSignal sigpoll = ProcessSignal._(29, "SIGKPOLL");
  static const ProcessSignal sigprof = ProcessSignal._(27, "SIGKPROF");
  static const ProcessSignal sigsys = ProcessSignal._(31, "SIGSYS");

  final int _id;
  final String _name;

  const ProcessSignal._(this._id, this._name);

  @override
  int get hashCode => _id;

  @override
  String toString() => _name;
}

enum ProcessStartMode {
  detached,
  detachedWithStdio,
  inheritStdio,
  normal,
}
