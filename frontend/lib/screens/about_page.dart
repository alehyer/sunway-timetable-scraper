import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("About"),

        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              "Sunway Timetable",

              style: TextStyle(
                fontSize: 26,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            const Text(
              "A timetable assistant app for Sunway University "
              "students.\n\n"
              "Features:\n"
              "• Timetable scraping\n"
              "• AI study recommendations\n"
              "• Quick access to student tools",

              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
