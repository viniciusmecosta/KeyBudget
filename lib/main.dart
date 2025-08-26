import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:key_budget/app/config/app_providers.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/view/auth_gate.dart';
import 'package:key_budget/app/view/lock_screen.dart';
import 'package:key_budget/core/services/app_lock_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  try {
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp();
    await dotenv.load(fileName: "assets/.env");

    runApp(
      MultiProvider(
        providers: appProviders,
        child: const MyApp(),
      ),
    );
  } catch (e) {
    runApp(ErrorScreen(error: e.toString()));
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final appLockService = Provider.of<AppLockService>(context, listen: false);
    final authViewModel = Provider.of<AuthViewModel>(context, listen: false);

    if (state == AppLifecycleState.paused &&
        authViewModel.currentUser != null) {
      appLockService.lockApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'KeyBudget',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      locale: const Locale('pt', 'BR'),
      home: Consumer<AppLockService>(
        builder: (context, appLock, child) {
          return Stack(
            children: [
              child!,
              if (appLock.isLocked) const LockScreen(),
            ],
          );
        },
        child: const AuthGate(),
      ),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'Ocorreu um erro crítico na inicialização:\n\n$error',
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ),
      ),
    );
  }
}
