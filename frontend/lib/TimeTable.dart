import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_test_app/RefreshSignal.dart';
import 'package:flutter_test_app/CalendarExport.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Timetable extends StatefulWidget {
  const Timetable({super.key});
  static List<dynamic> timetableData = [];

  @override
  State<Timetable> createState() => _TimetableState();
}

class _TimetableState extends State<Timetable> {
  // Store the raw parsed schedule list directly
  // List<dynamic> timetableData = [];
  bool isLoading = true;
  bool isExporting = false;

  @override
  void initState() {
    super.initState();
    _loadSavedTimetable();
    // Re-load automatically whenever a login happens on the Profile tab,
    // since IndexedStack keeps this page alive and won't rebuild it on its own.
    timetableRefreshSignal.addListener(_loadSavedTimetable);
  }

  @override
  void dispose() {
    timetableRefreshSignal.removeListener(_loadSavedTimetable);
    super.dispose();
  }

  // Simply loads whatever timetable was last saved locally (from the
  // Profile/Login screen). This data persists indefinitely — it is only
  // ever replaced when the user logs in again, never auto-cleared.
  Future<void> _loadSavedTimetable() async {
    setState(() => isLoading = true);

    final prefs = await SharedPreferences.getInstance();
    final String? savedData = prefs.getString('timetableData');

    if (savedData != null) {
      final List<dynamic> parsedData = jsonDecode(savedData);
      setState(() {
        Timetable.timetableData = parsedData
            .where((day) => day['Header'] != "Slot 1 Slot 2 Slot 3")
            .toList();
        isLoading = false;
      });
    } else {
      setState(() {
        Timetable.timetableData = [];
        isLoading = false;
      });
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : null,
      ),
    );
  }

  Future<void> _handleDownloadIcs() async {
    if (Timetable.timetableData.isEmpty) {
      _showMessage('No schedule data loaded yet.', isError: true);
      return;
    }
    final weeks = await CalendarExportService.promptForWeeks(context);
    if (weeks == null) return; // user cancelled

    setState(() => isExporting = true);
    try {
      await CalendarExportService.downloadIcsFile(
        Timetable.timetableData,
        weeks: weeks,
      );
    } catch (e) {
      _showMessage('Could not create .ics file: $e', isError: true);
    } finally {
      if (mounted) setState(() => isExporting = false);
    }
  }

  Future<void> _handleAddToDeviceCalendar() async {
    if (Timetable.timetableData.isEmpty) {
      _showMessage('No schedule data loaded yet.', isError: true);
      return;
    }
    final weeks = await CalendarExportService.promptForWeeks(context);
    if (weeks == null) return; // user cancelled

    setState(() => isExporting = true);
    try {
      final result = await CalendarExportService.addToDeviceCalendar(
        Timetable.timetableData,
        weeks: weeks,
      );
      _showMessage(result);
    } catch (e) {
      _showMessage('Could not add to calendar: $e', isError: true);
    } finally {
      if (mounted) setState(() => isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _loadSavedTimetable,
        child: Timetable.timetableData.isEmpty
            ? ListView(
                // ListView so pull-to-refresh still works on an empty state
                children: const [
                  SizedBox(height: 200),
                  Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        "No schedule data loaded yet.\nGo to Profile to log in and fetch your timetable.",
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                //a Function (that explains te return statments)
                itemCount: Timetable.timetableData.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return exportOptions();
                  }
                  final dataIndex = index - 1;
                  //loop body//The index variable automatically increments on every iteration
                  final dayData = Timetable.timetableData[dataIndex];
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
    );
  }

  Widget exportOptions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton(
            onPressed: isExporting ? null : _handleAddToDeviceCalendar,
            child: isExporting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Import to Calendar',
                    style: TextStyle(color: Colors.indigo),
                  ),
          ),
          ElevatedButton(
            onPressed: isExporting ? null : _handleDownloadIcs,
            child: isExporting
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text(
                    'Download .ics file',
                    style: TextStyle(color: Colors.indigo),
                  ),
          ),
        ],
      ),
    );
  }
}
