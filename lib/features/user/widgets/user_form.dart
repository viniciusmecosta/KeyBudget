import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/widgets/image_picker_widget.dart';
import 'package:key_budget/app/widgets/password_form_field.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class UserForm extends ConsumerStatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController phoneController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;
  final String? avatarPath;
  final Function(String?) onAvatarChanged;

  const UserForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.phoneController,
    required this.passwordController,
    required this.confirmPasswordController,
    required this.avatarPath,
    required this.onAvatarChanged,
  });

  @override
  ConsumerState<UserForm> createState() => _UserFormState();
}

class _UserFormState extends ConsumerState<UserForm> {
  bool _passwordExpanded = false;

  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #.####.####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  Widget _sectionHeader(BuildContext context, String label, IconData icon) {
    final theme = Theme.of(context);
    final color = theme.brightness == Brightness.dark ? Colors.white : Colors.black87;
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.titleSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Divider(
              color: theme.colorScheme.primary.withValues(alpha: 0.25),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Form(
      key: widget.formKey,
      child: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          Center(
            child: ImagePickerWidget(
              initialImagePath: widget.avatarPath,
              onImageSelected: (path) => widget.onAvatarChanged(path),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (widget.avatarPath != null)
            Center(
              child: TextButton.icon(
                onPressed: () => widget.onAvatarChanged(null),
                icon: const Icon(Icons.no_photography_outlined, size: 18),
                label: const Text('Remover foto'),
                style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
              ),
            ),
          _sectionHeader(context, 'INFORMAÇÕES PESSOAIS', Icons.person_outline),
          AppTextField(
            controller: widget.nameController,
            label: 'Nome completo *',
            prefixIcon: Icons.badge_outlined,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                (value == null || value.isEmpty) ? 'Insira seu nome' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: widget.phoneController,
            label: 'Telefone',
            prefixIcon: Icons.phone_outlined,
            inputFormatters: [_phoneMaskFormatter],
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.done,
          ),
          _sectionHeader(context, 'SEGURANÇA', Icons.lock_outline),
          Theme(
            data: theme.copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              initiallyExpanded: _passwordExpanded,
              onExpansionChanged: (v) => setState(() => _passwordExpanded = v),
              leading: Icon(
                Icons.key_outlined,
                color: theme.colorScheme.primary,
              ),
              title: Text(
                'Alterar Senha',
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(
                'Toque para expandir',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              children: [
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Deixe em branco para manter a senha atual.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                PasswordFormField(
                  controller: widget.passwordController,
                  labelText: 'Nova Senha',
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length < 6) {
                      return 'A senha deve ter pelo menos 6 caracteres';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: AppSpacing.md),
                PasswordFormField(
                  controller: widget.confirmPasswordController,
                  labelText: 'Confirmar Nova Senha',
                  validator: (value) =>
                      value != widget.passwordController.text
                      ? 'As senhas não coincidem'
                      : null,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
