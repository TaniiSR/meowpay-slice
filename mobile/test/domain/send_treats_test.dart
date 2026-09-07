import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/domain/entities/cat.dart';
import 'package:mobile/domain/entities/meowpay_failure.dart';
import 'package:mobile/domain/usecases/send_treats.dart';

import '../support/fake_meowpay_repository.dart';

void main() {
  group('SendTreats', () {
    test('happy path: moves treats and returns the transfer', () async {
      const sender = Cat(id: '1', name: 'Whiskers', balanceTreats: 100);
      const recipient = Cat(id: '2', name: 'Biscuit', balanceTreats: 0);
      final repo = FakeMeowPayRepository([sender, recipient]);
      final sendTreats = SendTreats(repo);

      final transfer = await sendTreats(fromCatId: '1', toCatId: '2', amountTreats: 20);

      expect(transfer.fromCatId, '1');
      expect(transfer.toCatId, '2');
      expect(transfer.amountTreats, 20);

      final cats = {for (final c in await repo.getCats()) c.id: c};
      expect(cats['1']!.balanceTreats, 80);
      expect(cats['2']!.balanceTreats, 20);
    });

    test('rejects sending to yourself, client-side, without calling the repository', () async {
      const cat = Cat(id: '1', name: 'Whiskers', balanceTreats: 100);
      final repo = FakeMeowPayRepository([cat]);
      final sendTreats = SendTreats(repo);

      await expectLater(
        () => sendTreats(fromCatId: '1', toCatId: '1', amountTreats: 10),
        throwsA(isA<MeowPayException>()),
      );

      final cats = {for (final c in await repo.getCats()) c.id: c};
      expect(cats['1']!.balanceTreats, 100);
    });

    test('rejects a zero amount, client-side, without calling the repository', () async {
      const sender = Cat(id: '1', name: 'Whiskers', balanceTreats: 100);
      const recipient = Cat(id: '2', name: 'Biscuit', balanceTreats: 0);
      final repo = FakeMeowPayRepository([sender, recipient]);
      final sendTreats = SendTreats(repo);

      await expectLater(
        () => sendTreats(fromCatId: '1', toCatId: '2', amountTreats: 0),
        throwsA(isA<MeowPayException>()),
      );

      final cats = {for (final c in await repo.getCats()) c.id: c};
      expect(cats['1']!.balanceTreats, 100);
      expect(cats['2']!.balanceTreats, 0);
    });

    test('rejects a negative amount, client-side, without calling the repository', () async {
      const sender = Cat(id: '1', name: 'Whiskers', balanceTreats: 100);
      const recipient = Cat(id: '2', name: 'Biscuit', balanceTreats: 0);
      final repo = FakeMeowPayRepository([sender, recipient]);
      final sendTreats = SendTreats(repo);

      await expectLater(
        () => sendTreats(fromCatId: '1', toCatId: '2', amountTreats: -5),
        throwsA(isA<MeowPayException>()),
      );

      final cats = {for (final c in await repo.getCats()) c.id: c};
      expect(cats['1']!.balanceTreats, 100);
      expect(cats['2']!.balanceTreats, 0);
    });

    test('surfaces insufficient treats from the repository', () async {
      const sender = Cat(id: '1', name: 'Whiskers', balanceTreats: 0);
      const recipient = Cat(id: '2', name: 'Biscuit', balanceTreats: 0);
      final repo = FakeMeowPayRepository([sender, recipient]);
      final sendTreats = SendTreats(repo);

      await expectLater(
        () => sendTreats(fromCatId: '1', toCatId: '2', amountTreats: 10),
        throwsA(
          isA<MeowPayException>()
              .having((e) => e.failure, 'failure', isA<InsufficientTreatsFailure>()),
        ),
      );
    });

    test('surfaces cat-not-found from the repository for an unknown sender', () async {
      const recipient = Cat(id: '2', name: 'Biscuit', balanceTreats: 0);
      final repo = FakeMeowPayRepository([recipient]);
      final sendTreats = SendTreats(repo);

      await expectLater(
        () => sendTreats(fromCatId: 'unknown', toCatId: '2', amountTreats: 10),
        throwsA(
          isA<MeowPayException>().having((e) => e.failure, 'failure', isA<CatNotFoundFailure>()),
        ),
      );
    });

    test('surfaces cat-not-found from the repository for an unknown recipient', () async {
      const sender = Cat(id: '1', name: 'Whiskers', balanceTreats: 100);
      final repo = FakeMeowPayRepository([sender]);
      final sendTreats = SendTreats(repo);

      await expectLater(
        () => sendTreats(fromCatId: '1', toCatId: 'unknown', amountTreats: 10),
        throwsA(
          isA<MeowPayException>().having((e) => e.failure, 'failure', isA<CatNotFoundFailure>()),
        ),
      );
    });
  });
}
