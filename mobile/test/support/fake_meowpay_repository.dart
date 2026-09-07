import 'package:mobile/domain/entities/cat.dart';
import 'package:mobile/domain/entities/meowpay_failure.dart';
import 'package:mobile/domain/entities/treat_transfer.dart';
import 'package:mobile/domain/repositories/meowpay_repository.dart';

class FakeMeowPayRepository implements MeowPayRepository {
  final Map<String, Cat> _cats;
  final List<TreatTransfer> _transfers = [];
  int _nextTransferId = 1;

  FakeMeowPayRepository(List<Cat> seed) : _cats = {for (final c in seed) c.id: c};

  @override
  Future<List<Cat>> getCats() async => _cats.values.toList();

  @override
  Future<List<TreatTransfer>> getTransfers({String? catId}) async => _transfers
      .where((t) => catId == null || t.fromCatId == catId || t.toCatId == catId)
      .toList();

  @override
  Future<Cat> topUp({required String catId, required int amountTreats}) async {
    final cat = _cats[catId];
    if (cat == null) {
      throw MeowPayException(CatNotFoundFailure('Cat $catId not found'));
    }
    final updated = cat.copyWith(balanceTreats: cat.balanceTreats + amountTreats);
    _cats[catId] = updated;
    return updated;
  }

  @override
  Future<TreatTransfer> sendTreats({
    required String fromCatId,
    required String toCatId,
    required int amountTreats,
  }) async {
    final from = _cats[fromCatId];
    final to = _cats[toCatId];
    if (from == null || to == null) {
      throw MeowPayException(CatNotFoundFailure('Cat not found'));
    }
    if (from.balanceTreats < amountTreats) {
      throw MeowPayException(
        InsufficientTreatsFailure('Cat $fromCatId does not have enough treats'),
      );
    }
    _cats[fromCatId] = from.copyWith(balanceTreats: from.balanceTreats - amountTreats);
    _cats[toCatId] = to.copyWith(balanceTreats: to.balanceTreats + amountTreats);
    final transfer = TreatTransfer(
      id: 't${_nextTransferId++}',
      fromCatId: fromCatId,
      toCatId: toCatId,
      amountTreats: amountTreats,
      createdAt: DateTime.now(),
    );
    _transfers.add(transfer);
    return transfer;
  }
}
