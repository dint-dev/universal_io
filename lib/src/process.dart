part of universal_io;

const Encoding systemEncoding = utf8;

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
      bool includeParentEnvironment: true,
      bool runInShell: false,
      Encoding stdoutEncoding: systemEncoding,
      Encoding stderrEncoding: systemEncoding}) {
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
      bool includeParentEnvironment: true,
      bool runInShell: false,
      ProcessStartMode mode: ProcessStartMode.normal}) {
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
      bool includeParentEnvironment: true,
      bool runInShell: false,
      Encoding stdoutEncoding: systemEncoding,
      Encoding stderrEncoding: systemEncoding}) {
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
  static const ProcessSignal sighup = const ProcessSignal._(1, "SIGHUP");
  static const ProcessSignal sigint = const ProcessSignal._(2, "SIGINT");
  static const ProcessSignal sigquit = const ProcessSignal._(3, "SIGQUIT");
  static const ProcessSignal sigill = const ProcessSignal._(4, "SIGILL");
  static const ProcessSignal sigtrap = const ProcessSignal._(5, "SIGTRAP");
  static const ProcessSignal sigabrt = const ProcessSignal._(6, "SIGABRT");
  static const ProcessSignal sigbus = const ProcessSignal._(7, "SIGBUS");
  static const ProcessSignal sigfpe = const ProcessSignal._(8, "SIGFPE");
  static const ProcessSignal sigkill = const ProcessSignal._(9, "SIGKILL");
  static const ProcessSignal sigusr1 = const ProcessSignal._(10, "SIGUSR1");
  static const ProcessSignal sigsegv = const ProcessSignal._(11, "SIGSEGV");
  static const ProcessSignal sigusr2 = const ProcessSignal._(12, "SIGUSR2");
  static const ProcessSignal sigpipe = const ProcessSignal._(13, "SIGKPIPE");
  static const ProcessSignal sigalrm = const ProcessSignal._(14, "SIGALRM");
  static const ProcessSignal sigterm = const ProcessSignal._(15, "SIGTERM");
  static const ProcessSignal sigpoll = const ProcessSignal._(29, "SIGKPOLL");
  static const ProcessSignal sigprof = const ProcessSignal._(27, "SIGKPROF");
  static const ProcessSignal sigsys = const ProcessSignal._(31, "SIGSYS");

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

abstract class Stdin implements Stream<List<int>> {
  bool echoMode;
  bool get hasTerminal;
  bool lineMode;
  bool get supportsAnsiEscapes;

  int readByteSync();

  String readLineSync(
      {Encoding encoding: systemEncoding, bool retainNewlines: false});
}

Stdin get stdin => IODriver.current.stdin;

abstract class Stdout implements IOSink {
  bool get hasTerminal;
  IOSink get nonBlocking;
  bool get supportsAnsiEscapes;
  int get terminalColumns;
  int get terminalLines;
}

Stdout get stdout => IODriver.current.stdout;
