import '../entities/treat_transfer.dart';
import '../repositories/meowpay_repository.dart';

class GetTransferHistory {
  final MeowPayRepository _repository;

  const GetTransferHistory(this._repository);

  Future<List<TreatTransfer>> call({String? catId}) =>
      _repository.getTransfers(catId: catId);
}
