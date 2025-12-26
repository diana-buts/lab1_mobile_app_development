import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:my_project/repositories/user_repository_impl.dart';
import 'package:my_project/routes/app_routes.dart';
import 'package:my_project/widgets/custom_button.dart';
import 'package:my_project/widgets/custom_textfield.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final repo = BudgetUserRepository();

  Future<void> _login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    // Перевірка інтернету — твоя логіка лишається
    final connection = await Connectivity().checkConnectivity();
    if (connection == ConnectivityResult.none) {
      _showError('No internet connection');
      return;
    }

    final success = await repo.authenticate(email, password);

    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      _showError('Invalid email or password');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                const Text(
                  'BudgetBuddy',
                  style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                CustomTextField(hint: 'Email', controller: emailController),
                const SizedBox(height: 12),

                CustomTextField(
                  hint: 'Password',
                  obscureText: true,
                  controller: passwordController,
                ),
                const SizedBox(height: 24),

                CustomButton(text: 'Login', onPressed: _login),

                TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRoutes.register),
                  child: const Text("Don't have an account? Register"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
