import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeyBudget',
      home: Scaffold(
        appBar: AppBar(title: const Text('KeyBudget')),
        body: const Center(child: Text('Configuração Inicial Completa')),
      ),
    );
  }
}
