import 'package:cloud_firestore/cloud_firestore.dart';

class SyntheticTimestamp {
  final int seconds;
  final int nanoseconds;

  const SyntheticTimestamp(this.seconds, [this.nanoseconds = 0]);

  factory SyntheticTimestamp.fromDate(DateTime date) {
    final int millis = date.millisecondsSinceEpoch;
    final int seconds = millis ~/ 1000;
    final int nanoseconds = (millis % 1000) * 1000000;
    return SyntheticTimestamp(seconds, nanoseconds);
  }

  DateTime toDate() {
    return DateTime.fromMillisecondsSinceEpoch(
      seconds * 1000 + (nanoseconds ~/ 1000000),
      isUtc: false,
    );
  }

  Map<String, dynamic> toMap() => {
        '_seconds': seconds,
        '_nanoseconds': nanoseconds,
      };

  factory SyntheticTimestamp.fromMap(Map<String, dynamic> map) {
    return SyntheticTimestamp(
      map['_seconds'] as int,
      (map['_nanoseconds'] as int?) ?? 0,
    );
  }
}

class LegacyFixtures {

  static Map<String, dynamic> get l01 => {
        'id': 'L01',
        'description': 'Regra mensal dia 31 com lançamentos existentes',
        'recurring': {
          'id': 'rec_l01',
          'amount': 150.0,
          'categoryId': 'cat_bills',
          'motivation': 'Aluguel dia 31',
          'frequency': 'monthly',
          'startDate': Timestamp.fromDate(DateTime(2024, 1, 31)),
          'dayOfMonth': 31,
          'lastInstanceDate': Timestamp.fromDate(DateTime(2024, 3, 31)),
          'isIncome': false,
          'advanceGenerationCount': 0,
        },
        'expenses': [
          {
            'id': 'exp_l01_jan',
            'amount': 150.0,
            'date': '2024-01-31T10:00:00.000',
            'recurringExpenseId': 'rec_l01',
            'isIncome': false,
          },
          {
            'id': 'exp_l01_feb',
            'amount': 150.0,
            'date': '2024-02-29T10:00:00.000',
            'recurringExpenseId': 'rec_l01',
            'isIncome': false,
          },
          {
            'id': 'exp_l01_mar',
            'amount': 150.0,
            'date': '2024-03-31T10:00:00.000',
            'recurringExpenseId': 'rec_l01',
            'isIncome': false,
          },
        ],
      };

  static Map<String, dynamic> get l02 => {
        'id': 'L02',
        'description': 'Regra sem dayOfMonth preservando progressão pelo cursor',
        'recurring': {
          'id': 'rec_l02',
          'amount': 80.0,
          'categoryId': 'cat_services',
          'motivation': 'Assinatura',
          'frequency': 'monthly',
          'startDate': Timestamp.fromDate(DateTime(2023, 1, 31)),
          'dayOfMonth': null,
          'lastInstanceDate': Timestamp.fromDate(DateTime(2023, 2, 28)),
          'isIncome': false,
        },
      };

  static Map<String, dynamic> get l03 => {
        'id': 'L03',
        'description': 'Regra com lastInstanceDate adiantado',
        'recurring': {
          'id': 'rec_l03',
          'amount': 200.0,
          'frequency': 'monthly',
          'startDate': Timestamp.fromDate(DateTime(2026, 1, 15)),
          'dayOfMonth': 15,
          'lastInstanceDate': Timestamp.fromDate(DateTime(2026, 12, 15)),
          'advanceGenerationCount': 3,
        },
      };

  static Map<String, dynamic> get l04 => {
        'id': 'L04',
        'description': 'Regra com cursor nulo e histórico disperso',
        'recurring': {
          'id': 'rec_l04',
          'amount': 50.0,
          'frequency': 'monthly',
          'startDate': Timestamp.fromDate(DateTime(2025, 1, 10)),
          'lastInstanceDate': null,
        },
        'expenses': [
          {
            'id': 'random_id_9481',
            'amount': 50.0,
            'date': '2025-01-10T00:00:00.000',
            'recurringExpenseId': 'rec_l04',
          },
          {
            'id': 'random_id_3321',
            'amount': 50.0,
            'date': '2025-02-10T00:00:00.000',
            'recurringExpenseId': 'rec_l04',
          },
        ],
      };

  static Map<String, dynamic> get l05 => {
        'id': 'L05',
        'description': 'Duplicatas existentes na mesma data',
        'expenses': [
          {
            'id': 'dup_1',
            'amount': 120.0,
            'date': '2026-05-01T08:00:00.000',
            'recurringExpenseId': 'rec_l05',
          },
          {
            'id': 'dup_2',
            'amount': 120.0,
            'date': '2026-05-01T08:00:00.000',
            'recurringExpenseId': 'rec_l05',
          },
        ],
      };

  static Map<String, dynamic> get l06 => {
        'id': 'L06',
        'description': 'Despesa editada órfã',
        'expense': {
          'id': 'exp_orphan',
          'amount': 99.9,
          'date': '2026-06-15T12:00:00.000',
          'motivation': 'Conta de luz',
          'recurringExpenseId': null,
        },
      };

  static Map<String, dynamic> get l07 => {
        'id': 'L07',
        'description': 'Regra semanal atravessando virada de ano',
        'recurring': {
          'id': 'rec_weekly',
          'amount': 30.0,
          'frequency': 'weekly',
          'startDate': Timestamp.fromDate(DateTime(2025, 12, 25)),
          'dayOfWeek': 4,
          'lastInstanceDate': Timestamp.fromDate(DateTime(2026, 1, 8)),
        },
      };

  static Map<String, dynamic> get l08 => {
        'id': 'L08',
        'description': 'Variações de isIncome',
        'expenses': [
          {'id': 'e1', 'amount': 100.0, 'date': '2026-01-01', 'isIncome': null},
          {'id': 'e2', 'amount': 50.0, 'date': '2026-01-02', 'isIncome': false},
          {'id': 'e3', 'amount': 500.0, 'date': '2026-01-03', 'isIncome': true},
        ],
      };

  static Map<String, dynamic> get l09 => {
        'id': 'L09',
        'description': 'Parcelas com divisões periódicas float',
        'expenses': [
          {
            'id': 'inst_1',
            'amount': 33.333333333333336,
            'date': '2026-02-01',
            'currentInstallment': 1,
            'totalInstallments': 3,
            'installmentGroupId': 'grp_100',
          },
          {
            'id': 'inst_2',
            'amount': 33.333333333333336,
            'date': '2026-03-01',
            'currentInstallment': 2,
            'totalInstallments': 3,
            'installmentGroupId': 'grp_100',
          },
          {
            'id': 'inst_3',
            'amount': 33.333333333333336,
            'date': '2026-04-01',
            'currentInstallment': 3,
            'totalInstallments': 3,
            'installmentGroupId': 'grp_100',
          },
        ],
      };

  static Map<String, dynamic> get l10 => {
        'id': 'L10',
        'description': 'Vínculos órfãos e ausência de categoria',
        'expenses': [
          {'id': 'e_orphan_cat', 'amount': 42.0, 'date': '2026-03-01', 'categoryId': 'deleted_cat_123'},
          {'id': 'e_null_cat', 'amount': 15.0, 'date': '2026-03-02', 'categoryId': null},
        ],
      };

  static Map<String, dynamic> get l11 => {
        'id': 'L11',
        'description': 'Campos desconhecidos e alta precisão',
        'rawDoc': {
          'id': 'doc_unknown_fields',
          'amount': 123.45,
          'date': '2026-04-01T10:20:30.123456Z',
          'legacyExtraFlag': true,
          'nestedMetadata': {
            'importedFrom': 'old_app_v1',
            'tags': ['sync', 'imported'],
          },
          'exactCreated': SyntheticTimestamp(1711966830, 987654321).toMap(),
        },
      };

  static Map<String, dynamic> get l12 => {
        'id': 'L12',
        'description': 'Documento com versões e metadados de anexos',
        'document': {
          'id': 'doc_master',
          'title': 'Contrato Aluguel',
          'isPrincipal': true,
          'originalDocumentId': null,
          'driveFileId': 'drive_file_001',
          'fileHash': 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
        },
        'versions': [
          {
            'id': 'doc_v1',
            'title': 'Contrato Aluguel v1',
            'isPrincipal': false,
            'originalDocumentId': 'doc_master',
            'driveFileId': 'drive_file_002',
          },
        ],
      };

  static Map<String, dynamic> get l13 => {
        'id': 'L13',
        'description': 'Senhas com espaços e flags Google',
        'testCases': [
          {'rawPassword': '  minhasenha123  ', 'trimmed': 'minhasenha123'},
          {'googleUid': 'google_user_uid_98765', 'savedAsPassword': false},
        ],
      };

  static Map<String, dynamic> get l14 => {
        'id': 'L14',
        'description': 'Datas ISO no final do mês e fusos',
        'timestamps': [
          '2024-02-29T23:59:59.999Z',
          '2024-02-29T23:59:59.999-03:00',
          '2024-03-01T00:00:00.000',
        ],
      };

  static Map<String, dynamic> get l15 => {
        'id': 'L15',
        'description': 'Regra encerrada com gap intencional',
        'recurring': {
          'id': 'rec_ended',
          'amount': 250.0,
          'startDate': Timestamp.fromDate(DateTime(2023, 1, 1)),
          'endDate': Timestamp.fromDate(DateTime(2023, 6, 1)),
          'lastInstanceDate': Timestamp.fromDate(DateTime(2023, 6, 1)),
        },
        'existingMonths': [1, 2, 4, 5, 6],
      };

  static Map<String, dynamic> get l16 => {
        'id': 'L16',
        'description': 'Cenário de concorrência com revisão divergente',
        'remoteDoc': {
          'id': 'exp_shared',
          'amount': 75.0,
          'updatedAt': '2026-09-20T10:00:00.000',
        },
        'clientSnapshot': {
          'id': 'exp_shared',
          'amount': 70.0,
          'updatedAt': '2026-09-20T09:00:00.000',
        },
      };
}
