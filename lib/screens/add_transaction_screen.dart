import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/app_header.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _type = 'Expense'; // Default
  String? _category;

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

              // Transaction Type Switch
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
              const CustomTextField(hint: 'Title (e.g. Coffee, Salary)'),
              const SizedBox(height: 12),
              const CustomTextField(hint: 'Amount (USD)'),
              const SizedBox(height: 12),

              // Category Dropdown
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
                value: _category,
                onChanged: (value) => setState(() => _category = value),
                items: _type == 'Expense'
                    ? const [
                        DropdownMenuItem(value: 'Food', child: Text('Food')),
                        DropdownMenuItem(
                          value: 'Transport',
                          child: Text('Transport'),
                        ),
                        DropdownMenuItem(
                          value: 'Shopping',
                          child: Text('Shopping'),
                        ),
                        DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ]
                    : const [
                        DropdownMenuItem(
                          value: 'Salary',
                          child: Text('Salary'),
                        ),
                        DropdownMenuItem(
                          value: 'Freelance',
                          child: Text('Freelance'),
                        ),
                        DropdownMenuItem(
                          value: 'Investment',
                          child: Text('Investment'),
                        ),
                        DropdownMenuItem(value: 'Gift', child: Text('Gift')),
                      ],
                hint: const Text(
                  'Select Category',
                  style: TextStyle(color: Colors.white54),
                ),
              ),

              const SizedBox(height: 24),
              CustomButton(
                text: 'Save $_type',
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('$_type added successfully!'),
                      backgroundColor: _type == 'Expense'
                          ? Colors.redAccent
                          : Colors.green,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
