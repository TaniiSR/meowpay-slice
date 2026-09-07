import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../domain/entities/meowpay_failure.dart';
import '../models/cat_model.dart';
import '../models/treat_transfer_model.dart';

class MeowPayRemoteDataSource {
  final String baseUrl;
  final http.Client client;

  MeowPayRemoteDataSource({required this.baseUrl, http.Client? client})
      : client = client ?? http.Client();

  static const _jsonHeaders = {'Content-Type': 'application/json'};

  Future<List<CatModel>> getCats() async {
    final response = await _get('$baseUrl/api/cats');
    final decoded = _decodeOrThrow(response) as List<dynamic>;
    return decoded
        .map((json) => CatModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<TreatTransferModel>> getTransfers({String? catId}) async {
    final uri = Uri.parse('$baseUrl/api/transfers').replace(
      queryParameters: catId != null ? {'catId': catId} : null,
    );
    final response = await _getUri(uri);
    final decoded = _decodeOrThrow(response) as List<dynamic>;
    return decoded
        .map((json) => TreatTransferModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<CatModel> topUp({required String catId, required int amountTreats}) async {
    final response = await _post(
      '$baseUrl/api/cats/$catId/topup',
      {'amountTreats': amountTreats},
    );
    final decoded = _decodeOrThrow(response) as Map<String, dynamic>;
    return CatModel.fromJson(decoded);
  }

  Future<TreatTransferModel> sendTreats({
    required String fromCatId,
    required String toCatId,
    required int amountTreats,
  }) async {
    final response = await _post('$baseUrl/api/transfers', {
      'fromCatId': fromCatId,
      'toCatId': toCatId,
      'amountTreats': amountTreats,
    });
    final decoded = _decodeOrThrow(response) as Map<String, dynamic>;
    return TreatTransferModel.fromJson(decoded);
  }

  Future<http.Response> _get(String url) => _getUri(Uri.parse(url));

  Future<http.Response> _getUri(Uri uri) async {
    try {
      return await client.get(uri, headers: _jsonHeaders);
    } on SocketException catch (e) {
      throw MeowPayException(NetworkFailure(e.toString()));
    } on http.ClientException catch (e) {
      throw MeowPayException(NetworkFailure(e.toString()));
    } on IOException catch (e) {
      throw MeowPayException(NetworkFailure(e.toString()));
    }
  }

  Future<http.Response> _post(String url, Map<String, dynamic> body) async {
    try {
      return await client.post(
        Uri.parse(url),
        headers: _jsonHeaders,
        body: jsonEncode(body),
      );
    } on SocketException catch (e) {
      throw MeowPayException(NetworkFailure(e.toString()));
    } on http.ClientException catch (e) {
      throw MeowPayException(NetworkFailure(e.toString()));
    } on IOException catch (e) {
      throw MeowPayException(NetworkFailure(e.toString()));
    }
  }

  dynamic _decodeOrThrow(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }
    Map<String, dynamic>? body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {}
    final message = body?['message'] as String? ?? 'Request failed with status ${response.statusCode}';
    final errorCode = body?['error'] as String?;
    switch (response.statusCode) {
      case 404:
        throw MeowPayException(CatNotFoundFailure(message));
      case 409:
        throw MeowPayException(InsufficientTreatsFailure(message));
      case 400:
        if (errorCode == 'VALIDATION_ERROR') {
          throw MeowPayException(ValidationFailure(message));
        }
        throw MeowPayException(InvalidTransferFailure(message));
      default:
        throw MeowPayException(UnknownFailure(message));
    }
  }
}
