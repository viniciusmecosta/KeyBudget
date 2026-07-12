import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/widgets/image_picker_widget.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
import 'package:key_budget/core/utils/formatters.dart';
import 'package:key_budget/features/credentials/widgets/saved_logos_screen.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class SupplierForm extends ConsumerWidget {
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

  Widget _sectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    final color = theme.brightness == Brightness.dark ? Colors.white : Colors.black87;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: AppSpacing.sm),
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.2,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          const SizedBox(height: AppSpacing.md),
          Center(
            child: AbsorbPointer(
              absorbing: !isEditing && photoPath != null,
              child: ImagePickerWidget(
                initialImagePath: photoPath,
                onImageSelected: (path) => onPhotoChanged(path),
                radius: 40,
                placeholderIcon: Icons.store_mall_directory,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextButton.icon(
                onPressed: selectSavedLogo,
                icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
                label: const Text('Escolher Logo'),
              ),
              if (photoPath != null) ...[
                const SizedBox(width: AppSpacing.sm),
                TextButton.icon(
                  onPressed: () => onPhotoChanged(null),
                  icon: const Icon(Icons.no_photography_outlined, size: 18),
                  label: const Text('Remover'),
                  style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionHeader(context, 'IDENTIFICAÇÃO', Icons.store_outlined),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: nameController,
            label: 'Nome do Fornecedor / Loja *',
            prefixIcon: Icons.storefront_outlined,
            textCapitalization: TextCapitalization.words,
            readOnly: !isEditing,
            textInputAction: TextInputAction.next,
            validator: (value) =>
                value == null || value.isEmpty ? 'Informe o nome do fornecedor' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: repNameController,
            label: 'Nome do Representante',
            prefixIcon: Icons.person_outline,
            textCapitalization: TextCapitalization.words,
            readOnly: !isEditing,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionHeader(context, 'CONTATO', Icons.contacts_outlined),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: emailController,
            label: 'Email',
            prefixIcon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            readOnly: !isEditing,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
              if (!emailRegex.hasMatch(value)) return 'Insira um email válido';
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: phoneController,
            label: 'Telefone / WhatsApp',
            prefixIcon: Icons.phone_outlined,
            inputFormatters: [PasteSanitizerInputFormatter(), phoneMaskFormatter],
            keyboardType: TextInputType.phone,
            readOnly: !isEditing,
            textInputAction: TextInputAction.next,
            validator: (value) {
              if (value == null || value.isEmpty) return null;
              final unmasked = phoneMaskFormatter.unmaskText(phoneController.text);
              if (unmasked.isNotEmpty && unmasked.length < 10) {
                return 'O telefone deve ter no mínimo 10 dígitos';
              }
              return null;
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionHeader(context, 'EXTRAS', Icons.notes_outlined),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: notesController,
            label: 'Observações',
            prefixIcon: Icons.edit_note_outlined,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            readOnly: !isEditing,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
