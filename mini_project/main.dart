import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(MaterialApp(
    title: 'Battery Planner',
    theme: ThemeData(primarySwatch: Colors.teal),
    home: DayScreen(),
  ));
}

const drain = {'video': 12, 'games': 15, 'chat': 5, 'music': 6, 'idle': 2};

// Stand-in: replace with your Lab 11 day (17 activities, 7:00 to 23:00).
const sample = [
  'games', 'games', 'video', 'chat', 'games', 'video', 'chat', 'video',
  'idle', 'chat', 'video', 'games', 'video', 'video', 'chat', 'idle', 'idle',
];

class Hour {
  Hour(this.hour, this.activity, this.charging);
  final int hour;
  String activity;
  bool charging;
}

List<Hour> sampleDay() {
  List<Hour> day = [];
  for (int i = 0; i < sample.length; i++) {
    day.add(Hour(7 + i, sample[i], false));
  }
  return day;
}

// Battery after each hour; null = dead.
List<int?> simulate(List<Hour> day) {
  List<int?> out = [];
  int battery = 100;
  bool dead = false;
  for (final h in day) {
    if (dead) {
      out.add(null);
      continue;
    }
    battery = battery - (drain[h.activity] ?? 0);
    if (h.charging) battery = battery + 20;
    if (battery > 100) battery = 100;
    if (battery < 0) battery = 0;
    if (battery == 0) dead = true;
    out.add(battery);
  }
  return out;
}

class DayScreen extends StatefulWidget {
  @override
  _DayScreenState createState() => _DayScreenState();
}

class _DayScreenState extends State<DayScreen> {
  List<Hour> day = sampleDay();
  String tempText = 'Loading...';
  bool failed = false;

  @override
  void initState() {
    super.initState();
    load();
    fetchTemp();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList('day');
    if (saved == null || saved.length != sample.length) return;
    List<Hour> loaded = [];
    for (int i = 0; i < saved.length; i++) {
      final parts = saved[i].split(':');
      loaded.add(Hour(7 + i, parts[0], parts[1] == 'true'));
    }
    setState(() {
      day = loaded;
    });
  }

  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        'day', day.map((h) => '${h.activity}:${h.charging}').toList());
  }

  Future<void> fetchTemp() async {
    setState(() {
      tempText = 'Loading...';
      failed = false;
    });
    try {
      final r = await http
          .get(Uri.parse(
              'https://api.open-meteo.com/v1/forecast?latitude=-1.94&longitude=30.06&current=temperature_2m'))
          .timeout(Duration(seconds: 8));
      final t = jsonDecode(r.body)['current']['temperature_2m'];
      setState(() {
        tempText = 'Kigali now: $t°C';
      });
    } catch (e) {
      setState(() {
        tempText = 'No internet. Could not load the temperature.';
        failed = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final levels = simulate(day);
    final death = levels.indexOf(0);
    return Scaffold(
      appBar: AppBar(title: Text('Battery Planner')),
      body: Column(
        children: [
          ListTile(
            leading: Icon(Icons.thermostat),
            title: Text(tempText),
            trailing: failed
                ? ElevatedButton(onPressed: fetchTemp, child: Text('Retry'))
                : null,
          ),
          Container(
            width: double.infinity,
            margin: EdgeInsets.symmetric(horizontal: 12),
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: death >= 0 ? Colors.red : Colors.green,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              death >= 0
                  ? '☠ Dies at ${day[death].hour}:00'
                  : 'Survives with ${levels.last}% left',
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: day.length,
              itemBuilder: (context, i) {
                final h = day[i];
                final level = levels[i];
                return ListTile(
                  leading: Text('${h.hour}:00'),
                  title: Text(h.activity),
                  subtitle: level == null
                      ? Text('Dead')
                      : LinearProgressIndicator(
                          value: level / 100,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              level < 20 ? Colors.red : Colors.teal),
                        ),
                  trailing: Text(level == null
                      ? '—'
                      : '${h.charging ? '⚡ ' : ''}$level%'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => EditScreen(h)),
                    ).then((_) {
                      setState(() {});
                      save();
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EditScreen extends StatefulWidget {
  final Hour h;
  EditScreen(this.h);

  @override
  _EditScreenState createState() => _EditScreenState();
}

class _EditScreenState extends State<EditScreen> {
  String activity = '';
  bool charging = false;

  @override
  void initState() {
    super.initState();
    activity = widget.h.activity;
    charging = widget.h.charging;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit ${widget.h.hour}:00')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 8,
              children: drain.keys.map((a) {
                return ChoiceChip(
                  label: Text(a),
                  selected: activity == a,
                  onSelected: (_) {
                    setState(() {
                      activity = a;
                    });
                  },
                );
              }).toList(),
            ),
            SwitchListTile(
              title: Text('Charging (+20%)'),
              value: charging,
              onChanged: (v) {
                setState(() {
                  charging = v;
                });
              },
            ),
            ElevatedButton(
              onPressed: () {
                widget.h.activity = activity;
                widget.h.charging = charging;
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        ),
      ),
    );
  }
}
