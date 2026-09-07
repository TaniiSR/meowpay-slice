import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'data/datasources/meowpay_remote_data_source.dart';
import 'data/repositories/meowpay_repository_impl.dart';
import 'domain/usecases/get_cats.dart';
import 'domain/usecases/get_transfer_history.dart';
import 'domain/usecases/send_treats.dart';
import 'domain/usecases/top_up.dart';
import 'presentation/cubit/meowpay_cubit.dart';
import 'presentation/views/home_screen.dart';

void main() {
  runApp(const MeowPayApp());
}

class MeowPayApp extends StatelessWidget {
  const MeowPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    final remoteDataSource = MeowPayRemoteDataSource(
      baseUrl: const String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080'),
    );
    final repository = MeowPayRepositoryImpl(remoteDataSource);
    return BlocProvider(
      create: (_) => MeowPayCubit(
        getCats: GetCats(repository),
        getTransferHistory: GetTransferHistory(repository),
        sendTreats: SendTreats(repository),
        topUp: TopUp(repository),
      ),
      child: MaterialApp(
        title: 'MeowPay',
        theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
        home: const HomeScreen(),
      ),
    );
  }
}
