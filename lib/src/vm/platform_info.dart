class PlatformInfo {
  final int numberOfProcessors;
  final String pathSeparator;
  final String localeName;
  final String operatingSystem;
  final String operatingSystemVersion;
  final String localHostname;
  final Map<String, String> environment;
  final String executable;
  final String resolvedExecutable;
  final Uri script;
  final List<String> executableArguments;
  final String packageRoot;
  final String packageConfig;
  final String version;

  factory PlatformInfo.fromEnvironment() {
    return PlatformInfo();
  }

  const PlatformInfo({
    this.numberOfProcessors = 1,
    this.pathSeparator = "/",
    this.localeName = "en",
    this.operatingSystem = "",
    this.operatingSystemVersion = "",
    this.localHostname = "",
    this.environment = const <String, String>{},
    this.executable = "",
    this.resolvedExecutable = "",
    this.script,
    this.executableArguments = const <String>[],
    this.packageRoot = "",
    this.packageConfig = "",
    this.version = "2.0.0",
  });
}
