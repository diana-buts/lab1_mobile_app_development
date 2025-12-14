import 'package:my_project/repositories/user_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocalUserRepository implements UserRepository {
  static const String _keyName = 'name';
  static const String _keyEmail = 'email';
  static const String _keyPassword = 'password';
  static const String _keyLoggedIn = 'is_logged_in';

  @override
  Future<void> saveUser(String name, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyPassword, password);

    /// одразу активуємо сесію
    await prefs.setBool(_keyLoggedIn, true);
  }

  @override
  Future<Map<String, String>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();

    final name = prefs.getString(_keyName);
    final email = prefs.getString(_keyEmail);
    final password = prefs.getString(_keyPassword);

    if (name == null || email == null || password == null) {
      return null;
    }

    return {'name': name, 'email': email, 'password': password};
  }

  /// --- Перевірка чи сесія існує ---
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyLoggedIn) ?? false;
  }

  @override
  Future<bool> authenticate(String email, String password) async {
    final user = await getUser();
    if (user == null) return false;

    final correct = user['email'] == email && user['password'] == password;

    if (correct) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyLoggedIn, true);
    }

    return correct;
  }

  @override
  Future<void> updateUser(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyName, name);
    await prefs.setString(_keyEmail, email);
  }

  /// --- Вихід з акаунта ---
  @override
  Future<void> deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyName);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyPassword);
    await prefs.remove(_keyLoggedIn);
  }
}
