import 'package:flutter_test/flutter_test.dart';
import 'package:key_budget/core/models/expense_model.dart';
import 'package:key_budget/core/models/recurring_expense_model.dart';
import 'package:key_budget/core/money/money.dart';
import 'package:key_budget/core/money/money_parser.dart';

void main() {
  group('Money Value Object & Arithmetic', () {
    test('0,10 + 0,20 resulta exatamente em 30 centavos', () {
      final m1 = MoneyParser.parse('0,10');
      final m2 = MoneyParser.parse('0,20');
      final sum = m1 + m2;

      expect(sum.amountMinor, 30);
      expect(sum.formatBrl(), 'R\$ 0,30');
      expect(sum.toDouble(), 0.30);
    });

    test('10,00 em 1 parcela resulta em 1000 centavos sem perda', () {
      final m = Money.fromNumWithHalfAwayFromZero(10.00);
      expect(m.amountMinor, 1000);
      final parts = m.split(1);
      expect(parts.length, 1);
      expect(parts.first.amountMinor, 1000);
    });

    test('Aritmética básica de soma, subtração e multiplicação', () {
      final a = Money.fromCents(500);
      final b = Money.fromCents(250);

      expect((a + b).amountMinor, 750);
      expect((a - b).amountMinor, 250);
      expect((b * 3).amountMinor, 750);
    });

    test('Comparadores e ordenação', () {
      final a = Money.fromCents(100);
      final b = Money.fromCents(200);
      final c = Money.fromCents(100);

      expect(a < b, isTrue);
      expect(b > a, isTrue);
      expect(a <= c, isTrue);
      expect(a >= c, isTrue);
      expect(a == c, isTrue);
      expect(a == b, isFalse);
    });

    test('Moedas diferentes disparam erro em operações aritméticas', () {
      final brl = Money.fromCents(100, currency: 'BRL');
      final usd = Money.fromCents(100, currency: 'USD');

      expect(() => brl + usd, throwsArgumentError);
      expect(() => brl - usd, throwsArgumentError);
      expect(() => brl.compareTo(usd), throwsArgumentError);
    });

    test('Formatação pt-BR com e sem símbolo, positivos e negativos', () {
      expect(Money.fromCents(123456).formatBrl(), 'R\$ 1.234,56');
      expect(
        Money.fromCents(123456).formatBrl(includeSymbol: false),
        '1.234,56',
      );
      expect(Money.fromCents(5).formatBrl(), 'R\$ 0,05');
      expect(Money.fromCents(0).formatBrl(), 'R\$ 0,00');
      expect(Money.fromCents(-123456).formatBrl(), '-R\$ 1.234,56');
      expect(Money.fromCents(-50).formatBrl(includeSymbol: false), '-0,50');
      expect(Money.fromCents(100000000).formatBrl(), 'R\$ 1.000.000,00');
    });

    test(
      'Limite conservador de 53 bits (abs <= 9007199254740991) e erro em overflow',
      () {
        const safeMax = 9007199254740991;
        final safeMoney = Money.fromCents(safeMax);
        expect(safeMoney.amountMinor, safeMax);

        expect(() => Money.fromCents(safeMax + 1), throwsArgumentError);
        expect(() => Money.fromCents(-safeMax - 1), throwsArgumentError);
      },
    );

    test('Valor enorme/NaN/infinito lança erro explícito sem truncamento', () {
      expect(
        () => Money.fromNumWithHalfAwayFromZero(double.nan),
        throwsArgumentError,
      );
      expect(
        () => Money.fromNumWithHalfAwayFromZero(double.infinity),
        throwsArgumentError,
      );
      expect(
        () => Money.fromNumWithHalfAwayFromZero(double.negativeInfinity),
        throwsArgumentError,
      );
    });
  });

  group('MoneyParser', () {
    test('Parse de formatos pt-BR e internacional', () {
      expect(MoneyParser.parse('R\$ 1.234,56').amountMinor, 123456);
      expect(MoneyParser.parse('1.234,56').amountMinor, 123456);
      expect(MoneyParser.parse('1234,56').amountMinor, 123456);
      expect(MoneyParser.parse('1234.56').amountMinor, 123456);
      expect(MoneyParser.parse('1,234.56').amountMinor, 123456);
      expect(MoneyParser.parse('10').amountMinor, 1000);
      expect(MoneyParser.parse('0,5').amountMinor, 50);
      expect(MoneyParser.parse('0,05').amountMinor, 5);
      expect(MoneyParser.parse('-R\$ 10,00').amountMinor, -1000);
      expect(MoneyParser.parse('(10,00)').amountMinor, -1000);
    });

    test(
      'fromMaskedText aceita formato típico de MoneyMaskedTextController',
      () {
        expect(MoneyParser.fromMaskedText('R\$ 1.234,56').amountMinor, 123456);
        expect(MoneyParser.fromMaskedText('R\$ 0,00').amountMinor, 0);
        expect(MoneyParser.fromMaskedText('R\$ 33,33').amountMinor, 3333);
      },
    );

    test(
      'Casas decimais extras disparam ExtraDecimalsException quando não autorizadas',
      () {
        expect(
          () => MoneyParser.parse('12,345', allowExtraDecimals: false),
          throwsA(isA<ExtraDecimalsException>()),
        );
        expect(
          () => MoneyParser.parse('100.555', allowExtraDecimals: false),
          throwsA(isA<ExtraDecimalsException>()),
        );
      },
    );

    test(
      'Casas decimais extras com allowExtraDecimals aplica half-away-from-zero',
      () {
        final m1 = MoneyParser.parse('1.005', allowExtraDecimals: true);
        expect(m1.amountMinor, 101);

        final m2 = MoneyParser.parse('1.004', allowExtraDecimals: true);
        expect(m2.amountMinor, 100);

        final m3 = MoneyParser.parse('33.3333333333', allowExtraDecimals: true);
        expect(m3.amountMinor, 3333);
      },
    );
  });

  group('Leitura Compatível de Legado (Expense & RecurringExpense)', () {
    test(
      'Registro financeiro sem data válida falha em vez de receber a data atual',
      () {
        expect(
          () => Expense.fromMap({'amount': 10}, 'exp_without_date'),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test(
      'Regra sem início ou frequência conhecida falha em vez de virar mensal',
      () {
        expect(
          () => RecurringExpense.fromMap({
            'amount': 10,
            'frequency': 'monthly',
          }, 'rec_without_start'),
          throwsA(isA<FormatException>()),
        );
        expect(
          () => RecurringExpense.fromMap({
            'amount': 10,
            'frequency': 'fortnightly',
            'startDate': '2026-03-01T00:00:00.000',
          }, 'rec_unknown_frequency'),
          throwsA(isA<FormatException>()),
        );
      },
    );

    test('Integer Firestore amount: 10 é lido como 1000 centavos', () {
      final map = {'amount': 10, 'date': '2026-03-01T10:00:00.000'};
      final exp = Expense.fromMap(map, 'exp_int');
      expect(exp.amount, 10.0);
      expect(exp.amountMinor, 1000);
      expect(exp.rawAmount, 10);
      expect(exp.isLegacyApproximate, isFalse);
      expect(exp.hasMoneyInconsistency, isFalse);
    });

    test(
      'Legado amount: 33.3333333333 preserva bruto, indica aproximado e gera zero writes no toMap',
      () {
        const legacyAmount = 33.333333333333336;
        final map = {
          'amount': legacyAmount,
          'date': '2026-03-01T10:00:00.000',
          'motivation': 'Parcela antiga',
        };
        final exp = Expense.fromMap(map, 'exp_float');
        expect(exp.amount, legacyAmount);
        expect(exp.rawAmount, legacyAmount);
        expect(exp.amountMinor, 3333);
        expect(exp.isLegacyApproximate, isTrue);
        expect(exp.hasMoneyInconsistency, isFalse);

        final exported = exp.toMap();
        expect(exported['amount'], legacyAmount);
        expect(exported.containsKey('amountMinor'), isFalse);
      },
    );

    test('Legado 1.005 resulta em 101 centavos com bruto preservado', () {
      final map = {'amount': 1.005, 'date': '2026-03-01T10:00:00.000'};
      final exp = Expense.fromMap(map, 'exp_half');
      expect(exp.amountMinor, 101);
      expect(exp.rawAmount, 1.005);
      expect(exp.isLegacyApproximate, isTrue);

      final exported = exp.toMap();
      expect(exported['amount'], 1.005);
      expect(exported.containsKey('amountMinor'), isFalse);
    });

    test(
      'amountMinor diverge de amount: inconsistência detectada e política aplicada',
      () {
        final map = {
          'amount': 150.0,
          'amountMinor': 10000,
          'moneyVersion': 1,
          'currency': 'BRL',
          'date': '2026-03-01T10:00:00.000',
        };
        final exp = Expense.fromMap(map, 'exp_divergent');
        expect(exp.hasMoneyInconsistency, isTrue);

        expect(exp.amountMinor, 15000);
        expect(exp.amount, 150.0);
      },
    );

    test(
      'Editar somente descrição mantém mapa monetário e vínculo idênticos',
      () {
        const legacyAmount = 33.333333333333336;
        final original = Expense.fromMap({
          'amount': legacyAmount,
          'date': '2026-03-01T10:00:00.000',
          'motivation': 'Descrição original',
          'recurringExpenseId': 'rec_123',
        }, 'exp_edit_desc');

        final edited = original.copyWith(motivation: 'Descrição editada');

        expect(edited.motivation, 'Descrição editada');
        expect(edited.rawAmount, legacyAmount);
        expect(edited.amount, legacyAmount);
        expect(edited.recurringExpenseId, 'rec_123');

        final exported = edited.toMap();
        expect(exported['amount'], legacyAmount);
        expect(exported.containsKey('amountMinor'), isFalse);
        expect(exported['recurringExpenseId'], 'rec_123');
      },
    );

    test('Editar valor explicitamente converte para amountMinor novo', () {
      final original = Expense.fromMap({
        'amount': 50.0,
        'date': '2026-03-01T10:00:00.000',
      }, 'exp_edit_val');

      final edited = original.copyWith(amount: 75.50);
      expect(edited.amountMinor, 7550);
      expect(edited.moneyVersion, 1);
      expect(edited.amount, 75.50);

      final exported = edited.toMap();
      expect(exported['amountMinor'], 7550);
      expect(exported['moneyVersion'], 1);
      expect(exported['currency'], 'BRL');
      expect(exported['amount'], 75.50);
    });

    test(
      'RecurringExpense lê inteiros, lida com divergências e preserva campos desconhecidos',
      () {
        final map = {
          'amount': 250,
          'frequency': 'monthly',
          'startDate': '2026-01-01T00:00:00.000',
          'customLegacyField': 'preserved_value',
        };
        final rec = RecurringExpense.fromMap(map, 'rec_int');
        expect(rec.amountMinor, 25000);
        expect(rec.rawAmount, 250);
        expect(rec.unmappedData['customLegacyField'], 'preserved_value');

        final exported = rec.toMap();
        expect(exported['customLegacyField'], 'preserved_value');
      },
    );
  });
}
