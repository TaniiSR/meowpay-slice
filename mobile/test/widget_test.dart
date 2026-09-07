import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/domain/entities/cat.dart';
import 'package:mobile/presentation/cubit/meowpay_cubit.dart';
import 'package:mobile/presentation/views/home_screen.dart';

import 'support/fake_meowpay_repository.dart';

const _whiskers = Cat(id: 'w', name: 'Whiskers', balanceTreats: 100);
const _mochi = Cat(id: 'm', name: 'Mochi', balanceTreats: 50);

Widget _wrap(MeowPayCubit cubit) => BlocProvider<MeowPayCubit>.value(
      value: cubit,
      child: const MaterialApp(home: HomeScreen()),
    );

void main() {
  testWidgets('shows spinner then seeded cats and balances', (tester) async {
    final cubit = buildTestCubit(FakeMeowPayRepository([_whiskers, _mochi]));
    await tester.pumpWidget(_wrap(cubit));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.text('Whiskers'), findsOneWidget);
    expect(find.text('Mochi'), findsOneWidget);
    expect(find.text('100'), findsOneWidget);
    expect(find.text('50'), findsOneWidget);
  });

  testWidgets('tapping a cat top-up button updates its balance', (tester) async {
    final cubit = buildTestCubit(FakeMeowPayRepository([_whiskers, _mochi]));
    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Top up +20').first);
    await tester.pumpAndSettle();

    expect(find.text('120'), findsOneWidget);
  });

  testWidgets('submitting the send-treats form shows a success message', (tester) async {
    final cubit = buildTestCubit(FakeMeowPayRepository([_whiskers, _mochi]));
    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('fromCatDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Whiskers').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toCatDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mochi').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('amountField')), '15');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sent 15'), findsOneWidget);
  });

  testWidgets('end-to-end: a later self-transfer clears the prior success message', (tester) async {
    final cubit = buildTestCubit(FakeMeowPayRepository([_whiskers, _mochi]));
    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('fromCatDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Whiskers').last);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('toCatDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Mochi').last);
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('amountField')), '15');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sent 15'), findsOneWidget);

    // Now change 'To' to Whiskers as well (self-transfer) and resubmit.
    await tester.tap(find.byKey(const Key('toCatDropdown')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Whiskers').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Sent 15'), findsNothing);
    expect(find.textContaining('itself'), findsOneWidget);
  });
}
