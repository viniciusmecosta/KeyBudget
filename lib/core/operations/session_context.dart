class SessionContext {
  final String userId;
  final int sessionGeneration;
  final String? operationId;

  const SessionContext({
    required this.userId,
    required this.sessionGeneration,
    this.operationId,
  });

  bool get isValid => userId.isNotEmpty && sessionGeneration > 0;

  bool isValidFor(String currentUserId, int currentGeneration) {
    return userId == currentUserId && sessionGeneration == currentGeneration;
  }

  SessionContext withOperation(String opId) {
    return SessionContext(
      userId: userId,
      sessionGeneration: sessionGeneration,
      operationId: opId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionContext &&
          runtimeType == other.runtimeType &&
          userId == other.userId &&
          sessionGeneration == other.sessionGeneration &&
          operationId == other.operationId;

  @override
  int get hashCode =>
      userId.hashCode ^ sessionGeneration.hashCode ^ operationId.hashCode;
}
