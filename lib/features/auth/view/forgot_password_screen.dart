import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_button.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/auth/widgets/auth_page_layout.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  final String? initialEmail;

  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController;
  bool _isSending = false;
  bool _sentSuccess = false;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _cooldownSeconds = 30);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() => _cooldownSeconds = 0);
      } else {
        setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _submit() async {
    if (_cooldownSeconds > 0) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSending = true);
    final authViewModel = ref.read(authViewModelProvider);
    final result =
        await authViewModel.sendPasswordResetEmail(_emailController.text);

    if (!mounted) return;
    setState(() => _isSending = false);

    if (result.isSuccess) {
      setState(() => _sentSuccess = true);
      _startCooldown();
      SnackbarService.showSuccess(
        context,
        result.message ??
            'Se houver uma conta com este e-mail, você receberá as instruções para redefinir sua senha.',
      );
    } else {
      SnackbarService.showError(
        context,
        result.safeError ?? 'Não foi possível enviar as instruções.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isButtonDisabled = _isSending || _cooldownSeconds > 0;
    String buttonLabel;
    if (_cooldownSeconds > 0) {
      buttonLabel = 'Reenviar em ${_cooldownSeconds}s';
    } else if (_sentSuccess) {
      buttonLabel = 'Reenviar Instruções';
    } else {
      buttonLabel = 'Enviar E-mail';
    }

    return AuthPageLayout(
      title: "Recuperar Senha",
      subtitle:
          "Informe seu e-mail para receber as instruções de recuperação.",
      footer: TextButton(
        onPressed: () => Navigator.of(context).pop(),
        child: Text(
          'Voltar para o Login',
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            AppTextField(
              controller: _emailController,
              label: 'E-mail',
              hint: 'exemplo@email.com',
              prefixIcon: Icons.mail_outline,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.done,
              readOnly: _isSending,
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) return 'Informe o e-mail.';
                if (!trimmed.contains('@')) return 'E-mail inválido.';
                return null;
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              label: buttonLabel,
              isFullWidth: true,
              isLoading: _isSending,
              onPressed: isButtonDisabled ? null : _submit,
            ),
          ],
        ),
      ),
    );
  }
}
