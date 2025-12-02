abstract class UserRepository {
  Future<void> saveUser(String name, String email, String password);
  Future<Map<String, String>?> getUser();
  Future<bool> authenticate(String email, String password);
  Future<void> updateUser(String name, String email);
  Future<void> deleteUser();
}
