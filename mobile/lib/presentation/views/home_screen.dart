import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/meowpay_cubit.dart';
import '../cubit/meowpay_state.dart';
import '../widgets/cat_list_tile.dart';
import '../widgets/send_treats_form.dart';
import '../widgets/transfer_history_list.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MeowPayCubit>().loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.pets),
            SizedBox(width: 8),
            Text('MeowPay'),
          ],
        ),
      ),
      body: SafeArea(
        child: BlocBuilder<MeowPayCubit, MeowPayState>(
          builder: (context, state) {
            return switch (state) {
              MeowPayInitial() || MeowPayLoading() =>
                const Center(child: CircularProgressIndicator()),
              MeowPayLoadError(:final message) => _buildError(context, message),
              MeowPayLoaded() => _buildLoaded(context, state),
            };
          },
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text("Couldn't reach the MeowPay backend."),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: () => context.read<MeowPayCubit>().loadData(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoaded(BuildContext context, MeowPayLoaded state) {
    return RefreshIndicator(
      onRefresh: () => context.read<MeowPayCubit>().loadData(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('CATS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          for (final cat in state.cats)
            CatListTile(
              cat: cat,
              onTopUp: () => context.read<MeowPayCubit>().topUp(cat.id),
            ),
          const SizedBox(height: 24),
          const Text('SEND TREATS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          SendTreatsForm(
            cats: state.cats,
            isSubmitting: state.isSubmitting,
            errorText: state.formError,
            successText: state.formSuccess,
            onSubmit: ({required fromCatId, required toCatId, required amountTreats}) =>
                context.read<MeowPayCubit>().sendTreats(
                      fromCatId: fromCatId,
                      toCatId: toCatId,
                      amountTreats: amountTreats,
                    ),
          ),
          const SizedBox(height: 24),
          const Text('RECENT TRANSFERS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          TransferHistoryList(
            transfers: state.transfers,
            catById: state.catById,
          ),
        ],
      ),
    );
  }
}
