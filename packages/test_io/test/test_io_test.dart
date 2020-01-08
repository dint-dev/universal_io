import 'package:test_io/test_io.dart';
import 'package:test/test.dart';

void main() {
  test('loadEnvironment() causes environmental variables to be loaded',
      () async {
    final env = await getEnvironmentalVariables();
    expect(env, isNotEmpty);
  });
}
