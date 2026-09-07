import 'package:equatable/equatable.dart';
import '../../domain/entities/cat.dart';
import '../../domain/entities/treat_transfer.dart';

sealed class MeowPayState extends Equatable {
  const MeowPayState();
  @override
  List<Object?> get props => [];
}

class MeowPayInitial extends MeowPayState {
  const MeowPayInitial();
}

class MeowPayLoading extends MeowPayState {
  const MeowPayLoading();
}

class MeowPayLoadError extends MeowPayState {
  final String message;
  const MeowPayLoadError(this.message);
  @override
  List<Object?> get props => [message];
}

class MeowPayLoaded extends MeowPayState {
  final List<Cat> cats;
  final List<TreatTransfer> transfers;
  final bool isSubmitting;
  final String? formError;
  final String? formSuccess;

  const MeowPayLoaded({
    required this.cats,
    required this.transfers,
    this.isSubmitting = false,
    this.formError,
    this.formSuccess,
  }) : assert(formError == null || formSuccess == null,
            'copyWith: formError and formSuccess must not both be set - call clearFormMessages instead');

  Cat? catById(String id) {
    for (final cat in cats) {
      if (cat.id == id) return cat;
    }
    return null;
  }

  MeowPayLoaded copyWith({
    List<Cat>? cats,
    List<TreatTransfer>? transfers,
    bool? isSubmitting,
    String? formError,
    String? formSuccess,
    bool clearFormMessages = false,
  }) =>
      MeowPayLoaded(
        cats: cats ?? this.cats,
        transfers: transfers ?? this.transfers,
        isSubmitting: isSubmitting ?? this.isSubmitting,
        formError:
            clearFormMessages ? null : (formError ?? (formSuccess != null ? null : this.formError)),
        formSuccess:
            clearFormMessages ? null : (formSuccess ?? (formError != null ? null : this.formSuccess)),
      );

  @override
  List<Object?> get props => [cats, transfers, isSubmitting, formError, formSuccess];
}
