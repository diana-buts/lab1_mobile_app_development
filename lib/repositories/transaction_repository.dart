import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';
import '../services/network_service.dart';
import '../models/transaction_model.dart';

abstract class ITransactionRepository {
  Future<List<Map<String, dynamic>>> loadAll();
  Future<void> saveAll(List<Map<String, dynamic>> items);
  Future<void> add(Map<String, dynamic> item);
  Future<void> removeById(String id);
  Future<void> clearAll();
}

class TransactionRepository implements ITransactionRepository {
  // окремі ключі: кеш API та користувацькі транзакції
  static const _apiKey = 'transactions_cache_api_v1';
  static const _userKey = 'transactions_user_v1';

  final ApiService _api = ApiService();

  // -------------------- PUBLIC API --------------------

  /// Повертає мердж: API-кеш + локальні користувацькі.
  /// Якщо є інтернет — оновлює кеш API з сервера.
  @override
  Future<List<Map<String, dynamic>>> loadAll() async {
    final prefs = await SharedPreferences.getInstance();
    final online = await NetworkService.isOnline();

    List<Map<String, dynamic>> apiPart = await _loadApiCache(prefs);

    if (online) {
      try {
        final fromApi = await _fetchTransactionsFromApi();
        apiPart = fromApi;
        await _saveApiCache(prefs, apiPart);
      } catch (_) {
        // якщо API впало — залишаємо попередній кеш
      }
    }

    final userPart = await _loadUserLocal(prefs);

    // мердж без змін твоєї структури
    final merged = <Map<String, dynamic>>[...apiPart, ...userPart];

    // опційно можна відсортувати за датою, якщо є
    merged.sort((a, b) {
      final ad =
          DateTime.tryParse(
            a['date']?.toString() ?? '',
          )?.millisecondsSinceEpoch ??
          0;
      final bd =
          DateTime.tryParse(
            b['date']?.toString() ?? '',
          )?.millisecondsSinceEpoch ??
          0;
      return bd.compareTo(ad);
    });

    return merged;
  }

  /// Зберігає **тільки користувацькі** (фільтруємо).
  /// Це використовується твоїм UI, коли ти вручну оновлюєш список.
  @override
  Future<void> saveAll(List<Map<String, dynamic>> items) async {
    final prefs = await SharedPreferences.getInstance();
    final userOnly = items
        .where(_isUserItem)
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
    await _saveUserLocal(prefs, userOnly);
  }

  /// Додає **користувацьку** транзакцію (MQTT/ручна).
  @override
  Future<void> add(Map<String, dynamic> item) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _loadUserLocal(prefs);

    final toAdd = Map<String, dynamic>.from(item);
    // маркер користувацького елементу, щоб не змішувати з API
    toAdd['source'] = 'user';

    // підстрахуємо поля
    toAdd['id'] =
        toAdd['id']?.toString() ??
        DateTime.now().millisecondsSinceEpoch.toString();
    toAdd['date'] = (toAdd['date'] is DateTime)
        ? (toAdd['date'] as DateTime).toIso8601String()
        : (toAdd['date']?.toString() ?? DateTime.now().toIso8601String());

    list.add(toAdd);
    await _saveUserLocal(prefs, list);
  }

  /// Видаляє з **користувацького** списку (API-елементи не чіпаємо).
  @override
  Future<void> removeById(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await _loadUserLocal(prefs);
    list.removeWhere((t) => (t['id']?.toString() ?? '') == id);
    await _saveUserLocal(prefs, list);
  }

  /// Очищає і кеш API, і користувацькі (на випадок “повне очищення”).
  @override
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_apiKey);
    await prefs.remove(_userKey);
  }

  // -------------------- INTERNAL HELPERS --------------------

  Future<List<Map<String, dynamic>>> _fetchTransactionsFromApi() async {
    final List<TransactionModel> apiData = await _api.fetchTransactions();

    return apiData
        .map(
          (t) => <String, dynamic>{
            'id': 'api_${t.id}', // <<< УНІКАЛЬНИЙ STRING ID
            'title': t.title,
            'amount': t.amount,
            'type': 'Expense', // або Income, як хочеш
            'category': 'API',
            'date': DateTime.now().toIso8601String(),
          },
        )
        .toList();
  }


  Future<List<Map<String, dynamic>>> _loadApiCache(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_apiKey);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map),
            )
            .toList();
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  Future<void> _saveApiCache(
    SharedPreferences prefs,
    List<Map<String, dynamic>> items,
  ) async {
    await prefs.setString(_apiKey, jsonEncode(items));
  }

  Future<List<Map<String, dynamic>>> _loadUserLocal(
    SharedPreferences prefs,
  ) async {
    final raw = prefs.getString(_userKey);
    if (raw == null || raw.isEmpty) return <Map<String, dynamic>>[];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded
            .map<Map<String, dynamic>>(
              (e) => Map<String, dynamic>.from(e as Map),
            )
            .toList();
      }
    } catch (_) {}
    return <Map<String, dynamic>>[];
  }

  Future<void> _saveUserLocal(
    SharedPreferences prefs,
    List<Map<String, dynamic>> items,
  ) async {
    await prefs.setString(_userKey, jsonEncode(items));
  }

  // Вважаємо користувацькими:
  //  - якщо явно позначено source=='user'
  //  - або якщо id — не чисто числовий int (звично у тебе string timestamp)
  bool _isUserItem(Map<String, dynamic> t) {
    final source = t['source']?.toString();
    if (source == 'user') return true;

    final id = t['id'];
    if (id is String) return true;
    return false;
  }
}
