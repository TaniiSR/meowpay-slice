import '../entities/cat.dart';
import '../entities/treat_transfer.dart';

abstract interface class MeowPayRepository {
  Future<List<Cat>> getCats();

  Future<List<TreatTransfer>> getTransfers({String? catId});

  Future<Cat> topUp({required String catId, required int amountTreats});

  Future<TreatTransfer> sendTreats({
    required String fromCatId,
    required String toCatId,
    required int amountTreats,
  });
}
