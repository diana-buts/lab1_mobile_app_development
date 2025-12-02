import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/transaction_card.dart';
import '../routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'My Transactions'),
      body: ListView(
        children: const [
          TransactionCard(title: 'Groceries', amount: '45.20', isIncome: false),
          TransactionCard(title: 'Salary', amount: '1200.00', isIncome: true),
          TransactionCard(title: 'Netflix', amount: '9.99', isIncome: false),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRoutes.addTransaction),
        child: const Icon(Icons.add),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.teal),
              child: Text(
                'BudgetBuddy',
                style: TextStyle(fontSize: 22, color: Colors.white),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Profile'),
              onTap: () => Navigator.pushNamed(context, AppRoutes.profile),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () => Navigator.pushNamed(context, AppRoutes.login),
            ),
          ],
        ),
      ),
    );
  }
}
