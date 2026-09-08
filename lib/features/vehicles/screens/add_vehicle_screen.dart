import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_error.dart';
import '../../ads/banner_ad_widget.dart';
import '../../cities/state/cities_provider.dart';
import '../state/vehicles_provider.dart';

const _defaultReminderTime = TimeOfDay(hour: 20, minute: 0);

String _formatTimeOfDay(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay _parseReminderTime(String value) {
  final parts = value.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

/// Data needed to prefill the form when editing an existing vehicle. Passed
/// via go_router's `extra` from wherever "editar" is tapped.
class VehicleEditArgs {
  const VehicleEditArgs({
    required this.id,
    required this.nickname,
    required this.plateDigit,
    required this.cityId,
    required this.reminderTime,
  });

  final String id;
  final String nickname;
  final int plateDigit;
  final String cityId;
  final String reminderTime;
}

class AddVehicleScreen extends ConsumerStatefulWidget {
  const AddVehicleScreen({super.key, this.editArgs});

  final VehicleEditArgs? editArgs;

  bool get isEditing => editArgs != null;

  @override
  ConsumerState<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends ConsumerState<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nicknameController;
  int? _plateDigit;
  String? _cityId;
  late TimeOfDay _reminderTime;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final args = widget.editArgs;
    _nicknameController = TextEditingController(text: args?.nickname);
    _plateDigit = args?.plateDigit;
    _cityId = args?.cityId;
    _reminderTime = args != null ? _parseReminderTime(args.reminderTime) : _defaultReminderTime;
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickReminderTime() async {
    final picked = await showTimePicker(context: context, initialTime: _reminderTime);
    if (picked != null) setState(() => _reminderTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _plateDigit == null || _cityId == null) {
      if (_plateDigit == null || _cityId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Completa el dígito de placa y la ciudad')),
        );
      }
      return;
    }

    setState(() => _submitting = true);
    try {
      final repo = ref.read(vehiclesRepositoryProvider);
      final reminderTime = _formatTimeOfDay(_reminderTime);
      if (widget.isEditing) {
        await repo.updateVehicle(
          id: widget.editArgs!.id,
          nickname: _nicknameController.text.trim(),
          plateDigit: _plateDigit!,
          cityId: _cityId!,
          reminderTime: reminderTime,
        );
      } else {
        await repo.createVehicle(
          nickname: _nicknameController.text.trim(),
          plateDigit: _plateDigit!,
          cityId: _cityId!,
          reminderTime: reminderTime,
        );
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar vehículo'),
        content: Text('¿Seguro que quieres eliminar "${widget.editArgs!.nickname}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      await ref.read(vehiclesRepositoryProvider).deleteVehicle(widget.editArgs!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(extractErrorMessage(error))));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final citiesAsync = ref.watch(citiesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isEditing ? 'Editar vehículo' : 'Agregar vehículo'),
        actions: [
          if (widget.isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Eliminar vehículo',
              onPressed: _submitting ? null : _delete,
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nicknameController,
                decoration: const InputDecoration(labelText: 'Apodo (ej. "Mi carro")'),
                validator: (value) => (value == null || value.trim().isEmpty) ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int>(
                initialValue: _plateDigit,
                decoration: const InputDecoration(labelText: 'Último dígito de la placa'),
                items: List.generate(10, (i) => i).map((digit) => DropdownMenuItem(value: digit, child: Text('$digit'))).toList(),
                onChanged: (value) => setState(() => _plateDigit = value),
              ),
              const SizedBox(height: 16),
              citiesAsync.when(
                data: (cities) => DropdownButtonFormField<String>(
                  initialValue: _cityId,
                  decoration: const InputDecoration(labelText: 'Ciudad'),
                  items: cities.map((city) => DropdownMenuItem(value: city.id, child: Text(city.name))).toList(),
                  onChanged: (value) => setState(() => _cityId = value),
                ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Text(extractErrorMessage(error)),
              ),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Hora del aviso el mismo día'),
                subtitle: const Text(
                  'El día de la restricción, a esta hora. También recibes un aviso fijo la noche anterior (6:00 pm).',
                ),
                trailing: TextButton(
                  onPressed: _pickReminderTime,
                  child: Text(_reminderTime.format(context), style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(widget.isEditing ? 'Guardar cambios' : 'Guardar'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const BannerAdWidget(),
    );
  }
}
