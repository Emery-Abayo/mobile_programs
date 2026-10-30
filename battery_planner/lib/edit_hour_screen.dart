import 'package:flutter/material.dart';

import 'activity_style.dart';
import 'hour_slot.dart';

/// Screen 2: change what happens in one hour.
/// It receives the HourSlot from the day screen and pops back an edited copy.
class EditHourScreen extends StatefulWidget {
  final HourSlot slot;
  const EditHourScreen({super.key, required this.slot});

  @override
  State<EditHourScreen> createState() => _EditHourScreenState();
}

class _EditHourScreenState extends State<EditHourScreen> {
  late String _activity;
  late bool _charges;

  @override
  void initState() {
    super.initState();
    _activity = widget.slot.activity;
    _charges = widget.slot.charges;
  }

  bool get _changed =>
      _activity != widget.slot.activity || _charges != widget.slot.charges;

  // The hour's net effect, computed live from the current choices.
  int get _net =>
      -(drainPerHour[_activity] ?? 0) + (_charges ? chargeGain : 0);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final hour = widget.slot.hour;
    final netText = _net > 0 ? '+$_net%' : '$_net%';

    return Scaffold(
      appBar: AppBar(title: Text('Edit ${clock(hour)}')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${clock(hour)} to ${clock(hour + 1)}',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          const Text('What are you doing this hour?'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in activityNames)
                ChoiceChip(
                  avatar: Icon(iconFor(name), size: 18),
                  label: Text('${titleCase(name)}  -${drainPerHour[name]}%'),
                  selected: _activity == name,
                  onSelected: (_) => setState(() => _activity = name),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Phone is charging'),
            subtitle: const Text('Adds $chargeGain% this hour'),
            secondary: const Icon(Icons.bolt),
            value: _charges,
            onChanged: (value) => setState(() => _charges = value),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: scheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(iconFor(_activity), color: scheme.onPrimaryContainer),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Net change this hour: $netText',
                    style: TextStyle(
                      fontSize: 16,
                      color: scheme.onPrimaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Save'),
            onPressed: () => Navigator.pop(
              context,
              widget.slot.copyWith(activity: _activity, charges: _charges),
            ),
          ),
          const SizedBox(height: 8),
          // A way to fix mistakes before saving.
          TextButton.icon(
            icon: const Icon(Icons.undo),
            label: const Text('Undo my changes'),
            onPressed: _changed
                ? () => setState(() {
                      _activity = widget.slot.activity;
                      _charges = widget.slot.charges;
                    })
                : null,
          ),
        ],
      ),
    );
  }
}
