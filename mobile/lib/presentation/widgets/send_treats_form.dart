import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/cat.dart';

class SendTreatsForm extends StatefulWidget {
  final List<Cat> cats;
  final bool isSubmitting;
  final String? errorText;
  final String? successText;
  final void Function({
    required String fromCatId,
    required String toCatId,
    required int amountTreats,
  }) onSubmit;

  const SendTreatsForm({
    super.key,
    required this.cats,
    required this.isSubmitting,
    required this.errorText,
    required this.successText,
    required this.onSubmit,
  });

  @override
  State<SendTreatsForm> createState() => _SendTreatsFormState();
}

class _SendTreatsFormState extends State<SendTreatsForm> {
  String? _fromCatId;
  String? _toCatId;
  final _amountController = TextEditingController();

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _submit() {
    final fromCatId = _fromCatId;
    final toCatId = _toCatId;
    final amountTreats = int.tryParse(_amountController.text);
    if (fromCatId == null || toCatId == null || amountTreats == null) return;
    widget.onSubmit(fromCatId: fromCatId, toCatId: toCatId, amountTreats: amountTreats);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Send treats', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            key: const Key('fromCatDropdown'),
            initialValue: _fromCatId,
            decoration: const InputDecoration(labelText: 'From'),
            items: [
              for (final cat in widget.cats)
                DropdownMenuItem(value: cat.id, child: Text(cat.name)),
            ],
            onChanged: (value) => setState(() => _fromCatId = value),
          ),
          DropdownButtonFormField<String>(
            key: const Key('toCatDropdown'),
            initialValue: _toCatId,
            decoration: const InputDecoration(labelText: 'To'),
            items: [
              for (final cat in widget.cats)
                DropdownMenuItem(value: cat.id, child: Text(cat.name)),
            ],
            onChanged: (value) => setState(() => _toCatId = value),
          ),
          TextField(
            key: const Key('amountField'),
            controller: _amountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(labelText: 'Amount'),
          ),
          const SizedBox(height: 8),
          if (widget.errorText != null)
            Text(widget.errorText!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          if (widget.successText != null)
            Text(widget.successText!, style: const TextStyle(color: Colors.green)),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: widget.isSubmitting ? null : _submit,
            child: Text(widget.isSubmitting ? 'Sending...' : 'Send'),
          ),
        ],
      ),
    );
  }
}
