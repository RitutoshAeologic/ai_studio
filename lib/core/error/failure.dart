/// Sealed failure types for uniform error handling across data/domain/UI layers.
sealed class Failure {
  final String message;
  final Object? error;

  const Failure(this.message, [this.error]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Network connection failed', super.error]);
}

class InsufficientCreditsFailure extends Failure {
  const InsufficientCreditsFailure([super.message = 'Insufficient credits available', super.error]);
}

class JobFailedFailure extends Failure {
  const JobFailedFailure([super.message = 'AI generation job failed', super.error]);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Authentication failed', super.error]);
}

class UnknownFailure extends Failure {
  const UnknownFailure([super.message = 'An unknown error occurred', super.error]);
}
