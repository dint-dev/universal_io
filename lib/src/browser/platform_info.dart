import 'dart:html';

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
    // Locale
    String locale = "en";
    final languages = window.navigator.languages;
    if (languages.isNotEmpty) {
      locale = languages.first;
    }

    // Operating system
    String operatingSystem = "windows";
    final userAgent = window.navigator.userAgent;
    if (userAgent.contains("Android")) {
      operatingSystem = "android";
    } else if (userAgent.contains("iPhone")) {
      operatingSystem = "ios";
    } else if (userAgent.contains("Mac OS X")) {
      operatingSystem = "macos";
    } else if (userAgent.contains("CrOS")) {
      operatingSystem = "linux";
    }

    return PlatformInfo(
      numberOfProcessors: window.navigator.hardwareConcurrency ?? 1,
      localeName: locale,
      operatingSystem: operatingSystem,
    );
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
