import 'dart:io';
import 'dart:async';
import 'package:flutter/services.dart';

class AssetsHttpServer {
  final HttpServer _server;

  static ContentType _getContentTypeForPath(String path) {
    final extension = path.split('.').last;
    final mimeType = MimeTypes.mimeTypes[extension] ?? 'text/plain';
    final contentType = mimeType.split('/');
    return ContentType(contentType[0], contentType[1], charset: 'utf-8');
  }

  static Future<AssetsHttpServer> start(int port, String assetDirectory) async {
    try {
      var server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      print('HTTP Server listening on port $port');

      server.listen((HttpRequest request) async {
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, HEAD, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
        try {
          final String path = request.uri.toFilePath();
          final String assetPath = path == '/' ? 'index.html' : path.substring(1); // Adjust based on your assets structure
          final ByteData data = await rootBundle.load('$assetDirectory/$assetPath');

          request.response.headers.contentType = _getContentTypeForPath(assetPath);
          request.response.add(data.buffer.asUint8List());


          await request.response.close();
        } catch (e) {
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
        }
      });

      return AssetsHttpServer._(server);
    } on SocketException catch (e) {
      print('Failed to start server: $e');
      rethrow;
    }
  }

  AssetsHttpServer._(this._server);

  Future stop() async {
    await _server.close();
    print('HTTP server stopped');
  }

}

class MimeTypes {
  static const Map<String, String> mimeTypes = {
    'html': 'text/html',
    'js': 'application/javascript',
    'css': 'text/css',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'gif': 'image/gif',
    // ... add other file types as needed
  };
}
