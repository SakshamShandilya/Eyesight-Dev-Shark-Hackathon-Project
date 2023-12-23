import 'package:flutter/material.dart';

class SelectAndOpen extends StatelessWidget {
  final List<String> listOFFileName;
  SelectAndOpen({Key key, @required this.listOFFileName}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Select the text file"),
        centerTitle: true,
      ),
      body: Center(
        child: ListView.builder(
          itemCount: listOFFileName.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.pop(context, index);
                },
                child: Card(
                  elevation: 25,
                  child: Text(
                    listOFFileName[index].toString(),
                    textScaleFactor: 2,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
