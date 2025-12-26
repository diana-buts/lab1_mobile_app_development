import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../services/network_service.dart';
import '../models/user_model.dart';

abstract class UserRepository {
  Future<void> saveUser(String name, String email, String password);
  Future<Map<String, String>?> getUser();
  Future<bool> authenticate(String email, String password);
  Future<void> updateUser(String name, String email);
  Future<void> deleteUser();
}

/// Реалізація з офлайн-кешем і оновленням з API при наявності інтернету.
class BudgetUserRepository implements UserRepository {
  static const _profileKey = 'user_profile_v1';
  static const _passwordKey = 'user_password_v1';

  final ApiService _api = ApiService();

  /// Зберігає профіль локально (разом із паролем).
  @override
  Future<void> saveUser(String name, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    final map = <String, dynamic>{'name': name, 'email': email};

    await prefs.setString(_profileKey, jsonEncode(map));
    await prefs.setString(_passwordKey, password);
  }

  /// Повертає профіль: якщо є інтернет — підтягне з API і оновить локальний кеш,
  /// якщо немає — віддасть локальні дані (або null, якщо їх немає).
  @override
  Future<Map<String, String>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final online = await NetworkService.isOnline();

    if (online) {
      try {
        final UserModel apiUser = await _api.fetchUser();
        final cachedPassword = prefs.getString(_passwordKey) ?? '';

        final updated = <String, String>{
          'name': apiUser.name,
          'email': apiUser.email,
          // пароль беремо з локального сховища, бо API його не дає
          'password': cachedPassword,
        };

        await prefs.setString(_profileKey, jsonEncode(updated));
        return updated;
      } catch (_) {
        // якщо впало звернення до API — повертаємо локальне
      }
    }

    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      return <String, String>{
        'name': decoded['name']?.toString() ?? '',
        'email': decoded['email']?.toString() ?? '',
        'password': (prefs.getString(_passwordKey) ?? '').toString(),
      };
    } catch (_) {
      return null;
    }
  }

  /// Проста локальна автентифікація: звіряє збережені email+password.
  @override
  Future<bool> authenticate(String email, String password) async {
    final prefs = await SharedPreferences.getInstance();

    final raw = prefs.getString(_profileKey);
    final savedPass = prefs.getString(_passwordKey) ?? '';

    if (raw == null || raw.isEmpty) return false;

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final savedEmail = decoded['email']?.toString() ?? '';
      return (email == savedEmail) && (password == savedPass);
    } catch (_) {
      return false;
    }
  }

  /// Оновлює name/email локально (і залишає пароль як є).
  /// При наявності інтернету можна було б синкати на бек — але для JSONPlaceholder це no-op.
  @override
  Future<void> updateUser(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_profileKey);

    Map<String, dynamic> current = {};
    if (raw != null && raw.isNotEmpty) {
      try {
        current = jsonDecode(raw) as Map<String, dynamic>;
      } catch (_) {
        current = {};
      }
    }

    current['name'] = name;
    current['email'] = email;

    await prefs.setString(_profileKey, jsonEncode(current));
  }

  /// Видаляє профіль і пароль з локального сховища.
  @override
  Future<void> deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    await prefs.remove(_passwordKey);
  }
}
