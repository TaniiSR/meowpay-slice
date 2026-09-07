import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/domain/entities/cat.dart';
import 'package:mobile/domain/entities/meowpay_failure.dart';
import 'package:mobile/domain/usecases/top_up.dart';

import '../support/fake_meowpay_repository.dart';

void main() {
  group('TopUp', () {
    test('happy path: increases the balance and returns the updated cat', () async {
      const mochi = Cat(id: '2', name: 'Mochi', balanceTreats: 50);
      final repo = FakeMeowPayRepository([mochi]);
      final topUp = TopUp(repo);

      final updated = await topUp(catId: '2', amountTreats: 25);

      expect(updated.balanceTreats, 75);
    });

    test('rejects a zero amount, client-side, without calling the repository', () async {
      const mochi = Cat(id: '2', name: 'Mochi', balanceTreats: 50);
      final repo = FakeMeowPayRepository([mochi]);
      final topUp = TopUp(repo);

      await expectLater(
        () => topUp(catId: '2', amountTreats: 0),
        throwsA(
          isA<MeowPayException>().having((e) => e.failure, 'failure', isA<InvalidTransferFailure>()),
        ),
      );

      final cats = {for (final c in await repo.getCats()) c.id: c};
      expect(cats['2']!.balanceTreats, 50);
    });

    test('rejects a negative amount, client-side, without calling the repository', () async {
      const mochi = Cat(id: '2', name: 'Mochi', balanceTreats: 50);
      final repo = FakeMeowPayRepository([mochi]);
      final topUp = TopUp(repo);

      await expectLater(
        () => topUp(catId: '2', amountTreats: -1),
        throwsA(
          isA<MeowPayException>().having((e) => e.failure, 'failure', isA<InvalidTransferFailure>()),
        ),
      );

      final cats = {for (final c in await repo.getCats()) c.id: c};
      expect(cats['2']!.balanceTreats, 50);
    });

    test('surfaces cat-not-found from the repository for an unknown catId', () async {
      final repo = FakeMeowPayRepository(const []);
      final topUp = TopUp(repo);

      await expectLater(
        () => topUp(catId: 'unknown', amountTreats: 10),
        throwsA(
          isA<MeowPayException>().having((e) => e.failure, 'failure', isA<CatNotFoundFailure>()),
        ),
      );
    });
  });
}
