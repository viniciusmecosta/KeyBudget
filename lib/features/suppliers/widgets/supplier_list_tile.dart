import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:key_budget/app/config/app_theme.dart';
import 'package:key_budget/core/models/supplier_model.dart';
import 'package:key_budget/core/services/snackbar_service.dart';
import 'package:key_budget/features/suppliers/view/supplier_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class SupplierListTile extends StatelessWidget {
  final Supplier supplier;

  const SupplierListTile({super.key, required this.supplier});

  void _launchWhatsApp(BuildContext context, String phone) async {
    final sanitizedPhone = phone.replaceAll(RegExp(r'[^0-9]'), '');
    final whatsappUrl = "https://wa.me/55$sanitizedPhone";
    final uri = Uri.parse(whatsappUrl);

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        SnackbarService.showError(
            context, 'Não foi possível abrir o WhatsApp.');
      }
    }
  }

  void _launchEmail(BuildContext context, String email) async {
    final emailUrl = 'mailto:$email';
    final uri = Uri.parse(emailUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (context.mounted) {
        SnackbarService.showError(
            context, 'Não foi possível abrir o app de e-mail.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final photoPath = supplier.photoPath;
    String subtitleText;
    if (supplier.representativeName != null &&
        supplier.representativeName!.isNotEmpty) {
      subtitleText = supplier.representativeName!;
    } else if (supplier.phoneNumber != null &&
        supplier.phoneNumber!.isNotEmpty) {
      subtitleText = supplier.phoneNumber!;
    } else if (supplier.email != null && supplier.email!.isNotEmpty) {
      subtitleText = supplier.email!;
    } else {
      subtitleText = 'Sem contato';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.spaceS),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 0,
        child: InkWell(
          onTap: () {
            Navigator.of(context).push(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    SupplierDetailScreen(supplier: supplier),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  const begin = Offset(0.0, 1.0);
                  const end = Offset.zero;
                  const curve = Curves.easeInOutCubic;
                  var tween = Tween(begin: begin, end: end)
                      .chain(CurveTween(curve: curve));
                  return SlideTransition(
                      position: animation.drive(tween), child: child);
                },
                transitionDuration: const Duration(milliseconds: 300),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.outline.withAlpha((255 * 0.1).round()),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: theme.colorScheme.tertiary
                      .withAlpha((255 * 0.15).round()),
                  backgroundImage: photoPath != null && photoPath.isNotEmpty
                      ? MemoryImage(base64Decode(photoPath))
                      : null,
                  child: photoPath == null || photoPath.isEmpty
                      ? Icon(Icons.store_outlined,
                          color: theme.colorScheme.tertiary)
                      : null,
                ),
                const SizedBox(width: AppTheme.spaceM),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AutoSizeText(
                        supplier.name,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        minFontSize: 14,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitleText,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface
                              .withAlpha((255 * 0.6).round()),
                        ),
                      ),
                    ],
                  ),
                ),
                if (supplier.phoneNumber != null &&
                    supplier.phoneNumber!.isNotEmpty)
                  IconButton(
                    icon: FaIcon(FontAwesomeIcons.whatsapp,
                        color: Colors.green.shade700),
                    onPressed: () =>
                        _launchWhatsApp(context, supplier.phoneNumber!),
                  ),
                if (supplier.email != null && supplier.email!.isNotEmpty)
                  IconButton(
                    icon:
                        Icon(Icons.email_outlined, color: Colors.blue.shade600),
                    onPressed: () => _launchEmail(context, supplier.email!),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
