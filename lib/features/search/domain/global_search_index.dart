import 'package:passfin/core/models/credential_model.dart';
import 'package:passfin/core/models/document_model.dart';
import 'package:passfin/core/models/expense_model.dart';
import 'package:passfin/core/models/supplier_model.dart';
import 'package:passfin/core/search/search_normalizer.dart';

enum GlobalSearchKind { expense, credential, document, supplier }

class GlobalSearchResult {
  final GlobalSearchKind kind;
  final String id;
  final String title;
  final String subtitle;
  final Object item;

  const GlobalSearchResult({
    required this.kind,
    required this.id,
    required this.title,
    required this.subtitle,
    required this.item,
  });

  String get favoriteId => '${kind.name}_$id';
}

class GlobalSearchIndex {
  static List<GlobalSearchResult> search({
    required String query,
    required List<Expense> expenses,
    required List<Credential> credentials,
    required List<Document> documents,
    required List<Supplier> suppliers,
    bool includeDocuments = true,
    bool includeSuppliers = true,
  }) {
    final normalized = SearchNormalizer.normalize(query);
    final results = <GlobalSearchResult>[];

    bool matches(Iterable<String?> fields) =>
        normalized.isEmpty ||
        fields.any(
          (field) =>
              field != null &&
              SearchNormalizer.normalize(field).contains(normalized),
        );

    for (final expense in expenses) {
      if (expense.id != null &&
          matches([expense.motivation, expense.location])) {
        results.add(
          GlobalSearchResult(
            kind: GlobalSearchKind.expense,
            id: expense.id!,
            title: expense.motivation?.trim().isNotEmpty == true
                ? expense.motivation!
                : 'Lançamento',
            subtitle: expense.location ?? 'Despesas',
            item: expense,
          ),
        );
      }
    }
    for (final credential in credentials) {
      if (credential.id != null &&
          matches([credential.location, credential.login])) {
        results.add(
          GlobalSearchResult(
            kind: GlobalSearchKind.credential,
            id: credential.id!,
            title: credential.location,
            subtitle: credential.login,
            item: credential,
          ),
        );
      }
    }
    if (includeDocuments) {
      for (final document in documents) {
        if (document.id != null &&
            matches([document.documentName, document.number])) {
          results.add(
            GlobalSearchResult(
              kind: GlobalSearchKind.document,
              id: document.id!,
              title: document.documentName,
              subtitle: document.number ?? 'Documento',
              item: document,
            ),
          );
        }
      }
    }
    if (includeSuppliers) {
      for (final supplier in suppliers) {
        if (supplier.id != null &&
            matches([supplier.name, supplier.representativeName])) {
          results.add(
            GlobalSearchResult(
              kind: GlobalSearchKind.supplier,
              id: supplier.id!,
              title: supplier.name,
              subtitle: supplier.representativeName ?? 'Fornecedor',
              item: supplier,
            ),
          );
        }
      }
    }
    return results;
  }
}
