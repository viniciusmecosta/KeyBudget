import 'package:flutter/material.dart';

enum AppDestination {
  dashboard(
    id: 'dashboard',
    label: 'Painel',
    icon: Icons.home_rounded,
    selectedIcon: Icons.home_rounded,
  ),
  expenses(
    id: 'expenses',
    label: 'Lançamentos',
    icon: Icons.monetization_on_rounded,
    selectedIcon: Icons.monetization_on_rounded,
  ),
  credentials(
    id: 'credentials',
    label: 'Credenciais',
    icon: Icons.vpn_key_rounded,
    selectedIcon: Icons.vpn_key_rounded,
  ),
  documents(
    id: 'documents',
    label: 'Documentos',
    icon: Icons.folder_copy_rounded,
    selectedIcon: Icons.folder_copy_rounded,
  ),
  suppliers(
    id: 'suppliers',
    label: 'Fornecedores',
    icon: Icons.storefront_rounded,
    selectedIcon: Icons.storefront_rounded,
  ),
  profile(
    id: 'profile',
    label: 'Perfil',
    icon: Icons.person_rounded,
    selectedIcon: Icons.person_rounded,
  );

  final String id;
  final String label;
  final IconData icon;
  final IconData selectedIcon;

  const AppDestination({
    required this.id,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  static List<AppDestination> getAvailable({required bool enableSuppliers}) {
    return [
      AppDestination.dashboard,
      AppDestination.expenses,
      AppDestination.credentials,
      AppDestination.documents,
      if (enableSuppliers) AppDestination.suppliers,
      AppDestination.profile,
    ];
  }
}
