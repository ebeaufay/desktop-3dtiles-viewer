import 'dart:io';
import 'dart:async';

class LocalHttpServer {

  static Future<HttpServer> start(int port, String directoryPath) async {
    try {
      var server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
      print('HTTP Server listening on port $port');

      server.listen((HttpRequest request) async {
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.add('Access-Control-Allow-Methods', 'GET, POST, HEAD, OPTIONS');
        request.response.headers.add('Access-Control-Allow-Headers', 'Origin, X-Requested-With, Content-Type, Accept');
        final String path = request.uri.toFilePath();
        final String filePath = path == '/' ? '/index.html' : path;
        final File file = File('$directoryPath$filePath');

        if (await file.exists()) {
          try {
            request.response.headers.contentType = ContentType.html;
            await request.response.addStream(file.openRead());
          } catch (e) {
            print('Error serving file: $e');
            request.response.statusCode = HttpStatus.internalServerError;
          }
        } else {
          request.response.statusCode = HttpStatus.notFound;
        }
        await request.response.close();
      });

      return server;
    } on SocketException catch (e) {
      print('Failed to start server: $e');
      throw e;
    }
  }
}
