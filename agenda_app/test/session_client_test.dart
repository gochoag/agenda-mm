import 'package:agenda_app/services/session_client.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  late int avisos;
  SessionClient cliente(int codigo) => SessionClient(
        MockClient((_) async => http.Response('{}', codigo)),
        () async => avisos++,
      );
  final conToken = {'Authorization': 'Bearer abc'};

  setUp(() => avisos = 0);

  test('401 con sesión avisa', () async {
    await cliente(401).get(Uri.parse('https://x/api/notes'), headers: conToken);
    await Future<void>.delayed(Duration.zero);
    expect(avisos, 1);
  });

  test('401 sin sesión (login con contraseña incorrecta) no avisa', () async {
    await cliente(401).post(Uri.parse('https://x/api/auth/login'));
    await Future<void>.delayed(Duration.zero);
    expect(avisos, 0);
  });

  test('200 no avisa', () async {
    await cliente(200).get(Uri.parse('https://x/api/notes'), headers: conToken);
    await Future<void>.delayed(Duration.zero);
    expect(avisos, 0);
  });
}
