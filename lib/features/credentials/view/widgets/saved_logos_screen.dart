import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:provider/provider.dart';

class SavedLogosScreen extends StatelessWidget {
  const SavedLogosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<CredentialViewModel>(context, listen: false);
    final logos = viewModel.userCredentialLogos;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Logo'),
      ),
      body: (logos.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        size: 80,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Nenhum logo salvo encontrado',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color:
                              theme.textTheme.bodyMedium?.color?.withAlpha(200),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Os logos que você salva em suas credenciais aparecem aqui.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ],
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
                    final logoBase64 = logos[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.of(context).pop(logoBase64);
                      },
                      child: Card(
                        elevation: 4,
                        shadowColor: theme.colorScheme.shadow.withOpacity(0.2),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.surfaceVariant.withOpacity(0.3),
                          backgroundImage:
                              MemoryImage(base64Decode(logoBase64)),
                        ),
                      ),
                    );
                  },
                ))
          .animate()
          .fadeIn(duration: 250.ms)
          .slideY(begin: 0.1, end: 0),
    );
  }
}
