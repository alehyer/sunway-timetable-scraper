import 'package:flutter/material.dart';

import 'screens/about_page.dart';
import 'screens/home_page.dart';
import 'screens/update_profile_page.dart';

void main() {
  runApp(const SunwayApp());
}

class SunwayApp extends StatelessWidget {
  const SunwayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      title: "Sunway Timetable",

      theme: ThemeData(
        useMaterial3: true,

        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
        ),
      ),

      home: const HomePage(),

      routes: {
        '/about': (context) => const AboutPage(),

        '/updateProfile': (context) =>
            const UpdateProfilePage(),
      },
    );
  }
}
