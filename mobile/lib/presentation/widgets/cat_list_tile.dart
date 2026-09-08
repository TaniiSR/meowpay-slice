import 'package:flutter/material.dart';
import '../../domain/entities/cat.dart';

class CatListTile extends StatelessWidget {
  final Cat cat;
  final VoidCallback onTopUp;
  final bool isTopUpInFlight;

  const CatListTile({
    super.key,
    required this.cat,
    required this.onTopUp,
    this.isTopUpInFlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(cat.name, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${cat.balanceTreats}'),
            const SizedBox(width: 4),
            const Icon(Icons.cookie, size: 16),
            const SizedBox(width: 12),
            OutlinedButton(
              onPressed: isTopUpInFlight ? null : onTopUp,
              child: Text(isTopUpInFlight ? 'Adding…' : 'Top up +20'),
            ),
          ],
        ),
      ),
    );
  }
}
