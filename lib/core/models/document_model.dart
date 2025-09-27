import 'package:cloud_firestore/cloud_firestore.dart';

class Document {
  final String? id;
  final String nomeDocumento;
  final String numero;
  final DateTime? dataExpedicao;
  final DateTime? validade;
  final Map<String, String> camposAdicionais;
  final List<Anexo> anexos;
  final bool isPrincipal;
  final String? originalDocumentId;
  final List<Document> versoes;

  Document({
    this.id,
    required this.nomeDocumento,
    required this.numero,
    this.dataExpedicao,
    this.validade,
    this.camposAdicionais = const {},
    this.anexos = const [],
    this.isPrincipal = true,
    this.originalDocumentId,
    this.versoes = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'nomeDocumento': nomeDocumento,
      'numero': numero,
      'dataExpedicao':
          dataExpedicao != null ? Timestamp.fromDate(dataExpedicao!) : null,
      'validade': validade != null ? Timestamp.fromDate(validade!) : null,
      'camposAdicionais': camposAdicionais,
      'anexos': anexos.map((anexo) => anexo.toMap()).toList(),
      'isPrincipal': isPrincipal,
      'originalDocumentId': originalDocumentId,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map, String id) {
    return Document(
      id: id,
      nomeDocumento: map['nomeDocumento'] ?? '',
      numero: map['numero'] ?? '',
      dataExpedicao: (map['dataExpedicao'] as Timestamp?)?.toDate(),
      validade: (map['validade'] as Timestamp?)?.toDate(),
      camposAdicionais: Map<String, String>.from(map['camposAdicionais'] ?? {}),
      anexos: (map['anexos'] as List<dynamic>?)
              ?.map((anexoMap) => Anexo.fromMap(anexoMap))
              .toList() ??
          [],
      isPrincipal: map['isPrincipal'] ?? true,
      originalDocumentId: map['originalDocumentId'],
    );
  }

  Document copyWith({
    String? id,
    String? nomeDocumento,
    String? numero,
    DateTime? dataExpedicao,
    DateTime? validade,
    Map<String, String>? camposAdicionais,
    List<Anexo>? anexos,
    bool? isPrincipal,
    String? originalDocumentId,
    List<Document>? versoes,
  }) {
    return Document(
      id: id ?? this.id,
      nomeDocumento: nomeDocumento ?? this.nomeDocumento,
      numero: numero ?? this.numero,
      dataExpedicao: dataExpedicao ?? this.dataExpedicao,
      validade: validade ?? this.validade,
      camposAdicionais: camposAdicionais ?? this.camposAdicionais,
      anexos: anexos ?? this.anexos,
      isPrincipal: isPrincipal ?? this.isPrincipal,
      originalDocumentId: originalDocumentId ?? this.originalDocumentId,
      versoes: versoes ?? this.versoes,
    );
  }
}

class Anexo {
  final String nome;
  final String tipo;
  final String base64;

  Anexo({
    required this.nome,
    required this.tipo,
    required this.base64,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'tipo': tipo,
      'base64': base64,
    };
  }

  factory Anexo.fromMap(Map<String, dynamic> map) {
    return Anexo(
      nome: map['nome'],
      tipo: map['tipo'],
      base64: map['base64'],
    );
  }
}
