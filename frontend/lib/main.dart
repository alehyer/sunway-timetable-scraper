import 'package:flutter/material.dart';
import 'package:flutter_test_app/About.dart';
import 'package:flutter_test_app/SkeletonPage.dart';
//import 'package:flutter_test_app/Profile.dart';
import 'package:flutter_test_app/UpdateProfile.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: SkeletonPage(),
      routes: {
        // '/profile': (context) => Profile(),
        '/about': (context) => About(),
        '/updateProfile': (context) => Updateprofile(),
      },
    );
  }
}
