import 'src/impl_vm.dart' if (dart.library.html) 'src/impl_browser.dart'
    as impl;
import 'dart:convert';
import 'dart:typed_data';

/// Returns environmental variables. Unlike _dart:io_ [Platform.environment](https://api.dartlang.org/stable/2.7.0/dart-io/Platform/environment.html),
/// this method works in browsers too.
///
/// Optional parameter `includeFiles` can be used to give a list of files that
/// contain environmental variables overriding previous ones. Any file that
/// doesn't exist is ignored. The files should have the following format:
/// ```
/// K0=V0
/// K1=V1
/// KN=VN
/// ```
Future<Map<String, String>> getEnvironmentalVariables({
  List<String> includeFiles,
}) async {
  var environment = await impl.getEnvironmentalVariables();
  if (includeFiles != null) {
    environment = Map<String, String>.from(environment);
    if (includeFiles is List) {
      for (var path in includeFiles) {
        if (path is String) {
          final file = await readFileAsString(path);
          if (file != null) {
            final lines = file.split('\n');
            for (var line in lines) {
              line = line.trim();
              if (line.isEmpty) {
                continue;
              }
              final i = line.indexOf('=');
              final key = line.substring(0, i);
              final value = line.substring(i + 1);
              environment[key] = value;
            }
          }
        }
      }
    }
  }
  return environment;
}

/// Reads file as a string. Unlike _dart:io_ [File](https://api.dartlang.org/stable/2.7.0/dart-io/Platform/file.html),
/// this method works in browsers too.
Future<String> readFileAsString(String path) {
  return scriptRelativeFileAsBytes(path).then(
    (value) => value == null ? null : utf8.decode(value),
  );
}

/// Reads file as bytes. Unlike _dart:io_ [File](https://api.dartlang.org/stable/2.7.0/dart-io/Platform/file.html),
/// this method works in browsers too.
Future<Uint8List> scriptRelativeFileAsBytes(String path) {
  return impl.readFileAsBytes(path);
}
