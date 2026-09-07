class Cat {
  final String id;
  final String name;
  final int balanceTreats;

  const Cat({required this.id, required this.name, required this.balanceTreats});

  Cat copyWith({int? balanceTreats}) => Cat(
        id: id,
        name: name,
        balanceTreats: balanceTreats ?? this.balanceTreats,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Cat &&
          id == other.id &&
          name == other.name &&
          balanceTreats == other.balanceTreats;

  @override
  int get hashCode => Object.hash(id, name, balanceTreats);
}
