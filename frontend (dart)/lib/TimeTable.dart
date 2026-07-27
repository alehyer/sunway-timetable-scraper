import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class Timetable extends StatefulWidget {
  const Timetable({super.key});

  @override
  State<Timetable> createState() => _TimetableState();
}

class _TimetableState extends State<Timetable> {
  // Store the raw parsed schedule list directly
  List<dynamic> timetableData = [];
  bool isLoading = false;

  Future<void> fetchTable(String id, String password) async {
    setState(() => isLoading = true);

    final url = Uri.parse('http://10.0.2.2:8020/api/timetable/scrape');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"studentId": id, "password": password}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> parsedData = jsonDecode(response.body);

        setState(() {
          // Filter out the "Slot 1 Slot 2 Slot 3" header row if it contains no actual schedule items
          timetableData = parsedData
              .where((day) => day['Header'] != "Slot 1 Slot 2 Slot 3")
              .toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
        _showErrorSnackBar("Failed to fetch data from server.");
      }
    } catch (e) {
      setState(() => isLoading = false);
      _showErrorSnackBar("An error occurred: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    //telling the screen: "Hey, interrupt whatever you are doing and slide a notification up from the bottom."
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String studentID = "";
  String password = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: ElevatedButton(
              onPressed: () => fetchTable(studentID, password),
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Fetch Timetable",
                      style: TextStyle(color: Colors.indigo),
                    ),
            ),
          ),
          Expanded(
            child: timetableData.isEmpty
                ? const Center(child: Text("No schedule data loaded yet."))
                : ListView.builder(
                    //a Function (that explains te return statments)
                    itemCount: timetableData.length,
                    itemBuilder: (context, index) {
                      //loop body//The index variable automatically increments on every iteration
                      final dayData = timetableData[index];
                      final String dayHeader =
                          dayData['Header']; //e.g timetableData[1]['Header'];
                      final List<dynamic> classes = dayData['tableDataList'];

                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        child: ExpansionTile(
                          initiallyExpanded: true,
                          title: Text(
                            dayHeader,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          children: classes.map<Widget>((classItem) {
                            //Widget here is like List<Widget>
                            final List<dynamic> details =
                                classItem['tableDataDetails'] ??
                                []; //saftey net: says:If the thing on my left is null, use the thing on my right instead.

                            // Check if the day is empty/no subject
                            if (details.contains("No subject")) {
                              return const ListTile(
                                title: Text(
                                  "Free Day!",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              );
                            }

                            // Assuming details list order standard: Course, Time, Grouping, Venue, Lecturer
                            return Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.05),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: details.map((detailLine) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2.0, //the seperation
                                    ),
                                    child: Text(
                                      detailLine,
                                      style: TextStyle(
                                        fontWeight: detailLine.contains(" - ")
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: detailLine.contains(" - ")
                                            ? Colors.blue[800]
                                            : Colors.black87,
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            );
                          }).toList(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget exportOptions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        ElevatedButton(
          onPressed: () {},
          child: Text(
            'Import to Calender',
            style: TextStyle(color: Colors.indigo),
          ),
        ),
        ElevatedButton(
          onPressed: () {},
          child: Text(
            'Download .ics file',
            style: TextStyle(color: Colors.indigo),
          ),
        ),
      ],
    );
  }
}
