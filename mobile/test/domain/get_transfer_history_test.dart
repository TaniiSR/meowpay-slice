import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/domain/entities/cat.dart';
import 'package:mobile/domain/usecases/get_transfer_history.dart';

import '../support/fake_meowpay_repository.dart';

void main() {
  late FakeMeowPayRepository repo;
  late GetTransferHistory getTransferHistory;

  setUp(() async {
    const whiskers = Cat(id: '1', name: 'Whiskers', balanceTreats: 100);
    const mochi = Cat(id: '2', name: 'Mochi', balanceTreats: 50);
    const biscuit = Cat(id: '3', name: 'Biscuit', balanceTreats: 0);
    repo = FakeMeowPayRepository([whiskers, mochi, biscuit]);
    getTransferHistory = GetTransferHistory(repo);

    // Whiskers -> Mochi, Mochi -> Biscuit, Biscuit -> Whiskers.
    await repo.sendTreats(fromCatId: '1', toCatId: '2', amountTreats: 10);
    await repo.sendTreats(fromCatId: '2', toCatId: '3', amountTreats: 5);
    await repo.sendTreats(fromCatId: '3', toCatId: '1', amountTreats: 1);
  });

  test('with no filter, returns all transfers', () async {
    final result = await getTransferHistory();

    expect(result, hasLength(3));
  });

  test('with catId filter, returns only transfers where that cat sent or received', () async {
    final result = await getTransferHistory(catId: '2');

    expect(result, hasLength(2));
    expect(
      result.every((t) => t.fromCatId == '2' || t.toCatId == '2'),
      isTrue,
    );
  });
}
