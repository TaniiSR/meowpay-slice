import 'package:flutter/material.dart';
import '../../domain/entities/cat.dart';

class CatListTile extends StatelessWidget {
  final Cat cat;
  final VoidCallback onTopUp;

  const CatListTile({super.key, required this.cat, required this.onTopUp});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        title: Text(cat.name),
        subtitle: Text('${cat.balanceTreats}'),
        trailing: OutlinedButton(
          onPressed: onTopUp,
          child: const Text('Top up +20'),
        ),
      ),
    );
  }
}
