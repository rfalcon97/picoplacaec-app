import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/notification_history_entry.dart';

final notificationHistoryServiceProvider = Provider<NotificationHistoryService>((ref) {
  return NotificationHistoryService();
});

/// Local, on-device log of every notification the app has shown: scheduled
/// reminders and server push alerts alike. There's no server-side "read"
/// state (see PROJECT_CONTEXT.md — no backend notification storage), so
/// read/unread lives here too.
class NotificationHistoryService {
  static const _historyKey = 'notification_history_v3';
  static const _lastScheduledKey = 'notification_last_scheduled_v3';
  static const _maxEntries = 100;

  Future<List<NotificationHistoryEntry>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_historyKey);
    if (raw == null) return [];
    final list = jsonDecode(raw) as List<dynamic>;
    final entries = list.map((e) => NotificationHistoryEntry.fromJson(e as Map<String, dynamic>)).toList();
    entries.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return entries;
  }

  Future<int> getUnreadCount() async {
    final history = await getHistory();
    return history.where((e) => !e.read).length;
  }

  Future<void> markAllAsRead() async {
    final history = await getHistory();
    if (history.every((e) => e.read)) return;
    await _save(history.map((e) => e.copyWith(read: true)).toList());
  }

  /// Records a local reminder (night-before/same-day) only if it's actually
  /// new for that vehicle — avoids spamming the same entry every time the
  /// status list refreshes and reschedules the same upcoming date.
  Future<void> recordScheduledIfNew({
    required String dedupeKey,
    required String restrictedDate,
    required String title,
    required String body,
    required NotificationKind kind,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final lastRaw = prefs.getString(_lastScheduledKey);
    final lastMap = lastRaw != null
        ? Map<String, String>.from(jsonDecode(lastRaw) as Map<String, dynamic>)
        : <String, String>{};

    if (lastMap[dedupeKey] == restrictedDate) return;
    lastMap[dedupeKey] = restrictedDate;
    await prefs.setString(_lastScheduledKey, jsonEncode(lastMap));

    await _insert(NotificationHistoryEntry(title: title, body: body, kind: kind, createdAt: DateTime.now()));
  }

  /// Records a server push as soon as it's received — always appended, no
  /// dedup, since each push is its own event.
  Future<void> recordPush({required String title, required String body}) {
    return _insert(
      NotificationHistoryEntry(title: title, body: body, kind: NotificationKind.serverPush, createdAt: DateTime.now()),
    );
  }

  Future<void> _insert(NotificationHistoryEntry entry) async {
    final history = await getHistory();
    history.insert(0, entry);
    await _save(history.take(_maxEntries).toList());
  }

  Future<void> _save(List<NotificationHistoryEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_historyKey, jsonEncode(entries.map((e) => e.toJson()).toList()));
  }
}
