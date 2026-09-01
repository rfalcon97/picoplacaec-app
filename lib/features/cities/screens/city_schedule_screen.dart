import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_error.dart';
import '../state/cities_provider.dart';

const _weekdayOrder = ['MONDAY', 'TUESDAY', 'WEDNESDAY', 'THURSDAY', 'FRIDAY', 'SATURDAY', 'SUNDAY'];
const _weekdayLabels = {
  'MONDAY': 'Lunes',
  'TUESDAY': 'Martes',
  'WEDNESDAY': 'Miércoles',
  'THURSDAY': 'Jueves',
  'FRIDAY': 'Viernes',
  'SATURDAY': 'Sábado',
  'SUNDAY': 'Domingo',
};

class CityScheduleScreen extends ConsumerWidget {
  const CityScheduleScreen({super.key, required this.citySlug});

  final String citySlug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(cityScheduleProvider(citySlug));
    final todayWeekday = _weekdayOrder[DateTime.now().weekday - 1];

    return Scaffold(
      appBar: AppBar(title: const Text('Horario semanal')),
      body: scheduleAsync.when(
        data: (schedule) {
          final rulesByWeekday = {for (final rule in schedule.dayRules) rule.weekday: rule};
          final upcomingExceptions = schedule.dateExceptions
              .where((e) => DateTime.parse(e.date).isAfter(DateTime.now().subtract(const Duration(days: 1))))
              .toList()
            ..sort((a, b) => a.date.compareTo(b.date));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(schedule.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                schedule.allDay ? 'Restricción todo el día' : 'Restricción de ${schedule.timeStart} a ${schedule.timeEnd}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ..._weekdayOrder.map((weekday) {
                final digits = rulesByWeekday[weekday]?.digits ?? const <int>[];
                final isToday = weekday == todayWeekday;
                return Card(
                  color: isToday ? Theme.of(context).colorScheme.primaryContainer : null,
                  child: ListTile(
                    title: Text(_weekdayLabels[weekday]!, style: TextStyle(fontWeight: isToday ? FontWeight.bold : null)),
                    trailing: digits.isEmpty
                        ? const Text('Libre', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold))
                        : Text('No circulan: ${digits.join(', ')}', style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                  ),
                );
              }),
              if (upcomingExceptions.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text('Próximas excepciones', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...upcomingExceptions.map(
                  (exception) => Card(
                    child: ListTile(
                      leading: Icon(
                        exception.restrictionActive ? Icons.warning_amber : Icons.event_available,
                        color: exception.restrictionActive ? Colors.orange : Colors.green,
                      ),
                      title: Text(exception.reason),
                      subtitle: Text(
                        '${exception.date}: ${exception.restrictionActive ? "la restricción SÍ aplica" : "restricción suspendida"}',
                      ),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(extractErrorMessage(error))),
      ),
    );
  }
}
