import 'dart:io';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_audio_recorder/flutter_audio_recorder.dart';
import 'package:path_provider/path_provider.dart';

class record extends StatefulWidget {
  @override
  _recordState createState() => _recordState();
}

class _recordState extends State<record> {
  bool isRecord = false;
  Directory audioDir;
  var recorder;
  void getPermissions() async {
    bool hasPermission = await FlutterAudioRecorder.hasPermissions;
  }

  void startRecording() async {
    DateTime now = DateTime.now();
    String formattedDate = DateFormat('yyyy-MM-dd – kk:mm').format(now);
    audioDir = await getApplicationSupportDirectory();
    recorder = FlutterAudioRecorder(audioDir.path + '/' + formattedDate,
        audioFormat: AudioFormat.WAV,
        sampleRate: 22000); // sampleRate is 16000 by default
    await recorder.initialized;

    await recorder.start();
    var recording = await recorder.current(channel: 0);
  }

  void stopRecording() async {
    var result = await recorder.stop();
    File file = File(result.path);
    //print(file.path.toString());
    Navigator.pop(context, file);
  }

  @override
  void initState() {
    getPermissions();
    // TODO: implement initState
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Record Audio"),
        centerTitle: true,
      ),
      body: Container(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Visibility(
                  visible: !isRecord,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Flexible(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: RaisedButton(
                          elevation: 30.0,
                          child: Text(
                            "Record",
                            textScaleFactor: 3,
                          ),
                          onPressed: () {
                            isRecord = true;
                            startRecording();
                            setState(() {});
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Visibility(
                  visible: isRecord,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Flexible(
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        height: MediaQuery.of(context).size.height * 0.3,
                        child: RaisedButton(
                          elevation: 30.0,
                          child: Text(
                            "Stop",
                            textScaleFactor: 3,
                          ),
                          onPressed: () {
                            stopRecording();
                          },
                        ),
                      ),
                    ),
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
