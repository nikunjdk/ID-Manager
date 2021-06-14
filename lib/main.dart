import 'dart:io';

import 'package:flip_card/flip_card.dart';
import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter/services.dart';
import 'package:edge_detection/edge_detection.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:id_manager/id_model.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String? imagePath;
  String? text;
  List<IdModel> idCards = [];
  bool isBusy = false;
  int? type;

  @override
  void initState() {
    super.initState();
  }

  Future<void> getImage() async {
    String? imagePathEdge;
    OkCancelResult? result;
    IdModel newId = new IdModel();
    try {
      imagePathEdge = (await EdgeDetection.detectEdge);
    } on PlatformException {
      print('Failed to get cropped image path.');
    }
    if (!mounted) return;
    setState(() {
      imagePath = imagePathEdge;
      newId.imagePath = imagePath;
      isBusy = true;
    });
    final inputImage = InputImage.fromFilePath(imagePath!);
    final textDetector = GoogleMlKit.vision.textDetector();
    final RecognisedText recognisedText =
        await textDetector.processImage(inputImage);
    print("Detected Text\n${recognisedText.text}");
    text = recognisedText.text;
    if (text!.contains('Permanent Account Number Card')) {
      newId.type = "PAN Card";
    }
    // } else {
    //   result = await showOkAlertDialog(
    //     context: context,
    //     title: "Scan Failed",
    //     message:
    //         "Sorry the app couldn't recognize the scanned ID. Please try again.",
    //     barrierDismissible: false,
    //   );
    // }
    if (newId.type?.compareTo("PAN Card") == 0) {
      for (TextBlock block in recognisedText.blocks) {
        final String text = block.text;
        print(text);
        if (text.compareTo("Permanent Account Number Card") == 0) {
          int i = recognisedText.blocks.indexOf(block);
          newId.id = recognisedText.blocks[i + 1].text;
          print("Added Pan ID: ${newId.id}");
          print(recognisedText.blocks.length);
          if (recognisedText.blocks[i + 2].lines.length > 1) {
            newId.name = recognisedText.blocks[i + 2].lines[1].text;
          } else {
            newId.name = recognisedText.blocks[i + 3].text;
          }
          print("Added PAN Name: ${newId.name}");
        }

        // if (text.endsWith("Name")) {
        //   int i = recognisedText.blocks.indexOf(block);
        //   newId.name = recognisedText.blocks[i + 1].text;
        //   print("Added PAN Name");
        // }
        // for (TextLine line in block.lines) {
        //   // Same getters as TextBlock
        //   print(line.elements.toString());
        //   for (TextElement element in line.elements) {
        //     // Same getters as TextBlock
        //     print(element.text);
        //   }
        // }
      }
      TextEditingController nameC = new TextEditingController();
      nameC.text = newId.name!;
      TextEditingController idC = new TextEditingController();
      idC.text = newId.id!;
      // await showDialog(
      //     context: context,
      //     builder: (context) {
      //       return AlertDialog(
      //         title: Text('${newId.type} detected'),
      //         content: Column(
      //           children: [
      //             TextField(
      //               onChanged: (value) {
      //                 setState(() {
      //                   newId.name = value;
      //                 });
      //               },
      //               controller: nameC,
      //               decoration: InputDecoration(labelText: "Name"),
      //             ),
      //             SizedBox(
      //               height: 10.0,
      //             ),
      //             TextField(
      //               onChanged: (value) {
      //                 setState(() {
      //                   newId.id = value;
      //                 });
      //               },
      //               controller: idC,
      //               decoration: InputDecoration(labelText: "ID"),
      //             ),
      //           ],
      //         ),
      //         actions: <Widget>[
      //           FlatButton(
      //             color: Colors.blue,
      //             textColor: Colors.white,
      //             child: Text('OK'),
      //             onPressed: () {
      //               setState(() {
      //                 Navigator.pop(context);
      //               });
      //             },
      //           ),
      //         ],
      //       );
      //     });
    }
    setState(() {
      if (result == null && newId.name != null) {
        idCards.add(newId);
      }
      isBusy = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
          floatingActionButton: FloatingActionButton(
            onPressed: getImage,
            child: Center(
              child: Icon(Icons.add),
            ),
          ),
          appBar: AppBar(
            title: const Text('ID Manager'),
          ),
          body: isBusy == true
              ? Center(
                  child: CircularProgressIndicator(),
                )
              : idCards.length == 0
                  ? Center(
                      child: Text(
                        "No ID's added",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 40.0),
                      ),
                    )
                  : ListView.builder(
                      itemCount: idCards.length,
                      itemBuilder: (BuildContext context, int index) {
                        IdModel idCard = idCards[index];
                        return Card(
                          child: FlipCard(
                            front: Container(
                              child: Padding(
                                padding: const EdgeInsets.only(
                                    top: 0, left: 0, right: 0),
                                child: Text(
                                  'Type: ${idCard.type}\nName: ${idCard.name}\nid: ${idCard.id}\n',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 10),
                                ),
                              ),
                            ),
                            back: Container(
                              child: imagePath == null
                                  ? Container()
                                  : Image.file(
                                      File(idCard.imagePath!),
                                      fit: BoxFit.contain,
                                    ),
                            ),
                          ),
                        );
                      },
                    )),
    );
  }
}
