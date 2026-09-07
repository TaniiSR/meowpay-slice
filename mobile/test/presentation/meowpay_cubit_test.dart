import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/domain/entities/cat.dart';
import 'package:mobile/domain/entities/meowpay_failure.dart';
import 'package:mobile/domain/entities/treat_transfer.dart';
import 'package:mobile/domain/repositories/meowpay_repository.dart';
import 'package:mobile/domain/usecases/get_cats.dart';
import 'package:mobile/domain/usecases/get_transfer_history.dart';
import 'package:mobile/domain/usecases/send_treats.dart';
import 'package:mobile/domain/usecases/top_up.dart';
import 'package:mobile/presentation/cubit/meowpay_cubit.dart';
import 'package:mobile/presentation/cubit/meowpay_state.dart';

import '../support/fake_meowpay_repository.dart';

class _UnreachableRepository implements MeowPayRepository {
  @override
  Future<List<Cat>> getCats() async {
    throw const MeowPayException(NetworkFailure('offline'));
  }

  @override
  Future<List<TreatTransfer>> getTransfers({String? catId}) async => throw UnimplementedError();

  @override
  Future<Cat> topUp({required String catId, required int amountTreats}) async =>
      throw UnimplementedError();

  @override
  Future<TreatTransfer> sendTreats({
    required String fromCatId,
    required String toCatId,
    required int amountTreats,
  }) async =>
      throw UnimplementedError();
}

const _whiskers = Cat(id: 'w', name: 'Whiskers', balanceTreats: 100);
const _mochi = Cat(id: 'm', name: 'Mochi', balanceTreats: 50);

void main() {
  group('MeowPayCubit.loadData', () {
    blocTest<MeowPayCubit, MeowPayState>(
      'happy path emits Loading then Loaded with cats',
      build: () => buildTestCubit(FakeMeowPayRepository([_whiskers, _mochi])),
      act: (cubit) => cubit.loadData(),
      expect: () => [
        const MeowPayLoading(),
        isA<MeowPayLoaded>().having((s) => s.cats, 'cats', hasLength(2)),
      ],
    );

    blocTest<MeowPayCubit, MeowPayState>(
      'failure emits Loading then LoadError',
      build: () => MeowPayCubit(
        getCats: GetCats(_UnreachableRepository()),
        getTransferHistory: GetTransferHistory(_UnreachableRepository()),
        sendTreats: SendTreats(_UnreachableRepository()),
        topUp: TopUp(_UnreachableRepository()),
      ),
      act: (cubit) => cubit.loadData(),
      expect: () => [
        const MeowPayLoading(),
        const MeowPayLoadError('offline'),
      ],
    );
  });

  group('MeowPayCubit.sendTreats', () {
    blocTest<MeowPayCubit, MeowPayState>(
      'happy path moves balances and sets formSuccess',
      build: () => buildTestCubit(FakeMeowPayRepository([_whiskers, _mochi])),
      act: (cubit) async {
        await cubit.loadData();
        await cubit.sendTreats(fromCatId: 'w', toCatId: 'm', amountTreats: 30);
      },
      verify: (cubit) {
        final state = cubit.state as MeowPayLoaded;
        expect(state.formError, isNull);
        expect(state.formSuccess, contains('30'));
        expect(state.catById('w')!.balanceTreats, 70);
        expect(state.catById('m')!.balanceTreats, 80);
      },
    );

    blocTest<MeowPayCubit, MeowPayState>(
      'self-transfer sets formError and leaves balances unchanged',
      build: () => buildTestCubit(FakeMeowPayRepository([_whiskers, _mochi])),
      act: (cubit) async {
        await cubit.loadData();
        await cubit.sendTreats(fromCatId: 'w', toCatId: 'w', amountTreats: 10);
      },
      verify: (cubit) {
        final state = cubit.state as MeowPayLoaded;
        expect(state.formError, contains('itself'));
        expect(state.catById('w')!.balanceTreats, 100);
      },
    );

    blocTest<MeowPayCubit, MeowPayState>(
      'insufficient treats sets formError',
      build: () => buildTestCubit(
        FakeMeowPayRepository([const Cat(id: 'w', name: 'Whiskers', balanceTreats: 5), _mochi]),
      ),
      act: (cubit) async {
        await cubit.loadData();
        await cubit.sendTreats(fromCatId: 'w', toCatId: 'm', amountTreats: 30);
      },
      verify: (cubit) {
        final state = cubit.state as MeowPayLoaded;
        expect(state.formError, contains('enough treats'));
      },
    );

    blocTest<MeowPayCubit, MeowPayState>(
      'unknown cat sets formError',
      build: () => buildTestCubit(FakeMeowPayRepository([_whiskers, _mochi])),
      act: (cubit) async {
        await cubit.loadData();
        await cubit.sendTreats(fromCatId: 'w', toCatId: 'nope', amountTreats: 10);
      },
      verify: (cubit) {
        final state = cubit.state as MeowPayLoaded;
        expect(state.formError, isNotNull);
      },
    );

    blocTest<MeowPayCubit, MeowPayState>(
      'mutual exclusivity regression: a later failing submit clears a prior success',
      build: () => buildTestCubit(FakeMeowPayRepository([_whiskers, _mochi])),
      act: (cubit) async {
        await cubit.loadData();
        await cubit.sendTreats(fromCatId: 'w', toCatId: 'm', amountTreats: 10);
        await cubit.sendTreats(fromCatId: 'w', toCatId: 'w', amountTreats: 10);
      },
      verify: (cubit) {
        final state = cubit.state as MeowPayLoaded;
        expect(state.formError, contains('itself'));
        expect(state.formSuccess, isNull);
      },
    );
  });

  group('MeowPayCubit.topUp', () {
    blocTest<MeowPayCubit, MeowPayState>(
      'happy path increases balance by amount',
      build: () => buildTestCubit(FakeMeowPayRepository([_whiskers, _mochi])),
      act: (cubit) async {
        await cubit.loadData();
        await cubit.topUp('w');
      },
      verify: (cubit) {
        final state = cubit.state as MeowPayLoaded;
        expect(state.catById('w')!.balanceTreats, 120);
      },
    );

    blocTest<MeowPayCubit, MeowPayState>(
      'unknown cat sets formError',
      build: () => buildTestCubit(FakeMeowPayRepository([_whiskers, _mochi])),
      act: (cubit) async {
        await cubit.loadData();
        await cubit.topUp('nope');
      },
      verify: (cubit) {
        final state = cubit.state as MeowPayLoaded;
        expect(state.formError, isNotNull);
      },
    );
  });

  group('MeowPayCubit guards against acting before load', () {
    blocTest<MeowPayCubit, MeowPayState>(
      'sendTreats while Initial emits nothing',
      build: () => buildTestCubit(FakeMeowPayRepository([_whiskers, _mochi])),
      act: (cubit) => cubit.sendTreats(fromCatId: 'w', toCatId: 'm', amountTreats: 10),
      expect: () => [],
    );

    blocTest<MeowPayCubit, MeowPayState>(
      'topUp while Initial emits nothing',
      build: () => buildTestCubit(FakeMeowPayRepository([_whiskers, _mochi])),
      act: (cubit) => cubit.topUp('w'),
      expect: () => [],
    );
  });
}
