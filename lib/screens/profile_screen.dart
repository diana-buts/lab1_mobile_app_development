import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/custom_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Profile'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.tealAccent,
              child: Icon(Icons.person, size: 50),
            ),
            const SizedBox(height: 20),
            const Text('Diana Buts', style: TextStyle(fontSize: 22)),
            const Text(
              'diana@example.com',
              style: TextStyle(color: Colors.white54),
            ),
            const SizedBox(height: 30),
            CustomButton(text: 'Edit Profile', onPressed: () {}),
          ],
        ),
      ),
    );
  }
}
