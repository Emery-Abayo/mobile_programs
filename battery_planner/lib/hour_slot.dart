import 'package:cloud_firestore/cloud_firestore.dart';

// ---------------------------------------------------------------------------
// Battery Planner: the model and ALL the rules live here, outside any widget.
// Saved facts: hour, activity, charges.  Everything else (battery after each
// hour, banner, report, charging plan) is computed each time and never saved.
// ---------------------------------------------------------------------------

const int firstHour = 7;
const int lastHour = 23;
const int startBattery = 100;
const int chargeGain = 20;
const int lowBattery = 20; // the bar turns red below this

/// Battery drained by one hour of each activity.
const Map<String, int> drainPerHour = {
  'video': 12,
  'games': 15,
  'chat': 5,
  'music': 6,
  'idle': 2,
};

/// The order activities are offered in on the edit screen.
const List<String> activityNames = ['video', 'games', 'chat', 'music', 'idle'];

/// One hour of the day: what the user does and whether the phone is charging.
class HourSlot {
  final int hour;
  final String activity;
  final bool charges;

  const HourSlot({
    required this.hour,
    required this.activity,
    required this.charges,
  });

  Map<String, dynamic> toMap() => {
        'hour': hour,
        'activity': activity,
        'charges': charges,
      };

  factory HourSlot.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final savedActivity = data['activity'];
    return HourSlot(
      hour: (data['hour'] as num?)?.toInt() ?? firstHour,
      // An unknown activity name in the database is treated as idle.
      activity: drainPerHour.containsKey(savedActivity)
          ? savedActivity as String
          : 'idle',
      charges: data['charges'] == true,
    );
  }

  HourSlot copyWith({String? activity, bool? charges}) => HourSlot(
        hour: hour,
        activity: activity ?? this.activity,
        charges: charges ?? this.charges,
      );
}

/// The sample day: 17 hours, 7:00 to 23:00, with no charging.
/// Totals: video 6h, games 4h, chat 4h, idle 3h.
const List<String> sampleActivities = [
  'games', 'chat', 'video', 'games', 'chat', 'games', 'video', 'chat',
  'video', 'chat', 'video', 'games', 'video', 'idle', 'video', 'idle',
  'idle',
];

List<HourSlot> sampleDay() => List.generate(
      sampleActivities.length,
      (i) => HourSlot(
        hour: firstHour + i,
        activity: sampleActivities[i],
        charges: false,
      ),
    );

/// The result for one hour. battery is null once the phone is dead.
class HourResult {
  final HourSlot slot;
  final int? battery;
  const HourResult({required this.slot, required this.battery});
}

/// Rule: each hour subtract the drain, add 20 if charging, keep it in 0..100.
/// Clamping every hour (not only at the end) matters: a full battery cannot
/// store extra charge, and a dead phone cannot go below 0.
List<HourResult> simulate(List<HourSlot> slots) {
  final results = <HourResult>[];
  int battery = startBattery;
  bool dead = false;
  for (final slot in slots) {
    if (dead) {
      results.add(HourResult(slot: slot, battery: null));
      continue;
    }
    battery = battery - (drainPerHour[slot.activity] ?? 0);
    if (slot.charges) battery = battery + chargeGain;
    if (battery < 0) battery = 0;
    if (battery > 100) battery = 100;
    results.add(HourResult(slot: slot, battery: battery));
    if (battery == 0) dead = true;
  }
  return results;
}

/// The clock time when the phone dies (the end of the first hour at 0%),
/// or null if it survives the whole day.
int? deathHour(List<HourResult> results) {
  for (final r in results) {
    if (r.battery == 0) return r.slot.hour + 1;
  }
  return null;
}

String twoDigits(int n) => n.toString().padLeft(2, '0');

String clock(int hour) => '${twoDigits(hour)}:00';

/// The banner text shown at the top of the day screen.
String bannerText(List<HourResult> results) {
  if (results.isEmpty) return 'No hours yet';
  final death = deathHour(results);
  if (death != null) return 'Dies at ${clock(death)}';
  return 'Survives with ${results.last.battery}% left';
}

bool survives(List<HourSlot> slots) => deathHour(simulate(slots)) == null;

/// Total drain per activity over the whole day (hours x drain), highest first.
/// Activities that are never used are left out.
List<MapEntry<String, int>> activityTotals(List<HourSlot> slots) {
  final totals = <String, int>{};
  for (final slot in slots) {
    totals[slot.activity] =
        (totals[slot.activity] ?? 0) + (drainPerHour[slot.activity] ?? 0);
  }
  final list = totals.entries.toList();
  list.sort((a, b) => b.value.compareTo(a.value));
  return list;
}

/// The fewest charging hours that make the day survive.
/// Returns [] if no charging is needed and null if no plan can work.
/// It tries 0 hours, then 1, then 2 ... so the first answer is the smallest.
List<int>? findChargingPlan(List<HourSlot> slots) {
  final hours = slots.map((s) => s.hour).toList();
  for (int count = 0; count <= hours.length; count++) {
    final found = _tryCombinations(slots, hours, 0, count, <int>[]);
    if (found != null) return found;
  }
  return null;
}

List<int>? _tryCombinations(
  List<HourSlot> slots,
  List<int> hours,
  int start,
  int left,
  List<int> chosen,
) {
  if (left == 0) {
    final trial = slots
        .map((s) => s.copyWith(charges: chosen.contains(s.hour)))
        .toList();
    return survives(trial) ? List<int>.from(chosen) : null;
  }
  for (int i = start; i <= hours.length - left; i++) {
    chosen.add(hours[i]);
    final result = _tryCombinations(slots, hours, i + 1, left - 1, chosen);
    chosen.removeLast();
    if (result != null) return result;
  }
  return null;
}
