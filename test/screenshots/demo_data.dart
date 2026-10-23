// Synthetic data for documentation screenshots. No real accounts or backend.
import 'package:firebase_auth/firebase_auth.dart' as firebase;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/models/expense_category_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/folder_model.dart';
import 'package:key_budget/core/models/user_model.dart';
import 'package:key_budget/features/auth/repository/auth_repository.dart';
import 'package:key_budget/features/auth/viewmodel/auth_viewmodel.dart';
import 'package:key_budget/features/category/viewmodel/category_viewmodel.dart';
import 'package:key_budget/features/credentials/repository/credential_repository.dart';
import 'package:key_budget/features/credentials/viewmodel/credential_viewmodel.dart';
import 'package:key_budget/features/documents/repository/document_repository.dart';
import 'package:key_budget/features/documents/viewmodel/document_viewmodel.dart';
import 'package:key_budget/features/expenses/repository/expense_repository.dart';
import 'package:key_budget/features/expenses/viewmodel/expense_viewmodel.dart';

class FakeAuthRepo extends Fake implements AuthRepository {
  @override
  Stream<firebase.User?> get firebaseAuthStateChanges => const Stream.empty();
}

class FakeExpenseRepo extends Fake implements ExpenseRepository {}

class FakeCredentialRepo extends Fake implements CredentialRepository {}

class FakeDocumentRepo extends Fake implements DocumentRepository {}

class FakeCategoryVM extends CategoryViewModel {
  final List<ExpenseCategory> mockCategories;

  FakeCategoryVM(this.mockCategories);

  @override
  List<ExpenseCategory> get categories => mockCategories;

  @override
  bool get isLoading => false;

  @override
  ExpenseCategory? getCategoryById(String? id) {
    if (id == null) return null;
    try {
      return mockCategories.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> fetchCategories(String userId) async {}
}

class FakeExpenseVM extends ExpenseViewModel {
  final List<Expense> initialExpenses;

  FakeExpenseVM({this.initialExpenses = const []})
    : super(repository: FakeExpenseRepo()) {
    allExpenses = initialExpenses;
  }

  @override
  ExpenseSyncStatus get syncStatus => ExpenseSyncStatus.synced;

  @override
  bool get isLoading => false;

  @override
  List<Expense> get currentDisplayItems => monthlyFilteredExpenses;

  @override
  void listenToExpenses(String userId) {}

  @override
  Future<void> retryListenToExpenses(String userId) async {}
}

class FakeCredentialVM extends CredentialViewModel {
  final List<Folder> mockFolders;
  final List<Credential> mockCredentials;

  FakeCredentialVM({
    this.mockFolders = const [],
    this.mockCredentials = const [],
  }) : super(repository: FakeCredentialRepo());

  @override
  List<Folder> get allFolders => mockFolders;

  @override
  List<Credential> get allCredentials => mockCredentials;

  @override
  List<dynamic> get currentDisplayItems {
    final list = <dynamic>[];
    list.addAll(mockFolders);
    list.addAll(mockCredentials.where((c) => c.folderId == null));
    return list;
  }

  @override
  bool get isLoading => false;

  @override
  void listenToCredentials(String userId) {}
}

class FakeDocumentVM extends DocumentViewModel {
  final List<Document> mockDocuments;

  FakeDocumentVM({this.mockDocuments = const []})
    : super(repository: FakeDocumentRepo());

  @override
  List<Document> get allDocuments => mockDocuments;

  @override
  List<Document> get currentDisplayItems => mockDocuments;

  @override
  bool get isLoading => false;

  @override
  void listenToDocuments(String userId) {}
}

class FakeAuthVM extends AuthViewModel {
  final User? mockUser;

  FakeAuthVM({this.mockUser})
    : super(authRepository: FakeAuthRepo(), listenToAuthChanges: false);

  @override
  User? get currentUser => mockUser;

  @override
  bool get isLoading => false;
}

class HelperData {
  static final now = DateTime.now();

  static final mockUser = User(
    id: 'demo_user',
    name: 'Marina Costa',
    email: 'marina@example.com',
    themeColor: 0xFF0058D9,
    enableIncomes: true,
    enableSuppliers: false,
  );

  static final categories = [
    ExpenseCategory(
      id: 'c1',
      name: 'Moradia',
      colorValue: const Color(0xFF2563EB).toARGB32(),
      iconCodePoint: Icons.home.codePoint,
    ),
    ExpenseCategory(
      id: 'c2',
      name: 'Alimentação',
      colorValue: const Color(0xFFF59E0B).toARGB32(),
      iconCodePoint: Icons.restaurant.codePoint,
    ),
    ExpenseCategory(
      id: 'c3',
      name: 'Transporte',
      colorValue: const Color(0xFF0EA5E9).toARGB32(),
      iconCodePoint: Icons.directions_car.codePoint,
    ),
    ExpenseCategory(
      id: 'c4',
      name: 'Saúde',
      colorValue: const Color(0xFFEF4444).toARGB32(),
      iconCodePoint: Icons.local_hospital.codePoint,
    ),
    ExpenseCategory(
      id: 'c5',
      name: 'Lazer',
      colorValue: const Color(0xFF8B5CF6).toARGB32(),
      iconCodePoint: Icons.sports_esports.codePoint,
    ),
    ExpenseCategory(
      id: 'c6',
      name: 'Educação',
      colorValue: const Color(0xFF10B981).toARGB32(),
      iconCodePoint: Icons.school.codePoint,
    ),
  ];

  static final mockFolders = [
    Folder(
      id: 'f1',
      name: 'Trabalho & Tech',
      color: '0xFF9F1239',
      createdAt: DateTime(2026, 9, 1),
    ),
    Folder(
      id: 'f2',
      name: 'Finanças & Bancos',
      color: '0xFF2563EB',
      createdAt: DateTime(2026, 9, 10),
    ),
    Folder(
      id: 'f3',
      name: 'Serviços & Assinaturas',
      color: '0xFF10B981',
      createdAt: DateTime(2026, 9, 15),
    ),
  ];

  static final allExpensesList = [
    // Outubro
    Expense(
      id: 'e1',
      motivation: 'Supermercado Mensal',
      amount: 840.50,
      date: DateTime(now.year, now.month, 18),
      categoryId: 'c2',
    ),
    Expense(
      id: 'e2',
      motivation: 'Salário Empresa Tech',
      amount: 7200.00,
      date: DateTime(now.year, now.month, 5),
      isIncome: true,
    ),
    Expense(
      id: 'e3',
      motivation: 'Aluguel do Apartamento',
      amount: 1650.00,
      date: DateTime(now.year, now.month, 10),
      categoryId: 'c1',
    ),
    Expense(
      id: 'e4',
      motivation: 'Combustível Posto Shell',
      amount: 220.00,
      date: DateTime(now.year, now.month, 15),
      categoryId: 'c3',
    ),
    Expense(
      id: 'e5',
      motivation: 'Farmácia & Vitaminas',
      amount: 145.90,
      date: DateTime(now.year, now.month, 12),
      categoryId: 'c4',
    ),
    Expense(
      id: 'e6',
      motivation: 'Restaurante Fim de Semana',
      amount: 180.00,
      date: DateTime(now.year, now.month, 14),
      categoryId: 'c2',
    ),
    Expense(
      id: 'e7',
      motivation: 'Cinema e Streaming',
      amount: 83.40,
      date: DateTime(now.year, now.month, 8),
      categoryId: 'c5',
    ),
    Expense(
      id: 'e8',
      motivation: 'Curso Especialização Online',
      amount: 350.00,
      date: DateTime(now.year, now.month, 3),
      categoryId: 'c6',
    ),
    Expense(
      id: 'e9',
      motivation: 'Consultoria Freelance',
      amount: 1700.00,
      date: DateTime(now.year, now.month, 12),
      isIncome: true,
    ),

    // Setembro
    Expense(
      id: 'e10',
      motivation: 'Salário Tech',
      amount: 7200.00,
      date: DateTime(now.year, now.month - 1, 5),
      isIncome: true,
    ),
    Expense(
      id: 'e11',
      motivation: 'Aluguel Apartamento',
      amount: 1650.00,
      date: DateTime(now.year, now.month - 1, 10),
      categoryId: 'c1',
    ),
    Expense(
      id: 'e12',
      motivation: 'Supermercado Setembro',
      amount: 920.30,
      date: DateTime(now.year, now.month - 1, 15),
      categoryId: 'c2',
    ),
    Expense(
      id: 'e13',
      motivation: 'Combustível',
      amount: 240.00,
      date: DateTime(now.year, now.month - 1, 18),
      categoryId: 'c3',
    ),
    Expense(
      id: 'e14',
      motivation: 'Plano de Saúde',
      amount: 480.00,
      date: DateTime(now.year, now.month - 1, 22),
      categoryId: 'c4',
    ),
    Expense(
      id: 'e15',
      motivation: 'Livros e Cursos',
      amount: 290.00,
      date: DateTime(now.year, now.month - 1, 25),
      categoryId: 'c6',
    ),

    // Agosto
    Expense(
      id: 'e16',
      motivation: 'Salário Tech',
      amount: 7200.00,
      date: DateTime(now.year, now.month - 2, 5),
      isIncome: true,
    ),
    Expense(
      id: 'e17',
      motivation: 'Aluguel Apartamento',
      amount: 1650.00,
      date: DateTime(now.year, now.month - 2, 10),
      categoryId: 'c1',
    ),
    Expense(
      id: 'e18',
      motivation: 'Supermercado',
      amount: 810.00,
      date: DateTime(now.year, now.month - 2, 12),
      categoryId: 'c2',
    ),
    Expense(
      id: 'e19',
      motivation: 'Revisão do Carro',
      amount: 650.00,
      date: DateTime(now.year, now.month - 2, 20),
      categoryId: 'c3',
    ),

    // Julho
    Expense(
      id: 'e20',
      motivation: 'Salário Tech',
      amount: 7200.00,
      date: DateTime(now.year, now.month - 3, 5),
      isIncome: true,
    ),
    Expense(
      id: 'e21',
      motivation: 'Rendimento Investimentos',
      amount: 950.00,
      date: DateTime(now.year, now.month - 3, 15),
      isIncome: true,
    ),
    Expense(
      id: 'e22',
      motivation: 'Aluguel Apartamento',
      amount: 1650.00,
      date: DateTime(now.year, now.month - 3, 10),
      categoryId: 'c1',
    ),
    Expense(
      id: 'e23',
      motivation: 'Supermercado',
      amount: 780.00,
      date: DateTime(now.year, now.month - 3, 14),
      categoryId: 'c2',
    ),

    // Junho
    Expense(
      id: 'e24',
      motivation: 'Salário Tech',
      amount: 7200.00,
      date: DateTime(now.year, now.month - 4, 5),
      isIncome: true,
    ),
    Expense(
      id: 'e25',
      motivation: 'Aluguel Apartamento',
      amount: 1650.00,
      date: DateTime(now.year, now.month - 4, 10),
      categoryId: 'c1',
    ),
    Expense(
      id: 'e26',
      motivation: 'Viagem de Férias',
      amount: 1450.00,
      date: DateTime(now.year, now.month - 4, 18),
      categoryId: 'c5',
    ),
    Expense(
      id: 'e27',
      motivation: 'Supermercado',
      amount: 830.00,
      date: DateTime(now.year, now.month - 4, 12),
      categoryId: 'c2',
    ),

    // Maio
    Expense(
      id: 'e28',
      motivation: 'Salário Tech',
      amount: 7200.00,
      date: DateTime(now.year, now.month - 5, 5),
      isIncome: true,
    ),
    Expense(
      id: 'e29',
      motivation: 'Aluguel Apartamento',
      amount: 1650.00,
      date: DateTime(now.year, now.month - 5, 10),
      categoryId: 'c1',
    ),
    Expense(
      id: 'e30',
      motivation: 'Supermercado',
      amount: 790.00,
      date: DateTime(now.year, now.month - 5, 12),
      categoryId: 'c2',
    ),
  ];

  static final currentMonthExpenses = allExpensesList
      .where((e) => e.date.month == now.month)
      .toList();

  static final List<Credential> credentials = [
    Credential(
      id: 'cr1',
      location: 'Google Workspace',
      login: 'alexandre@empresa.example',
      encryptedPassword: 'x',
      folderId: 'f1',
    ),
    Credential(
      id: 'cr2',
      location: 'GitHub Developer',
      login: 'alexandre-silva',
      encryptedPassword: 'x',
      folderId: 'f1',
    ),
    Credential(
      id: 'cr3',
      location: 'AWS Cloud Admin',
      login: 'infra@example.com',
      encryptedPassword: 'x',
      folderId: 'f1',
    ),
    Credential(
      id: 'cr4',
      location: 'Nubank PJ',
      login: 'marina@example.com',
      encryptedPassword: 'x',
      folderId: 'f2',
    ),
    Credential(
      id: 'cr5',
      location: 'Netflix 4K',
      login: 'marina@example.com',
      encryptedPassword: 'x',
      folderId: null,
    ),
    Credential(
      id: 'cr6',
      location: 'Spotify Family',
      login: 'marina@example.com',
      encryptedPassword: 'x',
      folderId: null,
    ),
  ];

  static final List<Document> documents = [
    Document(
      id: 'd1',
      documentName: 'Passaporte Brasileiro',
      number: 'BR7849201',
      expiryDate: DateTime(2032, 5, 15),
      isPrincipal: true,
    ),
    Document(
      id: 'd2',
      documentName: 'CNH Digital',
      number: '04918274910',
      expiryDate: DateTime(2028, 11, 20),
      isPrincipal: false,
    ),
    Document(
      id: 'd3',
      documentName: 'Contrato de Aluguel',
      number: 'AP-402',
      expiryDate: DateTime(2027, 2, 1),
      isPrincipal: false,
    ),
    Document(
      id: 'd4',
      documentName: 'Diploma Engenharia',
      number: 'UF-2018',
      expiryDate: null,
      isPrincipal: false,
    ),
  ];
}
