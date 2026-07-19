// import 'dart:ffi';

import 'package:flutter/material.dart';

class Updateprofile extends StatefulWidget {
  Updateprofile({super.key});

  @override
  State<Updateprofile> createState() => _UpdateprofileState();
}

class _UpdateprofileState extends State<Updateprofile> {
  //access users studdeent id and password
  TextEditingController studentId = TextEditingController();

  TextEditingController studentPassword = TextEditingController();

  void test() {
    print(studentId.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Profile"),
        backgroundColor: Colors.orange[700],
      ),

      body: Container(
        height: 350,
        width: 350,
        margin: EdgeInsets.fromLTRB(30, 100, 30, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          color: Colors.indigo[900],
        ),

        child: Column(
          children: [
            TextField(
              controller: studentId,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Your Student ID..",
              ),
            ),

            TextField(
              controller: studentPassword,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: "Password..",
              ),
            ),

            ElevatedButton(onPressed: test, child: Text("Tap")),
          ],
        ),
      ),
    );
  }
}
