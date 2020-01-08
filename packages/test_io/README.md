# Description

This contains helpers for testing 'package:datastore' setups.

## Getting environmental variables
```dart
final env = await getEnvironmentalVariables();
print(env['EXAMPLE']);
```