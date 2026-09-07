import 'package:flutter/material.dart';
import '../../domain/entities/cat.dart';
import '../../domain/entities/treat_transfer.dart';

class TransferHistoryList extends StatelessWidget {
  final List<TreatTransfer> transfers;
  final Cat? Function(String) catById;

  const TransferHistoryList({super.key, required this.transfers, required this.catById});

  @override
  Widget build(BuildContext context) {
    if (transfers.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Text('No transfers yet.', style: TextStyle(color: Colors.grey)),
      );
    }
    final sorted = [...transfers]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Column(
      children: sorted.map((transfer) {
        final fromName = catById(transfer.fromCatId)?.name ?? 'Unknown';
        final toName = catById(transfer.toCatId)?.name ?? 'Unknown';
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            title: Text('$fromName → $toName'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${transfer.amountTreats}'),
                const SizedBox(width: 4),
                const Icon(Icons.cookie, size: 16),
              ],
            ),
            subtitle: Text(transfer.createdAt.toLocal().toString()),
          ),
        );
      }).toList(),
    );
  }
}
