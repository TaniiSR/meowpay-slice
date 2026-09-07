import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/data/models/cat_model.dart';
import 'package:mobile/domain/entities/cat.dart';

void main() {
  group('CatModel', () {
    test('fromJson parses all fields', () {
      final json = {
        'id': '11111111-1111-1111-1111-111111111111',
        'name': 'Whiskers',
        'balanceTreats': 100,
      };

      final model = CatModel.fromJson(json);

      expect(model.id, '11111111-1111-1111-1111-111111111111');
      expect(model.name, 'Whiskers');
      expect(model.balanceTreats, 100);
    });

    test('toDomain returns matching Cat entity', () {
      const model = CatModel(
        id: '11111111-1111-1111-1111-111111111111',
        name: 'Whiskers',
        balanceTreats: 100,
      );

      expect(
        model.toDomain(),
        const Cat(
          id: '11111111-1111-1111-1111-111111111111',
          name: 'Whiskers',
          balanceTreats: 100,
        ),
      );
    });
  });
}
