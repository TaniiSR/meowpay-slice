import '../../domain/entities/treat_transfer.dart';

class TreatTransferModel {
  final String id;
  final String fromCatId;
  final String toCatId;
  final int amountTreats;
  final DateTime createdAt;

  const TreatTransferModel({
    required this.id,
    required this.fromCatId,
    required this.toCatId,
    required this.amountTreats,
    required this.createdAt,
  });

  factory TreatTransferModel.fromJson(Map<String, dynamic> json) => TreatTransferModel(
        id: json['id'] as String,
        fromCatId: json['fromCatId'] as String,
        toCatId: json['toCatId'] as String,
        amountTreats: json['amountTreats'] as int,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  TreatTransfer toDomain() => TreatTransfer(
        id: id,
        fromCatId: fromCatId,
        toCatId: toCatId,
        amountTreats: amountTreats,
        createdAt: createdAt,
      );
}
