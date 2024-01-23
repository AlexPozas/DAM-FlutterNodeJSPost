import 'dart:convert';
import 'package:flutter_postget/app_data.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';

import 'package:provider/provider.dart';

class ChatGPTInterface extends StatefulWidget {
  const ChatGPTInterface({super.key, required this.title});

  final String title;

  @override
  _ChatGPTInterfaceState createState() => _ChatGPTInterfaceState();
}

class _ChatGPTInterfaceState extends State<ChatGPTInterface> {
  final List<ChatMessage> _messages = <ChatMessage>[];
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text(widget.title),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: CupertinoColors.systemGrey),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8.0),
                  child: ListView.builder(
                    reverse: true,
                    itemCount: _messages.length,
                    itemBuilder: (BuildContext context, int index) {
                      return _messages[index];
                    },
                  ),
                ),
              ),
            ),
            SizedBox(height: 8.0),
            Row(
              children: <Widget>[
                CupertinoButton(
                  onPressed: () => _handleImagePick(),
                  child: Text('Imagen'),
                ),
                SizedBox(width: 8.0),
                Expanded(
                  child: CupertinoTextField(
                    controller: _textController,
                    placeholder: 'Escribe un mensaje...',
                    padding: EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      border: Border.all(color: CupertinoColors.systemGrey),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                SizedBox(width: 8.0),
                CupertinoButton(
                  onPressed: () => _handleSubmitted(_textController.text),
                  child: Text('Enviar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _handleSubmitted(String text) async {
    _textController.clear();

    AppData appData = Provider.of<AppData>(context, listen: false);

    try {
      String result = await appData.readMessage(text);

      ChatMessage message = ChatMessage(
        text: result,
        isMe: true,
        isImage: false,
      );
      setState(() {
        _messages.insert(0, message);
      });
      // Muestra el resultado en la interfaz de usuario (puedes usar un widget como un AlertDialog o SnackBar)
      // Ejemplo:
    } catch (e) {
      print('Error: $e');
    }
  }

  Future<void> _handleImagePick() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.image,
    );

    if (result != null) {
      File file = File(result.files.single.path!);
      ChatMessage message = ChatMessage(
        text: 'Imagen Adjunta',
        isMe: true,
        isImage: true,
        imageFile: file,
      );
      setState(() {
        _messages.insert(0, message);
      });
    }
  }
}

class ChatMessage extends StatelessWidget {
  ChatMessage({
    required this.text,
    required this.isMe,
    required this.isImage,
    this.imageFile,
  });

  final String text;
  final bool isMe;
  final bool isImage;
  final File? imageFile;

  @override
  Widget build(BuildContext context) {
    if (isImage) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.green,
                borderRadius: BorderRadius.circular(8.0),
              ),
              padding: EdgeInsets.all(12.0),
              child: Image.file(
                imageFile!,
                width: 100.0,
                height: 100.0,
                fit: BoxFit.cover,
              ),
            ),
            SizedBox(width: 8.0),
            Text(
              isMe ? 'You' : 'Chat',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              isMe ? 'You' : 'Chat',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            SizedBox(width: 8.0),
            Flexible(
              child: Container(
                decoration: BoxDecoration(
                  color: isMe ? Colors.blue : Colors.green,
                  borderRadius: BorderRadius.circular(8.0),
                ),
                padding: EdgeInsets.all(12.0),
                child: Text(
                  text,
                  style: TextStyle(color: Colors.white),
                  softWrap: true,
                ),
              ),
            ),
          ],
        ),
      );
    }
  }
}
