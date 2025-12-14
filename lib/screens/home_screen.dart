import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';
import 'package:my_project/repositories/transaction_repository.dart';
import 'package:my_project/routes/app_routes.dart';
import 'package:my_project/widgets/app_header.dart';

enum PeriodFilter { all, today, thisWeek, thisMonth, custom }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ITransactionRepository _txRepo = TransactionRepository();
  List<Map<String, dynamic>> _transactions = [];

  // MQTT
  late MqttServerClient _mqtt;
  String _mqttSensorValue = "—";

  PeriodFilter _filter = PeriodFilter.all;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
    _initMqtt();
  }

  // ---------------- MQTT INIT ----------------
  Future<void> _initMqtt() async {
    _mqtt = MqttServerClient(
      'localhost',
      'budgetbuddy-client-${DateTime.now().millisecondsSinceEpoch}',
    );
    _mqtt.port = 1884;
    _mqtt.logging(on: false);
    _mqtt.keepAlivePeriod = 20;
    _mqtt.autoReconnect = true;

    _mqtt.onConnected = () => print("MQTT: connected");
    _mqtt.onDisconnected = () => print("MQTT: disconnected");
    _mqtt.onAutoReconnect = () => print("MQTT: reconnecting...");
    _mqtt.onAutoReconnected = () => print("MQTT: auto reconnected");

    try {
      await _mqtt.connect();
    } catch (e) {
      print("MQTT ERROR: $e");
      try {
        _mqtt.disconnect();
      } catch (_) {}
      return;
    }

    if (_mqtt.connectionStatus?.state == MqttConnectionState.connected) {
      print("MQTT connected successfully");

      _mqtt.subscribe('sensor/budget', MqttQos.atLeastOnce);

      _mqtt.updates?.listen((messages) async {
        try {
          final recMsg = messages.first.payload as MqttPublishMessage;

          // Отримуємо рядок
          String raw = MqttPublishPayload.bytesToStringAsString(
            recMsg.payload.message,
          );

          // Очищення
          String cleaned = raw
              .replaceAll(RegExp(r'[\u0000-\u001F]'), '')
              .replaceAll('–', '-')
              .replaceAll('—', '-')
              .replaceAll('−', '-')
              .replaceAll('‐', '-')
              .trim();

          print("📩 MQTT RAW: '$cleaned'");

          // Парсимо число
          final numRegex = RegExp(r'[-+]?\d+(\.\d+)?');
          final match = numRegex.firstMatch(cleaned);

          if (match == null) {
            print("❌ Число не знайдено");
            setState(() => _mqttSensorValue = cleaned);
            return;
          }

          final numStr = match.group(0)!;
          double value = double.tryParse(numStr) ?? 0;

          print("🔢 Розпарсене число: $value");

          // Визначаємо тип і суму
          String transactionType;
          double transactionAmount;

          if (value < 0) {
            // Від'ємне → Витрата
            transactionType = "Expense";
            transactionAmount = value.abs();
            print(
              "💸 Витрата: -$value → зберігаємо тип=Expense, amount=$transactionAmount",
            );
          } else {
            // Позитивне → Дохід
            transactionType = "Income";
            transactionAmount = value;
            print(
              "💰 Дохід: +$value → зберігаємо тип=Income, amount=$transactionAmount",
            );
          }

          // Оновлюємо сенсор UI
          setState(() => _mqttSensorValue = cleaned);

          // Створюємо транзакцію
          final newTransaction = {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'title': transactionType == 'Expense'
                ? 'Sensor Expense'
                : 'Sensor Income',
            'amount': transactionAmount, // ПОЗИТИВНЕ число
            'type': transactionType, // "Income" або "Expense"
            'category': 'Sensor',
            'date': DateTime.now().toIso8601String(),
          };

          print(
            "✅ Зберігаємо: type=${newTransaction['type']}, amount=${newTransaction['amount']}",
          );

          // Зберігаємо
          await _txRepo.add(newTransaction);
          await _loadTransactions();

          print("✅ Транзакція збережена і список оновлено");
        } catch (e, st) {
          print("❌ MQTT ERROR: $e\n$st");
        }
      });
    } else {
      print("MQTT connection state: ${_mqtt.connectionStatus}");
    }
  }

  @override
  void dispose() {
    try {
      _mqtt.disconnect();
    } catch (_) {}
    super.dispose();
  }

  // ---------------- Transactions ----------------
  Future<void> _loadTransactions() async {
    final list = await _txRepo.loadAll();
    print("📋 Завантажено ${list.length} транзакцій");

    // Виводимо для дебагу
    for (var tx in list) {
      print("  - ${tx['title']}: type=${tx['type']}, amount=${tx['amount']}");
    }

    setState(() => _transactions = list);
  }

  Future<void> _saveTransactions() async {
    await _txRepo.saveAll(_transactions);
  }

  DateTime _parseDate(dynamic src) {
    if (src == null) return DateTime.now();
    if (src is DateTime) return src;
    if (src is String) {
      try {
        return DateTime.parse(src);
      } catch (_) {
        try {
          return DateTime.parse(src.replaceAll(' ', 'T'));
        } catch (_) {}
      }
    }
    return DateTime.now();
  }

  Future<bool?> _confirmDeleteDialog(BuildContext ctx, String title) {
    return showDialog<bool>(
      context: ctx,
      builder: (c) => AlertDialog(
        title: const Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete "$title"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteTransactionByIndex(int globalIndex) async {
    if (globalIndex < 0 || globalIndex >= _transactions.length) return;
    final tx = _transactions[globalIndex];
    final confirmed = await _confirmDeleteDialog(
      context,
      tx['title']?.toString() ?? 'item',
    );
    if (confirmed != true) return;

    final id = tx['id']?.toString();
    setState(() => _transactions.removeAt(globalIndex));

    if (id != null && id.isNotEmpty) {
      await _txRepo.removeById(id);
    } else {
      await _saveTransactions();
    }
  }

  Future<bool> _onDismissConfirm(
    DismissDirection direction,
    String txId,
    String title,
  ) async {
    final confirmed = await _confirmDeleteDialog(context, title);
    if (confirmed != true) return false;
    await _txRepo.removeById(txId);
    setState(
      () => _transactions.removeWhere((t) => t['id']?.toString() == txId),
    );
    return true;
  }

  bool _inRange(DateTime d, DateTime start, DateTime end) {
    final dd = DateTime(d.year, d.month, d.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !(dd.isBefore(s) || dd.isAfter(e));
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_filter == PeriodFilter.all) return _transactions;
    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (_filter == PeriodFilter.today) {
      start = DateTime(now.year, now.month, now.day);
      end = start;
    } else if (_filter == PeriodFilter.thisWeek) {
      start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: now.weekday - 1));
      end = start.add(const Duration(days: 6));
    } else if (_filter == PeriodFilter.thisMonth) {
      start = DateTime(now.year, now.month);
      end = DateTime(now.year, now.month + 1, 0);
    } else {
      if (_customRange == null) return [];
      start = _customRange!.start;
      end = _customRange!.end;
    }

    return _transactions.where((t) {
      final d = _parseDate(t['date']);
      return _inRange(d, start, end);
    }).toList();
  }

  Map<String, double> get _stats {
    double totalIncome = 0;
    double totalExpense = 0;

    print(
      "📊 Розрахунок статистики для ${_filteredTransactions.length} транзакцій:",
    );

    for (final tx in _filteredTransactions) {
      // Отримуємо тип
      final typeRaw = tx['type']?.toString() ?? 'Expense';
      final type = typeRaw.trim();

      // Отримуємо суму
      double amount = 0;
      if (tx['amount'] is num) {
        amount = (tx['amount'] as num).toDouble();
      } else if (tx['amount'] is String) {
        amount = double.tryParse(tx['amount'] as String) ?? 0;
      }

      // Беремо абсолютне значення (на всяк випадок)
      amount = amount.abs();

      // Додаємо до відповідної категорії
      if (type == 'Income') {
        totalIncome += amount;
        print(
          "  ✅ Income: +${amount.toStringAsFixed(2)} (загалом income: ${totalIncome.toStringAsFixed(2)})",
        );
      } else {
        totalExpense += amount;
        print(
          "  ❌ Expense: +${amount.toStringAsFixed(2)} (загалом expense: ${totalExpense.toStringAsFixed(2)})",
        );
      }
    }

    final balance = totalIncome - totalExpense;

    print(
      "📊 ПІДСУМОК: Income=$totalIncome, Expense=$totalExpense, Balance=$balance",
    );

    return {'income': totalIncome, 'expense': totalExpense, 'balance': balance};
  }

  Future<void> _chooseCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _customRange,
    );
    if (picked != null)
      setState(() {
        _filter = PeriodFilter.custom;
        _customRange = picked;
      });
  }

  String _formatDateForTile(dynamic src) {
    final d = _parseDate(src);
    return '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final stats = _stats;
    return Scaffold(
      appBar: AppHeader(
        title: 'BudgetBuddy 💰',
        showLogout: true,
        onLogout: () async {
          final confirmed = await showDialog<bool>(
            context: context,
            builder: (c) => AlertDialog(
              title: const Text('Confirm Logout'),
              content: const Text('Are you sure you want to logout?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(c, false),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(c, true),
                  child: const Text('Logout'),
                ),
              ],
            ),
          );
          if (confirmed == true)
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (r) => false,
            );
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.profile);
              await _loadTransactions();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // MQTT sensor card
            Card(
              color: Colors.grey[850],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "Sensor:",
                      style: TextStyle(color: Colors.white70, fontSize: 16),
                    ),
                    Text(
                      _mqttSensorValue,
                      style: const TextStyle(
                        color: Colors.tealAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Filter + Add
            Row(
              children: [
                Expanded(
                  child: DropdownButton<PeriodFilter>(
                    value: _filter,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(
                        value: PeriodFilter.all,
                        child: Text('All Time'),
                      ),
                      DropdownMenuItem(
                        value: PeriodFilter.today,
                        child: Text('Today'),
                      ),
                      DropdownMenuItem(
                        value: PeriodFilter.thisWeek,
                        child: Text('This Week'),
                      ),
                      DropdownMenuItem(
                        value: PeriodFilter.thisMonth,
                        child: Text('This Month'),
                      ),
                      DropdownMenuItem(
                        value: PeriodFilter.custom,
                        child: Text('Select Period'),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      if (v == PeriodFilter.custom)
                        _chooseCustomRange();
                      else
                        setState(() {
                          _filter = v;
                          _customRange = null;
                        });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () async {
                    final res = await Navigator.pushNamed(
                      context,
                      AppRoutes.addTransaction,
                    );
                    if (res != null && res is Map<String, dynamic>) {
                      final tx = Map<String, dynamic>.from(res);
                      tx['id'] ??= DateTime.now().millisecondsSinceEpoch
                          .toString();
                      tx['date'] = (tx['date'] is DateTime)
                          ? (tx['date'] as DateTime).toIso8601String()
                          : DateTime.now().toIso8601String();
                      await _txRepo.add(tx);
                      await _loadTransactions();
                    }
                  },
                  child: const Text("Add"),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Statistics card
            Card(
              color: Colors.grey[850],
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text(
                          'Income',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '+${stats['income']!.toStringAsFixed(2)} \$',
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'Expenses',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '-${stats['expense']!.toStringAsFixed(2)} \$',
                          style: const TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      children: [
                        const Text(
                          'Balance',
                          style: TextStyle(color: Colors.white70),
                        ),
                        Text(
                          '${stats['balance']! >= 0 ? '+' : ''}${stats['balance']!.toStringAsFixed(2)} \$',
                          style: TextStyle(
                            color: (stats['balance']! < 0)
                                ? Colors.redAccent
                                : Colors.greenAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Transactions list
            Expanded(
              child: _filteredTransactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = _filteredTransactions[index];
                        final id = tx['id']?.toString() ?? '';
                        final globalIndex = _transactions.indexWhere(
                          (t) => t['id']?.toString() == id,
                        );

                        // Отримуємо тип
                        final typeRaw = tx['type']?.toString() ?? 'Expense';
                        final type = typeRaw.trim();
                        final isExpense = type == 'Expense';

                        // Отримуємо суму
                        double amount = 0;
                        if (tx['amount'] is num) {
                          amount = (tx['amount'] as num).toDouble();
                        } else if (tx['amount'] is String) {
                          amount = double.tryParse(tx['amount'] as String) ?? 0;
                        }
                        amount = amount.abs();

                        return Dismissible(
                          key: ValueKey(id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (d) => _onDismissConfirm(
                            d,
                            id,
                            tx['title']?.toString() ?? '',
                          ),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 20),
                            color: Colors.redAccent,
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: Card(
                            color: Colors.grey[900],
                            child: ListTile(
                              title: Text(
                                tx['title']?.toString() ?? '',
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '${tx['category']} • $type • ${_formatDateForTile(tx['date'])}',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: Text(
                                '${isExpense ? '-' : '+'}${amount.toStringAsFixed(2)} \$',
                                style: TextStyle(
                                  color: isExpense
                                      ? Colors.redAccent
                                      : Colors.greenAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              onLongPress: () async {
                                if (globalIndex != -1)
                                  await _deleteTransactionByIndex(globalIndex);
                              },
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
