class TreatTransfer {
  final String id;
  final String fromCatId;
  final String toCatId;
  final int amountTreats;
  final DateTime createdAt;

  const TreatTransfer({
    required this.id,
    required this.fromCatId,
    required this.toCatId,
    required this.amountTreats,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TreatTransfer &&
          id == other.id &&
          fromCatId == other.fromCatId &&
          toCatId == other.toCatId &&
          amountTreats == other.amountTreats &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(id, fromCatId, toCatId, amountTreats, createdAt);
}
