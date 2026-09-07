import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/presentation/cubit/meowpay_state.dart';

void main() {
  group('MeowPayLoaded.copyWith', () {
    test('setting one form message clears the other', () {
      final withError = const MeowPayLoaded(cats: [], transfers: []).copyWith(formError: 'boom');
      expect(withError.formError, 'boom');
      expect(withError.formSuccess, isNull);

      final withSuccess = withError.copyWith(formSuccess: 'yay');
      expect(withSuccess.formSuccess, 'yay');
      expect(withSuccess.formError, isNull);
    });

    test('clearFormMessages clears both', () {
      final withBoth = const MeowPayLoaded(cats: [], transfers: [], formError: 'boom');
      final cleared = withBoth.copyWith(clearFormMessages: true);
      expect(cleared.formError, isNull);
      expect(cleared.formSuccess, isNull);
    });
  });
}
