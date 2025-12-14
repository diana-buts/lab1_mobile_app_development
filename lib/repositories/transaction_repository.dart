import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

abstract class ITransactionRepository {
  Future<List<Map<String, dynamic>>> loadAll();
  Future<void> saveAll(List<Map<String, dynamic>> items);
  Future<void> add(Map<String, dynamic> item);
  Future<void> removeById(String id);
  Future<void> clearAll();
}

class TransactionRepository implements ITransactionRepository {
  static const _key = 'transactions_v1';

  @override
  Future<void> add(Map<String, dynamic> item) async {
    final all = await loadAll();
    all.add(item);
    await saveAll(all);
  }

  @override
  Future<List<Map<String, dynamic>>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];

    try {
      final decoded = jsonDecode(raw);

      // Якщо decoded — список, приводимо кожен елемент до Map<String, dynamic>
      if (decoded is List) {
        final List<Map<String, dynamic>> out = decoded
            .map<Map<String, dynamic>>((e) {
              if (e is Map) {
                return Map<String, dynamic>.from(e);
              } else {
                // Якщо елемент не Map — ігноруємо (повернемо порожній map)
                return <String, dynamic>{};
              }
            })
            .where((m) => m.isNotEmpty)
            .toList();

        return out;
      } else {
        // Якщо збережений JSON не список — повертаємо порожній
        return <Map<String, dynamic>>[];
      }
    } catch (e) {
      // В разі помилки парсингу — повертаємо порожній список
      return <Map<String, dynamic>>[];
    }
  }

  @override
  Future<void> saveAll(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(items);
    await prefs.setString(_key, raw);
  }

  @override
  Future<void> removeById(String id) async {
    final all = await loadAll();
    all.removeWhere((t) => (t['id']?.toString() ?? '') == id);
    await saveAll(all);
  }

  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
