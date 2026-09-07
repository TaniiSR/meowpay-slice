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
      appBar: AppBar(title: const Text('MeowPay')),
      body: BlocBuilder<MeowPayCubit, MeowPayState>(
        builder: (context, state) {
          return switch (state) {
            MeowPayInitial() || MeowPayLoading() =>
              const Center(child: CircularProgressIndicator()),
            MeowPayLoadError(:final message) => _buildError(context, message),
            MeowPayLoaded() => _buildLoaded(context, state),
          };
        },
      ),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message),
          const SizedBox(height: 12),
          ElevatedButton(
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
        children: [
          for (final cat in state.cats)
            CatListTile(
              cat: cat,
              onTopUp: () => context.read<MeowPayCubit>().topUp(cat.id),
            ),
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
          TransferHistoryList(
            transfers: state.transfers,
            catById: state.catById,
          ),
        ],
      ),
    );
  }
}
