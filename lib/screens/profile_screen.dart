import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../widgets/custom_button.dart';
import '../routes/app_routes.dart';
import '../repositories/local_user_repository.dart';
import '../repositories/user_repository.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserRepository _userRepo = LocalUserRepository();
  Map<String, String>? _user;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final u = await _userRepo.getUser();
    setState(() {
      _user = u;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Profile'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  // Мінімалістичний аватар — без можливості аплоаду
                  const CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.tealAccent,
                    child: Icon(Icons.person, size: 50),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    _user?['name'] ?? 'No name',
                    style: const TextStyle(fontSize: 22),
                  ),
                  Text(
                    _user?['email'] ?? 'No email',
                    style: const TextStyle(color: Colors.white54),
                  ),
                  const SizedBox(height: 30),
                  CustomButton(
                    text: 'Edit Profile',
                    onPressed: () {
                      Navigator.pushNamed(context, AppRoutes.editProfile).then((
                        _,
                      ) {
                        // Після повернення — перевантажимо дані
                        _loadUser();
                      });
                    },
                  ),
                ],
              ),
      ),
    );
  }
}
