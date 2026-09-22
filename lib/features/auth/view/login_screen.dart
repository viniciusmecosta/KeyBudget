import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:key_budget/app/utils/navigation_utils.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/view/forgot_password_screen.dart';
import 'package:key_budget/features/auth/view/register_screen.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/auth/widgets/auth_page_layout.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocusNode = FocusNode();
  bool _isPasswordVisible = false;
  String? _inlineError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    super.dispose();
  }

  void _submit({String? explicitPassword}) async {
    setState(() {
      _inlineError = null;
    });

    if (!_formKey.currentState!.validate()) return;
    final authViewModel = ref.read(authViewModelProvider);
    final email = _emailController.text.trim();
    final password = explicitPassword ?? _passwordController.text;

    final success = await authViewModel.loginUser(
      email: email,
      password: password,
    );

    if (mounted && !success) {
      final hasEdgeSpaces = password.trim() != password;
      if (hasEdgeSpaces) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Falha no login. Sua senha possui espaços no início ou fim. Deseja tentar sem eles?',
            ),
            duration: const Duration(seconds: 8),
            action: SnackBarAction(
              label: 'Tentar sem espaços',
              onPressed: () {
                _submit(explicitPassword: password.trim());
              },
            ),
          ),
        );
      } else {
        setState(() {
          _inlineError = authViewModel.errorMessage ??
              'Erro ao fazer login. Verifique suas credenciais.';
        });
      }
      _passwordController.clear();
    }
  }

  void _submitGoogle() async {
    setState(() {
      _inlineError = null;
    });
    final authViewModel = ref.read(authViewModelProvider);
    final success = await authViewModel.loginWithGoogle();
    if (mounted && !success) {
      if (authViewModel.errorMessage != null &&
          !authViewModel.errorMessage!.contains('cancelado')) {
        SnackbarService.showError(
          context,
          authViewModel.errorMessage!,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = ref.watch(authViewModelProvider);
    final isLoggingIn = viewModel.isOperating(AuthOperation.emailLogin);
    final isGoogleLoggingIn = viewModel.isOperating(AuthOperation.googleLogin);

    return AuthPageLayout(
      title: 'Entre na sua conta',
      subtitle: 'Acesse suas finanças e informações em um só lugar.',
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
          const SizedBox(height: AppSpacing.lg),
          _GoogleSignInButton(
            isLoading: isGoogleLoggingIn,
            onPressed: viewModel.isLoading ? null : _submitGoogle,
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Ainda não tem conta?',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(width: AppSpacing.xs),
              TextButton(
                onPressed: () =>
                    NavigationUtils.push(context, const RegisterScreen()),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Criar conta',
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
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppTextField(
                controller: _emailController,
                label: 'E-mail',
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email, AutofillHints.username],
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.none,
                onFieldSubmitted: (_) {
                  _passwordFocusNode.requestFocus();
                },
                validator: (value) => (value == null || !value.contains('@'))
                    ? 'Insira um email válido'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                controller: _passwordController,
                focusNode: _passwordFocusNode,
                label: 'Senha',
                prefixIcon: Icons.lock_outline,
                obscureText: !_isPasswordVisible,
                autofillHints: const [AutofillHints.password],
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                  ),
                  tooltip: _isPasswordVisible ? 'Ocultar senha' : 'Mostrar senha',
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                validator: (value) => (value == null || value.isEmpty)
                    ? 'Informe sua senha'
                    : null,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    NavigationUtils.push(
                      context,
                      ForgotPasswordScreen(
                        initialEmail: _emailController.text.trim().isNotEmpty
                            ? _emailController.text.trim()
                            : null,
                      ),
                    );
                  },
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
              if (_inlineError != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.errorContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        size: 18,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          _inlineError!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onErrorContainer,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: isLoggingIn ? 'Entrando...' : 'Entrar',
                isFullWidth: true,
                isLoading: isLoggingIn,
                onPressed: viewModel.isLoading ? null : _submit,
              ),
            ],
          ),
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
          minimumSize: const Size(48, 48),
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
