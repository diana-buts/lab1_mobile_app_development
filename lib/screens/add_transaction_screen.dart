import 'dart:math';
import 'package:flutter/material.dart';
import 'package:my_project/widgets/app_header.dart';
import 'package:my_project/widgets/custom_button.dart';
import 'package:my_project/widgets/custom_textfield.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _type = 'Expense';
  String? _category;
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  String _generateId() {
    final rand = Random();
    return DateTime.now().millisecondsSinceEpoch.toString() +
        "_" +
        rand.nextInt(100000).toString();
  }

  void _saveTransaction() {
    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;

    if (title.isEmpty || amount <= 0 || _category == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields correctly!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final newTransaction = {
      'id': _generateId(),
      'title': title,
      'amount': amount,
      'type': _type, // Income | Expense
      'category': _category,
      'date': DateTime.now().toIso8601String(),
    };

    Navigator.pop(context, newTransaction);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Add Transaction'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Transaction Details',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ChoiceChip(
                    label: const Text('Expense'),
                    selected: _type == 'Expense',
                    onSelected: (_) => setState(() => _type = 'Expense'),
                    selectedColor: Colors.redAccent,
                    backgroundColor: Colors.grey[900],
                    labelStyle: TextStyle(
                      color: _type == 'Expense' ? Colors.white : Colors.white70,
                    ),
                  ),
                  const SizedBox(width: 10),
                  ChoiceChip(
                    label: const Text('Income'),
                    selected: _type == 'Income',
                    onSelected: (_) => setState(() => _type = 'Income'),
                    selectedColor: Colors.green,
                    backgroundColor: Colors.grey[900],
                    labelStyle: TextStyle(
                      color: _type == 'Income' ? Colors.white : Colors.white70,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              CustomTextField(
                hint: 'Title (e.g. Coffee, Salary)',
                controller: _titleController,
              ),
              const SizedBox(height: 12),
              CustomTextField(
                hint: 'Amount (USD)',
                controller: _amountController,
              ),
              const SizedBox(height: 12),

              DropdownButtonFormField<String>(
                dropdownColor: Colors.grey[900],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (value) => setState(() => _category = value),
                items: _type == 'Expense'
                    ? const [
                        DropdownMenuItem(value: 'Food', child: Text('Food')),
                        DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                        DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                        DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ]
                    : const [
                        DropdownMenuItem(value: 'Salary', child: Text('Salary')),
                        DropdownMenuItem(value: 'Freelance', child: Text('Freelance')),
                        DropdownMenuItem(value: 'Investment', child: Text('Investment')),
                        DropdownMenuItem(value: 'Gift', child: Text('Gift')),
                      ],
                hint: const Text('Select Category', style: TextStyle(color: Colors.white54)),
              ),

              const SizedBox(height: 24),
              CustomButton(text: 'Save $_type', onPressed: _saveTransaction),
            ],
          ),
        ),
      ),
    );
  }
}
