import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/refresh_signal.dart';

class TimetablePage extends StatefulWidget {
  const TimetablePage({super.key});

  static List<dynamic> timetableData = [];

  @override
  State<TimetablePage> createState() =>
      _TimetablePageState();
}

class _TimetablePageState
    extends State<TimetablePage> {
  bool isLoading = true;

  @override
  void initState() {
    super.initState();

    loadTimetable();

    timetableRefreshSignal.addListener(
      loadTimetable,
    );
  }

  @override
  void dispose() {
    timetableRefreshSignal.removeListener(
      loadTimetable,
    );

    super.dispose();
  }

  Future<void> loadTimetable() async {
    setState(() {
      isLoading = true;
    });

    final prefs =
        await SharedPreferences.getInstance();

    final savedData = prefs.getString(
      'timetableData',
    );

    if (savedData == null) {
      setState(() {
        TimetablePage.timetableData = [];

        isLoading = false;
      });

      return;
    }

    final List<dynamic> data = jsonDecode(
      savedData,
    );

    setState(() {
      TimetablePage.timetableData = data
          .where(
            (day) =>
                day['Header'] !=
                "Slot 1 Slot 2 Slot 3",
          )
          .toList();

      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return RefreshIndicator(
      onRefresh: loadTimetable,

      child: TimetablePage.timetableData.isEmpty
          ? ListView(
              children: const [
                SizedBox(height: 200),

                Center(
                  child: Text(
                    "No timetable found.\n\n"
                    "Login from Profile to load your schedule.",

                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.all(12),

              itemCount: TimetablePage
                  .timetableData
                  .length,

              itemBuilder: (context, index) {
                final day = TimetablePage
                    .timetableData[index];

                final String header =
                    day['Header'];

                final List<dynamic> classes =
                    day['tableDataList'];

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 12,
                  ),

                  child: ExpansionTile(
                    initiallyExpanded: true,

                    leading: const Icon(
                      Icons.calendar_today,
                    ),

                    title: Text(
                      header,

                      style: const TextStyle(
                        fontWeight:
                            FontWeight.bold,
                      ),
                    ),

                    children: classes.map<Widget>((
                      classItem,
                    ) {
                      final details =
                          classItem['tableDataDetails'] ??
                          [];

                      if (details.contains(
                        "No subject",
                      )) {
                        return const ListTile(
                          leading: Icon(
                            Icons.free_breakfast,
                          ),

                          title: Text("Free Day"),
                        );
                      }

                      return Container(
                        margin:
                            const EdgeInsets.symmetric(
                              horizontal: 16,

                              vertical: 6,
                            ),

                        padding:
                            const EdgeInsets.all(
                              14,
                            ),

                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer,

                          borderRadius:
                              BorderRadius.circular(
                                14,
                              ),
                        ),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,

                          children: details.map<Widget>((
                            detail,
                          ) {
                            return Padding(
                              padding:
                                  const EdgeInsets.only(
                                    bottom: 4,
                                  ),

                              child: Text(
                                detail,

                                style:
                                    const TextStyle(
                                      fontSize:
                                          14,
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
    );
  }
}
