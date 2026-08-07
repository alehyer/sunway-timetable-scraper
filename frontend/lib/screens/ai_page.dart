import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../models/study_slot.dart';
import 'timetable_page.dart';

class AIPage extends StatefulWidget {
  const AIPage({super.key});

  @override
  State<AIPage> createState() => _AIPageState();
}

class _AIPageState extends State<AIPage> {
  double intensityLevel = 5;

  bool isLoading = false;

  String? errorMessage;

  List<StudySlot> studySlots = [];

  Future<void> fetchRecommendations() async {
    if (TimetablePage.timetableData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Please load your timetable first.",
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;

      errorMessage = null;
    });

    final url = Uri.parse(
      'http://10.0.2.2:8020/api/timetable/ai',
    );

    final body = {
      "tableHeader": TimetablePage.timetableData,

      "intensityLevel": intensityLevel.toInt(),
    };

    try {
      final response = await http.post(
        url,

        headers: {
          "Content-Type": "application/json",
        },

        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        final slots = data['studySlots'] ?? [];

        setState(() {
          studySlots = slots
              .map<StudySlot>(
                (slot) =>
                    StudySlot.fromJson(slot),
              )
              .toList();

          isLoading = false;
        });
      } else {
        throw Exception("Server error");
      }
    } catch (e) {
      setState(() {
        errorMessage = e.toString();

        isLoading = false;
      });
    }
  }

  void clearRecommendations() {
    setState(() {
      studySlots.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.stretch,

        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

                children: [
                  const Text(
                    "Study Intensity",

                    style: TextStyle(
                      fontSize: 18,

                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  Text(
                    "${intensityLevel.toInt()} / 10 "
                    "(${2 + intensityLevel.toInt() * 2} hours/week)",
                  ),

                  Slider(
                    value: intensityLevel,

                    min: 1,

                    max: 10,

                    divisions: 9,

                    onChanged: (value) {
                      setState(() {
                        intensityLevel = value;
                      });
                    },
                  ),

                  FilledButton.icon(
                    onPressed: isLoading
                        ? null
                        : fetchRecommendations,

                    icon: const Icon(
                      Icons.auto_awesome,
                    ),

                    label: const Text(
                      "Generate Schedule",
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          if (isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),

          if (errorMessage != null)
            Text(
              errorMessage!,

              style: const TextStyle(
                color: Colors.red,
              ),
            ),

          if (studySlots.isNotEmpty)
            Column(
              children: studySlots.map((slot) {
                return Card(
                  child: ListTile(
                    leading: const Icon(
                      Icons.menu_book,
                    ),

                    title: Text(slot.subject),

                    subtitle: Text(
                      "${slot.date}\n${slot.time}",
                    ),
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }
}
