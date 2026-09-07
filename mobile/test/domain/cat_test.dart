import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/domain/entities/cat.dart';

void main() {
  group('Cat', () {
    test('two Cats with identical fields are equal and share hashCode', () {
      const a = Cat(id: '1', name: 'Whiskers', balanceTreats: 100);
      const b = Cat(id: '1', name: 'Whiskers', balanceTreats: 100);

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });

    test('copyWith(balanceTreats:) changes only that field', () {
      const original = Cat(id: '1', name: 'Whiskers', balanceTreats: 100);

      final updated = original.copyWith(balanceTreats: 80);

      expect(updated.balanceTreats, 80);
      expect(updated.id, original.id);
      expect(updated.name, original.name);
    });

    test('copyWith() with no args returns an equivalent Cat', () {
      const original = Cat(id: '1', name: 'Whiskers', balanceTreats: 100);

      final copy = original.copyWith();

      expect(copy, equals(original));
    });
  });
}
