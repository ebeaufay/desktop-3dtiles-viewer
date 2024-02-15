import 'dart:io';
import 'package:desktop_3dtiles_viewer/AssetsHttpServer.dart';
import 'package:desktop_3dtiles_viewer/LocalHttpServer.dart';
import 'package:flutter/material.dart';
import 'package:webview_windows/webview_windows.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Desktop WebView',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final _webviewController = WebviewController();
  bool isWebViewReady = false; // New state variable

  String _filePath = '';

  AssetsHttpServer? webPageServer;
  HttpServer? tilesetServer;

  @override
  void initState() {
    super.initState();
    initWebView();
  }

  void initWebView() async {
    await _webviewController.initialize();
    try {
      webPageServer = await AssetsHttpServer.start(8989, 'assets');
      await _webviewController.loadUrl('http://localhost:8989/index.html');
      setState(() {
        isWebViewReady = true; // Set to true after WebView is ready
      });
    } on SocketException catch (e) {
      print('Could not start server: ${e.message}');
    } catch (e) {
      print('An unexpected error occurred: $e');
    }
  }

  @override
  void dispose() {
    _webviewController.dispose();
    webPageServer?.stop();
    tilesetServer?.close();

    super.dispose();
  }


  Future<void> _pickFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ["json"]
    );

    if (result != null) {
      String filePath = result.files.single.path!; // Get the selected file's path
      File file = File(filePath);

      String directoryPath = file.parent.path; // Get the directory containing the file

      // If a server is already running, stop it before starting a new one
      await tilesetServer?.close();

      // Start a new server with the directory of the selected file
      try {
        tilesetServer = await LocalHttpServer.start(8990, directoryPath);
        print('Server started at $directoryPath');
        await _webviewController.reload();
      } on SocketException catch (e) {
        print('Could not start server: ${e.message}');
      } catch (e) {
        print('An unexpected error occurred: $e');
      }
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Directly use WebView without Expanded
          isWebViewReady ? Webview(_webviewController) : Center(child: CircularProgressIndicator()),
          // Custom invisible button with icon
          Positioned(
            top: 20, // Adjust these values according to your layout
            left: 20,
            child: InkWell(
              onTap: _pickFile,
              child: Icon(Icons.folder_open, size: 64.0, color: Colors.black), // Customize icon size and color
            ),
          ),
        ],
      ),
    );
  }
}
