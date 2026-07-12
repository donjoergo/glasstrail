// Smoke check for a GlassTrail Supabase backend.
//
// Uses only dart:io/dart:convert so it runs without `flutter pub get` extras.
// Reads its configuration from environment variables (see .env.example):
//
//   SUPABASE_URL, SUPABASE_ANON_KEY                       required
//   GT_SMOKE_USER_A_EMAIL / GT_SMOKE_USER_A_PASSWORD      authenticated checks
//   GT_SMOKE_USER_B_EMAIL / GT_SMOKE_USER_B_PASSWORD      isolation checks
//   GT_SMOKE_ALLOW_WRITES=1                               enable write checks
//   GT_SMOKE_I_KNOW_THIS_IS_PROD=1                        allow writes on prod
//
// Exit codes: 0 all checks passed, 1 at least one check failed,
// 2 configuration/usage error.
//
// Usage: dart run tool/supabase_smoke_check.dart

import 'dart:convert';
import 'dart:io';

const _productionHost = 'lzuxlcfjnekgjukqxoza.supabase.co';
const _mediaBucket = 'user-media';
const _mediaFolders = <String>['profiles', 'custom-drinks', 'entries'];

// 1x1 transparent PNG.
final List<int> _tinyPng = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk'
  'YPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==',
);

int _passed = 0;
int _failed = 0;

void _report(bool ok, String name, [String? detail]) {
  if (ok) {
    _passed += 1;
    stdout.writeln('PASS  $name');
  } else {
    _failed += 1;
    stdout.writeln('FAIL  $name${detail == null ? '' : ' — $detail'}');
  }
}

Never _usage(String message) {
  stderr.writeln('Configuration error: $message');
  stderr.writeln('');
  stderr.writeln('Required environment variables:');
  stderr.writeln('  SUPABASE_URL         e.g. http://127.0.0.1:54321');
  stderr.writeln('  SUPABASE_ANON_KEY    anon/publishable key');
  stderr.writeln('Optional:');
  stderr.writeln('  GT_SMOKE_USER_A_EMAIL / GT_SMOKE_USER_A_PASSWORD');
  stderr.writeln('  GT_SMOKE_USER_B_EMAIL / GT_SMOKE_USER_B_PASSWORD');
  stderr.writeln('  GT_SMOKE_ALLOW_WRITES=1 to enable write checks');
  stderr.writeln('');
  stderr.writeln('See .env.example and docs/backend_setup.md.');
  exit(2);
}

class _Client {
  _Client(this.baseUrl, this.anonKey);

  final Uri baseUrl;
  final String anonKey;
  final HttpClient _http = HttpClient();

  Future<_Response> send(
    String method,
    String path, {
    Map<String, String> query = const {},
    String? bearer,
    Object? jsonBody,
    List<int>? rawBody,
    Map<String, String> headers = const {},
  }) async {
    final uri = baseUrl.replace(
      path: path,
      queryParameters: query.isEmpty ? null : query,
    );
    final request = await _http.openUrl(method, uri);
    request.headers.set('apikey', anonKey);
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${bearer ?? anonKey}',
    );
    headers.forEach(request.headers.set);
    if (jsonBody != null) {
      request.headers.contentType = ContentType.json;
      request.add(utf8.encode(jsonEncode(jsonBody)));
    } else if (rawBody != null) {
      request.add(rawBody);
    }
    final response = await request.close();
    final body = await response.transform(utf8.decoder).join();
    return _Response(response.statusCode, body);
  }

  void close() => _http.close(force: true);
}

class _Response {
  const _Response(this.status, this.body);

  final int status;
  final String body;

  bool get ok => status >= 200 && status < 300;

  dynamic get json {
    try {
      return jsonDecode(body);
    } on FormatException {
      return null;
    }
  }
}

class _Session {
  const _Session(this.label, this.accessToken, this.userId);

  final String label;
  final String accessToken;
  final String userId;
}

Future<_Session?> _signIn(
  _Client client,
  String label,
  String email,
  String password,
) async {
  final response = await client.send(
    'POST',
    '/auth/v1/token',
    query: {'grant_type': 'password'},
    jsonBody: {'email': email, 'password': password},
  );
  if (!response.ok) {
    _report(false, 'sign in $label', 'HTTP ${response.status}');
    return null;
  }
  final data = response.json as Map<String, dynamic>;
  final token = data['access_token'] as String?;
  final userId = (data['user'] as Map<String, dynamic>?)?['id'] as String?;
  if (token == null || userId == null) {
    _report(false, 'sign in $label', 'missing token or user id');
    return null;
  }
  _report(true, 'sign in $label');
  return _Session(label, token, userId);
}

Future<void> _checkOwnReads(_Client client, _Session session) async {
  final catalog = await client.send(
    'GET',
    '/rest/v1/global_drinks',
    query: {'select': 'id', 'limit': '1'},
    bearer: session.accessToken,
  );
  _report(
    catalog.ok && (catalog.json as List).isNotEmpty,
    'global catalog readable (${session.label})',
    'HTTP ${catalog.status}',
  );

  for (final table in ['profiles', 'user_settings']) {
    final column = table == 'profiles' ? 'id' : 'user_id';
    final response = await client.send(
      'GET',
      '/rest/v1/$table',
      query: {'select': column, column: 'eq.${session.userId}'},
      bearer: session.accessToken,
    );
    _report(
      response.ok && (response.json as List).length == 1,
      'own $table row readable (${session.label})',
      'HTTP ${response.status}: ${response.body}',
    );
  }

  for (final table in ['user_drinks', 'drink_entries']) {
    final response = await client.send(
      'GET',
      '/rest/v1/$table',
      query: {'select': 'id', 'user_id': 'eq.${session.userId}'},
      bearer: session.accessToken,
    );
    _report(
      response.ok,
      'own $table readable (${session.label})',
      'HTTP ${response.status}: ${response.body}',
    );
  }
}

Future<void> _checkIsolation(
  _Client client,
  _Session owner,
  _Session other,
) async {
  final read = await client.send(
    'GET',
    '/rest/v1/profiles',
    query: {'select': 'id', 'id': 'eq.${owner.userId}'},
    bearer: other.accessToken,
  );
  _report(
    read.ok && (read.json as List).isEmpty,
    '${other.label} cannot read ${owner.label} profile',
    'HTTP ${read.status}: ${read.body}',
  );

  final update = await client.send(
    'PATCH',
    '/rest/v1/user_settings',
    query: {'user_id': 'eq.${owner.userId}'},
    bearer: other.accessToken,
    jsonBody: {'theme_preference': 'dark'},
    headers: {'Prefer': 'return=representation'},
  );
  final updatedRows = update.ok ? (update.json as List? ?? []) : const [];
  _report(
    updatedRows.isEmpty,
    '${other.label} cannot update ${owner.label} settings',
    'HTTP ${update.status}: ${update.body}',
  );
}

Future<void> _checkWrites(
  _Client client,
  _Session userA,
  _Session? userB,
) async {
  final stamp = DateTime.now().millisecondsSinceEpoch;

  final categories = await client.send(
    'GET',
    '/rest/v1/drink_categories',
    query: {'select': 'slug', 'limit': '1'},
    bearer: userA.accessToken,
  );
  final categoryList = categories.ok ? categories.json as List : const [];
  if (categoryList.isEmpty) {
    _report(
      false,
      'load a drink category for write checks',
      'HTTP ${categories.status}',
    );
    return;
  }
  final categorySlug =
      (categoryList.first as Map<String, dynamic>)['slug'] as String;

  String? drinkId;
  final createDrink = await client.send(
    'POST',
    '/rest/v1/user_drinks',
    bearer: userA.accessToken,
    jsonBody: {
      'user_id': userA.userId,
      'name': 'gt-smoke-drink-$stamp',
      'category_slug': categorySlug,
      'volume_ml': 100,
    },
    headers: {'Prefer': 'return=representation'},
  );
  if (createDrink.ok) {
    drinkId =
        ((createDrink.json as List).first as Map<String, dynamic>)['id']
            as String;
  }
  _report(
    createDrink.ok,
    'create custom drink (${userA.label})',
    'HTTP ${createDrink.status}: ${createDrink.body}',
  );

  String? entryId;
  if (drinkId != null) {
    final createEntry = await client.send(
      'POST',
      '/rest/v1/drink_entries',
      bearer: userA.accessToken,
      jsonBody: {
        'user_id': userA.userId,
        'source_type': 'custom',
        'source_drink_id': drinkId,
        'drink_name': 'gt-smoke-drink-$stamp',
        'category_slug': categorySlug,
        'volume_ml': 100,
        'comment': 'gt-smoke-check',
      },
      headers: {'Prefer': 'return=representation'},
    );
    if (createEntry.ok) {
      entryId =
          ((createEntry.json as List).first as Map<String, dynamic>)['id']
              as String;
    }
    _report(
      createEntry.ok,
      'create drink entry (${userA.label})',
      'HTTP ${createEntry.status}: ${createEntry.body}',
    );

    if (userB != null) {
      final crossDelete = await client.send(
        'DELETE',
        '/rest/v1/drink_entries',
        query: {'id': 'eq.$entryId'},
        bearer: userB.accessToken,
        headers: {'Prefer': 'return=representation'},
      );
      final deletedRows = crossDelete.ok
          ? (crossDelete.json as List? ?? [])
          : const [];
      _report(
        deletedRows.isEmpty,
        '${userB.label} cannot delete ${userA.label} entry',
        'HTTP ${crossDelete.status}: ${crossDelete.body}',
      );
    }
  }

  final mediaPaths = <String>[];
  for (final folder in _mediaFolders) {
    final path = '${userA.userId}/$folder/gt-smoke-$stamp.png';
    final upload = await client.send(
      'POST',
      '/storage/v1/object/$_mediaBucket/$path',
      bearer: userA.accessToken,
      rawBody: _tinyPng,
      headers: {'Content-Type': 'image/png'},
    );
    if (upload.ok) {
      mediaPaths.add(path);
    }
    _report(
      upload.ok,
      'upload media to $folder/ (${userA.label})',
      'HTTP ${upload.status}: ${upload.body}',
    );
  }

  if (userB != null && mediaPaths.isNotEmpty) {
    final crossRead = await client.send(
      'GET',
      '/storage/v1/object/$_mediaBucket/${mediaPaths.first}',
      bearer: userB.accessToken,
    );
    _report(
      !crossRead.ok,
      '${userB.label} cannot read ${userA.label} media',
      'HTTP ${crossRead.status}',
    );
    final crossDelete = await client.send(
      'DELETE',
      '/storage/v1/object/$_mediaBucket/${mediaPaths.first}',
      bearer: userB.accessToken,
    );
    _report(
      !crossDelete.ok,
      '${userB.label} cannot delete ${userA.label} media',
      'HTTP ${crossDelete.status}',
    );
  }

  // Cleanup as user A; report failures so leftovers are visible.
  if (entryId != null) {
    final response = await client.send(
      'DELETE',
      '/rest/v1/drink_entries',
      query: {'id': 'eq.$entryId'},
      bearer: userA.accessToken,
    );
    _report(response.ok, 'cleanup drink entry', 'HTTP ${response.status}');
  }
  if (drinkId != null) {
    final response = await client.send(
      'DELETE',
      '/rest/v1/user_drinks',
      query: {'id': 'eq.$drinkId'},
      bearer: userA.accessToken,
    );
    _report(response.ok, 'cleanup custom drink', 'HTTP ${response.status}');
  }
  for (final path in mediaPaths) {
    final response = await client.send(
      'DELETE',
      '/storage/v1/object/$_mediaBucket/$path',
      bearer: userA.accessToken,
    );
    _report(response.ok, 'cleanup media $path', 'HTTP ${response.status}');
  }
}

Future<void> main() async {
  final env = Platform.environment;
  final url = env['SUPABASE_URL']?.trim() ?? '';
  final anonKey = env['SUPABASE_ANON_KEY']?.trim() ?? '';
  if (url.isEmpty || anonKey.isEmpty) {
    _usage('SUPABASE_URL and SUPABASE_ANON_KEY must be set.');
  }
  final baseUrl = Uri.tryParse(url);
  if (baseUrl == null || !baseUrl.hasScheme) {
    _usage('SUPABASE_URL is not a valid URL: $url');
  }

  final allowWrites = env['GT_SMOKE_ALLOW_WRITES'] == '1';
  final isProduction = baseUrl.host == _productionHost;
  if (allowWrites &&
      isProduction &&
      env['GT_SMOKE_I_KNOW_THIS_IS_PROD'] != '1') {
    _usage(
      'Refusing write checks against production ($_productionHost). '
      'Set GT_SMOKE_I_KNOW_THIS_IS_PROD=1 to override, and only with '
      'dedicated test users.',
    );
  }

  final client = _Client(baseUrl, anonKey);
  stdout.writeln('Target: $baseUrl (writes ${allowWrites ? 'ON' : 'off'})');

  try {
    final health = await client.send('GET', '/auth/v1/health');
    _report(health.ok, 'auth service reachable', 'HTTP ${health.status}');
    if (!health.ok) {
      exit(1);
    }

    _Session? userA;
    _Session? userB;
    final emailA = env['GT_SMOKE_USER_A_EMAIL'];
    final passwordA = env['GT_SMOKE_USER_A_PASSWORD'];
    if (emailA != null && passwordA != null) {
      userA = await _signIn(client, 'user A', emailA, passwordA);
    } else {
      stdout.writeln('SKIP  authenticated checks (GT_SMOKE_USER_A_* not set)');
    }
    final emailB = env['GT_SMOKE_USER_B_EMAIL'];
    final passwordB = env['GT_SMOKE_USER_B_PASSWORD'];
    if (emailB != null && passwordB != null) {
      userB = await _signIn(client, 'user B', emailB, passwordB);
    } else {
      stdout.writeln('SKIP  isolation checks (GT_SMOKE_USER_B_* not set)');
    }

    if (userA != null) {
      await _checkOwnReads(client, userA);
    }
    if (userA != null && userB != null) {
      await _checkIsolation(client, userA, userB);
    }
    if (userA != null && allowWrites) {
      await _checkWrites(client, userA, userB);
    } else if (userA != null) {
      stdout.writeln('SKIP  write checks (GT_SMOKE_ALLOW_WRITES != 1)');
    }
  } finally {
    client.close();
  }

  stdout.writeln('');
  stdout.writeln('$_passed passed, $_failed failed');
  exit(_failed == 0 ? 0 : 1);
}
