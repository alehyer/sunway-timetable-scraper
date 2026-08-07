import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_test_app/ics_exporter.dart';

void main() {
  test('buildIcs exports timetable entries as ICS events', () {
    final String ics = TimetableIcsExporter.buildIcs([
      {
        'Header': 'Tuesday, 16 Jun 2026',
        'tableDataList': [
          {
            'tableDataDetails': [
              'Time : 08:00 AM - 10:00 AM CSC3206 (L) - ARTIFICIAL INTELLIGENCE Grouping : 1 Venue : Online Class Lecturer : DR TEOH YUN XIN',
            ],
          },
          {
            'tableDataDetails': ['No subject'],
          },
        ],
      },
    ]);

    expect(ics, contains('BEGIN:VCALENDAR'));
    expect(ics, contains('BEGIN:VEVENT'));
    expect(ics, contains('SUMMARY:CSC3206 (L) - ARTIFICIAL INTELLIGENCE'));
    expect(ics, contains('LOCATION:Online Class'));
    expect(
      ics,
      contains(
        'DESCRIPTION:Course: CSC3206 (L) - ARTIFICIAL INTELLIGENCE\\nGrouping: 1\\nVenue: Online Class\\nLecturer: DR TEOH YUN XIN',
      ),
    );
    expect(ics, contains('DTSTART:20260616T000000Z'));
    expect(ics, contains('DTEND:20260616T020000Z'));
    expect(ics, isNot(contains('No subject')));
    expect(ics, contains('END:VCALENDAR'));
  });
}
