import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/treat_transfer_model.dart';
import 'package:mobile/domain/entities/treat_transfer.dart';

void main() {
  group('TreatTransferModel', () {
    test('fromJson parses all fields, including createdAt as UTC DateTime', () {
      final json = {
        'id': 'transfer-1',
        'fromCatId': '11111111-1111-1111-1111-111111111111',
        'toCatId': '22222222-2222-2222-2222-222222222222',
        'amountTreats': 10,
        'createdAt': '2026-09-08T12:00:00Z',
      };

      final model = TreatTransferModel.fromJson(json);

      expect(model.id, 'transfer-1');
      expect(model.fromCatId, '11111111-1111-1111-1111-111111111111');
      expect(model.toCatId, '22222222-2222-2222-2222-222222222222');
      expect(model.amountTreats, 10);
      expect(model.createdAt, DateTime.utc(2026, 9, 8, 12, 0, 0));
    });

    test('toDomain returns matching TreatTransfer entity', () {
      final model = TreatTransferModel(
        id: 'transfer-1',
        fromCatId: '11111111-1111-1111-1111-111111111111',
        toCatId: '22222222-2222-2222-2222-222222222222',
        amountTreats: 10,
        createdAt: DateTime.utc(2026, 9, 8, 12, 0, 0),
      );

      expect(
        model.toDomain(),
        TreatTransfer(
          id: 'transfer-1',
          fromCatId: '11111111-1111-1111-1111-111111111111',
          toCatId: '22222222-2222-2222-2222-222222222222',
          amountTreats: 10,
          createdAt: DateTime.utc(2026, 9, 8, 12, 0, 0),
        ),
      );
    });
  });
}
