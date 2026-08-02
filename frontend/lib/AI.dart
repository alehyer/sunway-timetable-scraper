import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'TimeTable.dart';

class StudySlot {
  final String date;
  final String subject;
  final String time;

  StudySlot({required this.date, required this.subject, required this.time});

  factory StudySlot.fromJson(Map<String, dynamic> json) {
    return StudySlot(
      date: json['date'] ?? '',
      subject: json['subject'] ?? '',
      time: json['time'] ?? '',
    );
  }
}

class AI extends StatefulWidget {
  const AI({super.key});

  @override
  State<AI> createState() => _AIScreenState();
}

class _AIScreenState extends State<AI> {
  double _intensityLevel = 5.0;
  bool _isLoading = false;
  String? _errorMessage;
  List<StudySlot> _studySlots = [];

  // Method to clear generated study slots
  void _clearStudySlots() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear Recommendations?'),
          content: const Text(
            'This will remove the generated study schedule slots from view.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Cancel
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _studySlots.clear();
                });
                Navigator.of(context).pop(); // Close dialog
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Study slots cleared.'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _fetchAiRecommendations() async {
    final tableHeaderData = Timetable.timetableData;

    if (tableHeaderData.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No timetable data found! Please scrape your timetable first.',
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final url = Uri.parse('http://10.0.2.2:8020/api/timetable/ai');

    final payload = {
      'tableHeader': tableHeaderData,
      'intensityLevel': _intensityLevel.toInt(),
    };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> slotsJson = data['studySlots'] ?? [];

        setState(() {
          _studySlots = slotsJson
              .map((json) => StudySlot.fromJson(json))
              .toList();
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'Server error (${response.statusCode}): Failed to generate recommendations.';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Connection failed: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Study Recommendations'),
        centerTitle: true,
        actions: [
          // Clear button in the AppBar (enabled only when slots exist)
          if (_studySlots.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Clear Slots',
              onPressed: _clearStudySlots,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Study Intensity Level',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Intensity: ${_intensityLevel.toInt()} / 10 (${2 + (_intensityLevel.toInt() * 2)} extra study hours/week)',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    Slider(
                      value: _intensityLevel,
                      min: 1.0,
                      max: 10.0,
                      divisions: 9,
                      label: _intensityLevel.toInt().toString(),
                      onChanged: (value) {
                        setState(() {
                          _intensityLevel = value;
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: _isLoading ? null : _fetchAiRecommendations,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate Study Schedule'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Analyzing timetable gaps & generating slots...'),
                    ],
                  ),
                ),
              ),

            if (_errorMessage != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red),
                ),
              ),

            // Recommended Slots Section
            if (!_isLoading && _studySlots.isNotEmpty) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recommended Study Slots',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton.icon(
                    onPressed: _clearStudySlots,
                    icon: const Icon(
                      Icons.clear_all,
                      size: 18,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Clear',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _studySlots.length,
                itemBuilder: (context, index) {
                  final slot = _studySlots[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: const CircleAvatar(child: Icon(Icons.menu_book)),
                      title: Text(
                        slot.subject,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text('${slot.date}\n${slot.time}'),
                      isThreeLine: true,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}
