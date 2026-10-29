import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:passfin/core/models/credential_model.dart';
import 'package:passfin/core/models/expense_model.dart';
import 'package:passfin/core/services/encryption_service.dart';
import 'package:passfin/features/credentials/repository/credential_repository.dart';
import 'package:passfin/features/expenses/repository/expense_repository.dart';

class DataImportService {
  final ExpenseRepository _expenseRepository;
  final CredentialRepository _credentialRepository;
  final EncryptionService? encryptionService;
  final EncryptionService Function()? encryptionResolver;

  DataImportService({
    ExpenseRepository? expenseRepository,
    CredentialRepository? credentialRepository,
    this.encryptionService,
    this.encryptionResolver,
  }) : _expenseRepository = expenseRepository ?? ExpenseRepository(),
       _credentialRepository = credentialRepository ?? CredentialRepository();

  EncryptionService get _activeEncryptionService =>
      encryptionService ?? encryptionResolver?.call() ?? EncryptionService();

  Future<int> importExpensesFromJsons(String userId) async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final jsonPaths = manifestMap.keys
        .where((String key) => key.contains('assets/data/'))
        .where((String key) => !key.contains('credentials.json'))
        .toList();

    int totalImported = 0;
    for (String path in jsonPaths) {
      if (kDebugMode) {
        print('Importando despesas de: $path');
      }
      final String fileContent = await rootBundle.loadString(path);
      final List<dynamic> jsonData = json.decode(fileContent);

      for (var item in jsonData) {
        final expense = Expense(
          amount: (item['amount'] as num).toDouble(),
          date: DateTime.parse(item['date']),
          categoryId: null,
          motivation: item['motivation'],
          location: item['location'],
        );
        await _expenseRepository.addExpense(userId, expense);
        totalImported++;
      }
    }
    return totalImported;
  }

  Future<int> importCredentialsFromJson(String userId) async {
    try {
      if (kDebugMode) {
        print('Iniciando importação de credenciais...');
      }
      final String fileContent = await rootBundle.loadString(
        'assets/data/credentials.json',
      );
      final List<dynamic> jsonData = json.decode(fileContent);

      int totalImported = 0;
      for (var item in jsonData) {
        final plainPassword = item['password']?.toString() ?? '';
        if (plainPassword.isEmpty) {
          if (kDebugMode) {
            print('Senha não encontrada para ${item['location']}, pulando.');
          }
          continue;
        }

        final id = _credentialRepository.reserveCredentialId(userId);
        final encryptedPassword = _activeEncryptionService.encryptData(
          plainPassword,
          recordId: id,
        );

        final credential = Credential(
          id: id,
          location: item['location'],
          login: item['login'],
          encryptedPassword: encryptedPassword,
          email: item['email'],
          phoneNumber: item['phone_number'],
          notes: item['notes'],
        );
        await _credentialRepository.addCredential(userId, credential);
        totalImported++;
        if (kDebugMode) {
          print('Credencial importada: ${credential.location}');
        }
      }
      if (kDebugMode) {
        print('Importação de credenciais concluída. Total: $totalImported');
      }
      return totalImported;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao importar credenciais: $e');
      }
      return 0;
    }
  }
}
