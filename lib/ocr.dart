import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_bluetooth/main.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:http/http.dart' as http;
import 'bluetoothsettings.dart' as bt;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import 'package:tts_azure/tts_azure.dart';

class ocr with ChangeNotifier {}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String Binary = '';
  TTSAzure _ttsazure;
  TextEditingController _controller;
  String _lang = 'es-ES';
  String _shortName = 'en-GB-HazelRUS';
  Map<String, String> headers = {
    'Ocp-Apim-Subscription-Key': '7e358799b1fd4643aee3ee0e9283938d',
    'Content-Type': 'multipart/form-data'
  };

  var url =
      Uri.parse('https://brailled.cognitiveservices.azure.com/vision/v3.1/ocr');
  var req = http.MultipartRequest(
      'POST',
      Uri.parse(
          'https://brailled.cognitiveservices.azure.com/vision/v3.1/ocr'));

  Future<Uint8List> payload;
  File _image;

  Future getImagefromcamera() async {
    var image = await ImagePicker.pickImage(source: ImageSource.camera);
    Future<Image> payload;
    await uploadImage(image.path,
        'https://brailled.cognitiveservices.azure.com/vision/v3.1/ocr');

    print('object');

    setState(() {
      _image = image;
    });
  }

  Future getImagefromGallery() async {
    var image = await ImagePicker.pickImage(source: ImageSource.gallery);
    var payload = await image.readAsBytes();
    await uploadImage(image.path,
        'https://brailled.cognitiveservices.azure.com/vision/v3.1/ocr');

    print('object');

    setState(() {
      _image = image;
    });
  }

  @override
  void initState() {
    _ttsazure = TTSAzure("17f4cbe881614a68aacf9dc966ec408c", "eastus");
    _controller = TextEditingController();
    _controller.text = "Test";
    _ttsazure.play("tts", _lang, _shortName);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Flutter Image Picker Example"),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Center(
            child: Text(
              "Image Picker Example in Flutter",
              style: TextStyle(fontSize: 20),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              width: MediaQuery.of(context).size.width,
              height: 200.0,
              child: Center(
                child: _image == null
                    ? Text("No Image is picked")
                    : Image.file(_image),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              FloatingActionButton(
                onPressed: getImagefromcamera,
                tooltip: "pickImage",
                child: Icon(Icons.add_a_photo),
              ),
              FloatingActionButton(
                onPressed: getImagefromGallery,
                tooltip: "Pick Image",
                child: Icon(Icons.camera_alt),
              )
            ],
          )
        ],
      ),
    );
  }

  List brailles = [
    '⠀',
    '⠮',
    '⠐',
    '⠼',
    '⠫',
    '⠩',
    '⠯',
    '⠄',
    '⠷',
    '⠾',
    '⠡',
    '⠬',
    '⠠',
    '⠤',
    '⠨',
    '⠌',
    '⠴',
    '⠂',
    '⠆',
    '⠒',
    '⠲',
    '⠢',
    '⠖',
    '⠶',
    '⠦',
    '⠔',
    '⠱',
    '⠰',
    '⠣',
    '⠿',
    '⠜',
    '⠹',
    '⠈',
    '⠁',
    '⠃',
    '⠉',
    '⠙',
    '⠑',
    '⠋',
    '⠛',
    '⠓',
    '⠊',
    '⠚',
    '⠅',
    '⠇',
    '⠍',
    '⠝',
    '⠕',
    '⠏',
    '⠟',
    '⠗',
    '⠎',
    '⠞',
    '⠥',
    '⠧',
    '⠺',
    '⠭',
    '⠽',
    '⠵',
    '⠪',
    '⠳',
    '⠻',
    '⠘',
    '⠸'
  ];
  List asciicodes = [
    ' ',
    '!',
    '"',
    '#',
    '\$',
    '%',
    '&',
    '',
    '(',
    ')',
    '*',
    '+',
    ',',
    '-',
    '.',
    '/',
    '0',
    '1',
    '2',
    '3',
    '4',
    '5',
    '6',
    '7',
    '8',
    '9',
    ':',
    ';',
    '<',
    '=',
    '>',
    '?',
    '@',
    'a',
    'b',
    'c',
    'd',
    'e',
    'f',
    'g',
    'h',
    'i',
    'j',
    'k',
    'l',
    'm',
    'n',
    'o',
    'p',
    'q',
    'r',
    's',
    't',
    'u',
    'v',
    'w',
    'x',
    'y',
    'z',
    '[',
    '\\',
    ']',
    '^',
    '_'
  ];
  List dotcodes = [
    '',
    '2346',
    '5',
    '3456',
    '1246',
    '146',
    '12346',
    '3',
    '12356',
    '23456',
    '16',
    '346',
    '6',
    '36',
    '46',
    '34',
    '356',
    '2',
    '23',
    '25',
    '256',
    '26',
    '235',
    '2356',
    '236',
    '35',
    '156',
    '56',
    '126',
    '123456',
    '345',
    '1456',
    '4',
    '1',
    '12',
    '14',
    '145',
    '15',
    '124',
    '1245',
    '125',
    '24',
    '245',
    '13',
    '123',
    '134',
    '1345',
    '135',
    '1234',
    '12345',
    '1235',
    '234',
    '2345',
    '136',
    '1236',
    '2456',
    '1346',
    '13456',
    '1356',
    '246',
    '1256',
    '12456',
    '45',
    '456'
  ];

  uploadImage(String filename, String url) async {
    var request = http.MultipartRequest('POST', Uri.parse(url));
    request.headers.addAll(headers);

    request.files.add(http.MultipartFile('picture',
        File(filename).readAsBytes().asStream(), File(filename).lengthSync(),
        filename: filename.split("/").last));
    var res = await request.send();
    final respStr = await res.stream.bytesToString();
    var myMap = jsonDecode(respStr);
    List JASON;

    Map<String, dynamic> sublines;
    var variab;
    Map<String, dynamic> userrr;

    //myMap = Map.from(JASON);
    Map<String, dynamic> user = jsonDecode(respStr);

    var userr = jsonDecode(respStr)['regions'];

    int len = userr.length;

    for (int i = 0; i < len; i++) {
      //print(userr[i].toString());

      //JASON[i] = userr[i].toString();
    }
    int j = 0;
    String tex = '';
    String myString = myMap.toString();
    RegExp exp = RegExp(r"text:(.+?(?=}))");
    Iterable<Match> texx = exp.allMatches(myString);
    print("allMatches : " + exp.allMatches(myString).toString());
    for (int i = 0; i < myString.length; i++) {
      if (myString[i] == 't') {
        if (myString[i + 1] == 'e') {
          if (myString[i + 2] == 'x') {
            if (myString[i + 3] == 't') {
              if (myString[i + 4] == ':') {
                j = i + 5;
                while (myString[j] != '}') {
                  tex = tex + myString[j];
                  j++;
                }
              }
            }
          }
        }
      }
    }
    void _play(String tts) {
      _ttsazure.play("tts", _lang, _shortName);
    }

    List WordsToSend = [];
    String wordstosend = '';
    for (Match m in texx) {
      String match = m[0];
      int idx = match.indexOf(':') + 1;

      WordsToSend.add(match.substring(idx).toString());
      wordstosend += (match.substring(idx).toString());
      _ttsazure.play(wordstosend, _lang, _shortName);

      //print(match.substring(idx));
    }
    print(wordstosend);

    void BinaryBraille(int indexofcodes) {
      String Sequence = dotcodes[indexofcodes].toString();
      Binary = '';

      if (String == '') {
        //print(Binary);
      } else {
        try {
          for (int i = 0; i < 8; i++) {
            if (Sequence.contains(i.toString())) {
              int IndexOfBinary = Sequence.indexOf(i.toString());
              Binary += '1';
            } else {
              Binary += '0';
            }
          }
          //print(Binary);
        } catch (e) {
          //print("Braille To Binary Error = $e");
        }
      }
    }

    void SendToDevice() {
      for (int i = 0; i < WordsToSend.length; i++) {
        String sendWord = WordsToSend[i].toString();
        //print(WordsToSend[i].toString());
        for (int j = 0; j < sendWord.length; j++) {
          try {
            int indexofcodes = asciicodes.indexOf(sendWord[j].toString());
            //print(brailles[indexofcodes].toString());
            //print(dotcodes[indexofcodes].toString());
            //BinaryBraille(indexofcodes);
          } catch (e) {
            print(e.toString());
          }

          //print(sendWord[j].toString());
          //

        }
      }
    }

    void alphbetToByte(String wordtobyte) {}

    SendToDevice();
    //print(WordsToSend);

    var match = texx.length;
    // print('$match');
    //print(tex);
    //print('Howdy, ${user['regions'][1]['lines']}!');

    //print('Howdy, ${userr['lines']}!');
    //print(c);
    //JASON = (user['regions']['lines']);
    //print('We sent the verification link to ${user['email']}.');
  }
}
