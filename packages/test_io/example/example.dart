import 'package:test/test.dart';
import 'package:test_io/test_io.dart';

void main() {
  test('Example', () async {
    final env = await getEnvironmentalVariables();
    print(env['EXAMPLE']);
  });
}
