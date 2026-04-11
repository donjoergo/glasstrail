import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glasstrail/src/models.dart';
import 'package:glasstrail/src/repository/supabase_app_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('SupabaseAppRepository.saveCustomDrink', () {
    late _MockSupabaseServer server;
    late SupabaseClient client;
    late SupabaseAppRepository repository;

    setUp(() async {
      server = await _MockSupabaseServer.start();
      client = SupabaseClient(
        server.baseUrl,
        'test-key',
        accessToken: () async => 'test-token',
        headers: const <String, String>{'X-Client-Info': 'glasstrail-test'},
      );
      repository = SupabaseAppRepository(client);
    });

    tearDown(() async {
      await client.dispose();
      await server.close();
    });

    test(
      'deletes the previous owned image when clearing a custom drink photo',
      () async {
        const userId = 'user-123';
        const drinkId = 'drink-123';
        const previousImagePath = 'user-123/custom-drinks/old-photo.png';

        server.userDrinksById[drinkId] = <String, dynamic>{
          'id': drinkId,
          'user_id': userId,
          'name': 'Office Brew',
          'category_slug': DrinkCategory.nonAlcoholic.storageValue,
          'volume_ml': 300,
          'image_path': previousImagePath,
        };

        final updated = await repository.saveCustomDrink(
          userId: userId,
          drinkId: drinkId,
          name: 'Office Brew',
          category: DrinkCategory.nonAlcoholic,
          volumeMl: 300,
          imagePath: null,
        );

        expect(updated.imagePath, isNull);
        expect(server.lastUpsertBody?['image_path'], isNull);
        expect(server.deletedPrefixes, <String>[previousImagePath]);
      },
    );

    test(
      'does not delete the stored image when the photo stays unchanged',
      () async {
        const userId = 'user-123';
        const drinkId = 'drink-123';
        const previousImagePath = 'user-123/custom-drinks/old-photo.png';

        server.userDrinksById[drinkId] = <String, dynamic>{
          'id': drinkId,
          'user_id': userId,
          'name': 'Office Brew',
          'category_slug': DrinkCategory.nonAlcoholic.storageValue,
          'volume_ml': 300,
          'image_path': previousImagePath,
        };

        final updated = await repository.saveCustomDrink(
          userId: userId,
          drinkId: drinkId,
          name: 'Office Brew',
          category: DrinkCategory.nonAlcoholic,
          volumeMl: 300,
          imagePath: previousImagePath,
        );

        expect(updated.imagePath, previousImagePath);
        expect(server.deletedPrefixes, isEmpty);
      },
    );
  });
}

class _MockSupabaseServer {
  _MockSupabaseServer._(this._server) {
    _server.listen((request) async {
      try {
        await _handle(request);
      } catch (error) {
        request.response.statusCode = HttpStatus.internalServerError;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode(<String, String>{'error': error.toString()}),
        );
        await request.response.close();
      }
    });
  }

  final HttpServer _server;
  final Map<String, Map<String, dynamic>> userDrinksById =
      <String, Map<String, dynamic>>{};
  final List<String> deletedPrefixes = <String>[];
  Map<String, dynamic>? lastUpsertBody;

  String get baseUrl => 'http://${_server.address.address}:${_server.port}';

  static Future<_MockSupabaseServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    return _MockSupabaseServer._(server);
  }

  Future<void> close() => _server.close(force: true);

  Future<void> _handle(HttpRequest request) async {
    final path = request.uri.path;

    if (request.method == 'GET' && path == '/rest/v1/user_drinks') {
      final drinkId = _stripEqPrefix(request.uri.queryParameters['id']);
      final userId = _stripEqPrefix(request.uri.queryParameters['user_id']);
      final row = userDrinksById[drinkId];
      final responseBody = row != null && row['user_id'] == userId
          ? <Map<String, dynamic>>[
              <String, dynamic>{'image_path': row['image_path']},
            ]
          : <Map<String, dynamic>>[];
      await _writeJson(request.response, responseBody);
      return;
    }

    if (request.method == 'POST' && path == '/rest/v1/user_drinks') {
      final body = await _readJsonMap(request);
      lastUpsertBody = body;
      userDrinksById[body['id'] as String] = Map<String, dynamic>.from(body);
      await _writeJson(request.response, body);
      return;
    }

    if (request.method == 'DELETE' && path == '/storage/v1/object/user-media') {
      final body = await _readJsonMap(request);
      final prefixes = List<String>.from(body['prefixes'] as List<dynamic>);
      deletedPrefixes.addAll(prefixes);
      await _writeJson(
        request.response,
        prefixes
            .map(
              (prefix) => <String, dynamic>{
                'name': prefix.split('/').last,
                'bucket_id': 'user-media',
              },
            )
            .toList(growable: false),
      );
      return;
    }

    request.response.statusCode = HttpStatus.notFound;
    await request.response.close();
  }

  Future<Map<String, dynamic>> _readJsonMap(HttpRequest request) async {
    final body = await utf8.decoder.bind(request).join();
    return Map<String, dynamic>.from(jsonDecode(body) as Map);
  }

  Future<void> _writeJson(HttpResponse response, Object body) async {
    response.headers.contentType = ContentType.json;
    response.write(jsonEncode(body));
    await response.close();
  }

  String? _stripEqPrefix(String? value) {
    if (value == null) {
      return null;
    }
    return value.startsWith('eq.') ? value.substring(3) : value;
  }
}
