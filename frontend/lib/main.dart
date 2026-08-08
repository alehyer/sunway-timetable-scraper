import 'package:flutter/material.dart';
import 'package:flutter_test_app/About.dart';
import 'package:flutter_test_app/SkeletonPage.dart';
//import 'package:flutter_test_app/Profile.dart';
import 'package:flutter_test_app/UpdateProfile.dart';
import 'package:shared_preferences/shared_preferences.dart';

// void main() {
//   runApp(MyApp());
// }
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // TEMP — TESTING ONLY: wipes the cached login/timetable on every cold
  // start so the 7-day login expiry never gets in the way while testing.
  // Remove this block before shipping.
  final prefs = await SharedPreferences.getInstance();
  await prefs.clear();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SkeletonPage(),
      routes: {
        // '/profile': (context) => Profile(),
        '/about': (context) => About(),
        '/updateProfile': (context) => Updateprofile(),
      },
    );
  }
}
