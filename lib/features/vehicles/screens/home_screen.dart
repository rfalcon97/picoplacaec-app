import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/api_error.dart';
import '../../ads/banner_ad_widget.dart';
import '../../ads/interstitial_ad_service.dart';
import '../../auth/state/auth_controller.dart';
import '../../notifications/notification_service.dart';
import '../../notifications/push_notification_service.dart';
import '../../notifications/screens/notification_history_screen.dart';
import '../../status/models/vehicle_status.dart';
import '../../status/state/status_provider.dart';
import 'add_vehicle_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(myVehiclesStatusProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider).valueOrNull ?? 0;
    final vehicles = statusAsync.valueOrNull;
    final firstVehicleCityId = (vehicles != null && vehicles.isNotEmpty) ? vehicles.first.cityId : null;

    // Registers/refreshes this device's push token for the current session.
    ref.watch(pushInitProvider);

    // Every time the status list refreshes, reschedule reminders to match.
    ref.listen(myVehiclesStatusProvider, (previous, next) {
      next.whenData((statuses) async {
        await NotificationService.instance.rescheduleAll(statuses);
        ref.invalidate(unreadNotificationCountProvider);
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis vehículos'),
        actions: [
          IconButton(
            tooltip: 'Planificar ruta',
            icon: const Icon(Icons.alt_route),
            onPressed: () => context.push('/route-planner', extra: firstVehicleCityId),
          ),
          IconButton(
            tooltip: 'Notificaciones',
            icon: Badge(
              label: Text('$unreadCount'),
              isLabelVisible: unreadCount > 0,
              child: const Icon(Icons.notifications_outlined),
            ),
            onPressed: () async {
              await context.push('/notification-history');
              ref.invalidate(unreadNotificationCountProvider);
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myVehiclesStatusProvider.future),
        child: statusAsync.when(
          data: (vehicles) {
            if (vehicles.isEmpty) {
              return _EmptyState(onAdd: () => _goToAddVehicle(context, ref));
            }
            return ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: vehicles.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _VehicleCard(
                status: vehicles[index],
                onChanged: () => ref.invalidate(myVehiclesStatusProvider),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(extractErrorMessage(error), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => ref.invalidate(myVehiclesStatusProvider),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _goToAddVehicle(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Vehículo'),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }

  Future<void> _goToAddVehicle(BuildContext context, WidgetRef ref) async {
    final added = await context.push<bool>('/add-vehicle');
    if (added == true) {
      ref.invalidate(myVehiclesStatusProvider);
      ref.read(interstitialAdServiceProvider).showIfReady();
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.directions_car_outlined, size: 64),
            const SizedBox(height: 16),
            const Text('Todavía no tienes vehículos registrados', textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: onAdd, icon: const Icon(Icons.add), label: const Text('Agregar vehículo')),
          ],
        ),
      ),
    );
  }
}

enum _VehicleCardAction { edit, schedule }

class _VehicleCard extends ConsumerWidget {
  const _VehicleCard({required this.status, required this.onChanged});

  final VehicleStatus status;
  final VoidCallback onChanged;

  Future<void> _onMenuSelected(BuildContext context, _VehicleCardAction action) async {
    switch (action) {
      case _VehicleCardAction.edit:
        final changed = await context.push<bool>(
          '/edit-vehicle',
          extra: VehicleEditArgs(
            id: status.vehicleId,
            nickname: status.nickname,
            plateDigit: status.plateDigit,
            cityId: status.cityId,
            reminderTime: status.reminderTime,
          ),
        );
        if (changed == true) onChanged();
      case _VehicleCardAction.schedule:
        if (context.mounted) context.push('/city-schedule/${status.citySlug}');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = status.today;
    final color = today.restricted ? Colors.red : Colors.green;
    final statusText = today.restricted
        ? (today.allDay ? 'NO circulas hoy (todo el día)' : 'NO circulas hoy (${today.timeStart} - ${today.timeEnd})')
        : 'Hoy SÍ circulas';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(status.nickname, style: Theme.of(context).textTheme.titleMedium)),
                Chip(label: Text('Placa termina en ${status.plateDigit}')),
                PopupMenuButton<_VehicleCardAction>(
                  onSelected: (action) => _onMenuSelected(context, action),
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: _VehicleCardAction.edit, child: Text('Editar / eliminar')),
                    PopupMenuItem(value: _VehicleCardAction.schedule, child: Text('Ver horario semanal')),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(status.cityName, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Icon(today.restricted ? Icons.block : Icons.check_circle, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(statusText, style: TextStyle(color: color, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            if (status.nextRestrictedDate != null && !today.restricted) ...[
              const SizedBox(height: 8),
              Text('Próxima restricción: ${status.nextRestrictedDate}', style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      ),
    );
  }
}
