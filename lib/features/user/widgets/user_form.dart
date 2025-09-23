import 'package:flutter/material.dart';
import 'package:key_budget/app/widgets/image_picker_widget.dart';
import 'package:key_budget/app/widgets/password_form_field.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class UserForm extends StatefulWidget {
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
  State<UserForm> createState() => _UserFormState();
}

class _UserFormState extends State<UserForm> {
  final _phoneMaskFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  Widget build(BuildContext context) {
    return Form(
      key: widget.formKey,
      child: ListView(
        children: [
          const SizedBox(height: 16),
          Center(
            child: ImagePickerWidget(
              initialImagePath: widget.avatarPath,
              onImageSelected: (path) {
                widget.onAvatarChanged(path);
              },
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                children: [
                  TextFormField(
                    controller: widget.nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                        labelText: 'Nome *',
                        prefixIcon: Icon(Icons.person_outline)),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'Insira seu nome'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: widget.phoneController,
                    inputFormatters: [_phoneMaskFormatter],
                    decoration: const InputDecoration(
                        labelText: 'Número',
                        prefixIcon: Icon(Icons.phone_outlined)),
                    keyboardType: TextInputType.phone,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Alterar Senha',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Deixe os campos em branco para não alterar a senha.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 20),
                  PasswordFormField(
                    controller: widget.passwordController,
                    labelText: 'Nova Senha',
                    validator: (value) {
                      if (value != null &&
                          value.isNotEmpty &&
                          value.length < 6) {
                        return 'A senha deve ter pelo menos 6 caracteres';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  PasswordFormField(
                    controller: widget.confirmPasswordController,
                    labelText: 'Confirmar Nova Senha',
                    validator: (value) =>
                        value != widget.passwordController.text
                            ? 'As senhas não coincidem'
                            : null,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
