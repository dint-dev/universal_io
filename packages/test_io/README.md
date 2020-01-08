# Description

This contains cross-platform testing helpers related to I/O and platform information.

## Getting environmental variables
Unlike [Platform.environment](https://api.dartlang.org/stable/2.7.0/dart-io/Platform/environment.html),
this method works in browsers too:
```dart
final env = await getEnvironmentalVariables();
print(env['EXAMPLE']);
```