import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mobile/data/datasources/meowpay_remote_data_source.dart';
import 'package:mobile/domain/entities/meowpay_failure.dart';

const _baseUrl = 'http://10.0.2.2:8080';

void main() {
  group('MeowPayRemoteDataSource', () {
    test('getCats sends GET to /api/cats and parses the response', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), '$_baseUrl/api/cats');
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
      final dataSource = MeowPayRemoteDataSource(baseUrl: _baseUrl, client: client);

      final cats = await dataSource.getCats();

      expect(cats, hasLength(1));
      expect(cats.single.id, '11111111-1111-1111-1111-111111111111');
      expect(cats.single.name, 'Whiskers');
      expect(cats.single.balanceTreats, 100);
    });

    test('getTransfers with no catId sends GET with no query string', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.toString(), '$_baseUrl/api/transfers');
        expect(request.url.query, isEmpty);
        return http.Response(jsonEncode([]), 200, headers: {'content-type': 'application/json'});
      });
      final dataSource = MeowPayRemoteDataSource(baseUrl: _baseUrl, client: client);

      final transfers = await dataSource.getTransfers();

      expect(transfers, isEmpty);
    });

    test('getTransfers with catId appends ?catId=...', () async {
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/api/transfers');
        expect(request.url.queryParameters['catId'], '11111111-1111-1111-1111-111111111111');
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
      final dataSource = MeowPayRemoteDataSource(baseUrl: _baseUrl, client: client);

      final transfers = await dataSource.getTransfers(
        catId: '11111111-1111-1111-1111-111111111111',
      );

      expect(transfers, hasLength(1));
      expect(transfers.single.id, 'transfer-1');
    });

    test('topUp sends POST with amountTreats body and returns updated cat', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(
          request.url.toString(),
          '$_baseUrl/api/cats/11111111-1111-1111-1111-111111111111/topup',
        );
        expect(request.headers['Content-Type'], contains('application/json'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, {'amountTreats': 25});
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
      final dataSource = MeowPayRemoteDataSource(baseUrl: _baseUrl, client: client);

      final cat = await dataSource.topUp(
        catId: '11111111-1111-1111-1111-111111111111',
        amountTreats: 25,
      );

      expect(cat.balanceTreats, 125);
    });

    test('sendTreats happy path sends POST with the 3-field body', () async {
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.toString(), '$_baseUrl/api/transfers');
        expect(request.headers['Content-Type'], contains('application/json'));
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body, {
          'fromCatId': '11111111-1111-1111-1111-111111111111',
          'toCatId': '22222222-2222-2222-2222-222222222222',
          'amountTreats': 10,
        });
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
      final dataSource = MeowPayRemoteDataSource(baseUrl: _baseUrl, client: client);

      final transfer = await dataSource.sendTreats(
        fromCatId: '11111111-1111-1111-1111-111111111111',
        toCatId: '22222222-2222-2222-2222-222222222222',
        amountTreats: 10,
      );

      expect(transfer.id, 'transfer-1');
      expect(transfer.amountTreats, 10);
    });

    test('sendTreats 404 throws MeowPayException(CatNotFoundFailure)', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'NOT_FOUND', 'message': 'Cat not found'}),
          404,
          headers: {'content-type': 'application/json'},
        );
      });
      final dataSource = MeowPayRemoteDataSource(baseUrl: _baseUrl, client: client);

      expect(
        () => dataSource.sendTreats(
          fromCatId: '11111111-1111-1111-1111-111111111111',
          toCatId: '22222222-2222-2222-2222-222222222222',
          amountTreats: 10,
        ),
        throwsA(
          isA<MeowPayException>().having((e) => e.failure, 'failure', isA<CatNotFoundFailure>()),
        ),
      );
    });

    test('sendTreats 409 throws MeowPayException(InsufficientTreatsFailure)', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'INSUFFICIENT_TREATS', 'message': 'Not enough treats'}),
          409,
          headers: {'content-type': 'application/json'},
        );
      });
      final dataSource = MeowPayRemoteDataSource(baseUrl: _baseUrl, client: client);

      expect(
        () => dataSource.sendTreats(
          fromCatId: '11111111-1111-1111-1111-111111111111',
          toCatId: '22222222-2222-2222-2222-222222222222',
          amountTreats: 10,
        ),
        throwsA(
          isA<MeowPayException>()
              .having((e) => e.failure, 'failure', isA<InsufficientTreatsFailure>()),
        ),
      );
    });

    test('sendTreats 400 VALIDATION_ERROR throws MeowPayException(ValidationFailure)', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'VALIDATION_ERROR', 'message': 'Amount must be positive'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });
      final dataSource = MeowPayRemoteDataSource(baseUrl: _baseUrl, client: client);

      expect(
        () => dataSource.sendTreats(
          fromCatId: '11111111-1111-1111-1111-111111111111',
          toCatId: '22222222-2222-2222-2222-222222222222',
          amountTreats: -1,
        ),
        throwsA(
          isA<MeowPayException>().having((e) => e.failure, 'failure', isA<ValidationFailure>()),
        ),
      );
    });

    test('sendTreats 400 INVALID_TRANSFER throws MeowPayException(InvalidTransferFailure)',
        () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({'error': 'INVALID_TRANSFER', 'message': 'Cannot send to self'}),
          400,
          headers: {'content-type': 'application/json'},
        );
      });
      final dataSource = MeowPayRemoteDataSource(baseUrl: _baseUrl, client: client);

      expect(
        () => dataSource.sendTreats(
          fromCatId: '11111111-1111-1111-1111-111111111111',
          toCatId: '11111111-1111-1111-1111-111111111111',
          amountTreats: 10,
        ),
        throwsA(
          isA<MeowPayException>()
              .having((e) => e.failure, 'failure', isA<InvalidTransferFailure>()),
        ),
      );
    });

    test('sendTreats with unparseable error body on 500 throws MeowPayException(UnknownFailure)',
        () async {
      final client = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });
      final dataSource = MeowPayRemoteDataSource(baseUrl: _baseUrl, client: client);

      expect(
        () => dataSource.sendTreats(
          fromCatId: '11111111-1111-1111-1111-111111111111',
          toCatId: '22222222-2222-2222-2222-222222222222',
          amountTreats: 10,
        ),
        throwsA(
          isA<MeowPayException>().having((e) => e.failure, 'failure', isA<UnknownFailure>()),
        ),
      );
    });

    test('sendTreats rethrows a SocketException as MeowPayException(NetworkFailure)', () async {
      final client = MockClient((request) async {
        throw const SocketException('Connection refused');
      });
      final dataSource = MeowPayRemoteDataSource(baseUrl: _baseUrl, client: client);

      expect(
        () => dataSource.sendTreats(
          fromCatId: '11111111-1111-1111-1111-111111111111',
          toCatId: '22222222-2222-2222-2222-222222222222',
          amountTreats: 10,
        ),
        throwsA(
          isA<MeowPayException>().having((e) => e.failure, 'failure', isA<NetworkFailure>()),
        ),
      );
    });
  });
}
