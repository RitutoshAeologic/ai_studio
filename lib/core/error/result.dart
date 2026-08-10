import 'failure.dart';

/// Functional Result pattern for returning typed Success data or Failure errors.
sealed class Result<S, F extends Failure> {
  const Result();

  bool get isSuccess => this is Success<S, F>;
  bool get isFailure => this is Error<S, F>;

  S? get dataOrNull => isSuccess ? (this as Success<S, F>).data : null;
  F? get failureOrNull => isFailure ? (this as Error<S, F>).failure : null;

  R fold<R>(R Function(S data) onSuccess, R Function(F failure) onFailure) {
    if (this is Success<S, F>) {
      return onSuccess((this as Success<S, F>).data);
    } else {
      return onFailure((this as Error<S, F>).failure);
    }
  }
}

class Success<S, F extends Failure> extends Result<S, F> {
  final S data;
  const Success(this.data);
}

class Error<S, F extends Failure> extends Result<S, F> {
  final F failure;
  const Error(this.failure);
}
