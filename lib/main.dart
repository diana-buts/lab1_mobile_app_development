import 'package:flutter/material.dart';
import 'package:my_project/repositories/local_user_repository.dart';
import 'package:my_project/routes/app_routes.dart';
import 'package:my_project/screens/home_screen.dart';
import 'package:my_project/screens/login_screen.dart';
import 'package:my_project/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repo = LocalUserRepository();
  final loggedIn = await repo.isLoggedIn();

  runApp(BudgetBuddyApp(isLoggedIn: loggedIn));
}

class BudgetBuddyApp extends StatelessWidget {
  final bool isLoggedIn;

  const BudgetBuddyApp({
    super.key,
    this.isLoggedIn = false,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BudgetBuddy',
      theme: AppTheme.darkTheme,
      debugShowCheckedModeBanner: false,
      routes: AppRoutes.routes,
      home: isLoggedIn ? const HomeScreen() : const LoginScreen(),
    );
  }
}
