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
    // Regex to find keywords related to total amount, followed by the value.
    // This is prioritized.
    final totalAmountRegex = RegExp(
      r'(?:total|valor\s+a\s+pagar|conta|final)\s*:?\s*r?\$\s*([\d.,]+)',
      caseSensitive: false,
    );

    // Generic regex to find any monetary value, used as a fallback.
    final genericAmountRegex = RegExp(r'r?\$\s*([\d.,]+)', caseSensitive: false);

    double? findBestMatch(Iterable<RegExpMatch> matches) {
      double? maxAmount;
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
      return maxAmount;
    }

    // Prioritize matches with keywords like "total".
    final totalMatches = totalAmountRegex.allMatches(text);
    final totalAmount = findBestMatch(totalMatches);
    if (totalAmount != null) {
      return totalAmount;
    }

    // Fallback: if no "total" keyword is found, find the largest amount on the receipt.
    final genericMatches = genericAmountRegex.allMatches(text);
    return findBestMatch(genericMatches);
  }

  DateTime? _extractDate(String text) {
    // Regex to find dates in dd/mm/yyyy, dd-mm-yyyy, or dd.mm.yyyy formats.
    final dateRegex = RegExp(r'(\d{2})[./-](\d{2})[./-](\d{2,4})');
    final match = dateRegex.firstMatch(text);

    if (match != null) {
      try {
        final day = int.parse(match.group(1)!);
        final month = int.parse(match.group(2)!);
        final yearStr = match.group(3)!;
        final year = int.parse(yearStr.length == 2 ? '20$yearStr' : yearStr);

        // Basic validation for date components.
        if (month > 0 && month <= 12 && day > 0 && day <= 31) {
          return DateTime(year, month, day);
        }
      } catch (e) {
        return null; // Parsing failed.
      }
    }
    return null;
  }

  String? _extractSupplier(String text) {
    // Heuristic: The supplier is often one of the first lines, but we need to
    // ignore common receipt boilerplate.
    final junkKeywords = [
      'cupom fiscal', 'cnpj', 'ie:', 'coo:', 'extrato', 'sat',
      'documento auxiliar', 'venda ao consumidor'
    ];

    final lines = text
        .split('\n')
        .map((line) => line.trim())
        .where((line) => line.isNotEmpty)
        .toList();

    for (final line in lines) {
      final lowerLine = line.toLowerCase();
      if (junkKeywords.any((keyword) => lowerLine.contains(keyword))) {
        continue; // Skip this line, it's likely boilerplate.
      }
      // A potential supplier name is usually short and doesn't contain a price.
      if (line.length < 30 && !line.contains(RegExp(r'r?\$\s*[\d.,]+'))) {
        return line;
      }
    }

    // Fallback to the very first line if the smart search fails.
    return lines.isNotEmpty ? lines.first : null;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
