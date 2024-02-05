import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_cupertino_desktop_kit/cdk.dart';
import 'package:provider/provider.dart';
import 'app_data.dart';

import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';

class LayoutChat extends StatefulWidget {
  const LayoutChat({super.key});

  @override
  _LayoutChatState createState() => _LayoutChatState();
}

TextEditingController _controller = TextEditingController();
ScrollController _scrollController = ScrollController();

class _LayoutChatState extends State<LayoutChat> {
  List<String> listPost = [];

  @override
  Widget build(BuildContext context) {
    AppData appData = Provider.of<AppData>(context);
    String stringPost = "";
    if (appData.loadingPost && appData.dataPost == "") {
      stringPost = "Loading ...";
    } else if (appData.dataPost != null) {
      stringPost = appData.dataPost.toString();
      appData.messages[appData.messages.length - 1].messageContent = stringPost;

      SchedulerBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
    }

    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Row(
          children: [
            SizedBox(width: 40),
            Image.asset(
              'assets/images/images.png', // Reemplaza con la ruta de tu imagen
              width: 30, // Ajusta el ancho según tus necesidades
              height: 30, // Ajusta la altura según tus necesidades
            ),
            SizedBox(width: 20),
            Text(
              'Chat IETI',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            // Ajusta el espacio entre el texto e la imagen
          ],
        ),
        backgroundColor: Color.fromARGB(255, 65, 74, 82),
      ),
      child: Scaffold(
        backgroundColor: Color.fromARGB(255, 57, 63, 69),
        body: Center(
          child: Container(
            width: MediaQuery.of(context).size.width / 1.5,
            height: MediaQuery.of(context).size.height,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Stack(
                    children: <Widget>[
                      SizedBox(
                        width: MediaQuery.of(context).size.width / 1.5,
                        height: MediaQuery.of(context).size.height -
                            120, // Ajusta la altura según tus necesidades
                        child: ListView.builder(
                          controller: _scrollController,
                          itemCount: appData.messages.length,
                          itemBuilder: (context, index) {
                            return Center(
                              child: Container(
                                alignment: Alignment.centerLeft,
                                padding:
                                    const EdgeInsets.only(top: 10, bottom: 10),
                                child: Column(
                                  children: [
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        appData.messages[index].type == 'send'
                                            ? "You"
                                            : "Chat ",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    appData.messages[index].image != ""
                                        ? Image.memory(
                                            base64Decode(
                                              appData.messages[index].image
                                                  .split(',')
                                                  .last,
                                            ),
                                            width: 400,
                                            height: 400,
                                            fit: BoxFit.cover,
                                          )
                                        : SizedBox(),
                                    const SizedBox(
                                      height: 8,
                                    ),
                                    Container(
                                      alignment: Alignment.centerLeft,
                                      child: Text(
                                        appData.messages[index].type == 'send'
                                            ? "${appData.messages[index].messageContent}"
                                            : appData.loadingPost &&
                                                    appData.messages[index - 1]
                                                            .image !=
                                                        "" &&
                                                    !appData
                                                        .messages[index].oldMssg
                                                ? "Loading ..."
                                                : "${appData.messages[index].messageContent}",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: Colors.white,
                                        ),
                                        softWrap: true,
                                        overflow: TextOverflow.visible,
                                      ),
                                      padding: const EdgeInsets.all(
                                          10), // Ajusta el espacio interno del contenedor
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(
                                            10), // Ajusta la esquina redondeada
                                        color: appData.messages[index].type ==
                                                'send'
                                            ? Colors.blue
                                            : Colors.green,
                                      ),
                                    ),
                                    SizedBox(height: 30),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.only(
                              left: 10, bottom: 10, top: 10),
                          height: 80,
                          width: 700,
                          child: Row(
                            children: <Widget>[
                              const SizedBox(
                                width: 15,
                              ),
                              Expanded(
                                child: CDKFieldText(
                                  controller: _controller,
                                  textSize: 18,
                                  isRounded: true,
                                  placeholder: "Message Chat...",
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              CDKButton(
                                onPressed: () {
                                  if (!appData.loadingPost) {
                                    setState(() {
                                      _controller.text != "" ||
                                              appData.tempImg != ""
                                          ? appData.messages.add(
                                              ChatMessage(
                                                messageContent:
                                                    _controller.text,
                                                type: "send",
                                                image: appData.tempImg,
                                                oldMssg: true,
                                              ),
                                            )
                                          : null;
                                      appData.messages.add(
                                        ChatMessage(
                                          messageContent: "",
                                          type: "receive",
                                          image: "",
                                          oldMssg: false,
                                        ),
                                      );
                                      if (appData.messages.length > 2) {
                                        appData
                                            .messages[
                                                appData.messages.length - 3]
                                            .oldMssg = true;
                                      }
                                    });
                                    appData.load('POST', _controller.text,
                                        appData.tempImg);
                                    _controller.text = "";
                                    appData.tempImg = "";
                                  } else {
                                    appData.load('POST', "", "");
                                  }
                                },
                                child: appData.loadingPost
                                    ? Text(
                                        "Stop",
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 16),
                                      )
                                    : Text(
                                        "Send",
                                        style: TextStyle(
                                            color: Colors.black, fontSize: 16),
                                      ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              CDKButton(
                                onPressed: () async {
                                  FilePickerResult? result =
                                      await FilePicker.platform.pickFiles(
                                    type: FileType.custom,
                                    allowedExtensions: ['png', 'jpg'],
                                    withData: true,
                                  );

                                  if (result != null) {
                                    PlatformFile file = result.files.first;
                                    Uint8List? fileBytes = file.bytes;
                                    if (fileBytes != null) {
                                      String base64String =
                                          base64Encode(fileBytes);
                                      setState(() {
                                        appData.tempImg = base64String;
                                      });
                                    }
                                  }
                                },
                                child: Text(
                                  "Image",
                                  style: TextStyle(
                                      color: Colors.black, fontSize: 16),
                                ),
                              ),
                              const SizedBox(
                                width: 8,
                              ),
                              appData.tempImg != ""
                                  ? Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color:
                                            Color.fromARGB(255, 245, 245, 220),
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Center(
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(
                                              8.0), // Aquí ajustas el radio del borde
                                          child: Image.memory(
                                            base64Decode(appData.tempImg
                                                .split(',')
                                                .last),
                                            width: 35,
                                            height: 35,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container()
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 500),
      curve: Curves.ease,
    );
  }
}

class ChatMessage {
  String messageContent;
  String type;
  String image;
  bool oldMssg;
  ChatMessage({
    required this.messageContent,
    required this.type,
    required this.image,
    required this.oldMssg,
  });
}
