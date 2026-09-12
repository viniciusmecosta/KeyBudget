import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:key_budget/app/utils/app_animations.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';

import 'package:key_budget/features/suppliers/viewmodel/supplier_viewmodel.dart';

class SavedLogosScreen extends ConsumerWidget {
  final bool isForSuppliers;

  const SavedLogosScreen({super.key, this.isForSuppliers = false});

  Widget _buildImageWidget(String imagePath, ThemeData theme) {
    try {
      if (imagePath.startsWith('http://') || imagePath.startsWith('https://')) {
        return Image.network(
          imagePath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => Icon(
            Icons.broken_image_outlined,
            color: theme.colorScheme.error,
          ),
        );
      }
      final bytes = base64Decode(imagePath);
      return Image.memory(
        bytes,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.broken_image_outlined,
          color: theme.colorScheme.error,
        ),
      );
    } catch (_) {
      return Icon(
        Icons.image_not_supported_outlined,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final List<String> rawLogos = isForSuppliers
        ? ref.watch(supplierViewModelProvider).userSupplierPhotos
        : ref.watch(credentialViewModelProvider).userCredentialLogos;

    final List<String> logos =
        rawLogos.where((p) => p.trim().isNotEmpty).toSet().toList();

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar Imagem Salva')),
      body: AppAnimations.fadeInFromBottom(
        logos.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        size: 80,
                        color: theme.colorScheme.onSurface.withAlpha(
                          (255 * 0.4).round(),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Nenhuma imagem salva encontrada',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: theme.textTheme.bodyMedium?.color?.withAlpha(
                            200,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'As imagens que você salva aparecem aqui.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.all(20.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                ),
                itemCount: logos.length,
                itemBuilder: (context, index) {
                  final logoPath = logos[index];
                  return GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop(logoPath);
                    },
                    child: Card(
                      elevation: 4,
                      shadowColor: theme.colorScheme.shadow.withAlpha(
                        (255 * 0.2).round(),
                      ),
                      shape: const CircleBorder(),
                      clipBehavior: Clip.antiAlias,
                      child: Container(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withAlpha((255 * 0.3).round()),
                        alignment: Alignment.center,
                        child: _buildImageWidget(logoPath, theme),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
