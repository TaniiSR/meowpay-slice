import '../entities/cat.dart';
import '../repositories/meowpay_repository.dart';

class GetCats {
  final MeowPayRepository _repository;

  const GetCats(this._repository);

  Future<List<Cat>> call() => _repository.getCats();
}
