import 'money.dart';

class ExtraDecimalsException implements Exception {
  final String rawInput;
  final int decimalPlaces;

  const ExtraDecimalsException(this.rawInput, this.decimalPlaces);

  @override
  String toString() =>
      'Valor "$rawInput" possui $decimalPlaces casas decimais (máximo permitido é 2). '
      'Necessário autorização explícita para arredondar.';
}

class MoneyParser {

  static Money parse(
    String input, {
    String currency = 'BRL',
    bool allowExtraDecimals = false,
  }) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const FormatException('Entrada monetária não pode ser vazia');
    }

    bool isNegative = false;
    String clean = trimmed;

    if (clean.startsWith('(') && clean.endsWith(')')) {
      isNegative = true;
      clean = clean.substring(1, clean.length - 1).trim();
    }

    if (clean.contains('-')) {
      isNegative = true;
      clean = clean.replaceAll('-', '').trim();
    }

    clean = clean
        .replaceAll('R\$', '')
        .replaceAll('\$', '')
        .replaceAll('\u00A0', '')
        .replaceAll(' ', '')
        .trim();

    if (clean.isEmpty) {
      throw const FormatException('Entrada não contém valor numérico válido');
    }

    String integerPartStr;
    String fractionalPartStr = '';

    final hasDot = clean.contains('.');
    final hasComma = clean.contains(',');

    if (hasDot && hasComma) {
      final lastDot = clean.lastIndexOf('.');
      final lastComma = clean.lastIndexOf(',');
      if (lastDot < lastComma) {

        integerPartStr = clean.substring(0, lastComma).replaceAll('.', '');
        fractionalPartStr = clean.substring(lastComma + 1);
      } else {

        integerPartStr = clean.substring(0, lastDot).replaceAll(',', '');
        fractionalPartStr = clean.substring(lastDot + 1);
      }
    } else if (hasComma) {
      final parts = clean.split(',');
      if (parts.length == 2) {
        integerPartStr = parts[0];
        fractionalPartStr = parts[1];
      } else {
        throw FormatException('Formato numérico ambíguo ou inválido com vírgulas: $input');
      }
    } else if (hasDot) {
      final parts = clean.split('.');
      if (parts.length == 2) {

        integerPartStr = parts[0];
        fractionalPartStr = parts[1];
      } else {

        integerPartStr = clean.replaceAll('.', '');
      }
    } else {

      integerPartStr = clean;
    }

    if (integerPartStr.isEmpty) {
      integerPartStr = '0';
    } else if (!RegExp(r'^\d+$').hasMatch(integerPartStr)) {
      throw FormatException('Parte inteira contém caracteres inválidos: $input');
    }

    if (fractionalPartStr.isNotEmpty && !RegExp(r'^\d+$').hasMatch(fractionalPartStr)) {
      throw FormatException('Parte fracionária contém caracteres inválidos: $input');
    }

    final int integerPart = int.parse(integerPartStr);

    int cents = 0;
    if (fractionalPartStr.isNotEmpty) {
      if (fractionalPartStr.length == 1) {
        cents = int.parse(fractionalPartStr) * 10;
      } else if (fractionalPartStr.length == 2) {
        cents = int.parse(fractionalPartStr);
      } else {
        if (!allowExtraDecimals) {
          throw ExtraDecimalsException(input, fractionalPartStr.length);
        }

        final firstTwo = int.parse(fractionalPartStr.substring(0, 2));
        final thirdDigit = int.parse(fractionalPartStr[2]);
        if (thirdDigit >= 5) {
          cents = firstTwo + 1;
        } else {
          cents = firstTwo;
        }
      }
    }

    int totalCents = integerPart * 100 + cents;
    if (isNegative) {
      totalCents = -totalCents;
    }

    return Money.fromCents(totalCents, currency: currency);
  }

  static Money fromMaskedText(String maskedText, {String currency = 'BRL'}) {
    return parse(maskedText, currency: currency, allowExtraDecimals: false);
  }
}
