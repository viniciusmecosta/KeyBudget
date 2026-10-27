import 'package:flutter/material.dart';
import 'package:key_budget/core/design_system/widgets/passfin_brand.dart';

/// Continues the native splash while application services initialize.
/// There is no artificial delay; startup ends as soon as the app is ready.
class StartupScreen extends StatelessWidget {
  const StartupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PassFinBrand(showName: true, width: 240),
                SizedBox(height: 32),
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    semanticsLabel: 'Abrindo PassFin',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
