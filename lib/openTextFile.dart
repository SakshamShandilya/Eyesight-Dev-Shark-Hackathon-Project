import 'package:flutter/material.dart';

class OpenFile extends StatefulWidget {
  @override
  _OpenFileState createState() => _OpenFileState();
}

class _OpenFileState extends State<OpenFile> {
  final nameController = TextEditingController();
  final TextController = TextEditingController();
  Map<String, String> nameAndText = {};

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
                        controller: nameController,
                        decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.black, width: 5)),
                            hintText: 'Enter File Name'),
                      ),
                    ),
                    Flexible(
                      child: TextField(
                        controller: TextController,
                        decoration: InputDecoration(
                            focusedBorder: OutlineInputBorder(
                                borderSide:
                                    BorderSide(color: Colors.black, width: 5)),
                            hintText: 'Enter Text Data'),
                      ),
                    ),
                    Flexible(
                      child: RaisedButton(
                        splashColor: Colors.teal,
                        elevation: 20,
                        child: Text('Save .txt File'),
                        onPressed: () {
                          nameAndText = {
                            nameController.text: TextController.text
                          };
                          Navigator.pop(context, nameAndText);
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
