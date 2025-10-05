import 'package:cloud_firestore/cloud_firestore.dart';

class Document {
  final String? id;
  final String documentName;
  final String? number;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final Map<String, String> additionalFields;
  final List<Attachment> attachments;
  final bool isPrincipal;
  final String? originalDocumentId;
  final List<Document> versions;

  Document({
    this.id,
    required this.documentName,
    this.number,
    this.issueDate,
    this.expiryDate,
    this.additionalFields = const {},
    this.attachments = const [],
    this.isPrincipal = true,
    this.originalDocumentId,
    this.versions = const [],
  });

  Map<String, dynamic> toMap() {
    final List<Map<String, dynamic>> attachmentsData =
        attachments.map((attachment) => attachment.toMap()).toList();

    return {
      'documentName': documentName,
      'number': number,
      'issueDate': issueDate != null ? Timestamp.fromDate(issueDate!) : null,
      'expiryDate': expiryDate != null ? Timestamp.fromDate(expiryDate!) : null,
      'additionalFields': Map<String, dynamic>.from(additionalFields),
      'attachments': attachmentsData,
      'isPrincipal': isPrincipal,
      'originalDocumentId': originalDocumentId,
    };
  }

  factory Document.fromMap(Map<String, dynamic> map, String id) {
    return Document(
      id: id,
      documentName: map['documentName'] ?? '',
      number: map['number'],
      issueDate: (map['issueDate'] as Timestamp?)?.toDate(),
      expiryDate: (map['expiryDate'] as Timestamp?)?.toDate(),
      additionalFields: Map<String, String>.from(map['additionalFields'] ?? {}),
      attachments: (map['attachments'] as List<dynamic>?)
              ?.map((attachmentMap) =>
                  Attachment.fromMap(attachmentMap as Map<String, dynamic>))
              .toList() ??
          [],
      isPrincipal: map['isPrincipal'] ?? true,
      originalDocumentId: map['originalDocumentId'],
    );
  }

  Document copyWith({
    String? id,
    String? documentName,
    String? number,
    DateTime? issueDate,
    DateTime? expiryDate,
    Map<String, String>? additionalFields,
    List<Attachment>? attachments,
    bool? isPrincipal,
    String? originalDocumentId,
    List<Document>? versions,
  }) {
    return Document(
      id: id ?? this.id,
      documentName: documentName ?? this.documentName,
      number: number ?? this.number,
      issueDate: issueDate ?? this.issueDate,
      expiryDate: expiryDate ?? this.expiryDate,
      additionalFields: additionalFields ?? this.additionalFields,
      attachments: attachments ?? this.attachments,
      isPrincipal: isPrincipal ?? this.isPrincipal,
      originalDocumentId: originalDocumentId ?? this.originalDocumentId,
      versions: versions ?? this.versions,
    );
  }
}

class Attachment {
  String name;
  final String type;
  final String driveId;

  Attachment({
    required this.name,
    required this.type,
    required this.driveId,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'driveId': driveId,
    };
  }

  factory Attachment.fromMap(Map<String, dynamic> map) {
    return Attachment(
      name: map['name'] ?? '',
      type: map['type'] ?? '',
      driveId: map['driveId'] ?? '',
    );
  }
}
