import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_postget/layout_desktop.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class AppData with ChangeNotifier {
  // Access appData globaly with:
  // AppData appData = Provider.of<AppData>(context);
  // AppData appData = Provider.of<AppData>(context, listen: false)

  bool loadingGet = false;
  bool loadingPost = false;
  bool loadingFile = false;

  dynamic dataGet;
  dynamic dataPost;
  dynamic dataFile;

  String tempImg = "";
  List<ChatMessage> messages = [];

  // Funció per fer crides tipus 'GET' i agafar la informació a mida que es va rebent

  Future<void> loadHttpPostByChunks(
      String url, String text, String image) async {
    var completer = Completer<void>();
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Agregar datos JSON como parte del formulario
    if (image == "" && text == "") {
      request.fields['data'] = '{"type":"stop"}';
      loadingPost = false;
    } else if (image == "") {
      request.fields['data'] = '{"type":"conversa", "prompt": "$text"}';
    } else {
      request.fields['data'] =
          '{"type":"imatge", "prompt": "$text", "image": "$image"}';
    }

    try {
      var response = await request.send();

      if (loadingPost) dataPost = "";

      // Listen to each chunk of data
      response.stream.transform(utf8.decoder).listen(
        (data) {
          if (loadingPost) {
            print(dataPost);
            // Update dataPost with the latest data
            dataPost += data;

            print(dataPost);
            notifyListeners();
          }
        },
        onDone: () {
          loadingPost = false;
          completer.complete();
        },
        onError: (error) {
          completer.completeError(
              "Error del servidor (appData/loadHttpPostByChunks): $error");
        },
      );
    } catch (e) {
      completer.completeError("Excepció (appData/loadHttpPostByChunks): $e");
    }

    return completer.future;
  }

  // Funció per fer carregar dades d'un arxiu json de la carpeta 'assets'
  Future<dynamic> readJsonAsset(String filePath) async {
    // If development, wait 1 second to simulate a delay
    if (!kReleaseMode) {
      await Future.delayed(const Duration(seconds: 1));
    }

    try {
      var jsonString = await rootBundle.loadString(filePath);
      final jsonData = json.decode(jsonString);
      return jsonData;
    } catch (e) {
      throw Exception("Excepció (appData/readJsonAsset): $e");
    }
  }

  void load(String type, String selectedString, String image) async {
    switch (type) {
      case 'POST':
        loadingPost = true;
        notifyListeners();
        await loadHttpPostByChunks(
            'http://localhost:3000/data', selectedString, image);
        loadingPost = false;
        notifyListeners();
        break;
      case 'FILE':
        loadingFile = true;
        notifyListeners();

        var fileData = await readJsonAsset("assets/data/example.json");

        loadingFile = false;
        dataFile = fileData;
        notifyListeners();
        break;
    }
  }
}
