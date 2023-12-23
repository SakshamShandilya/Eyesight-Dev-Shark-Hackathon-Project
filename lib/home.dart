import 'package:flutter/material.dart';
import 'package:flutter_bluetooth/openTextFile.dart';
import 'dart:async';
import 'dart:convert';
import 'package:toggle_switch/toggle_switch.dart';

import 'main.dart';
import 'package:flutter/services.dart';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:http/http.dart' as http;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:json_annotation/json_annotation.dart';
import 'dart:convert';
import 'package:tts_azure/tts_azure.dart';
import 'SaveTextFile.dart';
import 'package:path_provider/path_provider.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'SaveTextFile.dart';
import 'selectAndOpen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'recorder.dart';

class Home extends StatefulWidget {
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final TextEditingController _controller = TextEditingController();
  File jsonFile;
  Directory dir;
  String Binary = '';
  String filename = 'myJSONFile.json';
  bool fileExists = false;
  Map<String, String> fileContent;
  TTSAzure _ttsazure;
  String _lang = 'es-ES';
  String _shortName = 'en-GB-HazelRUS';
  int OCRindex = 0;
  int Textindex = 0;
  bool isBrailleTextVisible = true;
  int Speechindex = 0;
  bool isSpeechIndex = false;
  int speechToBSTIndex = 0;
  double TextScaleFactor = 1;
  bool isVisible = false;
  String textFileName = "";
  Map<String, String> mapOpenTextFile = {};
  Map<String, String> mapTypedTextFile = {};
  String textValueName = '';
  List<String> fileNameList = [];
  bool hasPermission;
  bool isSttTextAvailable = false;

  String Braille = '';
  String BrailleDisplay = '';
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

  Future getAudioFile() async {
    FilePickerResult result = await FilePicker.platform.pickFiles();
    if (result != null) {
      File filee = File(result.files.single.path);
      var file = filee.readAsBytes();
      final bytes = filee.readAsBytesSync();

      var headers = {
        'Ocp-Apim-Subscription-Key': '602081f946c94fe785e530194cef6b48',
        'Content-Type': 'audio/wav'
      };

      var response;
      Map<String, dynamic> responseBody;
      var recognizedVoiceText;

      try {
        response = await http.post(
          "https://eastus.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=en-IN",
          body: bytes,
          headers: headers,
        );

        // The response body is a string that needs to be decoded as a json in order to get the extract the text.
        responseBody = jsonDecode(response.body);
        recognizedVoiceText = responseBody["DisplayText"];
        textFileName = responseBody["DisplayText"].toString();
        isSttTextAvailable = true;
        setState(() {});
      } catch (e) {
        isSttTextAvailable = false;
        print('Error: ${e.toString()}');
        recognizedVoiceText = "Something went wrong";
      }

      //return recognizedVoiceText;
      print(recognizedVoiceText.toString());
    } else {
      isSttTextAvailable = false;
      // User canceled the picker
    }
  }

  void getStt(File file) async {
    final bytes = file.readAsBytesSync();

    var headers = {
      'Ocp-Apim-Subscription-Key': '602081f946c94fe785e530194cef6b48',
      'Content-Type': 'audio/wav'
    };

    var response;
    Map<String, dynamic> responseBody;
    var recognizedVoiceText;

    try {
      response = await http.post(
        "https://eastus.stt.speech.microsoft.com/speech/recognition/conversation/cognitiveservices/v1?language=en-IN",
        body: bytes,
        headers: headers,
      );

      // The response body is a string that needs to be decoded as a json in order to get the extract the text.
      responseBody = jsonDecode(response.body);
      recognizedVoiceText = responseBody["DisplayText"];
      print(responseBody["DisplayText"].toString());
      textFileName = responseBody["DisplayText"].toString();
      isSttTextAvailable = true;
      setState(() {});
    } catch (e) {
      isSttTextAvailable = false;
      print('Error: ${e.toString()}');
      recognizedVoiceText = "Something went wrong";
    }
  }

  void initializeHive() async {
    await Hive.initFlutter();
  }

  double _currentSliderValue = 20;

  // Initializing the Bluetooth connection state to be unknown
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  // Initializing a global key, as it would help us in showing a SnackBar later
  final GlobalKey<ScaffoldState> _scaffoldKey = new GlobalKey<ScaffoldState>();
  // Get the instance of the Bluetooth
  FlutterBluetoothSerial _bluetooth = FlutterBluetoothSerial.instance;
  // Track the Bluetooth connection with the remote device
  BluetoothConnection connection;

  int _deviceState;

  bool isDisconnecting = false;

  Map<String, Color> colors = {
    'onBorderColor': Colors.green,
    'offBorderColor': Colors.red,
    'neutralBorderColor': Colors.transparent,
    'onTextColor': Colors.green[700],
    'offTextColor': Colors.red[700],
    'neutralTextColor': Colors.blue,
  };

  // To track whether the device is still connected to Bluetooth
  bool get isConnected => connection != null && connection.isConnected;

  // Define some variables, which will be required later
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice _device;
  bool _connected = false;
  bool _isButtonUnavailable = false;
  Box box;

  void putData() {
    try {
      box.put(textFileName, Braille);
    } catch (e) {
      print(e.toString());
    }

    textFileName = '';
    print("file added to datbase");
    getAll();
  }

  void putMapData() {
    print("Putting typed Text Map data");
    try {
      box.put(textFileName, mapTypedTextFile[textFileName].toString());
      textFileName = mapTypedTextFile[textFileName].toString();
    } catch (e) {
      print(e.toString());
    }

    print("Putting typed Text Map data");
    print(box.toMap());

    setState(() {});
  }

  void getAll() {
    print("Getting all Data from Database");
    print(box.toMap());
  }

  Future openBox() async {
    dir = await getApplicationSupportDirectory();
    Hive.init(dir.path);
    box = await Hive.openBox('testbox');
  }

  recordAudioFile() async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => record()));
    getStt(result);
    //print(result.toString());
    //textFileName = result;
    //putData();
  }

  @override
  Future<void> initState() {
    super.initState();

    //initializeHive();
    openBox();

    _ttsazure = TTSAzure("17f4cbe881614a68aacf9dc966ec408c", "eastus");

    _controller.text = "Test";
    _ttsazure.play("tts", _lang, _shortName);

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    _deviceState = 0; // neutral

    // If the bluetooth of the device is not enabled,
    // then request permission to turn on bluetooth
    // as the app starts up
    enableBluetooth();

    // Listen for further state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
        if (_bluetoothState == BluetoothState.STATE_OFF) {
          _isButtonUnavailable = true;
        }
        getPairedDevices();
      });
    });
  }

  @override
  void dispose() {
    // Avoid memory leak and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  // Request Bluetooth permission from the user
  Future<void> enableBluetooth() async {
    // Retrieving the current Bluetooth state
    _bluetoothState = await FlutterBluetoothSerial.instance.state;

    // If the bluetooth is off, then turn it on first
    // and then retrieve the devices that are paired.
    if (_bluetoothState == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
      await getPairedDevices();
      return true;
    } else {
      await getPairedDevices();
    }
    return false;
  }

  // For retrieving and storing the paired devices
  // in a list.
  Future<void> getPairedDevices() async {
    List<BluetoothDevice> devices = [];

    // To get the list of paired devices
    try {
      devices = await _bluetooth.getBondedDevices();
    } on PlatformException {
      print("Error");
    }

    // It is an error to call [setState] unless [mounted] is true.
    if (!mounted) {
      return;
    }

    // Store the [devices] list in the [_devicesList] for accessing
    // the list outside this class
    setState(() {
      _devicesList = devices;
    });
  }

  NavigateToNameFile(BuildContext context) async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => NameAndSave()));
    print(result.toString());
    textFileName = result;
    putData();
  }

  openTextFile(BuildContext context) async {
    final map = await box.toMap();
    map.forEach((key, value) {
      fileNameList.add(key.toString());
    });
    final result = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SelectAndOpen(
                  listOFFileName: fileNameList,
                )));
    print(result.toString());
    try {
      textFileName = map.values.elementAt(result);
    } catch (e) {
      print(e.toString());
    }

    print(textFileName);
    fileNameList = [];

    setState(() {});
  }

  typeAndSave(BuildContext context) async {
    final result = await Navigator.push(
        context, MaterialPageRoute(builder: (context) => OpenFile()));
    print(result.toString());
    mapTypedTextFile = result;
    try {
      mapTypedTextFile.forEach((key, value) {
        textFileName = key.toString();
      });
    } catch (e) {
      print(e.toString());
    }

    putMapData();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      initialIndex: 0,
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Brailled'),
          centerTitle: true,
          backgroundColor: Colors.black,
          actions: <Widget>[
            FlatButton.icon(
              icon: Icon(
                Icons.refresh,
                color: Colors.white,
              ),
              label: Text(
                "Refresh",
                style: TextStyle(
                  color: Colors.white,
                ),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              splashColor: Colors.deepPurple,
              onPressed: () async {
                // So, that when new devices are paired
                // while the app is running, user can refresh
                // the paired devices list.
                await getPairedDevices().then((_) {
                  display('Device list refreshed');
                });
              },
            ),
          ],
          bottom: TabBar(
            tabs: <Widget>[
              Tab(
                icon: Icon(Icons.camera),
              ),
              Tab(
                icon: Icon(Icons.text_fields),
              ),
              Tab(
                  icon: Icon(
                Icons.mic,
              ))
            ],
          ),
        ),
        body: TabBarView(
          children: <Widget>[
            new Container(
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  Visibility(
                    visible: _isButtonUnavailable &&
                        _bluetoothState == BluetoothState.STATE_ON,
                    child: LinearProgressIndicator(
                      backgroundColor: Colors.yellow,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Bluetooth Settings and OCR",
                        style: TextStyle(fontSize: 24, color: Colors.teal),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Enable Bluetooth',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Switch(
                          value: _bluetoothState.isEnabled,
                          onChanged: (bool value) {
                            future() async {
                              if (value) {
                                await FlutterBluetoothSerial.instance
                                    .requestEnable();
                              } else {
                                await FlutterBluetoothSerial.instance
                                    .requestDisable();
                              }

                              await getPairedDevices();
                              _isButtonUnavailable = false;

                              if (_connected) {
                                _disconnect();
                              }
                            }

                            future().then((_) {
                              setState(() {});
                            });
                          },
                        )
                      ],
                    ),
                  ),
                  Stack(
                    children: <Widget>[
                      Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(
                                  'Device:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                DropdownButton(
                                  elevation: 25,
                                  items: _getDeviceItems(),
                                  onChanged: (value) =>
                                      setState(() => _device = value),
                                  value:
                                      _devicesList.isNotEmpty ? _device : null,
                                ),
                                RaisedButton(
                                  elevation: 25,
                                  onPressed: _isButtonUnavailable
                                      ? null
                                      : _connected
                                          ? _disconnect
                                          : _connect,
                                  child: Text(
                                      _connected ? 'Disconnect' : 'Connect'),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(20),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  SizedBox(height: 15),
                                  RaisedButton(
                                    elevation: 25,
                                    child: Text("Bluetooth Settings"),
                                    onPressed: () {
                                      FlutterBluetoothSerial.instance
                                          .openSettings();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: ToggleSwitch(
                              initialLabelIndex: OCRindex,
                              labels: ['Braille', 'Text', 'Speech'],
                              onToggle: (index) {
                                OCRindex = index;
                                print(index.toString());
                                setState(() {});
                              },
                            ),
                          ),
                          Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Card(
                                child: Text(
                                  Braille + BrailleDisplay,
                                  textScaleFactor: TextScaleFactor,
                                ),
                                elevation: 10,
                              )),
                          Visibility(
                            visible: isVisible && OCRindex == 0,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: RaisedButton(
                                elevation: 25,
                                child: Text('Send to Braille Device'),
                                onPressed: () {
                                  OCRSender();
                                },
                              ),
                            ),
                          ),
                          Visibility(
                            visible: isVisible && OCRindex == 1,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: RaisedButton(
                                elevation: 25,
                                child: Text('Save Text'),
                                onPressed: () {
                                  OCRSender();
                                },
                              ),
                            ),
                          ),
                          Visibility(
                            visible: isVisible && OCRindex == 2,
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: RaisedButton(
                                elevation: 25,
                                child: Text('Convert to Speech'),
                                onPressed: () {
                                  OCRSender();
                                },
                              ),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Center(
                                child: Text(
                                  "Select the conversion mode",
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
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
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            new Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.09,
                  child: Padding(
                    padding: EdgeInsets.all(6.0),
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        "Text to Braille/Speech",
                        style: TextStyle(fontSize: 30, color: Colors.teal),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RaisedButton(
                          splashColor: Colors.teal,
                          elevation: 20,
                          child: Text("Open Text File"),
                          onPressed: () {
                            openTextFile(context);
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: RaisedButton(
                          splashColor: Colors.teal,
                          elevation: 25,
                          child: Text("Type the Text"),
                          onPressed: () {
                            typeAndSave(context);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Card(
                      child: Text(
                        textFileName,
                        textScaleFactor: 1.5,
                      ),
                      elevation: 10,
                    )),
                Visibility(
                  visible: isBrailleTextVisible,
                  child: Padding(
                      padding: const EdgeInsets.all(3.0),
                      child: Card(
                        child: Text(
                          Braille + BrailleDisplay,
                          textScaleFactor: 3,
                        ),
                        elevation: 10,
                      )),
                ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ToggleSwitch(
                      initialLabelIndex: Textindex,
                      labels: ['Braille', 'Speech'],
                      onToggle: (index) {
                        Textindex = index;
                        if (Textindex == 0) {
                          isBrailleTextVisible = true;
                        } else {
                          isBrailleTextVisible = false;
                        }
                        print(index.toString());
                        setState(() {});
                      },
                    ),
                  ),
                ),
                Flexible(
                  child: Visibility(
                    visible: isBrailleTextVisible,
                    child: RaisedButton(
                      elevation: 25,
                      child: Text("Send to Braille Display"),
                      onPressed: () {
                        textSender();
                      },
                    ),
                  ),
                ),
                Flexible(
                  child: Visibility(
                    visible: !isBrailleTextVisible,
                    child: RaisedButton(
                      elevation: 25,
                      child: Text("To Speech"),
                      onPressed: () {
                        textSender();
                      },
                    ),
                  ),
                )
              ],
            ),
            SizedBox(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height * 0.09,
              child: new Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Padding(
                        padding: const EdgeInsets.only(top: 10),
                        child: Text(
                          "Speech to Braille/Text",
                          style: TextStyle(fontSize: 30, color: Colors.teal),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 30.0,
                        child: Text(
                          textFileName,
                          textScaleFactor: 1.5,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                      child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ToggleSwitch(
                      initialLabelIndex: Speechindex,
                      labels: ['Select', 'Record'],
                      onToggle: (index) {
                        Speechindex = index;
                        if (Speechindex == 0) {
                          isSpeechIndex = false;
                        } else {
                          isSpeechIndex = true;
                        }
                        setState(() {});
                        print(index.toString());
                      },
                    ),
                  )),
                  Visibility(
                    visible: !isSpeechIndex,
                    child: Flexible(
                      child: RaisedButton(
                        elevation: 25,
                        child: Text("Select Audio File"),
                        onPressed: () {
                          getAudioFile();
                        },
                      ),
                    ),
                  ),
                  Visibility(
                    visible: isSpeechIndex,
                    child: Flexible(
                      child: RaisedButton(
                        elevation: 25,
                        child: Text("Record Audio File"),
                        onPressed: () {
                          recordAudioFile();
                        },
                      ),
                    ),
                  ),
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        elevation: 10.0,
                        child: Text(
                          Braille + BrailleDisplay,
                          textScaleFactor: 3.0,
                        ),
                      ),
                    ),
                  ),
                  Flexible(
                    child: Visibility(
                      visible: isSttTextAvailable,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Flexible(
                              child: ToggleSwitch(
                                initialLabelIndex: speechToBSTIndex,
                                labels: ['Braille', 'Speech', 'Text'],
                                onToggle: (index) {
                                  Speechindex = index;
                                  speechToBSTIndex = index;
                                  setState(() {});
                                  print(index.toString());
                                },
                              ),
                            ),
                            Visibility(
                              visible: speechToBSTIndex == 0,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: RaisedButton(
                                  elevation: 25,
                                  child: Text("Send to Braille"),
                                  onPressed: () {
                                    sTTSender();
                                  },
                                ),
                              ),
                            ),
                            Visibility(
                              visible: speechToBSTIndex == 1,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: RaisedButton(
                                  elevation: 25,
                                  child: Text("Convert to Speech"),
                                  onPressed: () {
                                    sTTSender();
                                  },
                                ),
                              ),
                            ),
                            Visibility(
                              visible: speechToBSTIndex == 2,
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: RaisedButton(
                                  elevation: 25,
                                  child: Text("Save Text File"),
                                  onPressed: () {
                                    NavigateToNameFile(context);
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
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

  String OCRtoSpeech = '';
  List WordsToSend = [];

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

    for (Match m in texx) {
      String match = m[0];
      int idx = match.indexOf(':') + 1;
      OCRtoSpeech += match.substring(idx).toString();
      Braille = OCRtoSpeech;

      WordsToSend.add(match.substring(idx).toString());

      //print(match.substring(idx));
    }

    void alphbetToByte(String wordtobyte) {}

    //print(WordsToSend);

    var match = texx.length;
    // print('$match');
    //print(tex);
    //print('Howdy, ${user['regions'][1]['lines']}!');

    //print('Howdy, ${userr['lines']}!');
    //print(c);
    //JASON = (user['regions']['lines']);
    //print('We sent the verification link to ${user['email']}.');
    isVisible = true;
    setState(() {});
  }

  void OCRSender() async {
    Future<void> BinaryBraille(int indexofcodes) async {
      String Sequence = dotcodes[indexofcodes].toString();
      Binary = '';

      if (String == '') {
        print(Binary);
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
          print(Binary);
          Braille = (brailles[indexofcodes].toString().toLowerCase());
          BrailleDisplay = asciicodes[indexofcodes].toString().toLowerCase();
          await _sendBinary(Binary);
        } catch (e) {
          print("Braille To Binary Error = $e");
        }
        setState(() {});
      }
    }

    Future<void> SendToDevice() async {
      if (OCRindex == 0) {
        for (int i = 0; i < WordsToSend.length; i++) {
          String sendWord = WordsToSend[i].toString();
          print(WordsToSend[i].toString());
          for (int j = 0; j < sendWord.length; j++) {
            try {
              TextScaleFactor = 3;
              int indexofcodes =
                  asciicodes.indexOf(sendWord[j].toString().toLowerCase());

              print(brailles[indexofcodes].toString().toLowerCase());
              print(dotcodes[indexofcodes].toString().toLowerCase());

              //sleep(Duration(milliseconds: 1000));

              await BinaryBraille(indexofcodes);
            } catch (e) {
              print(e.toString());
            }
            setState(() {});

            //print(sendWord[j].toString());
            //

          }
        }
      }
      if (OCRindex == 1) {
        TextScaleFactor = 1;
        Braille = OCRtoSpeech;
        NavigateToNameFile(context);

        setState(() {});
      }
      if (OCRindex == 2) {
        TextScaleFactor = 1;
        _ttsazure.play(OCRtoSpeech, _lang, _shortName);
        Braille = OCRtoSpeech;
        setState(() {});
      }
    }

    SendToDevice();
  }

  void textSender() async {
    Future<void> BinaryBraille(int indexofcodes) async {
      String Sequence = dotcodes[indexofcodes].toString();
      Binary = '';

      if (String == '') {
        print(Binary);
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
          print(Binary);

          await _sendBinary(Binary);
          Braille = (brailles[indexofcodes].toString().toLowerCase());
          BrailleDisplay = asciicodes[indexofcodes].toString().toLowerCase();
        } catch (e) {
          print("Braille To Binary Error = $e");
        }
        setState(() {});
      }
    }

    Future<void> SendToDevice(String sendTextContent) async {
      if (Textindex == 0) {
        for (int i = 0; i < sendTextContent.length; i++) {
          String sendWord = sendTextContent[i].toString();
          print(sendTextContent[i].toString());
          for (int j = 0; j < sendWord.length; j++) {
            try {
              int indexofcodes =
                  asciicodes.indexOf(sendWord[j].toString().toLowerCase());

              print(brailles[indexofcodes].toString().toLowerCase());
              print(dotcodes[indexofcodes].toString().toLowerCase());

              //sleep(Duration(milliseconds: 1000));

              await BinaryBraille(indexofcodes);
            } catch (e) {
              print(e.toString());
            }
            setState(() {});

            //print(sendWord[j].toString());
            //

          }
        }
      }

      if (Textindex == 1) {
        _ttsazure.play(sendTextContent, _lang, _shortName);
        Braille = sendTextContent;
        setState(() {});
      }
    }

    SendToDevice(textFileName);
  }

  sTTSender() {
    Future<void> BinaryBraille(int indexofcodes) async {
      String Sequence = dotcodes[indexofcodes].toString();
      Binary = '';

      if (String == '') {
        print(Binary);
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
          print(Binary);
          await _sendBinary(Binary);
          Braille = (brailles[indexofcodes].toString().toLowerCase());
          BrailleDisplay = asciicodes[indexofcodes].toString().toLowerCase();
        } catch (e) {
          print("Braille To Binary Error = $e");
        }
        setState(() {});
      }
    }

    Future<void> SendToDevice(String sendTextContent) async {
      if (speechToBSTIndex == 0) {
        for (int i = 0; i < sendTextContent.length; i++) {
          String sendWord = sendTextContent[i].toString();
          print(sendTextContent[i].toString());
          for (int j = 0; j < sendWord.length; j++) {
            try {
              int indexofcodes =
                  asciicodes.indexOf(sendWord[j].toString().toLowerCase());

              print(brailles[indexofcodes].toString().toLowerCase());
              print(dotcodes[indexofcodes].toString().toLowerCase());

              //sleep(Duration(milliseconds: 1000));

              await BinaryBraille(indexofcodes);
              setState(() {});
            } catch (e) {
              print(e.toString());
            }
            setState(() {});

            //print(sendWord[j].toString());
            //

          }
        }
      }

      if (speechToBSTIndex == 1) {
        _ttsazure.play(sendTextContent, _lang, _shortName);
        Braille = sendTextContent;
        setState(() {});
      }
      if (speechToBSTIndex == 2) {
        _ttsazure.play(sendTextContent, _lang, _shortName);
        Braille = sendTextContent;
        setState(() {});
      }
    }

    SendToDevice(textFileName);
  }

  // Create the List of devices to be shown in Dropdown Menu
  List<DropdownMenuItem<BluetoothDevice>> _getDeviceItems() {
    List<DropdownMenuItem<BluetoothDevice>> items = [];
    if (_devicesList.isEmpty) {
      items.add(DropdownMenuItem(
        child: Text('NONE'),
      ));
    } else {
      _devicesList.forEach((device) {
        items.add(DropdownMenuItem(
          child: Text(device.name),
          value: device,
        ));
      });
    }
    return items;
  }

  // Method to connect to bluetooth
  void _connect() async {
    setState(() {
      _isButtonUnavailable = true;
    });
    if (_device == null) {
      display('No device selected');
    } else {
      if (!isConnected) {
        await BluetoothConnection.toAddress(_device.address)
            .then((_connection) {
          print('Connected to the device');
          connection = _connection;
          setState(() {
            _connected = true;
          });

          connection.input.listen(null).onDone(() {
            if (isDisconnecting) {
              print('Disconnecting locally!');
            } else {
              print('Disconnected remotely!');
            }
            if (this.mounted) {
              setState(() {});
            }
          });
        }).catchError((error) {
          print('Cannot connect, exception occurred');
          print(error);
        });
        display('Device connected');

        setState(() => _isButtonUnavailable = false);
      }
    }
  }

  // Method to disconnect bluetooth
  void _disconnect() async {
    setState(() {
      _isButtonUnavailable = true;
      _deviceState = 0;
    });

    await connection.close();
    display('Device disconnected');
    if (!connection.isConnected) {
      setState(() {
        _connected = false;
        _isButtonUnavailable = false;
      });
    }
  }

  // Method to send message,
  // for turning the Bluetooth device on

  void _sendOnMessageToBluetoothSlider(double m) async {
    String a = m.toString();
    connection.output.add(utf8.encode(a + "\r\n"));
    await connection.output.allSent;
    //display('Device Turned On');
    setState(() {
      _deviceState = 1; // device on
    });
  }

  Future<void> _sendBinary(String m) async {
    connection.output.add(utf8.encode(m + "\r\n"));
    await connection.output.allSent;
    display('Sent Binary Data');
    await Future.delayed(Duration(milliseconds: 1000));
    setState(() {});
  }

  // Method to show a Snackbar,
  // taking message as the text
  Future display(
    String message, {
    Duration duration: const Duration(seconds: 3),
  }) async {
    await new Future.delayed(new Duration(milliseconds: 100));
  }
}
