import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:my_project/repositories/local_user_repository.dart';
import 'package:my_project/routes/app_routes.dart';
import 'package:my_project/widgets/custom_button.dart';
import 'package:my_project/widgets/custom_textfield.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final repo = LocalUserRepository();

  Future<void> _register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (name.isEmpty || email.isEmpty || password.isEmpty) {
      _showError('Please fill all fields');
      return;
    }

    if (!email.contains('@')) {
      _showError('Invalid email format');
      return;
    }

    if (RegExp(r'\d').hasMatch(name)) {
      _showError('Name cannot contain numbers');
      return;
    }

    if (!_isPasswordStrong(password)) {
      _showError(
        'Password must be at least 8 characters, include an uppercase letter, a number, and a special character',
      );
      return;
    }

    // Перевірка інтернету перед реєстрацією
    final connection = await Connectivity().checkConnectivity();
    if (connection == ConnectivityResult.none) {
      _showError('No internet connection');
      return;
    }

    // Збереження юзера
    await repo.saveUser(name, email, password);

    // Одразу логінимо
    Navigator.pushReplacementNamed(context, AppRoutes.home);
  }

  bool _isPasswordStrong(String password) {
    final regex = RegExp(r'^(?=.*[A-Z])(?=.*\d)(?=.*[!@#\$&*~]).{8,}$');
    return regex.hasMatch(password);
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
                  'Create Account',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),

                CustomTextField(hint: 'Name', controller: nameController),
                const SizedBox(height: 12),

                CustomTextField(hint: 'Email', controller: emailController),
                const SizedBox(height: 12),

                CustomTextField(
                  hint: 'Password',
                  obscureText: true,
                  controller: passwordController,
                ),

                const SizedBox(height: 8),
                const Text(
                  'Password must be at least 8 characters,\ninclude an uppercase letter, a number, and a special character',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),

                const SizedBox(height: 24),
                CustomButton(text: 'Register', onPressed: _register),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Already have an account? Login'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
