# Description

This contains IO / platform related helpers for testing.

## Getting environmental variables
```dart
final env = await getEnvironmentalVariables();
print(env['EXAMPLE']);
```