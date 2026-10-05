import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/credential_model.dart';
import 'package:key_budget/core/models/document_model.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/supplier_model.dart';
import 'package:key_budget/features/search/domain/global_search_index.dart';

void main() {
  final expenses = [
    Expense(
      id: 'e1',
      amount: 42,
      date: DateTime(2026, 10, 1),
      motivation: 'Café da manhã',
    ),
  ];
  final credentials = [
    Credential(
      id: 'c1',
      location: 'Banco Ágil',
      login: 'usuario',
      encryptedPassword: 'segredo-cifrado',
    ),
  ];
  final documents = [Document(id: 'd1', documentName: 'Identidade')];
  final suppliers = [Supplier(id: 's1', name: 'Oficina São José')];

  test('Busca nomes com acentos sem consultar senhas', () {
    final result = GlobalSearchIndex.search(
      query: 'agil',
      expenses: expenses,
      credentials: credentials,
      documents: documents,
      suppliers: suppliers,
    );
    expect(result.single.favoriteId, 'credential_c1');

    final passwordResult = GlobalSearchIndex.search(
      query: 'segredo-cifrado',
      expenses: expenses,
      credentials: credentials,
      documents: documents,
      suppliers: suppliers,
    );
    expect(passwordResult, isEmpty);
  });

  test('Oculta módulos desativados sem afetar lançamentos e credenciais', () {
    final result = GlobalSearchIndex.search(
      query: '',
      expenses: expenses,
      credentials: credentials,
      documents: documents,
      suppliers: suppliers,
      includeDocuments: false,
      includeSuppliers: false,
    );
    expect(result.map((item) => item.kind), [
      GlobalSearchKind.expense,
      GlobalSearchKind.credential,
    ]);
  });
}
