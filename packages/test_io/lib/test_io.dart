import 'src/impl_vm.dart' if (dart.library.html) 'src/impl_browser.dart'
    as impl;

/// Returns environmental variables. Unlike `Platform.environment,` works in
/// both VM and browser.
Future<Map<String, String>> getEnvironmentalVariables() {
  _environmentalVariables ??= impl.getEnvironmentalVariables();
  return _environmentalVariables;
}

Future<Map<String, String>> _environmentalVariables;
