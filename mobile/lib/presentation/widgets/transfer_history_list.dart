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
        padding: EdgeInsets.all(16),
        child: Text('No transfers yet.'),
      );
    }
    final sorted = [...transfers]..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final transfer in sorted)
          ListTile(
            title: Text(
              '${catById(transfer.fromCatId)?.name ?? transfer.fromCatId} '
              '→ ${catById(transfer.toCatId)?.name ?? transfer.toCatId}',
            ),
            subtitle: Text('${transfer.createdAt}'),
            trailing: Text('${transfer.amountTreats}'),
          ),
      ],
    );
  }
}
