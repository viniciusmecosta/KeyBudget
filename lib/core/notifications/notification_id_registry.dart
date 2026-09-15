
import 'dart:convert';
import 'dart:io';

class NotificationRegistryEntry {
  final String logicalKey;
  final int nativeId;
  final String uid;
  final String ruleId;
  final String scheduledDateKey;
  final String fingerprint;
  final DateTime scheduledAt;
  final int version;

  const NotificationRegistryEntry({
    required this.logicalKey,
    required this.nativeId,
    required this.uid,
    required this.ruleId,
    required this.scheduledDateKey,
    required this.fingerprint,
    required this.scheduledAt,
    this.version = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'logicalKey': logicalKey,
      'nativeId': nativeId,
      'uid': uid,
      'ruleId': ruleId,
      'scheduledDateKey': scheduledDateKey,
      'fingerprint': fingerprint,
      'scheduledAt': scheduledAt.toIso8601String(),
      'version': version,
    };
  }

  factory NotificationRegistryEntry.fromMap(Map<String, dynamic> map) {
    return NotificationRegistryEntry(
      logicalKey: map['logicalKey'] as String,
      nativeId: map['nativeId'] as int,
      uid: map['uid'] as String,
      ruleId: map['ruleId'] as String,
      scheduledDateKey: map['scheduledDateKey'] as String,
      fingerprint: map['fingerprint'] as String,
      scheduledAt: DateTime.parse(map['scheduledAt'] as String),
      version: (map['version'] as int?) ?? 1,
    );
  }
}

class NotificationIdRegistry {
  File? _storageFile;
  final Map<String, NotificationRegistryEntry> _entries = {};

  NotificationIdRegistry({this._storageFile}) {
    if (_storageFile != null && _storageFile!.existsSync()) {
      _loadFromStorage();
    }
  }

  void initWithFile(File file) {
    _storageFile = file;
    if (_storageFile!.existsSync()) {
      _loadFromStorage();
    }
  }

  void _loadFromStorage() {
    if (_storageFile == null || !_storageFile!.existsSync()) return;
    try {
      final rawJson = _storageFile!.readAsStringSync();
      if (rawJson.isNotEmpty) {
        final decoded = json.decode(rawJson) as Map<String, dynamic>;
        _entries.clear();
        decoded.forEach((key, value) {
          if (value is Map<String, dynamic>) {
            _entries[key] = NotificationRegistryEntry.fromMap(value);
          }
        });
      }
    } catch (_) {

      _entries.clear();
    }
  }

  Future<void> _persistToStorage() async {
    if (_storageFile == null) return;
    try {
      final Map<String, dynamic> serialized = {};
      _entries.forEach((key, entry) {
        serialized[key] = entry.toMap();
      });
      await _storageFile!.writeAsString(json.encode(serialized), flush: true);
    } catch (_) {

    }
  }

  Future<NotificationRegistryEntry> getOrAllocate({
    required String logicalKey,
    required String uid,
    required String ruleId,
    required String scheduledDateKey,
    required String fingerprint,
    required DateTime scheduledAt,
  }) async {
    final existing = _entries[logicalKey];
    if (existing != null) {

      final updated = NotificationRegistryEntry(
        logicalKey: logicalKey,
        nativeId: existing.nativeId,
        uid: uid,
        ruleId: ruleId,
        scheduledDateKey: scheduledDateKey,
        fingerprint: fingerprint,
        scheduledAt: scheduledAt,
        version: existing.version,
      );
      _entries[logicalKey] = updated;
      await _persistToStorage();
      return updated;
    }

    final usedNativeIds = _entries.values.map((e) => e.nativeId).toSet();
    int candidate = (logicalKey.hashCode & 0x7FFFFFFF) % 2000000000 + 1000;
    while (usedNativeIds.contains(candidate)) {
      candidate = (candidate + 1) % 2000000000 + 1000;
    }

    final newEntry = NotificationRegistryEntry(
      logicalKey: logicalKey,
      nativeId: candidate,
      uid: uid,
      ruleId: ruleId,
      scheduledDateKey: scheduledDateKey,
      fingerprint: fingerprint,
      scheduledAt: scheduledAt,
    );
    _entries[logicalKey] = newEntry;
    await _persistToStorage();
    return newEntry;
  }

  NotificationRegistryEntry? getEntry(String logicalKey) => _entries[logicalKey];

  List<NotificationRegistryEntry> getEntriesForUid(String uid) {
    return _entries.values.where((e) => e.uid == uid).toList();
  }

  List<NotificationRegistryEntry> getAllEntries() {
    return _entries.values.toList();
  }

  Future<void> removeByLogicalKey(String logicalKey) async {
    if (_entries.containsKey(logicalKey)) {
      _entries.remove(logicalKey);
      await _persistToStorage();
    }
  }

  Future<void> removeEntriesForUid(String uid) async {
    final keysToRemove = _entries.entries
        .where((e) => e.value.uid == uid)
        .map((e) => e.key)
        .toList();
    for (final k in keysToRemove) {
      _entries.remove(k);
    }
    await _persistToStorage();
  }

  Future<void> clearAll() async {
    _entries.clear();
    await _persistToStorage();
  }
}
