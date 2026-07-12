import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/view/register_screen.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

import '../widgets/auth_page_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryBiometricAuth();
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _tryBiometricAuth() async {
    final authViewModel = ref.read(authViewModelProvider);
    if (authViewModel.currentUser == null) {
      await authViewModel.authenticateWithBiometrics();
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final authViewModel = ref.read(authViewModelProvider);
    final success = await authViewModel.loginUser(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );
    if (mounted && !success) {
      SnackbarService.showError(
        context,
        authViewModel.errorMessage ?? 'Erro ao fazer login. Verifique suas credenciais.',
      );
      _passwordController.clear();
    }
  }

  void _submitGoogle() async {
    final authViewModel = ref.read(authViewModelProvider);
    final success = await authViewModel.loginWithGoogle();
    if (mounted && !success) {
      SnackbarService.showError(
        context,
        authViewModel.errorMessage ?? 'Erro ao fazer login com Google.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(authViewModelProvider);

    return AuthPageLayout(
      title: "Bem-vindo de volta",
      subtitle: "Faça login para continuar",
      footer: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Divider(color: Theme.of(context).colorScheme.outlineVariant),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  'ou',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              Expanded(
                child: Divider(color: Theme.of(context).colorScheme.outlineVariant),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          _GoogleSignInButton(
            isLoading: viewModel.isLoading,
            onPressed: _submitGoogle,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Novo por aqui?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              TextButton(
                onPressed: () => NavigationUtils.push(context, const RegisterScreen()),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Cadastre-se',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              controller: _emailController,
              label: 'Email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) =>
                  (value == null || !value.contains('@')) ? 'Insira um email válido' : null,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _passwordController,
              label: 'Senha',
              prefixIcon: Icons.lock_outline,
              obscureText: !_isPasswordVisible,
              suffixIcon: IconButton(
                icon: Icon(
                  _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                ),
                onPressed: () {
                  setState(() {
                    _isPasswordVisible = !_isPasswordVisible;
                  });
                },
              ),
              validator: (value) => (value == null || value.length < 6)
                  ? 'A senha deve ter pelo menos 6 caracteres'
                  : null,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                    vertical: AppSpacing.sm,
                  ),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Esqueceu sua senha?',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              label: 'Entrar',
              isFullWidth: true,
              isLoading: viewModel.isLoading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoogleSignInButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onPressed;

  const _GoogleSignInButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.md,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.08),
            width: 1.5,
          ),
          backgroundColor: isDark 
              ? theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3) 
              : Colors.white,
          elevation: isDark ? 0 : 1,
          shadowColor: Colors.black.withValues(alpha: 0.05),
        ),
        child: isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: theme.colorScheme.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FaIcon(FontAwesomeIcons.google, size: 18, color: const Color(0xFF4285F4)),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    'Continuar com Google',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: isDark ? Colors.white : Colors.black87,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
