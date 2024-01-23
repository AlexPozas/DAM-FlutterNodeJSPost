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
  List<ChatMessage> _messages = <ChatMessage>[];
  dynamic dataGet;
  dynamic dataPost;
  dynamic dataFile;

  // Funció per fer crides tipus 'GET' i agafar la informació a mida que es va rebent
  Future<void> loadHttpGetByChunks(String url) async {
    var httpClient = HttpClient();
    var completer = Completer<void>();

    try {
      var request = await httpClient.getUrl(Uri.parse(url));
      var response = await request.close();

      dataGet = "";

      // Listen to each chunk of data
      response.transform(utf8.decoder).listen(
        (data) {
          // Aquí rep cada un dels troços de dades que envia el servidor amb 'res.write'
          dataGet += data;
          notifyListeners();
        },
        onDone: () {
          completer.complete();
        },
        onError: (error) {
          completer.completeError(
              "Error del servidor (appData/loadHttpGetByChunks): $error");
        },
      );
    } catch (e) {
      completer.completeError("Excepció (appData/loadHttpGetByChunks): $e");
    }

    return completer.future;
  }

  // Funció per fer crides tipus 'POST' amb un arxiu adjunt,
  // i agafar la informació a mida que es va rebent
  Future<String> loadHttpPostByChunks(
      String url, String text, String image) async {
    var completer = Completer<String>();
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
      String dataPost = "";

      // Listen to each chunk of data
      await for (String data in response.stream.transform(utf8.decoder)) {
        dataPost += data;

        if (loadingPost) {
          notifyListeners(); // Notifica a los escuchadores cada vez que se actualiza dataPost
        }
      }

      loadingPost = false;
      completer
          .complete(dataPost); // Retorna los datos al completar la solicitud
    } catch (e) {
      loadingPost = false;
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

  // Carregar dades segons el tipus que es demana
  void load(String type, {File? selectedFile}) async {
    switch (type) {
      case 'GET':
        loadingGet = true;
        notifyListeners();
        await loadHttpGetByChunks(
            'http://localhost:3000/llistat?cerca=motos&color=vermell');
        loadingGet = false;
        notifyListeners();
        break;
      case 'POST':
        loadingPost = true;
        notifyListeners();
        //await loadHttpPostByChunks('http://localhost:3000/data', );
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

  Future<String> readMessage(String text) async {
    try {
      String url = 'http://localhost:3000/data';
      String image = '';
      return loadHttpPostByChunks(url, text, image);
    } catch (e) {
      print('Error: $e');
      throw e; // Puedes manejar el error según tus necesidades
    }
  }
}
