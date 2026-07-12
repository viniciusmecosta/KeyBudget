import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/widgets/image_picker_widget.dart';
import 'package:key_budget/app/widgets/password_form_field.dart';
import 'package:key_budget/core/design_system/spacing/app_spacing.dart';
import 'package:key_budget/core/design_system/widgets/app_text_field.dart';
import 'package:key_budget/core/models/folder_model.dart';
import 'package:key_budget/features/credentials/widgets/saved_logos_screen.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class CredentialForm extends ConsumerWidget {
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
  final List<Folder> availableFolders;
  final String? selectedFolderId;
  final Function(String?) onFolderChanged;
  final VoidCallback? onChanged;

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
    this.availableFolders = const [],
    this.selectedFolderId,
    required this.onFolderChanged,
    this.onChanged,
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
            fontWeight: FontWeight.bold,
            color: color,
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
        MaterialPageRoute(builder: (_) => const SavedLogosScreen()),
      );
      if (selectedLogo != null) {
        onLogoChanged(selectedLogo);
      }
    }

    return Form(
      key: formKey,
      onChanged: onChanged,
      child: ListView(
        children: [
          const SizedBox(height: AppSpacing.md),
          Center(
            child: AbsorbPointer(
              absorbing: !isEditing,
              child: ImagePickerWidget(
                initialImagePath: logoPath,
                onImageSelected: (path) => onLogoChanged(path),
                placeholderIcon: Icons.add_photo_alternate_outlined,
                radius: 40,
              ),
            ),
          ),
          if (isEditing)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: selectSavedLogo,
                  icon: const Icon(Icons.collections_bookmark_outlined, size: 18),
                  label: const Text('Escolher Salva'),
                ),
                if (logoPath != null) ...[
                  const SizedBox(width: AppSpacing.sm),
                  TextButton.icon(
                    onPressed: () => onLogoChanged(null),
                    icon: const Icon(Icons.no_photography_outlined, size: 18),
                    label: const Text('Remover'),
                    style: TextButton.styleFrom(foregroundColor: theme.colorScheme.error),
                  ),
                ],
              ],
            ),
          const SizedBox(height: AppSpacing.md),
          _sectionHeader(context, 'IDENTIFICAÇÃO', Icons.label_outline),
          const SizedBox(height: AppSpacing.sm),
          if (availableFolders.isNotEmpty) ...[
            DropdownButtonFormField<String?>(
              key: ValueKey(selectedFolderId),
              initialValue: selectedFolderId,
              decoration: const InputDecoration(
                labelText: 'Pasta',
                prefixIcon: Icon(Icons.folder_outlined),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('Nenhuma (Principal)'),
                ),
                ...availableFolders.map(
                  (folder) => DropdownMenuItem(value: folder.id, child: Text(folder.name)),
                ),
              ],
              onChanged: isEditing ? onFolderChanged : null,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppTextField(
            controller: locationController,
            label: 'Local / Serviço *',
            prefixIcon: Icons.language_outlined,
            readOnly: !isEditing,
            textCapitalization: TextCapitalization.sentences,
            textInputAction: TextInputAction.next,
            validator: (value) => value!.isEmpty ? 'Informe o local ou serviço' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionHeader(context, 'ACESSO', Icons.key_outlined),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: loginController,
            label: 'Login / Usuário *',
            prefixIcon: Icons.person_outline,
            readOnly: !isEditing,
            textInputAction: TextInputAction.next,
            validator: (value) => value!.isEmpty ? 'Informe o login ou usuário' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          PasswordFormField(
            controller: passwordController,
            labelText: 'Senha *',
            readOnly: !isEditing,
            forceVisible: isEditing,
            textInputAction: TextInputAction.next,
            validator: (value) => value!.isEmpty ? 'Informe a senha' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionHeader(context, 'CONTATO', Icons.contacts_outlined),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: emailController,
            label: 'Email',
            prefixIcon: Icons.email_outlined,
            readOnly: !isEditing,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: phoneController,
            label: 'Telefone',
            prefixIcon: Icons.phone_outlined,
            readOnly: !isEditing,
            inputFormatters: [phoneMaskFormatter],
            keyboardType: TextInputType.phone,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: AppSpacing.md),
          _sectionHeader(context, 'EXTRAS', Icons.notes_outlined),
          const SizedBox(height: AppSpacing.sm),
          AppTextField(
            controller: notesController,
            label: 'Observações',
            prefixIcon: Icons.edit_note_outlined,
            readOnly: !isEditing,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ),
    );
  }
}
