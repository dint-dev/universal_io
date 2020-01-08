import 'src/impl_vm.dart' if (dart.library.html) 'src/impl_browser.dart'
    as impl;

/// Returns environmental variables. Unlike [Platform.environment](https://api.dartlang.org/stable/2.7.0/dart-io/Platform/environment.html),
/// this method works in browsers too.
Future<Map<String, String>> getEnvironmentalVariables() {
  _environmentalVariables ??= impl.getEnvironmentalVariables();
  return _environmentalVariables;
}

Future<Map<String, String>> _environmentalVariables;
