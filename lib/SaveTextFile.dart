import 'package:flutter/material.dart';

class NameAndSave extends StatefulWidget {
  @override
  _NameAndSaveState createState() => _NameAndSaveState();
}

class _NameAndSaveState extends State<NameAndSave> {
  final myController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text("Give a Name to Text File"),
          centerTitle: true,
        ),
        body: Center(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: TextField(
                        controller: myController,
                        decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.black, width: 5)),
                            hintText: 'Enter File Name'),
                      ),
                    ),
                    Flexible(
                      child: RaisedButton(
                        splashColor: Colors.teal,
                        elevation: 20,
                        child: Text('Save .txt File'),
                        onPressed: () {
                          Navigator.pop(context, myController.text);
                        },
                      ),
                    )
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
