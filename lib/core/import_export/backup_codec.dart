import 'dart:collection';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';

class BackupCodecException implements Exception {
  final String message;
  final String? recordId;
  final String? fieldName;

  BackupCodecException(this.message, {this.recordId, this.fieldName});

  @override
  String toString() {
    if (recordId != null && fieldName != null) {
      return 'BackupCodecException: $message (registro: $recordId, campo: $fieldName)';
    }
    return 'BackupCodecException: $message';
  }
}

class BackupRecord {
  final String id;
  final Map<String, dynamic> data;
  final String? portablePassword;
  final Map<String, dynamic>? metadata;

  const BackupRecord({
    required this.id,
    required this.data,
    this.portablePassword,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'data': BackupCodec.canonicalizeValue(data, recordId: id),
        if (portablePassword != null) 'portablePassword': portablePassword,
        if (metadata != null)
          'metadata': BackupCodec.canonicalizeValue(metadata, recordId: id),
      };

  factory BackupRecord.fromMap(Map<String, dynamic> map) {
    return BackupRecord(
      id: map['id'] as String,
      data: BackupCodec.restoreValue(
        map['data'],
        recordId: map['id'] as String?,
      ) as Map<String, dynamic>,
      portablePassword: map['portablePassword'] as String?,
      metadata: map['metadata'] != null
          ? BackupCodec.restoreValue(
              map['metadata'],
              recordId: map['id'] as String?,
            ) as Map<String, dynamic>?
          : null,
    );
  }
}

class BackupCodec {

  static dynamic canonicalizeValue(
    dynamic value, {
    String? recordId,
    String? fieldName,
  }) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is int) return value;
    if (value is double) return value;
    if (value is String) return value;

    if (value is Timestamp) {
      return {
        '_type': 'timestamp',
        '_seconds': value.seconds,
        '_nanoseconds': value.nanoseconds,
      };
    }

    try {
      final dynamic dyn = value;
      if (dyn.seconds is int && dyn.nanoseconds is int) {
        return {
          '_type': 'timestamp',
          '_seconds': dyn.seconds as int,
          '_nanoseconds': dyn.nanoseconds as int,
        };
      }
    } catch (_) {}

    if (value is GeoPoint) {
      return {
        '_type': 'geopoint',
        'latitude': value.latitude,
        'longitude': value.longitude,
      };
    }

    if (value is List) {
      return value
          .asMap()
          .entries
          .map(
            (entry) => canonicalizeValue(
              entry.value,
              recordId: recordId,
              fieldName: fieldName != null
                  ? '$fieldName[${entry.key}]'
                  : '[${entry.key}]',
            ),
          )
          .toList();
    }

    if (value is Map) {
      final sortedKeys = value.keys.map((k) => k.toString()).toList()..sort();
      final SplayTreeMap<String, dynamic> sortedMap =
          SplayTreeMap<String, dynamic>();

      for (final key in sortedKeys) {
        final val = value[key];
        sortedMap[key] = canonicalizeValue(
          val,
          recordId: recordId,
          fieldName: fieldName != null ? '$fieldName.$key' : key,
        );
      }
      return sortedMap;
    }

    throw BackupCodecException(
      'Tipo de dado não suportado: ${value.runtimeType}',
      recordId: recordId,
      fieldName: fieldName,
    );
  }

  static dynamic restoreValue(
    dynamic value, {
    String? recordId,
    String? fieldName,
  }) {
    if (value == null) return null;
    if (value is bool || value is num || value is String) return value;

    if (value is List) {
      return value
          .asMap()
          .entries
          .map(
            (e) => restoreValue(
              e.value,
              recordId: recordId,
              fieldName: fieldName != null ? '$fieldName[${e.key}]' : '[${e.key}]',
            ),
          )
          .toList();
    }

    if (value is Map) {
      if (value['_type'] == 'timestamp') {
        final seconds = value['_seconds'] as int? ?? 0;
        final nanoseconds = value['_nanoseconds'] as int? ?? 0;
        return Timestamp(seconds, nanoseconds);
      }

      if (value['_type'] == 'geopoint') {
        final lat = (value['latitude'] as num).toDouble();
        final lng = (value['longitude'] as num).toDouble();
        return GeoPoint(lat, lng);
      }

      final Map<String, dynamic> resultMap = {};
      for (final entry in value.entries) {
        final k = entry.key.toString();
        resultMap[k] = restoreValue(
          entry.value,
          recordId: recordId,
          fieldName: fieldName != null ? '$fieldName.$k' : k,
        );
      }
      return resultMap;
    }

    return value;
  }

  static String encodeRecords(List<BackupRecord> records) {
    final listMap = records.map((r) => r.toMap()).toList();
    return const JsonEncoder.withIndent('  ').convert(listMap);
  }

  static List<BackupRecord> decodeRecords(String jsonStr) {
    final decoded = json.decode(jsonStr) as List<dynamic>;
    return decoded
        .map((e) => BackupRecord.fromMap(Map<String, dynamic>.from(e as Map)))
        .toList();
  }

  static String computeCanonicalDigest(
    Map<String, dynamic> data, {
    String? recordId,
  }) {
    final canonical = canonicalizeValue(data, recordId: recordId);
    final jsonString = json.encode(canonical);
    final bytes = utf8.encode(jsonString);
    return sha256.convert(bytes).toString();
  }

  static String computeBytesSha256(List<int> bytes) {
    return sha256.convert(bytes).toString();
  }
}
