import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Lab 1',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const InteractiveCounter(),
    );
  }
}

class InteractiveCounter extends StatefulWidget {
  const InteractiveCounter({super.key});

  @override
  State<InteractiveCounter> createState() => _InteractiveCounterState();
}

class _InteractiveCounterState extends State<InteractiveCounter> {
  int _counter = 0;
  final TextEditingController _controller = TextEditingController();

  void _increment() {
    setState(() {
      _counter++;
    });
  }

  void _processInput() {
    final input = _controller.text.trim();

    if (input.toLowerCase() == 'avada kedavra') {
      setState(() {
        _counter = 0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('💥 Spell casted! Counter reset.')),
      );
    } else if (int.tryParse(input) != null) {
      setState(() {
        _counter += int.parse(input);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('⚠️ Enter a number or "Avada Kedavra"!')),
      );
    }

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Interactive Counter 🧮')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Current value: $_counter',
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Enter number or spell',
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _processInput,
              child: const Text('Apply Input'),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _increment,
              icon: const Icon(Icons.add),
              label: const Text('Increment by 1'),
            ),
          ],
        ),
      ),
    );
  }
}
