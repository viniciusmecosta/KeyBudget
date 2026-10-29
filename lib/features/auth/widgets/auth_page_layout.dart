import 'package:passfin/core/design_system/widgets/passfin_brand.dart';
import 'package:passfin/core/design_system/widgets/app_card.dart';
import 'package:passfin/core/design_system/widgets/app_page_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:passfin/app/utils/app_animations.dart';
import 'package:passfin/core/design_system/spacing/app_spacing.dart';

class AuthPageLayout extends StatelessWidget {
  final Widget child;
  final String title;
  final String subtitle;
  final bool showBackButton;
  final Widget? footer;

  const AuthPageLayout({
    super.key,
    required this.child,
    this.title = 'PassFin',
    this.subtitle = 'Suas senhas e finanças em um só lugar',
    this.showBackButton = false,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCompact = MediaQuery.of(context).size.width < 600;
    final horizontalPadding = isCompact ? AppSpacing.md : AppSpacing.xl;

    return AppPageScaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: showBackButton
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Voltar',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            )
          : null,
      body: SafeArea(
        child: AppAnimations.fadeIn(
          Center(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPadding,
                vertical: AppSpacing.lg,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Hero(
                        tag: 'auth_logo',
                        child: const PassFinBrand(showName: true, width: 232),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      title,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppCard(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: child,
                    ),
                    if (footer != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      footer!,
                    ],
                  ],
                ),
              ),
            ),
          ),

          context: context,
        ),
      ),
    );
  }
}
