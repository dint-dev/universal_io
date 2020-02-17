import 'package:test/test.dart';
import 'package:test_io/test_io.dart';

void main() {
  test('getEnvironmentalVariables()', () async {
    final env = await getEnvironmentalVariables();
    expect(env, isNotEmpty);
  });

  test('getEnvironmentalVariables(includeFiles:_): not found', () async {
    final env = await getEnvironmentalVariables(
      includeFiles: ['DOES NOT EXIST'],
    );
    expect(env, isNotEmpty);
  });

  test('getEnvironmentalVariables(includeFiles:_): found', () async {
    final env = await getEnvironmentalVariables(
      includeFiles: ['test/example.env'],
    );
    expect(env, isNotEmpty);
    expect(env['PATH']?.length, 1);
  });

  test('readFileAsString(): not found', () async {
    final s = await readFileAsString('DOES NOT EXIST');
    expect(s, isNull);
  });

  test('readFileAsString(): found', () async {
    final s = await readFileAsString('test/example.env');
    expect(s, 'PATH=X');
  });
}
