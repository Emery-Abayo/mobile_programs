import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'activity_style.dart';
import 'day_data.dart';
import 'edit_hour_screen.dart';
import 'hour_slot.dart';
import 'report_screen.dart';

/// Screen 1: the whole day, read live from Firestore.
/// Only hour/activity/charges are stored; the battery numbers, the banner and
/// the plan are recomputed from them every time the data changes.
class DayScreen extends StatelessWidget {
  const DayScreen({super.key});

  void _say(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _edit(BuildContext context, HourSlot slot) async {
    final updated = await Navigator.push<HourSlot>(
      context,
      MaterialPageRoute(builder: (_) => EditHourScreen(slot: slot)),
    );
    if (updated == null) return; // user went back without saving
    try {
      await saveSlot(updated);
      if (context.mounted) _say(context, 'Saved ${clock(updated.hour)}');
    } catch (e) {
      if (context.mounted) _say(context, 'Could not save. Check your connection.');
    }
  }

  Future<void> _applyPlan(BuildContext context, List<HourSlot> slots) async {
    final plan = findChargingPlan(slots);
    if (plan == null) {
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('No plan works'),
          content: const Text(
              'Even charging every hour, this day cannot survive. Try changing some activities.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return;
    }
    if (plan.isEmpty) {
      _say(context, 'No charging needed. This day already survives.');
      return;
    }
    final hoursText = plan.map(clock).join(', ');
    final apply = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Charge for ${plan.length} hours'),
        content: Text('The fewest charging hours that survive the day:\n\n$hoursText'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Apply plan'),
          ),
        ],
      ),
    );
    if (apply != true) return;
    try {
      final batch = FirebaseFirestore.instance.batch();
      final col = myHours();
      for (final slot in slots) {
        batch.set(col.doc('${slot.hour}'),
            slot.copyWith(charges: plan.contains(slot.hour)).toMap());
      }
      await batch.commit();
      if (context.mounted) _say(context, 'Plan applied');
    } catch (e) {
      if (context.mounted) _say(context, 'Could not apply the plan.');
    }
  }

  Future<void> _reset(BuildContext context) async {
    final sure = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Are you sure?'),
        content: const Text(
            'This brings back the sample day with no charging. Your changes will be lost.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (sure != true) return;
    try {
      await writeSampleDay();
      if (context.mounted) _say(context, 'Sample day restored');
    } catch (e) {
      if (context.mounted) _say(context, 'Could not reset. Check your connection.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: myHours().orderBy('hour').snapshots(),
      builder: (context, snapshot) {
        // No blank screens: loading, error and empty each get a message.
        if (snapshot.hasError) {
          return Scaffold(
            appBar: _appBar(context, null),
            body: const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Could not load your day. Check your connection and the Firestore rules.',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }
        if (!snapshot.hasData) {
          return Scaffold(
            appBar: _appBar(context, null),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final slots =
            snapshot.data!.docs.map((doc) => HourSlot.fromDoc(doc)).toList();

        if (slots.isEmpty) {
          return Scaffold(
            appBar: _appBar(context, null),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.battery_unknown, size: 64),
                  const SizedBox(height: 12),
                  const Text('Your day is empty.'),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: () => _reset(context),
                    child: const Text('Load the sample day'),
                  ),
                ],
              ),
            ),
          );
        }

        final results = simulate(slots);
        final dies = deathHour(results) != null;
        final scheme = Theme.of(context).colorScheme;

        return Scaffold(
          appBar: _appBar(context, slots),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: dies ? scheme.errorContainer : scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Icon(
                      dies ? Icons.battery_alert : Icons.battery_full,
                      color: dies
                          ? scheme.onErrorContainer
                          : scheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      bannerText(results),
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: dies
                            ? scheme.onErrorContainer
                            : scheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) =>
                      _hourTile(context, results[index]),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          icon: const Icon(Icons.auto_fix_high),
                          label: const Text('Find a charging plan'),
                          onPressed: () => _applyPlan(context, slots),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.restart_alt),
                        label: const Text('Reset'),
                        onPressed: () => _reset(context),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  AppBar _appBar(BuildContext context, List<HourSlot>? slots) {
    return AppBar(
      title: const Text('VoltDay'),
      actions: [
        if (slots != null)
          IconButton(
            tooltip: 'Report',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ReportScreen(slots: slots)),
            ),
          ),
        IconButton(
          tooltip: 'Log out',
          icon: const Icon(Icons.logout),
          onPressed: () => FirebaseAuth.instance.signOut(),
        ),
      ],
    );
  }

  Widget _hourTile(BuildContext context, HourResult result) {
    final slot = result.slot;
    final battery = result.battery;
    final scheme = Theme.of(context).colorScheme;
    final isDead = battery == null;
    final isLow = battery != null && battery < lowBattery;
    final barColor = isLow ? Colors.red : scheme.primary;

    return ListTile(
      onTap: () => _edit(context, slot),
      leading: SizedBox(
        width: 44,
        child: Text(
          clock(slot.hour),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      title: Row(
        children: [
          Icon(iconFor(slot.activity), size: 18),
          const SizedBox(width: 6),
          Text(titleCase(slot.activity)),
          if (slot.charges) ...[
            const SizedBox(width: 8),
            Icon(Icons.bolt, size: 18, color: Colors.amber.shade700),
          ],
        ],
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 6),
        child: battery == null
            ? Text('Dead', style: TextStyle(color: scheme.error))
            : ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: battery / 100,
                  minHeight: 8,
                  color: barColor,
                ),
              ),
      ),
      trailing: SizedBox(
        width: 44,
        child: Text(
          isDead ? '' : '$battery%',
          textAlign: TextAlign.end,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isLow ? Colors.red : null,
          ),
        ),
      ),
    );
  }
}
