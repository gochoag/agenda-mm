import 'dart:async';
import 'package:http/http.dart' as http;

/// Cliente HTTP que avisa cuando el servidor rechaza la sesión guardada (401 en una petición con token):
/// sesión caducada, firmada por otro servidor o de un usuario que ya no existe.
/// Las peticiones sin token (el login) no avisan: ahí un 401 es una contraseña incorrecta.
class SessionClient extends http.BaseClient {
  SessionClient(this._inner, this._onSessionRejected);

  final http.Client _inner;
  final Future<void> Function() _onSessionRejected;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _inner.send(request);
    if (response.statusCode == 401 && request.headers.containsKey('Authorization')) {
      unawaited(_onSessionRejected());
    }
    return response;
  }
}
