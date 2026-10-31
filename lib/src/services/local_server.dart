import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/*
 * credit thanks to https://github.com/shah-xad/flutter_tex/blob/master/lib/src/utils/tex_view_server.dart
 */

/// Serves the editor's web assets to the WebView over http://localhost.
///
/// Only files under [assetDirectory] are served, on a port picked by the
/// system, so several editors can run at once.
class LocalServer {
  LocalServer({this.assetDirectory = 'packages/rich_editor/assets/editor/'});

  final String assetDirectory;
  HttpServer? _server;
  Future<int>? _starting;

  static const _contentTypes = {
    'html': 'text/html',
    'css': 'text/css',
    'js': 'text/javascript',
    'png': 'image/png',
    'svg': 'image/svg+xml',
  };

  /// The port being listened on, once [start] completed.
  int? get port => _server?.port;

  ///Starts the server and returns its port
  Future<int> start() {
    return _starting ??= () async {
      final server = await HttpServer.bind('localhost', 0);
      _server = server;
      server.listen(
        _handleRequest,
        onError: (Object e, StackTrace s) =>
            debugPrint('LocalServer error: $e'),
      );
      return server.port;
    }();
  }

  ///Closes the server.
  Future<void> close() async {
    final server = _server;
    _server = null;
    _starting = null;
    await server?.close(force: true);
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    final segments = request.uri.pathSegments;
    final path = segments.join('/');

    if (request.method != 'GET' ||
        segments.contains('..') ||
        !path.startsWith(assetDirectory)) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      return;
    }

    try {
      final data = await rootBundle.load(path);
      final extension = path.substring(path.lastIndexOf('.') + 1);
      response.headers.contentType = ContentType.parse(
          '${_contentTypes[extension] ?? 'application/octet-stream'}; charset=utf-8');
      response
          .add(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } catch (e) {
      debugPrint('Failed to load asset $path: $e');
      response.statusCode = HttpStatus.notFound;
    }
    await response.close();
  }
}
