import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Future<void> loadHttpPostByChunks(
      String url, String text, String image) async {
    var completer = Completer<void>();
    var request = http.MultipartRequest('POST', Uri.parse(url));

    // Agregar datos JSON como parte del formulario
    if (image == "" && text == "") {
      request.fields['data'] = '{"type":"stop"}';
      loadingPost = false;
    } else if (image == "") {
      loadingPost = true;
      request.fields['data'] = '{"type":"conversa", "prompt": "$text"}';
    } else {
      loadingPost = true;
      request.fields['data'] =
          '{"type":"imatge", "prompt": "$text", "image": "$image"}';
    }

    try {
      var response = await request.send();
      print("inicio try");

      if (loadingPost) dataPost = "";

      // Listen to each chunk of data
      response.stream.transform(utf8.decoder).listen(
        (data) {
          print(loadingPost);
          if (loadingPost) {
            print(dataPost);
            // Update dataPost with the latest data
            dataPost += data;
            print("Despues data");
            print(dataPost);
            notifyListeners();
          }
        },
        onDone: () {
          print("onDone");
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

  void readMessage(String text) async {
    try {
      String url = 'http://localhost:3000/data';
      String image = '';
      print(loadHttpPostByChunks(url, text, image));
    } catch (e) {
      print('Error: $e');
    }
  }
}
