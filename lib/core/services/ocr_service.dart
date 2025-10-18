import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  final TextRecognizer _textRecognizer =
      TextRecognizer(script: TextRecognitionScript.latin);

  Future<RecognizedText> processImage(XFile image) async {
    final inputImage = InputImage.fromFilePath(image.path);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText;
  }

  Map<String, dynamic> extractExpenseData(String text) {
    final lowerCaseText = text.toLowerCase();
    return {
      'amount': _extractAmount(lowerCaseText),
      'date': _extractDate(lowerCaseText),
      'description': _extractSupplier(text),
    };
  }

  double? _extractAmount(String text) {
    final patterns = [
      RegExp(r'(?:total\s+a\s+pagar|valor\s+total)\s*:?\s*r?\$\s*([\d.,]+)'),
      RegExp(r'(?:total|conta|final)\s*:?\s*r?\$\s*([\d.,]+)'),
      RegExp(r'r?\$\s*([\d.,]+)'),
    ];

    double? maxAmount;

    for (final pattern in patterns) {
      final matches = pattern.allMatches(text);
      if (matches.isNotEmpty) {
        for (final match in matches) {
          final valueString =
              match.group(1)!.replaceAll('.', '').replaceAll(',', '.');
          final value = double.tryParse(valueString);
          if (value != null) {
            if (maxAmount == null || value > maxAmount) {
              maxAmount = value;
            }
          }
        }
        if (maxAmount != null) return maxAmount;
      }
    }
    return maxAmount;
  }

  DateTime? _extractDate(String text) {
    final dateRegex = RegExp(r'(\d{2})[./-](\d{2})[./-](\d{2,4})');
    final match = dateRegex.firstMatch(text);

    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final yearStr = match.group(3)!;
        final year = int.parse(yearStr.length == 2 ? '20$yearStr' : yearStr);

        if (month > 0 && month <= 12 && day > 0 && day <= 31) {
          return DateTime(year, month, day);
        }
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  String? _extractSupplier(String text) {
    final junkKeywords = [
      'cupom fiscal',
      'cnpj',
      'ie:',
      'coo:',
      'extrato',
      'sat',
      'documento auxiliar',
      'venda ao consumidor',
      'endereço',
      'telefone'
    ];

    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    String? bestCandidate;
    double bestScore = 0;

    for (int i = 0; i < lines.length && i < 5; i++) {
      final line = lines[i];
      final lowerLine = line.toLowerCase();
      double currentScore = 0;

      if (junkKeywords.any((keyword) => lowerLine.contains(keyword))) {
        currentScore -= 20;
      }

      if (lowerLine.contains(RegExp(r'\d{5}-\d{3}')) ||
          lowerLine.contains(RegExp(r'^\d+$'))) {
        currentScore -= 10;
      }

      currentScore += (5 - i);

      if (line.length < 25) {
        currentScore += 5;
      }

      final alphaRatio =
          (line.replaceAll(RegExp(r'[^a-zA-Z]'), '').length / line.length);
      if (alphaRatio > 0.7) {
        currentScore += 10;
      }

      if (currentScore > bestScore) {
        bestScore = currentScore;
        bestCandidate = line;
      }
    }

    return bestCandidate;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
