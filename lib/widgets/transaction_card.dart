import 'package:flutter/material.dart';

class TransactionCard extends StatelessWidget {
  final String title;
  final String amount;
  final bool isIncome;
  const TransactionCard({
    super.key,
    required this.title,
    required this.amount,
    required this.isIncome,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(
          isIncome ? Icons.arrow_downward : Icons.arrow_upward,
          color: isIncome ? Colors.greenAccent : Colors.redAccent,
        ),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        trailing: Text(
          '${isIncome ? '+' : '-'} \$${amount}',
          style: TextStyle(
            color: isIncome ? Colors.greenAccent : Colors.redAccent,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
