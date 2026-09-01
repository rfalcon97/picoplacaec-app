import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import '../status/models/vehicle_status.dart';
import 'models/notification_history_entry.dart';
import 'notification_history_service.dart';

/// Schedules two local notifications per vehicle for its next restricted
/// day: a fixed "night before" heads-up, and a "same day" reminder at the
/// time the user configured for that vehicle. Purely on-device, computed
/// from cached status. See PushNotificationService for the separate
/// server-triggered push (used for last-minute admin changes).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _historyService = NotificationHistoryService();
  bool _initialized = false;

  /// Fixed time for the night-before heads-up — not user-configurable.
  /// 6pm on purpose: early enough that people still remember/can plan
  /// around it, rather than getting buried late at night.
  static const int _nightBeforeHour = 18;
  static const int _nightBeforeMinute = 0;

  // Inexact on purpose: a reminder can fire a few minutes off without issue,
  // and this avoids requiring the special "Alarms & reminders" permission
  // that exact scheduling needs on Android 12+.
  static const _scheduleMode = AndroidScheduleMode.inexactAllowWhileIdle;

  Future<void> init() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Guayaquil'));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const settings = InitializationSettings(android: androidSettings);
    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    _initialized = true;
  }

  /// Cancels all previously scheduled reminders and reschedules, per
  /// vehicle with an upcoming restricted date: one night-before notification
  /// (fixed time) and one same-day notification (vehicle's `reminderTime`).
  Future<void> rescheduleAll(List<VehicleStatus> statuses) async {
    await init();
    await _plugin.cancelAll();

    for (final status in statuses) {
      final nextDate = status.nextRestrictedDate;
      if (nextDate == null) continue;
      final restrictedDay = DateTime.parse(nextDate);

      await _scheduleOne(
        status: status,
        kind: NotificationKind.nightBefore,
        fireDate: DateTime(restrictedDay.year, restrictedDay.month, restrictedDay.day - 1),
        hour: _nightBeforeHour,
        minute: _nightBeforeMinute,
        title: 'Pico y Placa: ${status.nickname}',
        body: 'Mañana no circulas en ${status.cityName} (placa termina en ${status.plateDigit}).',
      );

      final timeParts = status.reminderTime.split(':');
      await _scheduleOne(
        status: status,
        kind: NotificationKind.sameDay,
        fireDate: restrictedDay,
        hour: int.parse(timeParts[0]),
        minute: int.parse(timeParts[1]),
        title: 'Pico y Placa: ${status.nickname}',
        body: 'Hoy no circulas en ${status.cityName} (placa termina en ${status.plateDigit}).',
      );
    }
  }

  Future<void> _scheduleOne({
    required VehicleStatus status,
    required NotificationKind kind,
    required DateTime fireDate,
    required int hour,
    required int minute,
    required String title,
    required String body,
  }) async {
    final scheduledDate = tz.TZDateTime(tz.local, fireDate.year, fireDate.month, fireDate.day, hour, minute);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id: '${status.vehicleId}:${kind.name}'.hashCode,
      title: title,
      body: body,
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'restriction_reminders',
          'Recordatorios de restricción',
          channelDescription: 'Avisa antes y durante un día con restricción vehicular',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: _scheduleMode,
    );

    await _historyService.recordScheduledIfNew(
      dedupeKey: '${status.vehicleId}:${kind.name}',
      restrictedDate: status.nextRestrictedDate!,
      title: title,
      body: body,
      kind: kind,
    );
  }
}
