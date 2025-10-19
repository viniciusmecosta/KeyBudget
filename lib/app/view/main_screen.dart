import 'package:flutter/material.dart';
import 'package:key_budget/app/viewmodel/navigation_viewmodel.dart';
import 'package:key_budget/app/widgets/main_bottom_navigation_bar.dart';
import 'package:key_budget/features/credentials/view/credentials_screen.dart';
import 'package:key_budget/features/dashboard/view/dashboard_screen.dart';
import 'package:key_budget/features/documents/view/documents_screen.dart';
import 'package:key_budget/features/expenses/view/expenses_screen.dart';
import 'package:key_budget/features/user/view/user_screen.dart';
import 'package:provider/provider.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const List<Widget> _widgetOptions = <Widget>[
    DashboardScreen(),
    ExpensesScreen(),
    CredentialsScreen(),
    DocumentsScreen(),
    UserScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final navigationViewModel = Provider.of<NavigationViewModel>(context);

    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: KeyedSubtree(
          key: ValueKey<int>(navigationViewModel.selectedIndex),
          child: _widgetOptions[navigationViewModel.selectedIndex],
        ),
        transitionBuilder: (Widget child, Animation<double> animation) {
          final isGoingForward = navigationViewModel.selectedIndex >
              navigationViewModel.previousIndex;
          final beginOffset =
              isGoingForward ? const Offset(0.2, 0.0) : const Offset(-0.2, 0.0);

          final tween = Tween(begin: beginOffset, end: Offset.zero);
          final curvedAnimation = CurvedAnimation(
            parent: animation,
            curve: Curves.easeInOutCubic,
          );

          return SlideTransition(
            position: tween.animate(curvedAnimation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
      ),
      bottomNavigationBar: const MainBottomNavigationBar(),
    );
  }
}
