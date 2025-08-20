import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/features/auth/view/login_screen.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: "assets/.env");

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel()),
        ChangeNotifierProvider(create: (_) => ExpenseViewModel()),
        ChangeNotifierProvider(create: (_) => CredentialViewModel()),
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeyBudget',
      theme: AppTheme.theme,
      home: const LoginScreen(),
    );
  }
}
