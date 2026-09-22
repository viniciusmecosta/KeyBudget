enum OperationStatus {
  completed,
  partial,
  cancelled,
  failed,
  conflict,
  pending,
}

class OperationResult<T> {
  final OperationStatus status;
  final T? data;
  final String? message;
  final String? safeError;
  final String? rawErrorCode;
  final List<String> affectedIds;
  final int totalCount;
  final int successCount;
  final int failedCount;
  final int conflictCount;
  final Map<String, dynamic>? metadata;

  const OperationResult({
    required this.status,
    this.data,
    this.message,
    this.safeError,
    this.rawErrorCode,
    this.affectedIds = const [],
    this.totalCount = 0,
    this.successCount = 0,
    this.failedCount = 0,
    this.conflictCount = 0,
    this.metadata,
  });

  bool get isSuccess => status == OperationStatus.completed;
  bool get isPartial => status == OperationStatus.partial;
  bool get isCancelled => status == OperationStatus.cancelled;
  bool get isFailed => status == OperationStatus.failed;
  bool get isConflict => status == OperationStatus.conflict;
  bool get isPending => status == OperationStatus.pending;

  factory OperationResult.completed({
    T? data,
    String? message,
    List<String> affectedIds = const [],
    int count = 1,
    Map<String, dynamic>? metadata,
  }) {
    return OperationResult(
      status: OperationStatus.completed,
      data: data,
      message: message,
      affectedIds: affectedIds,
      totalCount: count,
      successCount: count,
      metadata: metadata,
    );
  }

  factory OperationResult.partial({
    T? data,
    String? message,
    String? safeError,
    List<String> affectedIds = const [],
    int totalCount = 0,
    int successCount = 0,
    int failedCount = 0,
    int conflictCount = 0,
    Map<String, dynamic>? metadata,
  }) {
    return OperationResult(
      status: OperationStatus.partial,
      data: data,
      message: message,
      safeError: safeError,
      affectedIds: affectedIds,
      totalCount: totalCount,
      successCount: successCount,
      failedCount: failedCount,
      conflictCount: conflictCount,
      metadata: metadata,
    );
  }

  factory OperationResult.cancelled({
    String? message,
    T? data,
    Map<String, dynamic>? metadata,
  }) {
    return OperationResult(
      status: OperationStatus.cancelled,
      data: data,
      message: message ?? 'Operação cancelada.',
      metadata: metadata,
    );
  }

  factory OperationResult.failed({
    required String safeError,
    String? rawErrorCode,
    T? data,
    List<String> affectedIds = const [],
    Map<String, dynamic>? metadata,
  }) {
    return OperationResult(
      status: OperationStatus.failed,
      data: data,
      safeError: safeError,
      rawErrorCode: rawErrorCode,
      affectedIds: affectedIds,
      metadata: metadata,
    );
  }

  factory OperationResult.conflict({
    required String message,
    String? safeError,
    List<String> affectedIds = const [],
    T? data,
    Map<String, dynamic>? metadata,
  }) {
    return OperationResult(
      status: OperationStatus.conflict,
      data: data,
      message: message,
      safeError: safeError,
      affectedIds: affectedIds,
      conflictCount: affectedIds.isNotEmpty ? affectedIds.length : 1,
      metadata: metadata,
    );
  }

  factory OperationResult.pending({
    String? message,
    T? data,
    List<String> affectedIds = const [],
    Map<String, dynamic>? metadata,
  }) {
    return OperationResult(
      status: OperationStatus.pending,
      data: data,
      message: message ?? 'Operação pendente de sincronização.',
      affectedIds: affectedIds,
      metadata: metadata,
    );
  }
}
