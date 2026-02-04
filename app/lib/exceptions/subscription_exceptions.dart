/// Exception thrown when user exceeds concurrent reading limit
class ConcurrentReadingLimitException implements Exception {
  final String message;

  ConcurrentReadingLimitException(this.message);

  @override
  String toString() => 'ConcurrentReadingLimitException: $message';
}

/// Exception thrown when user exceeds AI Recall usage limit
class AiRecallLimitException implements Exception {
  final String message;
  final int remainingUses;

  AiRecallLimitException(this.message, {this.remainingUses = 0});

  @override
  String toString() => 'AiRecallLimitException: $message';
}

/// Exception thrown when subscription check fails
class SubscriptionCheckException implements Exception {
  final String message;

  SubscriptionCheckException(this.message);

  @override
  String toString() => 'SubscriptionCheckException: $message';
}
