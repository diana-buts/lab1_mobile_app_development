import 'package:flutter/material.dart';

/// Головна функція — точка входу в застосунок
void main() {
  runApp(const MyApp());
}

/// Основний віджет застосунку
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

/// Stateful віджет для інтерактивного лічильника
class InteractiveCounter extends StatefulWidget {
  const InteractiveCounter({super.key});

  @override
  State<InteractiveCounter> createState() => _InteractiveCounterState();
}

class _InteractiveCounterState extends State<InteractiveCounter> {
  int _counter = 0;
  final TextEditingController _controller = TextEditingController();
  Color _textColor = Colors.black;

  /// Метод для звичайного інкременту
  void _increment() {
    setState(() {
      _counter++;
    });
  }

  /// Метод для обробки введеного тексту
  void _processInput() {
    final input = _controller.text.trim();

    if (input.toLowerCase() == 'avada kedavra') {
      setState(() {
        _counter = 0;
        _textColor = Colors.red;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('💥 Spell casted! Counter reset.')),
      );

      // Через секунду повертаємо колір тексту назад
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          setState(() => _textColor = Colors.black);
        }
      });
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

  /// Звільняємо ресурси контролера після завершення
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _textColor,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _controller,
              onSubmitted: (_) => _processInput(),
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
