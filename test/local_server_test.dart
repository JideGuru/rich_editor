import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:rich_editor/src/services/local_server.dart';

/// flutter_test fakes HTTP; the server needs a real client.
class _RealHttp extends HttpOverrides {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalServer server;
  late int port;

  setUp(() async {
    // In this package's own tests the assets aren't under packages/.
    server = LocalServer(assetDirectory: 'assets/editor/');
    port = await server.start();
  });

  tearDown(() => server.close());

  Future<(int, String?)> get(String path) {
    return HttpOverrides.runWithHttpOverrides(() async {
      final client = HttpClient();
      try {
        final request = await client.get('localhost', port, path);
        final response = await request.close();
        await response.drain<void>();
        return (response.statusCode, response.headers.contentType?.mimeType);
      } finally {
        client.close(force: true);
      }
    }, _RealHttp());
  }

  test('uses a free port and returns it again when already started', () async {
    expect(port, greaterThan(0));
    expect(await server.start(), port);
  });

  test('serves editor assets with their content types', () async {
    expect(await get('/assets/editor/editor.html'), (200, 'text/html'));
    expect(await get('/assets/editor/style.css'), (200, 'text/css'));
    expect(await get('/assets/editor/editor.js'), (200, 'text/javascript'));
  });

  test('serves nothing outside the editor assets', () async {
    expect((await get('/pubspec.yaml')).$1, 404);
    expect((await get('/assets/editor/../../pubspec.yaml')).$1, 404);
    expect((await get('/assets/editor/missing.js')).$1, 404);
  });
}
