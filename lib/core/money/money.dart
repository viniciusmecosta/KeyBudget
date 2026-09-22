
class Money implements Comparable<Money> {

  static const int maxSafeInteger = 9007199254740991;

  final int amountMinor;

  final String currency;

  final int scale;

  const Money(
    this.amountMinor, {
    this.currency = 'BRL',
    this.scale = 2,
  }) : assert(
          amountMinor >= -maxSafeInteger && amountMinor <= maxSafeInteger,
          'Valor excede o limite seguro de 53 bits (abs(amountMinor) <= $maxSafeInteger)',
        );

  factory Money.fromCents(int cents, {String currency = 'BRL', int scale = 2}) {
    if (cents < -maxSafeInteger || cents > maxSafeInteger) {
      throw ArgumentError(
        'Valor $cents excede o limite seguro de 53 bits (-$maxSafeInteger a $maxSafeInteger)',
      );
    }
    return Money(cents, currency: currency, scale: scale);
  }

  factory Money.fromNumWithHalfAwayFromZero(
    num value, {
    String currency = 'BRL',
    int scale = 2,
  }) {
    if (value.isNaN || value.isInfinite) {
      throw ArgumentError('Valor monetário não pode ser NaN ou infinito: $value');
    }

    if (value is int) {
      return Money.fromCents(value * 100, currency: currency, scale: scale);
    }

    final isNegative = value < 0;
    String str = value.abs().toString();
    if (str.contains('e') || str.contains('E')) {
      str = value.abs().toStringAsFixed(8);
    }

    final dotIndex = str.indexOf('.');
    int totalCents;
    if (dotIndex == -1) {
      totalCents = int.parse(str) * 100;
    } else {
      final intPart = int.parse(str.substring(0, dotIndex));
      final fracPart = str.substring(dotIndex + 1);

      int cents = 0;
      if (fracPart.length == 1) {
        cents = int.parse(fracPart) * 10;
      } else if (fracPart.length == 2) {
        cents = int.parse(fracPart);
      } else {
        final firstTwo = int.parse(fracPart.substring(0, 2));
        final thirdDigit = int.parse(fracPart[2]);
        if (thirdDigit >= 5) {
          cents = firstTwo + 1;
        } else {
          cents = firstTwo;
        }
      }
      totalCents = intPart * 100 + cents;
    }

    if (isNegative) {
      totalCents = -totalCents;
    }

    return Money.fromCents(totalCents, currency: currency, scale: scale);
  }

  static bool hasMoreThanTwoDecimals(num value) {
    if (value is int) return false;
    String str = value.abs().toString();
    if (str.contains('e') || str.contains('E')) {
      str = value.abs().toStringAsFixed(8);
    }
    final dotIndex = str.indexOf('.');
    if (dotIndex == -1) return false;
    final fracPart = str.substring(dotIndex + 1);
    if (fracPart.length <= 2) return false;
    for (int i = 2; i < fracPart.length; i++) {
      if (fracPart[i] != '0') return true;
    }
    return false;
  }

  double toDouble() => amountMinor / 100.0;

  bool get isZero => amountMinor == 0;
  bool get isPositive => amountMinor > 0;
  bool get isNegative => amountMinor < 0;

  Money operator +(Money other) {
    _ensureSameCurrency(other);
    final result = amountMinor + other.amountMinor;
    return Money.fromCents(result, currency: currency, scale: scale);
  }

  Money operator -(Money other) {
    _ensureSameCurrency(other);
    final result = amountMinor - other.amountMinor;
    return Money.fromCents(result, currency: currency, scale: scale);
  }

  Money operator *(int factor) {
    final result = amountMinor * factor;
    return Money.fromCents(result, currency: currency, scale: scale);
  }

  List<Money> split(int parts) {
    if (parts <= 0) {
      throw ArgumentError('O número de partes deve ser maior que zero: $parts');
    }
    final base = amountMinor ~/ parts;
    final remainder = amountMinor % parts;

    return List.generate(parts, (i) {
      final extra = remainder >= 0
          ? (i < remainder ? 1 : 0)
          : (i < -remainder ? -1 : 0);
      return Money.fromCents(base + extra, currency: currency, scale: scale);
    });
  }

  String formatBrl({bool includeSymbol = true}) {
    final isNeg = amountMinor < 0;
    final abs = amountMinor.abs();
    final reais = abs ~/ 100;
    final cents = abs % 100;

    final reaisStr = _formatThousands(reais);
    final centsStr = cents.toString().padLeft(2, '0');
    final prefix = isNeg ? '-' : '';
    final symbol = includeSymbol ? 'R\$ ' : '';

    return '$prefix$symbol$reaisStr,$centsStr';
  }

  static String _formatThousands(int n) {
    final s = n.toString();
    final buffer = StringBuffer();
    final len = s.length;
    for (int i = 0; i < len; i++) {
      if (i > 0 && (len - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(s[i]);
    }
    return buffer.toString();
  }

  void _ensureSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Moedas incompatíveis: $currency e ${other.currency}. Não é permitida conversão cambial implícita.',
      );
    }
  }

  @override
  int compareTo(Money other) {
    _ensureSameCurrency(other);
    return amountMinor.compareTo(other.amountMinor);
  }

  bool operator <(Money other) => compareTo(other) < 0;
  bool operator <=(Money other) => compareTo(other) <= 0;
  bool operator >(Money other) => compareTo(other) > 0;
  bool operator >=(Money other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          runtimeType == other.runtimeType &&
          amountMinor == other.amountMinor &&
          currency == other.currency &&
          scale == other.scale;

  @override
  int get hashCode =>
      amountMinor.hashCode ^ currency.hashCode ^ scale.hashCode;

  @override
  String toString() => 'Money($amountMinor cents $currency)';
}
