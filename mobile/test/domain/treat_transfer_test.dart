import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/domain/entities/treat_transfer.dart';

void main() {
  group('TreatTransfer', () {
    test('two TreatTransfers with identical fields are equal and share hashCode', () {
      final createdAt = DateTime(2026, 1, 1, 12, 0, 0);
      final a = TreatTransfer(
        id: 't1',
        fromCatId: '1',
        toCatId: '2',
        amountTreats: 20,
        createdAt: createdAt,
      );
      final b = TreatTransfer(
        id: 't1',
        fromCatId: '1',
        toCatId: '2',
        amountTreats: 20,
        createdAt: createdAt,
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('TreatTransfers differing by a single field are not equal', () {
      final createdAt = DateTime(2026, 1, 1, 12, 0, 0);
      final a = TreatTransfer(
        id: 't1',
        fromCatId: '1',
        toCatId: '2',
        amountTreats: 20,
        createdAt: createdAt,
      );
      final differentAmount = TreatTransfer(
        id: 't1',
        fromCatId: '1',
        toCatId: '2',
        amountTreats: 99,
        createdAt: createdAt,
      );

      expect(a, isNot(equals(differentAmount)));
    });
  });
}
