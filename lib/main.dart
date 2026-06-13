import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';
import 'package:key_budget/app/config/app_config.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/app/utils/app_scroll_behavior.dart';
import 'package:key_budget/app/view/auth_gate.dart';
import 'package:key_budget/app/view/lock_screen.dart';
import 'package:key_budget/core/services/app_lock_service.dart';
import 'package:key_budget/core/services/home_widget_service.dart';
import 'package:key_budget/core/services/notification_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/dashboard/widgets/dashboard_skeleton.dart';
import 'package:key_budget/features/expenses/view/add_expense_screen.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(child: AppInitializer()),
  );
}

class AppInitializer extends ConsumerStatefulWidget {
  const AppInitializer({super.key});

  @override
  ConsumerState<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends ConsumerState<AppInitializer> {
  Future<void>? _initFuture;

  @override
  void initState() {
    super.initState();
    _initFuture = _initServices();
  }

  Future<void> _initServices() async {
    await AppConfig.initialize();
    ref.read(authViewModelProvider);
    HomeWidgetService.initialize();
    NotificationService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _initFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return ErrorScreen(error: snapshot.error.toString());
          }
          return const MyApp();
        }

        return MaterialApp(
          title: 'KeyBudget',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.system,
          debugShowCheckedModeBanner: false,
          scrollBehavior: const AppScrollBehavior(),
          home: const Scaffold(
            body: SafeArea(
              child: DashboardSkeleton(),
            ),
          ),
        );
      },
    );
  }
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  Uri? _pendingWidgetUri;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HomeWidget.widgetClicked.listen(_launchedFromWidget);
    _checkInitialWidgetLaunch();
  }

  Future<void> _checkInitialWidgetLaunch() async {
    final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
    if (uri != null && mounted) {
      _launchedFromWidget(uri);
    }
  }

  void _launchedFromWidget(Uri? uri) {
    if (uri?.host == 'addexpense') {
      _pendingWidgetUri = uri;
      _processPendingWidgetUri();
    }
  }

  void _processPendingWidgetUri() {
    if (_pendingWidgetUri == null) return;
    final context = navigatorKey.currentContext;

    if (context == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processPendingWidgetUri();
      });
      return;
    }

    final authViewModel = ref.read(authViewModelProvider);
    final appLockService = ref.read(appLockServiceProvider);

    void navigateAndClear() {
      _pendingWidgetUri = null;
      navigatorKey.currentState?.push(
        MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
      );
    }

    void checkReady() {
      if (authViewModel.currentUser != null && !appLockService.isLocked) {
        authViewModel.removeListener(checkReady);
        appLockService.removeListener(checkReady);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          navigateAndClear();
        });
      }
    }

    if (authViewModel.currentUser != null && !appLockService.isLocked) {
      navigateAndClear();
    } else {
      authViewModel.addListener(checkReady);
      appLockService.addListener(checkReady);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    final appLockService = ref.read(appLockServiceProvider);
    final authViewModel = ref.read(authViewModelProvider);

    if (state == AppLifecycleState.paused &&
        authViewModel.currentUser != null) {
      appLockService.lockApp();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'KeyBudget',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      scrollBehavior: const AppScrollBehavior(),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'),
      ],
      locale: const Locale('pt', 'BR'),
      home: const AuthGate(),
      builder: (context, navigator) {
        return Consumer(
          builder: (context, ref, _) {
            final appLock = ref.watch(appLockServiceProvider);
            return Stack(
              children: [
                if (navigator != null) navigator,
                if (appLock.isLocked) const LockScreen(),
              ],
            );
          },
        );
      },
    );
  }
}

class ErrorScreen extends ConsumerWidget {
  final String error;

  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
