sealed class MeowPayFailure {
  final String message;
  const MeowPayFailure(this.message);
}

class CatNotFoundFailure extends MeowPayFailure {
  const CatNotFoundFailure(super.message);
}

class InsufficientTreatsFailure extends MeowPayFailure {
  const InsufficientTreatsFailure(super.message);
}

class InvalidTransferFailure extends MeowPayFailure {
  const InvalidTransferFailure(super.message);
}

class ValidationFailure extends MeowPayFailure {
  const ValidationFailure(super.message);
}

class NetworkFailure extends MeowPayFailure {
  const NetworkFailure(super.message);
}

class UnknownFailure extends MeowPayFailure {
  const UnknownFailure(super.message);
}

class MeowPayException implements Exception {
  final MeowPayFailure failure;
  const MeowPayException(this.failure);

  @override
  String toString() => failure.message;
}
