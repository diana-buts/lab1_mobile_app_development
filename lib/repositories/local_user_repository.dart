import 'package:shared_preferences/shared_preferences.dart';
import 'user_repository.dart';

class LocalUserRepository implements UserRepository {
  @override
  Future<void> saveUser(String name, String email, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('password', password);
  }

  @override
  Future<Map<String, String>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('name');
    final email = prefs.getString('email');
    final password = prefs.getString('password');

    if (name == null || email == null || password == null) {
      return null;
    }

    return {'name': name, 'email': email, 'password': password};
  }

  @override
  Future<bool> authenticate(String email, String password) async {
    final user = await getUser();
    if (user == null) return false;

    return user['email'] == email && user['password'] == password;
  }

  @override
  Future<void> updateUser(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('email', email);
  }

  @override
  Future<void> deleteUser() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('password');
  }
}
