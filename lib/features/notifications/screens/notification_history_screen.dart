import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/notification_history_entry.dart';
import '../notification_history_service.dart';

final notificationHistoryProvider = FutureProvider<List<NotificationHistoryEntry>>((ref) {
  return ref.watch(notificationHistoryServiceProvider).getHistory();
});

final unreadNotificationCountProvider = FutureProvider<int>((ref) {
  return ref.watch(notificationHistoryServiceProvider).getUnreadCount();
});

IconData _kindIcon(NotificationKind kind) {
  switch (kind) {
    case NotificationKind.nightBefore:
      return Icons.nightlight_round;
    case NotificationKind.sameDay:
      return Icons.today;
    case NotificationKind.serverPush:
      return Icons.campaign;
  }
}

class NotificationHistoryScreen extends ConsumerStatefulWidget {
  const NotificationHistoryScreen({super.key});

  @override
  ConsumerState<NotificationHistoryScreen> createState() => _NotificationHistoryScreenState();
}

class _NotificationHistoryScreenState extends ConsumerState<NotificationHistoryScreen> {
  @override
  void initState() {
    super.initState();
    // Opening the list is what "marks as read" — matches most chat/social apps.
    Future.microtask(() async {
      await ref.read(notificationHistoryServiceProvider).markAllAsRead();
      ref.invalidate(notificationHistoryProvider);
      ref.invalidate(unreadNotificationCountProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
    final historyAsync = ref.watch(notificationHistoryProvider);
    // Purely numeric pattern — no locale symbol data needed at runtime.
    final dateFormat = DateFormat('dd/MM HH:mm');

    return Scaffold(
      appBar: AppBar(title: const Text('Notificaciones')),
      body: historyAsync.when(
        data: (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Todavía no tienes notificaciones.\nAgrega un vehículo para empezar a recibirlas.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView.separated(
            itemCount: entries.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: entry.read
                      ? Theme.of(context).colorScheme.surfaceContainerHighest
                      : Theme.of(context).colorScheme.primaryContainer,
                  child: Icon(_kindIcon(entry.kind)),
                ),
                title: Text(entry.title, style: TextStyle(fontWeight: entry.read ? FontWeight.normal : FontWeight.bold)),
                subtitle: Text(entry.body),
                trailing: Text(dateFormat.format(entry.createdAt), style: Theme.of(context).textTheme.bodySmall),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('$error')),
      ),
    );
  }
}
