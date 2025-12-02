import 'package:flutter/material.dart';
import '../widgets/app_header.dart';
import '../repositories/local_user_repository.dart';
import '../repositories/user_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final UserRepository _userRepo = LocalUserRepository();

  String _name = '';
  String _email = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    final u = await _userRepo.getUser();
    setState(() {
      _name = u?['name'] ?? '';
      _email = u?['email'] ?? '';
      _loading = false;
    });
  }

  String? _validateName(String? value) {
    final v = value ?? '';
    if (v.trim().isEmpty) return 'Please enter full name';
    if (RegExp(r'\d').hasMatch(v)) return 'Name should not contain digits';
    return null;
  }

  String? _validateEmail(String? value) {
    final v = value ?? '';
    if (v.trim().isEmpty) return 'Please enter email';
    if (!v.contains('@') || v.startsWith('@') || v.endsWith('@')) {
      return 'Enter a valid email';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    final form = _formKey.currentState;
    if (form == null) return;
    if (!form.validate()) return;

    form.save();

    await _userRepo.updateUser(_name.trim(), _email.trim());

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated successfully!')),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppHeader(title: 'Edit Profile'),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      initialValue: _name,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: _validateName,
                      onSaved: (value) => _name = value ?? '',
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      initialValue: _email,
                      decoration: const InputDecoration(
                        labelText: 'Email Address',
                      ),
                      validator: _validateEmail,
                      onSaved: (value) => _email = value ?? '',
                    ),
                    const SizedBox(height: 40),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.tealAccent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 30,
                        ),
                      ),
                      onPressed: _saveProfile,
                      child: const Text(
                        'Save Changes',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
