import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/cat.dart';
import '../../domain/entities/treat_transfer.dart';
import '../../domain/entities/meowpay_failure.dart';
import '../../domain/usecases/get_cats.dart';
import '../../domain/usecases/get_transfer_history.dart';
import '../../domain/usecases/send_treats.dart';
import '../../domain/usecases/top_up.dart';
import 'meowpay_state.dart';

class MeowPayCubit extends Cubit<MeowPayState> {
  final GetCats _getCats;
  final GetTransferHistory _getTransferHistory;
  final SendTreats _sendTreats;
  final TopUp _topUp;

  MeowPayCubit({
    required GetCats getCats,
    required GetTransferHistory getTransferHistory,
    required SendTreats sendTreats,
    required TopUp topUp,
  })  : _getCats = getCats,
        _getTransferHistory = getTransferHistory,
        _sendTreats = sendTreats,
        _topUp = topUp,
        super(const MeowPayInitial());

  Future<void> loadData() async {
    emit(const MeowPayLoading());
    try {
      final results = await Future.wait([_getCats(), _getTransferHistory()]);
      emit(MeowPayLoaded(cats: results[0] as List<Cat>, transfers: results[1] as List<TreatTransfer>));
    } on MeowPayException catch (e) {
      emit(MeowPayLoadError(e.failure.message));
    } catch (_) {
      emit(const MeowPayLoadError('Something went wrong loading MeowPay data'));
    }
  }

  Future<void> sendTreats({
    required String fromCatId,
    required String toCatId,
    required int amountTreats,
  }) async {
    final current = state;
    if (current is! MeowPayLoaded) return;
    emit(current.copyWith(isSubmitting: true, clearFormMessages: true));
    try {
      await _sendTreats(fromCatId: fromCatId, toCatId: toCatId, amountTreats: amountTreats);
      final from = current.catById(fromCatId)?.name ?? 'that cat';
      final to = current.catById(toCatId)?.name ?? 'that cat';
      final refreshed = await _reload();
      emit(refreshed.copyWith(
        formSuccess: 'Sent $amountTreats treat${amountTreats == 1 ? '' : 's'} from $from to $to',
      ));
    } on MeowPayException catch (e) {
      emit(current.copyWith(isSubmitting: false, formError: e.failure.message));
    } catch (_) {
      emit(current.copyWith(isSubmitting: false, formError: 'Transfer failed'));
    }
  }

  Future<void> topUp(String catId, {int amountTreats = 20}) async {
    final current = state;
    if (current is! MeowPayLoaded) return;
    emit(current.copyWith(clearFormMessages: true));
    try {
      await _topUp(catId: catId, amountTreats: amountTreats);
      emit(await _reload());
    } on MeowPayException catch (e) {
      emit(current.copyWith(formError: e.failure.message));
    } catch (_) {
      emit(current.copyWith(formError: 'Top-up failed'));
    }
  }

  Future<MeowPayLoaded> _reload() async {
    final results = await Future.wait([_getCats(), _getTransferHistory()]);
    return MeowPayLoaded(cats: results[0] as List<Cat>, transfers: results[1] as List<TreatTransfer>);
  }
}
