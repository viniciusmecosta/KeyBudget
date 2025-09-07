import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/core/services/app_lock_service.dart';
import 'package:key_budget/features/analysis/viewmodel/analysis_viewmodel.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/dashboard/viewmodel/dashboard_viewmodel.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';

List<SingleChildWidget> appProviders = [
  ChangeNotifierProvider(create: (_) => AuthViewModel()),
  ChangeNotifierProvider(create: (_) => AppLockService()),
  ChangeNotifierProvider(create: (_) => NavigationViewModel()),
  ChangeNotifierProvider(create: (_) => CategoryViewModel()),
  ChangeNotifierProvider(create: (_) => CredentialViewModel()),
  ChangeNotifierProvider(create: (_) => ExpenseViewModel()),
  // ChangeNotifierProvider(create: (_) => SupplierViewModel()),
  ChangeNotifierProxyProvider2<CategoryViewModel, ExpenseViewModel,
      AnalysisViewModel>(
    create: (context) => AnalysisViewModel(
      categoryViewModel: context.read<CategoryViewModel>(),
      expenseViewModel: context.read<ExpenseViewModel>(),
    ),
    update: (context, categoryViewModel, expenseViewModel, analysisViewModel) =>
        AnalysisViewModel(
      categoryViewModel: categoryViewModel,
      expenseViewModel: expenseViewModel,
    ),
  ),
  ChangeNotifierProxyProvider3<CategoryViewModel, ExpenseViewModel,
      CredentialViewModel, DashboardViewModel>(
    create: (context) => DashboardViewModel(
      categoryViewModel: context.read<CategoryViewModel>(),
      expenseViewModel: context.read<ExpenseViewModel>(),
      credentialViewModel: context.read<CredentialViewModel>(),
    ),
    update: (context, categoryViewModel, expenseViewModel, credentialViewModel,
            dashboardViewModel) =>
        DashboardViewModel(
      categoryViewModel: categoryViewModel,
      expenseViewModel: expenseViewModel,
      credentialViewModel: credentialViewModel,
    ),
  ),
];
