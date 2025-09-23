import 'package:flutter/material.dart';
import 'package:key_budget/features/credentials/view/widgets/logo_picker.dart';
import 'package:key_budget/features/credentials/view/widgets/saved_logos_screen.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

import '../../../app/widgets/paste_sanatizer_input_formatter.dart';

class SupplierForm extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nameController;
  final TextEditingController repNameController;
  final TextEditingController emailController;
  final TextEditingController phoneController;
  final TextEditingController notesController;
  final String? photoPath;
  final Function(String?) onPhotoChanged;
  final bool isEditing;

  const SupplierForm({
    super.key,
    required this.formKey,
    required this.nameController,
    required this.repNameController,
    required this.emailController,
    required this.phoneController,
    required this.notesController,
    required this.photoPath,
    required this.onPhotoChanged,
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
        MaterialPageRoute(
          builder: (_) => const SavedLogosScreen(isForSuppliers: true),
        ),
      );
      if (selectedLogo != null) {
        onPhotoChanged(selectedLogo);
      }
    }

    return Form(
      key: formKey,
      child: ListView(
        children: [
          Center(
            child: AbsorbPointer(
              absorbing: !isEditing && photoPath != null,
              child: LogoPicker(
                initialImagePath: photoPath,
                onImageSelected: (path) {
                  onPhotoChanged(path);
                },
              ),
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
              if (photoPath != null) ...[
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () => onPhotoChanged(null),
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
            controller: nameController,
            textCapitalization: TextCapitalization.words,
            decoration:
                const InputDecoration(labelText: 'Nome Fornecedor/Loja *'),
            validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: repNameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Nome Representante'),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: emailController,
            decoration: const InputDecoration(labelText: 'Email'),
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value)) {
                return 'Por favor, insira um email válido.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: phoneController,
            inputFormatters: [
              PasteSanitizerInputFormatter(),
              phoneMaskFormatter
            ],
            decoration: const InputDecoration(labelText: 'Telefone (WhatsApp)'),
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              final unmaskedText =
                  phoneMaskFormatter.unmaskText(phoneController.text);
              if (unmaskedText.isNotEmpty && unmaskedText.length < 10) {
                return 'O telefone deve ter no mínimo 10 dígitos.';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: notesController,
            decoration: const InputDecoration(labelText: 'Observações'),
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}
