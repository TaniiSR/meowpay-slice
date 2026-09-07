import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/domain/entities/cat.dart';
import 'package:mobile/domain/usecases/get_cats.dart';

import '../support/fake_meowpay_repository.dart';

void main() {
  test('GetCats returns all seeded cats, in order', () async {
    const whiskers = Cat(id: '1', name: 'Whiskers', balanceTreats: 100);
    const mochi = Cat(id: '2', name: 'Mochi', balanceTreats: 50);
    final repo = FakeMeowPayRepository([whiskers, mochi]);
    final getCats = GetCats(repo);

    final result = await getCats();

    expect(result, equals([whiskers, mochi]));
  });
}
