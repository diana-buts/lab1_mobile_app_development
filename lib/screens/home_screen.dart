import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../routes/app_routes.dart';
import '../repositories/transaction_repository.dart';

enum PeriodFilter { all, today, thisWeek, thisMonth, custom }

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ITransactionRepository _txRepo = TransactionRepository();
  List<Map<String, dynamic>> _transactions = [];
  PeriodFilter _filter = PeriodFilter.all;
  DateTimeRange? _customRange;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    final list = await _txRepo.loadAll();
    setState(() => _transactions = list);
  }

  Future<void> _saveTransactions() async {
    await _txRepo.saveAll(_transactions);
  }

  // Parse date string or DateTime stored by different screens
  DateTime _parseDate(dynamic src) {
    if (src == null) return DateTime.now();
    if (src is DateTime) return src;
    if (src is String) {
      try {
        return DateTime.parse(src);
      } catch (_) {
        // last resort: DateTime from toString()
        try {
          return DateTime.parse(src.replaceAll(' ', 'T'));
        } catch (_) {
          return DateTime.now();
        }
      }
    }
    return DateTime.now();
  }

  // confirm dialog for delete
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
    setState(() {
      _transactions.removeAt(globalIndex);
    });
    if (id != null && id.isNotEmpty) {
      await _txRepo.removeById(id);
    } else {
      await _saveTransactions();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "${tx['title'] ?? ''}"'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
      ),
    );
  }

  // When Dismissible requests confirmation
  Future<bool> _onDismissConfirm(
    DismissDirection direction,
    String txId,
    String title,
  ) async {
    final confirmed = await _confirmDeleteDialog(context, title);
    if (confirmed != true) return false;

    await _txRepo.removeById(txId);
    // update local state
    setState(() {
      _transactions.removeWhere((t) => (t['id']?.toString() ?? '') == txId);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Deleted "$title"'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
      ),
    );

    return true;
  }

  // Helpers for filtering
  bool _inRange(DateTime d, DateTime start, DateTime end) {
    final dd = DateTime(d.year, d.month, d.day);
    final s = DateTime(start.year, start.month, start.day);
    final e = DateTime(end.year, end.month, end.day);
    return !(dd.isBefore(s) || dd.isAfter(e));
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_filter == PeriodFilter.all) return List.unmodifiable(_transactions);

    final now = DateTime.now();
    DateTime start;
    DateTime end;

    if (_filter == PeriodFilter.today) {
      start = DateTime(now.year, now.month, now.day);
      end = start;
    } else if (_filter == PeriodFilter.thisWeek) {
      final weekday = now.weekday; // 1..7
      start = DateTime(
        now.year,
        now.month,
        now.day,
      ).subtract(Duration(days: weekday - 1)); // Monday
      end = start.add(const Duration(days: 6));
    } else if (_filter == PeriodFilter.thisMonth) {
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 0); // last day of month
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
    final list = _filteredTransactions;
    double income = 0;
    double expense = 0;
    for (final t in list) {
      final type = t['type']?.toString() ?? 'Expense';
      final amount = (t['amount'] is num)
          ? (t['amount'] as num).toDouble()
          : double.tryParse(t['amount']?.toString() ?? '0') ?? 0.0;
      if (type == 'Income') {
        income += amount;
      } else {
        expense += amount;
      }
    }
    return {'income': income, 'expense': expense, 'balance': income - expense};
  }

  Future<void> _chooseCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: _customRange,
      builder: (context, child) => Theme(
        data: Theme.of(
          context,
        ).copyWith(dialogBackgroundColor: Colors.grey[900]),
        child: child ?? const SizedBox.shrink(),
      ),
    );

    if (picked != null) {
      setState(() {
        _filter = PeriodFilter.custom;
        _customRange = picked;
      });
    }
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
          if (confirmed == true) {
            // Deletion/logout logic is not here — handle through UserRepository or appropriate code
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (r) => false,
            );
          }
        },
        actions: [
          IconButton(
            icon: const Icon(Icons.person_outline, color: Colors.white),
            onPressed: () async {
              await Navigator.pushNamed(context, AppRoutes.profile);
              // reload list after return (in case transactions were modified)
              await _loadTransactions();
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top row: period filter + Add button (calls your AddTransactionScreen)
            Row(
              children: [
                Expanded(
                  child: DropdownButton<PeriodFilter>(
                    value: _filter,
                    isExpanded: true,
                    dropdownColor: Colors.grey[900],
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
                        _chooseCustomRange();
                      } else {
                        setState(() {
                          _filter = v;
                          if (v != PeriodFilter.custom) _customRange = null;
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
                      // Normalize id and date
                      tx['id'] =
                          tx['id']?.toString() ??
                          DateTime.now().millisecondsSinceEpoch.toString();
                      tx['date'] = (tx['date'] is DateTime)
                          ? (tx['date'] as DateTime).toIso8601String()
                          : tx['date']?.toString() ??
                                DateTime.now().toIso8601String();

                      // Persist via repo
                      await _txRepo.add(tx);
                      await _loadTransactions();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Transaction Added'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.tealAccent,
                    foregroundColor: Colors.black,
                  ),
                  child: const Text('Add'),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Statistics
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
                        const SizedBox(height: 6),
                        Text(
                          '${stats['income']?.toStringAsFixed(2)} \$',
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
                        const SizedBox(height: 6),
                        Text(
                          '${stats['expense']?.toStringAsFixed(2)} \$',
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
                        const SizedBox(height: 6),
                        Text(
                          '${stats['balance']?.toStringAsFixed(2)} \$',
                          style: TextStyle(
                            color: (stats['balance'] ?? 0) < 0
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

            // Transaction list (filtered)
            Expanded(
              child: _filteredTransactions.isEmpty
                  ? const Center(
                      child: Text(
                        'No transactions for selected period',
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredTransactions.length,
                      itemBuilder: (context, index) {
                        final tx = _filteredTransactions[index];
                        final id = tx['id']?.toString() ?? '';
                        final title = tx['title']?.toString() ?? 'Untitled';
                        final category = tx['category']?.toString() ?? '';
                        final type = tx['type']?.toString() ?? 'Expense';
                        final amount = (tx['amount'] is num)
                            ? (tx['amount'] as num).toString()
                            : (tx['amount']?.toString() ?? '0');
                        final dateStr = tx['date'];
                        final dateLabel = _formatDateForTile(dateStr);

                        // Because _filteredTransactions is a filtered view, to delete we need global index:
                        final globalIndex = _transactions.indexWhere(
                          (t) => (t['id']?.toString() ?? '') == id,
                        );

                        return Dismissible(
                          key: ValueKey(id),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (direction) =>
                              _onDismissConfirm(direction, id, title),
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.redAccent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.delete,
                              color: Colors.white,
                            ),
                          ),
                          child: Card(
                            color: Colors.grey[900],
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              title: Text(
                                title,
                                style: const TextStyle(color: Colors.white),
                              ),
                              subtitle: Text(
                                '$category • $type • $dateLabel',
                                style: const TextStyle(color: Colors.white70),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${type == 'Expense' ? '-' : '+'}$amount\$',
                                    style: TextStyle(
                                      color: type == 'Expense'
                                          ? Colors.redAccent
                                          : Colors.greenAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () async {
                                      if (globalIndex == -1) return;
                                      await _deleteTransactionByIndex(
                                        globalIndex,
                                      );
                                    },
                                  ),
                                ],
                              ),
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
