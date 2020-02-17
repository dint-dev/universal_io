# Description

This contains __browser-compatible__ I/O functions for (unit/integration) testing.

The package uses [spawnHybridUri(...)](https://pub.flutter-io.cn/documentation/test_api/latest/test_api/spawnHybridUri.html)
to implement methods in the browser. `spawnHybridUri` starts a process in the VM, which handles RPCcalls received
from the browser.

## Reading environmental variables
```dart
final env = await getEnvironmentalVariables();
final apiKey = env['API_KEY']) as String;
```

## Reading files
```dart
final value = readFileAsString(path);
```

## Launching process
```dart
final process = await RemoteProcess.start('executable', ['arg0', 'arg1']);
```