import '../../domain/entities/cat.dart';
import '../../domain/entities/treat_transfer.dart';
import '../../domain/repositories/meowpay_repository.dart';
import '../datasources/meowpay_remote_data_source.dart';

class MeowPayRepositoryImpl implements MeowPayRepository {
  final MeowPayRemoteDataSource remoteDataSource;

  const MeowPayRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<Cat>> getCats() async {
    final models = await remoteDataSource.getCats();
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<List<TreatTransfer>> getTransfers({String? catId}) async {
    final models = await remoteDataSource.getTransfers(catId: catId);
    return models.map((model) => model.toDomain()).toList();
  }

  @override
  Future<Cat> topUp({required String catId, required int amountTreats}) async {
    final model = await remoteDataSource.topUp(catId: catId, amountTreats: amountTreats);
    return model.toDomain();
  }

  @override
  Future<TreatTransfer> sendTreats({
    required String fromCatId,
    required String toCatId,
    required int amountTreats,
  }) async {
    final model = await remoteDataSource.sendTreats(
      fromCatId: fromCatId,
      toCatId: toCatId,
      amountTreats: amountTreats,
    );
    return model.toDomain();
  }
}
