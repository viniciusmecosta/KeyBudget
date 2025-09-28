import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:key_budget/core/models/supplier_model.dart';
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível abrir o WhatsApp.')),
        );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Não foi possível abrir o app de e-mail.')),
        );
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

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: CircleAvatar(
          backgroundColor:
              theme.colorScheme.tertiary.withAlpha((255 * 0.15).round()),
          backgroundImage: photoPath != null && photoPath.isNotEmpty
              ? MemoryImage(base64Decode(photoPath))
              : null,
          child: photoPath == null || photoPath.isEmpty
              ? Icon(Icons.store_outlined, color: theme.colorScheme.tertiary)
              : null,
        ),
        title: Text(supplier.name,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(subtitleText),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (supplier.phoneNumber != null &&
                supplier.phoneNumber!.isNotEmpty)
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  icon: FaIcon(FontAwesomeIcons.whatsapp,
                      color: Colors.green.shade700),
                  onPressed: () =>
                      _launchWhatsApp(context, supplier.phoneNumber!),
                  style: IconButton.styleFrom(
                    backgroundColor:
                        Colors.green.withAlpha((255 * 0.1).round()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            if (supplier.email != null && supplier.email!.isNotEmpty)
              SizedBox(
                width: 40,
                height: 40,
                child: IconButton(
                  icon: Icon(Icons.email_outlined, color: Colors.blue.shade600),
                  onPressed: () => _launchEmail(context, supplier.email!),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.blue.withAlpha((255 * 0.1).round()),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => SupplierDetailScreen(supplier: supplier),
            ),
          );
        },
      ),
    );
  }
}
