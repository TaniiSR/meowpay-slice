import '../../domain/entities/cat.dart';

class CatModel {
  final String id;
  final String name;
  final int balanceTreats;

  const CatModel({required this.id, required this.name, required this.balanceTreats});

  factory CatModel.fromJson(Map<String, dynamic> json) => CatModel(
        id: json['id'] as String,
        name: json['name'] as String,
        balanceTreats: json['balanceTreats'] as int,
      );

  Cat toDomain() => Cat(id: id, name: name, balanceTreats: balanceTreats);
}
