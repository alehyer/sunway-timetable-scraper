class StudySlot {
  final String date;
  final String subject;
  final String time;

  const StudySlot({
    required this.date,
    required this.subject,
    required this.time,
  });

  factory StudySlot.fromJson(
    Map<String, dynamic> json,
  ) {
    return StudySlot(
      date: json['date'] ?? '',

      subject: json['subject'] ?? '',

      time: json['time'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,

      'subject': subject,

      'time': time,
    };
  }
}
