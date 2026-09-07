import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/data/datasources/meowpay_remote_data_source.dart';
import 'package:mobile/data/repositories/meowpay_repository_impl.dart';
import 'package:mobile/domain/entities/cat.dart';
import 'package:mobile/domain/entities/treat_transfer.dart';

const _baseUrl = 'http://10.0.2.2:8080';

MeowPayRepositoryImpl _repositoryWith(http.Client client) {
  return MeowPayRepositoryImpl(MeowPayRemoteDataSource(baseUrl: _baseUrl, client: client));
}

void main() {
  group('MeowPayRepositoryImpl', () {
    test('getCats maps CatModel list to domain Cat list', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': '11111111-1111-1111-1111-111111111111',
              'name': 'Whiskers',
              'balanceTreats': 100,
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final repository = _repositoryWith(client);

      final cats = await repository.getCats();

      expect(cats, [
        const Cat(
          id: '11111111-1111-1111-1111-111111111111',
          name: 'Whiskers',
          balanceTreats: 100,
        ),
      ]);
    });

    test('getTransfers maps TreatTransferModel list to domain TreatTransfer list', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode([
            {
              'id': 'transfer-1',
              'fromCatId': '11111111-1111-1111-1111-111111111111',
              'toCatId': '22222222-2222-2222-2222-222222222222',
              'amountTreats': 10,
              'createdAt': '2026-09-08T12:00:00Z',
            },
          ]),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final repository = _repositoryWith(client);

      final transfers = await repository.getTransfers();

      expect(transfers, [
        TreatTransfer(
          id: 'transfer-1',
          fromCatId: '11111111-1111-1111-1111-111111111111',
          toCatId: '22222222-2222-2222-2222-222222222222',
          amountTreats: 10,
          createdAt: DateTime.utc(2026, 9, 8, 12, 0, 0),
        ),
      ]);
    });

    test('topUp maps CatModel to domain Cat', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'id': '11111111-1111-1111-1111-111111111111',
            'name': 'Whiskers',
            'balanceTreats': 125,
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });
      final repository = _repositoryWith(client);

      final cat = await repository.topUp(
        catId: '11111111-1111-1111-1111-111111111111',
        amountTreats: 25,
      );

      expect(
        cat,
        const Cat(
          id: '11111111-1111-1111-1111-111111111111',
          name: 'Whiskers',
          balanceTreats: 125,
        ),
      );
    });

    test('sendTreats maps TreatTransferModel to domain TreatTransfer', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'id': 'transfer-1',
            'fromCatId': '11111111-1111-1111-1111-111111111111',
            'toCatId': '22222222-2222-2222-2222-222222222222',
            'amountTreats': 10,
            'createdAt': '2026-09-08T12:00:00Z',
          }),
          201,
          headers: {'content-type': 'application/json'},
        );
      });
      final repository = _repositoryWith(client);

      final transfer = await repository.sendTreats(
        fromCatId: '11111111-1111-1111-1111-111111111111',
        toCatId: '22222222-2222-2222-2222-222222222222',
        amountTreats: 10,
      );

      expect(
        transfer,
        TreatTransfer(
          id: 'transfer-1',
          fromCatId: '11111111-1111-1111-1111-111111111111',
          toCatId: '22222222-2222-2222-2222-222222222222',
          amountTreats: 10,
          createdAt: DateTime.utc(2026, 9, 8, 12, 0, 0),
        ),
      );
    });
  });
}
