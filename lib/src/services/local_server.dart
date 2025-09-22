import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:mime/mime.dart';

/*
 * credit thanks to https://github.com/shah-xad/flutter_tex/blob/master/lib/src/utils/tex_view_server.dart
 */

class LocalServer {
  HttpServer? server;
  final int port;

  LocalServer(this.port);

  ///Closes the server.
  Future<void> close() async {
    if (server != null) {
      await server?.close(force: true);
      server = null;
    }
  }

  ///Starts the server
  Future<void> start(Function(HttpRequest request) request) async {
    if (server != null) {
      throw Exception('Server already started on http://localhost:$port');
    }

    var completer = Completer();
    runZonedGuarded(
      () {
        HttpServer.bind('localhost', port, shared: true).then((server) {
          this.server = server;

          server.listen((HttpRequest httpRequest) async {
            request(httpRequest);
            var body = <int>[];
            var path = httpRequest.requestedUri.path;
            path = (path.startsWith('/')) ? path.substring(1) : path;
            path += (path.endsWith('/')) ? 'index.html' : '';

            try {
              body = (await rootBundle.load(path)).buffer.asUint8List();
            } catch (e) {
              debugPrint('Failed to load asset: ${e.toString()}');
              httpRequest.response.close();
              return;
            }

            var contentType = ['text', 'html'];
            if (!httpRequest.requestedUri.path.endsWith('/') &&
                httpRequest.requestedUri.pathSegments.isNotEmpty) {
              var mimeType = lookupMimeType(httpRequest.requestedUri.path,
                  headerBytes: body);
              if (mimeType != null) {
                contentType = mimeType.split('/');
              }
            }

            httpRequest.response.headers.contentType =
                ContentType(contentType[0], contentType[1], charset: 'utf-8');
            httpRequest.response.add(body);
            httpRequest.response.close();
          });
          completer.complete();
        });
      },
      (e, stackTrace) => debugPrint('LocalServer error: $e $stackTrace'),
    );
    return completer.future;
  }
}

class WebSocketServer {
  HttpServer? server;

  final int port;

  WebSocketServer(this.port);

  ///Closes the server.
  Future<void> close() async {
    if (server != null) {
      await server?.close(force: true);
      server = null;
    }
  }

  ///Starts the server
  Future<void> start() async {
    if (server != null) {
      throw Exception('Server already started on http://localhost:$port');
    }
    var completer = Completer();
    runZonedGuarded(
      () {
        HttpServer.bind('localhost', port, shared: true).then(
            (HttpServer server) {
          debugPrint('WebSocket listening at ws://localhost:$port/');
          this.server = server;
          server.listen((HttpRequest request) {
            WebSocketTransformer.upgrade(request).then((WebSocket ws) {
              ws.listen(
                (data) {
                  debugPrint(
                      'WebSocket data from ${request.connectionInfo?.remoteAddress}: ${data.toString()}');
                  Timer(const Duration(seconds: 1), () {
                    if (ws.readyState == WebSocket.open) {
                      // checking connection state helps to avoid unprecedented errors
                      ws.add("ping");
                    }
                  });
                },
                onDone: () => debugPrint('WebSocket connection closed'),
                onError: (err) =>
                    debugPrint('WebSocket listen error: ${err.toString()}'),
                cancelOnError: true,
              );
              // request.response.close();
            },
                onError: (err) =>
                    debugPrint('WebSocket upgrade error: ${err.toString()}'));
          },
              onError: (err) =>
                  debugPrint('Server listen error: ${err.toString()}'));
          completer.complete();
        },
            onError: (err) =>
                debugPrint('Server bind error: ${err.toString()}'));
      },
      (err, stacktrace) =>
          debugPrint('WebSocketServer error: ${err.toString()}'),
    );

    return completer.future;
  }
}
