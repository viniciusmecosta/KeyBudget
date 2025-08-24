import 'package:key_budget/core/services/app_lock_service.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';

List<SingleChildWidget> appProviders = [
  ChangeNotifierProvider(create: (_) => AuthViewModel()),
  ChangeNotifierProvider(create: (_) => ExpenseViewModel()),
  ChangeNotifierProvider(create: (_) => CredentialViewModel()),
  ChangeNotifierProvider(create: (_) => DashboardViewModel()),
  ChangeNotifierProvider(create: (_) => AppLockService()),
  ChangeNotifierProvider(create: (_) => NavigationViewModel()),
];