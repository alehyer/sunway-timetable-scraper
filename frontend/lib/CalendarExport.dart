// CalendarExport.dart
//
// Frontend-only calendar export/integration for the scraped timetable.
// Reads Timetable.timetableData (already cached locally by TimeTable.dart /
// SharedPreferences) — no backend changes required.
//
// Adds two capabilities:
//   1. downloadIcsFile()      -> builds a .ics file and hands it to the OS
//                                 share sheet ("Download .ics file")
//   2. addToDeviceCalendar()  -> inserts events directly into a calendar on
//                                 the phone via the device_calendar plugin
//                                 ("Import to Calendar")
//
// New pubspec.yaml dependencies needed (not included in this zip):
//   path_provider: ^2.1.0
//   share_plus: ^10.1.4   // pinned <11.0.0: this Dart SDK predates the
//                         // SharePlus.instance/ShareParams API (needs Dart 3.10+),
//                         // so this file uses the older Share.shareXFiles() call.
//   device_calendar: ^4.3.0
//   timezone: ^0.9.0
//
// Also needs, on the native side (not part of this Dart change):
//   Android (android/app/src/main/AndroidManifest.xml):
//     <uses-permission android:name="android.permission.READ_CALENDAR"/>
//     <uses-permission android:name="android.permission.WRITE_CALENDAR"/>
//   iOS (ios/Runner/Info.plist):
//     <key>NSCalendarsUsageDescription</key>
//     <string>Add your class schedule to your calendar</string>
//     (iOS 17+ also expects NSCalendarsFullAccessUsageDescription)

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/timezone.dart' as tz;

/// One concrete weekly class session parsed out of the raw scraped data.
class TimetableEvent {
  final String dayOfWeek; // raw header text, e.g. "MONDAY"
  final String course;
  final String? group;
  final String? venue;
  final String? lecturer;
  final TimeOfDay start;
  final TimeOfDay end;

  TimetableEvent({
    required this.dayOfWeek,
    required this.course,
    required this.start,
    required this.end,
    this.group,
    this.venue,
    this.lecturer,
  });
}

class CalendarExportException implements Exception {
  final String message;
  CalendarExportException(this.message);
  @override
  String toString() => message;
}

class CalendarExportService {
  CalendarExportService._();

  static const Map<String, int> _weekdayMap = {
    'MON': DateTime.monday,
    'TUE': DateTime.tuesday,
    'WED': DateTime.wednesday,
    'THU': DateTime.thursday,
    'FRI': DateTime.friday,
    'SAT': DateTime.saturday,
    'SUN': DateTime.sunday,
  };

  // Matches "8:00 AM - 10:00 AM", "08:00 - 10:00", "8.00pm-9.30pm", etc.
  static final RegExp _timeRangeRegex = RegExp(
    r'(\d{1,2}[:.]\d{2}\s*(?:[AaPp][Mm])?)\s*-\s*(\d{1,2}[:.]\d{2}\s*(?:[AaPp][Mm])?)',
  );

  // ---------------------------------------------------------------------
  // Parsing: raw Timetable.timetableData -> flat list of TimetableEvent
  // ---------------------------------------------------------------------

  static List<TimetableEvent> parse(List<dynamic> timetableData) {
    final events = <TimetableEvent>[];

    for (final day in timetableData) {
      final String header = (day['Header'] ?? '').toString();
      final int? weekday = _resolveWeekday(header);
      if (weekday == null) continue; // not a recognizable day row, skip

      final List<dynamic> classes = day['tableDataList'] ?? [];
      for (final classItem in classes) {
        final List<dynamic> rawDetails = classItem['tableDataDetails'] ?? [];
        final details = rawDetails.map((e) => e.toString()).toList();
        if (details.isEmpty || details.contains('No subject')) continue;

        final course = details.first;
        String? timeRaw;
        final extras = <String>[];

        for (final line in details.skip(1)) {
          if (timeRaw == null && _timeRangeRegex.hasMatch(line)) {
            timeRaw = line;
          } else {
            extras.add(line);
          }
        }

        if (timeRaw == null)
          continue; // can't build a calendar entry without a time
        final times = _parseTimeRange(timeRaw);
        if (times == null) continue;

        events.add(
          TimetableEvent(
            dayOfWeek: header,
            course: course,
            start: times.$1,
            end: times.$2,
            group: extras.isNotEmpty ? extras[0] : null,
            venue: extras.length > 1 ? extras[1] : null,
            lecturer: extras.length > 2 ? extras[2] : null,
          ),
        );
      }
    }
    return events;
  }

  static int? _resolveWeekday(String header) {
    final upper = header.toUpperCase();
    for (final entry in _weekdayMap.entries) {
      if (upper.contains(entry.key)) return entry.value;
    }
    return null;
  }

  static (TimeOfDay, TimeOfDay)? _parseTimeRange(String raw) {
    final match = _timeRangeRegex.firstMatch(raw);
    if (match == null) return null;
    final start = _parseClock(match.group(1)!);
    final end = _parseClock(match.group(2)!);
    if (start == null || end == null) return null;
    return (start, end);
  }

  static TimeOfDay? _parseClock(String raw) {
    final cleaned = raw.trim().toUpperCase().replaceAll('.', ':');
    final isPm = cleaned.contains('PM');
    final isAm = cleaned.contains('AM');
    final digitsOnly = cleaned.replaceAll(RegExp(r'[APM\s]'), '');
    final parts = digitsOnly.split(':');
    if (parts.length != 2) return null;
    var hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    if (isPm && hour < 12) hour += 12;
    if (isAm && hour == 12) hour = 0;
    if (hour > 23) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  /// Next date (today or later) that falls on [weekday] (1=Mon..7=Sun),
  /// counted from [from]'s date only (time stripped).
  static DateTime _nextOrSameWeekday(DateTime from, int weekday) {
    final base = DateTime(from.year, from.month, from.day);
    final diff = (weekday - base.weekday) % 7;
    return base.add(Duration(days: diff));
  }

  // ---------------------------------------------------------------------
  // Feature 1: Download .ics file
  // ---------------------------------------------------------------------

  static Future<void> downloadIcsFile(
    List<dynamic> timetableData, {
    DateTime? semesterStart,
    int weeks = 14,
  }) async {
    final events = parse(timetableData);
    if (events.isEmpty) {
      throw CalendarExportException(
        'No timed classes found in your timetable to export.',
      );
    }

    final ics = _buildICS(
      events,
      semesterStart: semesterStart ?? DateTime.now(),
      weeks: weeks,
    );

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/my_timetable.ics');
    await file.writeAsString(ics);

    // share_plus ^10.1.4 API (pre-11.0.0, which requires Dart 3.10+).
    // If you later upgrade share_plus to 11.0.0+, swap this for:
    //   SharePlus.instance.share(ShareParams(
    //     files: [XFile(file.path, mimeType: 'text/calendar')],
    //     subject: 'My Timetable',
    //   ));
    await Share.shareXFiles([
      XFile(file.path, mimeType: 'text/calendar'),
    ], subject: 'My Timetable');
  }

  static String _buildICS(
    List<TimetableEvent> events, {
    required DateTime semesterStart,
    required int weeks,
  }) {
    final buffer = StringBuffer();
    void line(String s) => buffer.write('$s\r\n');

    line('BEGIN:VCALENDAR');
    line('VERSION:2.0');
    line('PRODID:-//AIAsk//Timetable Export//EN');
    line('CALSCALE:GREGORIAN');
    line('X-WR-CALNAME:My Timetable');

    final stamp = _fmtStampUtc(DateTime.now().toUtc());

    for (final e in events) {
      final weekday = _weekdayMap.entries
          .firstWhere((en) => e.dayOfWeek.toUpperCase().contains(en.key))
          .value;
      final firstDay = _nextOrSameWeekday(semesterStart, weekday);
      final dtStart = DateTime(
        firstDay.year,
        firstDay.month,
        firstDay.day,
        e.start.hour,
        e.start.minute,
      );
      final dtEnd = DateTime(
        firstDay.year,
        firstDay.month,
        firstDay.day,
        e.end.hour,
        e.end.minute,
      );
      final until = dtStart
          .add(Duration(days: 7 * (weeks - 1)))
          .add(const Duration(hours: 23, minutes: 59, seconds: 59));

      line('BEGIN:VEVENT');
      line('UID:${_uid(e, dtStart)}');
      line('DTSTAMP:$stamp');
      line('DTSTART:${_fmtLocal(dtStart)}');
      line('DTEND:${_fmtLocal(dtEnd)}');
      line('RRULE:FREQ=WEEKLY;UNTIL=${_fmtLocal(until)}');
      line('SUMMARY:${_escape(e.course)}');
      if (e.venue != null) line('LOCATION:${_escape(e.venue!)}');
      final descParts = [
        if (e.group != null) 'Group: ${e.group}',
        if (e.lecturer != null) 'Lecturer: ${e.lecturer}',
      ];
      if (descParts.isNotEmpty) {
        line('DESCRIPTION:${_escape(descParts.join('\\n'))}');
      }
      line('END:VEVENT');
    }

    line('END:VCALENDAR');
    return buffer.toString();
  }

  static String _uid(TimetableEvent e, DateTime dtStart) {
    final raw =
        '${e.course}-${e.dayOfWeek}-${e.start.hour}${e.start.minute}'
        '-${dtStart.millisecondsSinceEpoch}';
    return '${raw.hashCode.abs()}@aiask-timetable';
  }

  static String _twoDigits(int n) => n.toString().padLeft(2, '0');

  static String _fmtLocal(DateTime dt) {
    return '${dt.year}${_twoDigits(dt.month)}${_twoDigits(dt.day)}'
        'T${_twoDigits(dt.hour)}${_twoDigits(dt.minute)}${_twoDigits(dt.second)}';
  }

  static String _fmtStampUtc(DateTime dt) {
    return '${_fmtLocal(dt)}Z';
  }

  static String _escape(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll(';', '\\;')
        .replaceAll(',', '\\,')
        .replaceAll('\n', '\\n');
  }

  // ---------------------------------------------------------------------
  // Feature 2: Connect directly to the phone's calendar
  // ---------------------------------------------------------------------

  static Future<String> addToDeviceCalendar(
    List<dynamic> timetableData, {
    DateTime? semesterStart,
    int weeks = 14,
  }) async {
    final events = parse(timetableData);
    if (events.isEmpty) {
      throw CalendarExportException(
        'No timed classes found in your timetable to add.',
      );
    }

    final plugin = DeviceCalendarPlugin();

    var permission = await plugin.hasPermissions();
    if (permission.data != true) {
      permission = await plugin.requestPermissions();
      if (permission.data != true) {
        throw CalendarExportException(
          'Calendar permission was denied. Enable it in system settings to import your timetable.',
        );
      }
    }

    final calendarsResult = await plugin.retrieveCalendars();
    final List<Calendar> calendars = (calendarsResult.data ?? <Calendar?>[])
        .where((c) => c != null && c.isReadOnly != true)
        .cast<Calendar>()
        .toList();
    if (calendars.isEmpty) {
      throw CalendarExportException(
        'No writable calendar was found on this device.',
      );
    }

    // Prefer a calendar already named for this app (created by the user or
    // a prior run); otherwise fall back to the device's first writable one.
    Calendar target = calendars.first;
    for (final c in calendars) {
      if ((c.name ?? '').toLowerCase().contains('aiask')) {
        target = c;
        break;
      }
    }

    final start = semesterStart ?? DateTime.now();
    int added = 0;

    for (final e in events) {
      final weekday = _weekdayMap.entries
          .firstWhere((en) => e.dayOfWeek.toUpperCase().contains(en.key))
          .value;
      final firstDay = _nextOrSameWeekday(start, weekday);

      final eventStart = tz.TZDateTime.from(
        DateTime(
          firstDay.year,
          firstDay.month,
          firstDay.day,
          e.start.hour,
          e.start.minute,
        ),
        tz.local,
      );
      final eventEnd = tz.TZDateTime.from(
        DateTime(
          firstDay.year,
          firstDay.month,
          firstDay.day,
          e.end.hour,
          e.end.minute,
        ),
        tz.local,
      );

      final description = [
        if (e.group != null) 'Group: ${e.group}',
        if (e.lecturer != null) 'Lecturer: ${e.lecturer}',
      ].join('\n');

      final event = Event(
        target.id,
        title: e.course,
        start: eventStart,
        end: eventEnd,
        location: e.venue,
        description: description.isEmpty ? null : description,
        recurrenceRule: RecurrenceRule(
          RecurrenceFrequency.Weekly,
          interval: 1,
          totalOccurrences: weeks,
        ),
      );

      final result = await plugin.createOrUpdateEvent(event);
      if (result?.isSuccess == true) added++;
    }

    return 'Added $added class${added == 1 ? '' : 'es'} to "${target.name}".';
  }

  // ---------------------------------------------------------------------
  // Small UI helper: ask how many weeks remain in the semester.
  // ---------------------------------------------------------------------

  static Future<int?> promptForWeeks(BuildContext context) {
    int weeks = 14;
    return showDialog<int>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('How many weeks left?'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Classes repeat weekly starting from the next occurrence '
                    'of each day. How many weeks should be added?',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 12),
                  Slider(
                    value: weeks.toDouble(),
                    min: 1,
                    max: 20,
                    divisions: 19,
                    label: '$weeks weeks',
                    onChanged: (v) => setState(() => weeks = v.round()),
                  ),
                  Text(
                    '$weeks weeks',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(weeks),
                  child: const Text('Continue'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
