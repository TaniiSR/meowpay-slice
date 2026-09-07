import '../entities/meowpay_failure.dart';
import '../entities/treat_transfer.dart';
import '../repositories/meowpay_repository.dart';

class SendTreats {
  final MeowPayRepository _repository;

  const SendTreats(this._repository);

  Future<TreatTransfer> call({
    required String fromCatId,
    required String toCatId,
    required int amountTreats,
  }) {
    if (fromCatId == toCatId) {
      throw const MeowPayException(
        InvalidTransferFailure("A cat can't send treats to itself"),
      );
    }
    if (amountTreats <= 0) {
      throw const MeowPayException(InvalidTransferFailure('Amount must be positive'));
    }
    return _repository.sendTreats(
      fromCatId: fromCatId,
      toCatId: toCatId,
      amountTreats: amountTreats,
    );
  }
}
