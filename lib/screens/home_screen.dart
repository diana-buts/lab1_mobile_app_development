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

  // Future for FutureBuilder
  Future<void>? _loadFuture;

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

    try {
      await _mqtt.connect();
    } catch (e) {
      try {
        _mqtt.disconnect();
      } catch (_) {}
      return;
    }

    if (_mqtt.connectionStatus?.state == MqttConnectionState.connected) {
      _mqtt.subscribe('sensor/budget', MqttQos.atLeastOnce);

      _mqtt.updates?.listen((messages) async {
        try {
          final recMsg = messages.first.payload as MqttPublishMessage;
          String raw = MqttPublishPayload.bytesToStringAsString(
            recMsg.payload.message,
          );

          String cleaned = raw
              .replaceAll(RegExp(r'[\u0000-\u001F]'), '')
              .replaceAll('–', '-')
              .replaceAll('—', '-')
              .replaceAll('−', '-')
              .replaceAll('‐', '-')
              .trim();

          final numRegex = RegExp(r'[-+]?\d+(\.\d+)?');
          final match = numRegex.firstMatch(cleaned);

          if (match == null) {
            setState(() => _mqttSensorValue = cleaned);
            return;
          }

          final numStr = match.group(0)!;
          double value = double.tryParse(numStr) ?? 0;

          String type = value < 0 ? "Expense" : "Income";
          double amount = value.abs();

          setState(() => _mqttSensorValue = cleaned);

          final tx = {
            'id': DateTime.now().millisecondsSinceEpoch.toString(),
            'title': type == 'Expense' ? 'Sensor Expense' : 'Sensor Income',
            'amount': amount,
            'type': type,
            'category': 'Sensor',
            'date': DateTime.now().toIso8601String(),
          };

          await _txRepo.add(tx);
          await _loadTransactions();
        } catch (_) {}
      });
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
    _loadFuture = _txRepo.loadAll().then((list) {
      setState(() {
        _transactions = list;
      });
    });
  }

  DateTime _parseDate(dynamic src) {
    if (src == null) return DateTime.now();
    if (src is DateTime) return src;
    if (src is String) {
      try {
        return DateTime.parse(src);
      } catch (_) {}
    }
    return DateTime.now();
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    final now = DateTime.now();
    if (_filter == PeriodFilter.all) return _transactions;

    DateTime start;
    DateTime end;

    if (_filter == PeriodFilter.today) {
      start = DateTime(now.year, now.month, now.day);
      end = start;
    } else if (_filter == PeriodFilter.thisWeek) {
      start = now.subtract(Duration(days: now.weekday - 1));
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
      return !d.isBefore(start) && !d.isAfter(end);
    }).toList();
  }

  Map<String, double> get _stats {
    double income = 0;
    double expense = 0;

    for (final tx in _filteredTransactions) {
      final type = tx['type']?.toString() ?? 'Expense';
      double amount = tx['amount'] is num
          ? (tx['amount'] as num).toDouble()
          : double.tryParse(tx['amount'].toString()) ?? 0;

      if (type == 'Income') {
        income += amount;
      } else {
        expense += amount;
      }
    }

    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  // ----------- UI -----------
  @override
  Widget build(BuildContext context) {
    final stats = _stats;

    // >>>> ДОДАНО: WillPopScope для підтвердження виходу <<<<
    return WillPopScope(
      onWillPop: () async {
        final exit = await showDialog<bool>(
          context: context,
          builder: (c) => AlertDialog(
            title: const Text('Confirm Exit'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(c, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(c, true),
                child: const Text('Exit'),
              ),
            ],
          ),
        );
        return exit ?? false;
      },
      child: Scaffold(
        appBar: AppHeader(
          title: 'BudgetBuddy 💰',
          showLogout: true,
          onLogout: () async {
            final shouldLogout = await showDialog<bool>(
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

            if (shouldLogout == true) {
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRoutes.login,
                  (_) => false,
                );
              }
            }
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
                        style: TextStyle(color: Colors.white70),
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
                        if (v == PeriodFilter.custom) {
                          showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2100),
                          ).then((picked) {
                            if (picked != null) {
                              setState(() {
                                _filter = PeriodFilter.custom;
                                _customRange = picked;
                              });
                            }
                          });
                        } else {
                          setState(() {
                            _filter = v;
                            _customRange = null;
                          });
                        }
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
                        tx['date'] = DateTime.now().toIso8601String();
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
                  padding: const EdgeInsets.all(12),
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
                              color: stats['balance']! < 0
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
              Expanded(
                child: FutureBuilder(
                  future: _loadFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final list = _filteredTransactions;

                    if (list.isEmpty) {
                      return const Center(
                        child: Text(
                          'No transactions',
                          style: TextStyle(color: Colors.white70),
                        ),
                      );
                    }

                    return ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final tx = list[index];
                        final id = tx['id']?.toString() ?? '';

                        final type = tx['type']?.toString() ?? 'Expense';
                        final isExpense = type == 'Expense';

                        double amount = tx['amount'] is num
                            ? (tx['amount'] as num).toDouble()
                            : double.tryParse(tx['amount'].toString()) ?? 0;

                        return Dismissible(
                          key: ValueKey(id),
                          direction: DismissDirection.endToStart,
                          onDismissed: (_) async {
                            await _txRepo.removeById(id);
                            await _loadTransactions();
                          },
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
                                '${tx['category']} • $type • ${tx['date'].toString().split("T").first}',
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
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
