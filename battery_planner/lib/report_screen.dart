import 'package:flutter/material.dart';

import 'activity_style.dart';
import 'hour_slot.dart';

/// Screen 3: which activity eats the most battery.
/// It receives the day's hours from the day screen and computes the ranking.
class ReportScreen extends StatelessWidget {
  final List<HourSlot> slots;
  const ReportScreen({super.key, required this.slots});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totals = activityTotals(slots);

    return Scaffold(
      appBar: AppBar(title: const Text('Battery report')),
      body: totals.isEmpty
          ? const Center(child: Text('No hours to report on yet.'))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: scheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Icon(iconFor(totals.first.key),
                          size: 32, color: scheme.onTertiaryContainer),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Hungriest: ${titleCase(totals.first.key)} '
                          '(${totals.first.value}% of the battery)',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: scheme.onTertiaryContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text('Total drain by activity',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                for (final entry in totals)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Row(
                      children: [
                        Icon(iconFor(entry.key)),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 64,
                          child: Text(titleCase(entry.key)),
                        ),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              minHeight: 12,
                              value: entry.value / totals.first.value,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        SizedBox(
                          width: 44,
                          child: Text('${entry.value}%',
                              textAlign: TextAlign.end),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }
}
