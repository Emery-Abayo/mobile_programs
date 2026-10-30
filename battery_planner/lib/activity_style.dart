import 'package:flutter/material.dart';

/// Icons for each activity, shared by all three screens.
const Map<String, IconData> activityIcons = {
  'video': Icons.smart_display,
  'games': Icons.sports_esports,
  'chat': Icons.chat_bubble,
  'music': Icons.music_note,
  'idle': Icons.bedtime,
};

IconData iconFor(String activity) => activityIcons[activity] ?? Icons.help;

String titleCase(String word) =>
    word.isEmpty ? word : word[0].toUpperCase() + word.substring(1);
