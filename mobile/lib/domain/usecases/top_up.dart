import '../entities/cat.dart';
import '../entities/meowpay_failure.dart';
import '../repositories/meowpay_repository.dart';

class TopUp {
  final MeowPayRepository _repository;

  const TopUp(this._repository);

  Future<Cat> call({required String catId, required int amountTreats}) {
    if (amountTreats <= 0) {
      throw const MeowPayException(InvalidTransferFailure('Amount must be positive'));
    }
    return _repository.topUp(catId: catId, amountTreats: amountTreats);
  }
}
