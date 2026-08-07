import 'package:flutter/foundation.dart';

/// Global signal used to notify pages when the timetable
/// has been refreshed after a successful login.
final ValueNotifier<int> timetableRefreshSignal =
    ValueNotifier<int>(0);
