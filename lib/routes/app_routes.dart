import 'package:flutter/material.dart';
import 'package:my_project/screens/add_transaction_screen.dart';
import 'package:my_project/screens/edit_profile_screen.dart';
import 'package:my_project/screens/home_screen.dart';
import 'package:my_project/screens/login_screen.dart';
import 'package:my_project/screens/profile_screen.dart';
import 'package:my_project/screens/register_screen.dart';

class AppRoutes {
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const profile = '/profile';
  static const addTransaction = '/add_transaction';
  static const editProfile = '/edit-profile';

  static Map<String, WidgetBuilder> routes = {
    login: (context) => const LoginScreen(),
    register: (context) => const RegisterScreen(),
    home: (context) => const HomeScreen(),
    profile: (context) => const ProfileScreen(),
    addTransaction: (context) => const AddTransactionScreen(),
    editProfile: (context) => const EditProfileScreen()
  };
}
