import 'package:flutter/foundation.dart';

/// Because SkeletonPage uses an IndexedStack, all 4 tab pages are built once
/// and kept alive in memory — Timetable's initState only runs once at app
/// startup, so it has no way of knowing a new login happened on another tab.
///
/// This is a tiny global signal: UpdateProfile bumps `.value` after a
/// successful login, and Timetable listens for changes and reloads its
/// data from local storage when that happens.
final ValueNotifier<int> timetableRefreshSignal = ValueNotifier<int>(0);
