import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:key_budget/core/operations/operation_result.dart';
import 'csv_import_parser.dart';

class LegacyImportAdapters {

  static Future<OperationResult<List<RawCsvRow>>> loadLegacyJsonFromAssets({
    AssetBundle? customBundle,
  }) async {
    final bundle = customBundle ?? rootBundle;
    try {

      String manifestContent;
      try {
        manifestContent = await bundle.loadString('AssetManifest.json');
      } catch (_) {
        return OperationResult.failed(
          safeError:
              'Manifesto de assets (AssetManifest.json) não encontrado no pacote do app.',
        );
      }

      final Map<String, dynamic> manifestMap = json.decode(manifestContent);
      final jsonPaths = manifestMap.keys
          .where((String key) => key.contains('assets/data/'))
          .where((String key) => !key.contains('credentials.json'))
          .toList();

      if (jsonPaths.isEmpty) {
        return OperationResult.failed(
          safeError: 'Nenhum arquivo de dados legado encontrado em assets/data/.',
        );
      }

      final List<RawCsvRow> extractedRows = [];
      int lineCounter = 0;

      for (final path in jsonPaths) {
        final String fileContent = await bundle.loadString(path);
        final dynamic decoded = json.decode(fileContent);

        if (decoded is! List) continue;

        for (final item in decoded) {
          lineCounter++;
          if (item is! Map) {
            extractedRows.add(
              RawCsvRow(
                lineNumber: lineCounter,
                values: {},
                rawTokens: [],
                parseError: 'Elemento na linha $lineCounter não é um objeto JSON válido.',
              ),
            );
            continue;
          }

          final map = Map<String, dynamic>.from(item);
          final values = <String, String>{};
          map.forEach((k, v) {
            values[k.toLowerCase()] = v?.toString() ?? '';
          });

          extractedRows.add(
            RawCsvRow(
              lineNumber: lineCounter,
              values: values,
              rawTokens: values.values.toList(),
            ),
          );
        }
      }

      return OperationResult.completed(
        data: extractedRows,
        count: extractedRows.length,
      );
    } catch (e) {
      return OperationResult.failed(
        safeError: 'Falha ao carregar JSON legado: ${e.toString()}',
      );
    }
  }

  static OperationResult<List<RawCsvRow>> parseJsonString(String jsonContent) {
    try {
      final dynamic decoded = json.decode(jsonContent);
      if (decoded is! List) {
        return OperationResult.failed(
          safeError: 'O arquivo JSON deve conter uma lista raiz de registros.',
        );
      }

      final List<RawCsvRow> rows = [];
      int lineCounter = 0;

      for (final item in decoded) {
        lineCounter++;
        if (item is! Map) {
          rows.add(
            RawCsvRow(
              lineNumber: lineCounter,
              values: {},
              rawTokens: [],
              parseError: 'Item $lineCounter não é um objeto JSON válido.',
            ),
          );
          continue;
        }

        final map = Map<String, dynamic>.from(item);
        final values = <String, String>{};
        map.forEach((k, v) {
          values[k.toLowerCase()] = v?.toString() ?? '';
        });

        rows.add(
          RawCsvRow(
            lineNumber: lineCounter,
            values: values,
            rawTokens: values.values.toList(),
          ),
        );
      }

      return OperationResult.completed(
        data: rows,
        count: rows.length,
      );
    } catch (e) {
      return OperationResult.failed(
        safeError: 'Erro de sintaxe JSON: ${e.toString()}',
      );
    }
  }
}
