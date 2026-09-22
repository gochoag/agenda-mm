import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/calendar_event.dart';
import '../models/sticky_note.dart';
import '../models/app_version.dart';
import '../models/monthly_cover.dart';

class ApiService {
  static final ApiService instance = ApiService._internal();
  ApiService._internal();

  static const String _defaultUrl = 'http://10.0.2.2:5000'; // Default para emulador
  static const String _keyToken = 'auth_token';
  static const String _keyUser = 'auth_user';
  static const String _keyBaseUrl = 'api_base_url';

  String? _token;
  User? _currentUser;
  String? _baseUrl;

  User? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _token != null && _currentUser != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString(_keyToken);

    // Prioridad: 1. .env (API_BASE_URL) -> 2. SharedPreferences previo -> 3. _defaultUrl
    final envUrl = dotenv.env['API_BASE_URL']?.trim();
    if (envUrl != null && envUrl.isNotEmpty) {
      _baseUrl = envUrl.endsWith('/') ? envUrl.substring(0, envUrl.length - 1) : envUrl;
    } else {
      _baseUrl = prefs.getString(_keyBaseUrl) ?? _defaultUrl;
    }

    final userJsonStr = prefs.getString(_keyUser);
    if (userJsonStr != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userJsonStr));
      } catch (_) {
        _currentUser = null;
      }
    }
  }

  Future<String> getBaseUrl() async {
    if (_baseUrl != null) return _baseUrl!;
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_keyBaseUrl) ?? _defaultUrl;
    return _baseUrl!;
  }

  Future<void> setBaseUrl(String url) async {
    String cleanUrl = url.trim();
    if (cleanUrl.endsWith('/')) {
      cleanUrl = cleanUrl.substring(0, cleanUrl.length - 1);
    }
    _baseUrl = cleanUrl;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBaseUrl, cleanUrl);
  }

  Map<String, String> _headers({bool needsAuth = true}) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (needsAuth && _token != null) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  // --- AUTH ---

  Future<Map<String, dynamic>> login(String username, String password) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/auth/login');

    try {
      final response = await http.post(
        url,
        headers: _headers(needsAuth: false),
        body: jsonEncode({'username': username, 'password': password}),
      ).timeout(const Duration(seconds: 15));

      Map<String, dynamic>? body;
      try {
        body = jsonDecode(utf8.decode(response.bodyBytes));
      } catch (_) {
        body = null;
      }

      if (response.statusCode == 200 && body != null) {
        _token = body['token'];
        _currentUser = User.fromJson(body['user']);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_keyToken, _token!);
        await prefs.setString(_keyUser, jsonEncode(_currentUser!.toJson()));

        return {'success': true, 'user': _currentUser};
      } else if (response.statusCode == 500) {
        return {
          'success': false,
          'error': 'Error 500 en el servidor. Falta aplicar las migraciones de base de datos en PythonAnywhere.'
        };
      } else {
        return {
          'success': false,
          'error': body?['error'] ?? 'Error de autenticación (${response.statusCode})'
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'No se pudo conectar con el servidor ($baseUrl): $e'};
    }
  }

  Future<void> logout() async {
    _token = null;
    _currentUser = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    await prefs.remove(_keyUser);
  }

  // --- CALENDARIO ---

  Future<List<CalendarEvent>> getCalendarEvents({int? userId, String? month}) async {
    final baseUrl = await getBaseUrl();
    final params = <String>[];
    if (userId != null) params.add('user_id=$userId');
    if (month != null && month.isNotEmpty) params.add('month=$month');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final url = Uri.parse('$baseUrl/api/calendar$query');

    final response = await http.get(url, headers: _headers());
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final list = body['events'] as List? ?? [];
      return list.map((item) => CalendarEvent.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar eventos (${response.statusCode})');
    }
  }

  Future<CalendarEvent> createCalendarEvent({
    required String detail,
    required String eventDate,
    String status = 'pendiente',
    int? userId,
  }) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/calendar');

    final payload = <String, dynamic>{
      'detail': detail,
      'event_date': eventDate,
      'status': status,
    };
    if (userId != null) payload['user_id'] = userId;

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return CalendarEvent.fromJson(body['event']);
    } else {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['error'] ?? 'Error al crear evento');
    }
  }

  Future<CalendarEvent> updateCalendarEvent(int id, {
    String? detail,
    String? eventDate,
    String? status,
  }) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/calendar/$id');

    final payload = <String, dynamic>{};
    if (detail != null) payload['detail'] = detail;
    if (eventDate != null) payload['event_date'] = eventDate;
    if (status != null) payload['status'] = status;

    final response = await http.put(
      url,
      headers: _headers(),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return CalendarEvent.fromJson(body['event']);
    } else {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['error'] ?? 'Error al actualizar evento');
    }
  }

  Future<void> deleteCalendarEvent(int id) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/calendar/$id');

    final response = await http.delete(url, headers: _headers());
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['error'] ?? 'Error al eliminar evento');
    }
  }

  // --- NOTAS ADHESIVAS ---

  Future<List<StickyNote>> getNotes({int? userId, String? month}) async {
    final baseUrl = await getBaseUrl();
    final params = <String>[];
    if (userId != null) params.add('user_id=$userId');
    if (month != null && month.isNotEmpty) params.add('month=$month');
    final query = params.isNotEmpty ? '?${params.join('&')}' : '';
    final url = Uri.parse('$baseUrl/api/notes$query');

    final response = await http.get(url, headers: _headers());
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final list = body['notes'] as List? ?? [];
      return list.map((item) => StickyNote.fromJson(item)).toList();
    } else {
      throw Exception('Error al cargar notas (${response.statusCode})');
    }
  }

  Future<StickyNote> createNote({
    required String content,
    String color = '#FFF59D',
    String fontFamily = 'handwriting',
    bool isPinned = false,
    String? monthYear,
    int? userId,
  }) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/notes');

    final payload = <String, dynamic>{
      'content': content,
      'color': color,
      'font_family': fontFamily,
      'is_pinned': isPinned,
    };
    if (monthYear != null && monthYear.isNotEmpty) payload['month_year'] = monthYear;
    if (userId != null) payload['user_id'] = userId;

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 201) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return StickyNote.fromJson(body['note']);
    } else {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['error'] ?? 'Error al crear nota');
    }
  }

  // --- CARÁTULAS MENSUALES (BULLET JOURNAL) ---

  Future<MonthlyCover> getMonthlyCover(String monthYear, {int? userId}) async {
    final baseUrl = await getBaseUrl();
    final params = <String>['month=$monthYear'];
    if (userId != null) params.add('user_id=$userId');
    final url = Uri.parse('$baseUrl/api/covers?${params.join('&')}');

    final response = await http.get(url, headers: _headers());
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return MonthlyCover.fromJson(body);
    } else {
      throw Exception('Error al obtener carátula mensual (${response.statusCode})');
    }
  }

  Future<MonthlyCover> saveMonthlyCover(MonthlyCover cover) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/covers');

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(cover.toJson()),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return MonthlyCover.fromJson(body);
    } else {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['error'] ?? 'Error al guardar carátula');
    }
  }

  Future<List<Map<String, dynamic>>> getCoverHistoryMonths() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/covers/history');

    final response = await http.get(url, headers: _headers());
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final list = body['months'] as List? ?? [];
      return list.cast<Map<String, dynamic>>();
    } else {
      return [];
    }
  }

  Future<StickyNote> updateNote(int id, {
    String? content,
    String? color,
    String? fontFamily,
    bool? isPinned,
  }) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/notes/$id');

    final payload = <String, dynamic>{};
    if (content != null) payload['content'] = content;
    if (color != null) payload['color'] = color;
    if (fontFamily != null) payload['font_family'] = fontFamily;
    if (isPinned != null) payload['is_pinned'] = isPinned;

    final response = await http.put(
      url,
      headers: _headers(),
      body: jsonEncode(payload),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      return StickyNote.fromJson(body['note']);
    } else {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['error'] ?? 'Error al actualizar nota');
    }
  }

  Future<void> deleteNote(int id) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/notes/$id');

    final response = await http.delete(url, headers: _headers());
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['error'] ?? 'Error al eliminar nota');
    }
  }

  // --- ADMINISTRACIÓN ---

  Future<List<User>> getAdminUsers() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/admin/users');

    final response = await http.get(url, headers: _headers());
    if (response.statusCode == 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      final list = body['users'] as List? ?? [];
      return list.map((item) => User.fromJson(item)).toList();
    } else {
      throw Exception('Error al obtener lista de usuarios');
    }
  }

  Future<User> createAdminUser({
    required String username,
    required String password,
    String role = 'coadmin',
  }) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/admin/users');

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode({
        'username': username,
        'password': password,
        'role': role,
      }),
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 201) {
      return User.fromJson(body['user']);
    } else {
      throw Exception(body['error'] ?? 'Error al crear usuario');
    }
  }

  Future<void> deleteAdminUser(int userId) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/admin/users/$userId');

    final response = await http.delete(url, headers: _headers());
    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['error'] ?? 'Error al eliminar usuario');
    }
  }

  Future<void> changeUserPassword(int userId, String newPassword) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/admin/users/$userId/password');

    final response = await http.put(
      url,
      headers: _headers(),
      body: jsonEncode({'new_password': newPassword}),
    );

    if (response.statusCode != 200) {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(body['error'] ?? 'Error al cambiar contraseña');
    }
  }

  Future<String> getAdminBackupRawJson() async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/admin/backup');

    final response = await http.get(url, headers: _headers());
    if (response.statusCode == 200) {
      return utf8.decode(response.bodyBytes);
    } else {
      throw Exception('Error al exportar copia de seguridad');
    }
  }

  Future<Map<String, dynamic>> restoreAdminBackup(Map<String, dynamic> backupData) async {
    final baseUrl = await getBaseUrl();
    final url = Uri.parse('$baseUrl/api/admin/restore');

    final response = await http.post(
      url,
      headers: _headers(),
      body: jsonEncode(backupData),
    );

    final body = jsonDecode(utf8.decode(response.bodyBytes));
    if (response.statusCode == 200) {
      return body;
    } else {
      throw Exception(body['error'] ?? 'Error en la restauración');
    }
  }

  Future<AppVersionInfo?> checkAppVersion() async {
    try {
      final baseUrl = await getBaseUrl();
      final url = Uri.parse('$baseUrl/api/app/version');
      final response = await http
          .get(url, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final body = jsonDecode(utf8.decode(response.bodyBytes));
        return AppVersionInfo.fromJson(body);
      }
    } catch (_) {
      // Si el backend no está disponible o no hay red, retorno silencioso
    }
    return null;
  }
}
