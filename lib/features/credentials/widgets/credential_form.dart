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
  });

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
      child: ListView(
        children: [
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
          const SizedBox(height: AppSpacing.sm),
          if (isEditing)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton.icon(
                  onPressed: selectSavedLogo,
                  icon:
                      const Icon(Icons.collections_bookmark_outlined, size: 18),
                  label: const Text('Escolher Salva'),
                ),
                if (logoPath != null) ...[
                  const SizedBox(width: AppSpacing.sm),
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
          const SizedBox(height: AppSpacing.xl),
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
                ...availableFolders.map((folder) => DropdownMenuItem(
                      value: folder.id,
                      child: Text(folder.name),
                    )),
              ],
              onChanged: isEditing ? onFolderChanged : null,
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          AppTextField(
            controller: locationController,
            label: 'Local/Serviço *',
            readOnly: !isEditing,
            textCapitalization: TextCapitalization.sentences,
            validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: loginController,
            label: 'Login/Usuário *',
            readOnly: !isEditing,
            validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          PasswordFormField(
            controller: passwordController,
            labelText: 'Senha *',
            readOnly: !isEditing,
            forceVisible: isEditing,
            validator: (value) => value!.isEmpty ? 'Campo obrigatório' : null,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: emailController,
            label: 'Email',
            readOnly: !isEditing,
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: phoneController,
            label: 'Número',
            readOnly: !isEditing,
            inputFormatters: [phoneMaskFormatter],
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: notesController,
            label: 'Observações',
            readOnly: !isEditing,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ),
    );
  }
}
