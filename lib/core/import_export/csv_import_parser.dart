import 'package:csv/csv.dart';

enum CsvImportType {
  expenses,
  credentials,
  categories,
  recurringExpenses,
  unknown,
}

class RawCsvRow {
  final int lineNumber;
  final Map<String, String> values;
  final List<String> rawTokens;
  final String? parseError;

  const RawCsvRow({
    required this.lineNumber,
    required this.values,
    required this.rawTokens,
    this.parseError,
  });

  bool get hasError => parseError != null;
}

class CsvParseResult {
  final CsvImportType detectedType;
  final List<String> headers;
  final Map<String, String> normalizedToOriginalHeader;
  final List<RawCsvRow> rows;
  final List<String> structuralErrors;
  final String detectedDelimiter;
  final bool hadBom;

  const CsvParseResult({
    required this.detectedType,
    required this.headers,
    required this.normalizedToOriginalHeader,
    required this.rows,
    required this.structuralErrors,
    required this.detectedDelimiter,
    required this.hadBom,
  });

  bool get isValid => structuralErrors.isEmpty;
  int get totalRows => rows.length;
  int get validStructureRows => rows.where((r) => !r.hasError).length;
}

class CsvImportParser {
  final int maxSizeBytes;
  final int maxRows;
  final int maxCellLength;

  const CsvImportParser({
    this.maxSizeBytes = 10 * 1024 * 1024,
    this.maxRows = 10000,
    this.maxCellLength = 20000,
  });

  static String stripLeadingBom(String content) {
    if (content.startsWith('\uFEFF')) {
      return content.substring(1);
    }
    return content;
  }

  static String detectDelimiter(String content) {
    final firstLine = content.split('\n').firstWhere(
          (l) => l.trim().isNotEmpty,
          orElse: () => '',
        );

    int commas = 0;
    int semicolons = 0;
    bool inQuote = false;

    for (int i = 0; i < firstLine.length; i++) {
      final char = firstLine[i];
      if (char == '"') {
        inQuote = !inQuote;
      } else if (!inQuote) {
        if (char == ',') commas++;
        if (char == ';') semicolons++;
      }
    }

    if (semicolons > commas) return ';';
    return ',';
  }

  static String canonicalizeHeader(String header) {
    final clean = stripLeadingBom(header).trim().toLowerCase();
    switch (clean) {
      case 'date':
      case 'data':
      case 'dt':
        return 'date';
      case 'amount':
      case 'valor':
      case 'val':
      case 'amountminor':
      case 'amount_minor':
        return 'amount';
      case 'categoryid':
      case 'category_id':
      case 'categoria':
      case 'categoria_id':
        return 'categoryid';
      case 'motivation':
      case 'motivo':
      case 'descricao':
      case 'description':
        return 'motivation';
      case 'location':
      case 'local':
      case 'estabelecimento':
      case 'site':
      case 'titulo':
      case 'title':
        return 'location';
      case 'login':
      case 'usuario':
      case 'user':
      case 'username':
        return 'login';
      case 'password':
      case 'senha':
      case 'pass':
        return 'password';
      case 'folderid':
      case 'folder_id':
      case 'pasta':
      case 'pasta_id':
        return 'folderid';
      case 'frequency':
      case 'frequencia':
      case 'periodo':
        return 'frequency';
      case 'startdate':
      case 'start_date':
      case 'inicio':
      case 'data_inicio':
        return 'startdate';
      case 'enddate':
      case 'end_date':
      case 'fim':
      case 'data_fim':
        return 'enddate';
      case 'isincome':
      case 'is_income':
      case 'receita':
      case 'tipo':
      case 'type':
        return 'isincome';
      case 'id':
      case 'uuid':
      case 'doc_id':
        return 'id';
      default:
        return clean;
    }
  }

  static CsvImportType detectType(Set<String> canonicalHeaders) {
    if (canonicalHeaders.contains('frequency') &&
        (canonicalHeaders.contains('startdate') || canonicalHeaders.contains('amount'))) {
      return CsvImportType.recurringExpenses;
    }
    if (canonicalHeaders.contains('password') ||
        (canonicalHeaders.contains('login') && canonicalHeaders.contains('location'))) {
      return CsvImportType.credentials;
    }
    if (canonicalHeaders.contains('name') && canonicalHeaders.contains('color')) {
      return CsvImportType.categories;
    }
    if (canonicalHeaders.contains('amount') ||
        (canonicalHeaders.contains('date') &&
            (canonicalHeaders.contains('motivation') || canonicalHeaders.contains('location')))) {
      return CsvImportType.expenses;
    }
    return CsvImportType.unknown;
  }

  CsvParseResult parseString(
    String rawContent, {
    String? explicitDelimiter,
  }) {
    final List<String> structuralErrors = [];

    if (rawContent.length > maxSizeBytes) {
      return CsvParseResult(
        detectedType: CsvImportType.unknown,
        headers: [],
        normalizedToOriginalHeader: {},
        rows: [],
        structuralErrors: [
          'Tamanho do arquivo (${rawContent.length} bytes) excede o limite máximo permitido ($maxSizeBytes bytes).'
        ],
        detectedDelimiter: ',',
        hadBom: false,
      );
    }

    final bool hadBom = rawContent.startsWith('\uFEFF');
    final String cleanContent = stripLeadingBom(rawContent);

    if (cleanContent.trim().isEmpty) {
      return CsvParseResult(
        detectedType: CsvImportType.unknown,
        headers: [],
        normalizedToOriginalHeader: {},
        rows: [],
        structuralErrors: ['O arquivo CSV está completamente vazio.'],
        detectedDelimiter: ',',
        hadBom: hadBom,
      );
    }

    final delimiter = explicitDelimiter ?? detectDelimiter(cleanContent);

    final csvDecoder = Csv(
      fieldDelimiter: delimiter,
      dynamicTyping: false,
      autoDetect: false,
      skipEmptyLines: false,
    );

    final List<List<dynamic>> decoded;
    try {
      decoded = csvDecoder.decode(cleanContent);
    } catch (e) {
      return CsvParseResult(
        detectedType: CsvImportType.unknown,
        headers: [],
        normalizedToOriginalHeader: {},
        rows: [],
        structuralErrors: ['Erro ao decodificar estrutura do CSV: ${e.toString()}'],
        detectedDelimiter: delimiter,
        hadBom: hadBom,
      );
    }

    if (decoded.isEmpty) {
      return CsvParseResult(
        detectedType: CsvImportType.unknown,
        headers: [],
        normalizedToOriginalHeader: {},
        rows: [],
        structuralErrors: ['Nenhuma linha válida encontrada no CSV.'],
        detectedDelimiter: delimiter,
        hadBom: hadBom,
      );
    }

    final rawHeaders = decoded.first.map((e) => e?.toString() ?? '').toList();
    final List<String> originalHeaders = [];
    final Set<String> seenCanonicals = {};
    final Map<String, String> canonicalToOriginal = {};
    final Set<String> duplicateHeaders = {};

    for (final h in rawHeaders) {
      final original = stripLeadingBom(h).trim();
      originalHeaders.add(original);
      final canonical = canonicalizeHeader(original);
      if (seenCanonicals.contains(canonical) && canonical.isNotEmpty) {
        duplicateHeaders.add(original);
      }
      seenCanonicals.add(canonical);
      canonicalToOriginal[canonical] = original;
    }

    if (duplicateHeaders.isNotEmpty) {
      structuralErrors.add(
        'Cabeçalhos duplicados encontrados no CSV: ${duplicateHeaders.join(", ")}.',
      );
    }

    final detectedType = detectType(seenCanonicals);
    final expectedCols = originalHeaders.length;

    final List<RawCsvRow> rows = [];
    int lineCounter = 1;

    for (int i = 1; i < decoded.length; i++) {
      lineCounter++;
      final row = decoded[i];

      final isAllEmpty = row.every((cell) => (cell?.toString().trim().isEmpty ?? true));
      if (isAllEmpty && i == decoded.length - 1) {
        continue;
      }

      if (rows.length >= maxRows) {
        structuralErrors.add(
          'Arquivo excede a quantidade máxima de $maxRows linhas. Linhas excedentes foram truncadas.',
        );
        break;
      }

      final tokens = row.map((cell) => cell?.toString() ?? '').toList();

      bool cellOverflow = false;
      for (final t in tokens) {
        if (t.length > maxCellLength) {
          cellOverflow = true;
          break;
        }
      }

      if (cellOverflow) {
        rows.add(
          RawCsvRow(
            lineNumber: lineCounter,
            values: {},
            rawTokens: tokens,
            parseError:
                'Linha $lineCounter contém célula que excede o limite de $maxCellLength caracteres.',
          ),
        );
        continue;
      }

      if (tokens.length != expectedCols) {
        rows.add(
          RawCsvRow(
            lineNumber: lineCounter,
            values: {},
            rawTokens: tokens,
            parseError:
                'Linha $lineCounter possui ${tokens.length} colunas (esperado $expectedCols pelo cabeçalho).',
          ),
        );
        continue;
      }

      final Map<String, String> valuesMap = {};
      for (int c = 0; c < expectedCols; c++) {
        final canonHeader = canonicalizeHeader(originalHeaders[c]);
        valuesMap[canonHeader] = tokens[c].trim();
      }

      rows.add(
        RawCsvRow(
          lineNumber: lineCounter,
          values: valuesMap,
          rawTokens: tokens,
        ),
      );
    }

    return CsvParseResult(
      detectedType: detectedType,
      headers: originalHeaders,
      normalizedToOriginalHeader: canonicalToOriginal,
      rows: rows,
      structuralErrors: structuralErrors,
      detectedDelimiter: delimiter,
      hadBom: hadBom,
    );
  }
}
