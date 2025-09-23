import 'package:flutter/material.dart';
import 'package:key_budget/features/credentials/widgets/logo_picker.dart';
import 'package:key_budget/features/credentials/widgets/saved_logos_screen.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../app/widgets/password_form_field.dart';

class CredentialForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController locationController;
  final TextEditingController loginController;
  final TextEditingController passwordController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController notesController;
  final String? logoPath;
  final Function(String?) onLogoChanged;
  final bool isEditing;

  const CredentialForm({
    super.key,
    required this.formKey,
    required this.locationController,
    required this.loginController,
    required this.passwordController,
    required this.emailController,
    required this.phoneController,
    required this.notesController,
    required this.logoPath,
    required this.onLogoChanged,
    this.isEditing = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final phoneMaskFormatter = MaskTextInputFormatter(
      mask: '(##) #####-####',
      filter: {"#": RegExp(r'[0-9]')},
    );

    void selectSavedLogo() async {
      final selectedLogo = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => const SavedLogosScreen()),
      );
      if (selectedLogo != null) {
        onLogoChanged(selectedLogo);
      }
    }

    return Form(
      key: formKey,
      child: ListView(
        children: [
          Center(
            child: LogoPicker(
              initialImagePath: logoPath,
              onImageSelected: (path) => onLogoChanged(path),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: selectSavedLogo,
                icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
                label: const Text('Escolher Salva'),
              ),
              if (logoPath != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => onLogoChanged(null),
                  icon: const Icon(Icons.no_photography_outlined, size: 18),
                  label: const Text('Remover'),
                  style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.error),
                ),
              ]
            ],
          ),
          const SizedBox(height: 24),
          TextFormField(
            controller: locationController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Local/Serviço *'),
            validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: loginController,
            decoration: const InputDecoration(labelText: 'Login/Usuário *'),
            validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 16),
          PasswordFormField(
            controller: passwordController,
            labelText: 'Senha *',
            validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: phoneController,
            inputFormatters: [phoneMaskFormatter],
            decoration: const InputDecoration(labelText: 'Número'),
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: notesController,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Observações'),
            maxLines: 3,
          ),
        ],
      ),
    );
  }
}
