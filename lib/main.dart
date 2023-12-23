import 'dart:async';
import 'dart:convert';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth/home.dart';
import 'bluetoothsettings.dart';

StreamController<String> streamController = StreamController<String>();

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
          primaryColor: Colors.black,
          scaffoldBackgroundColor: Colors.grey[350]),
      home: Home(),
    );
  }
}
