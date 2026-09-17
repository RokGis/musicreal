import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'lat_lng.dart';
import 'place.dart';
import 'uploaded_file.dart';
import '/backend/backend.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '/auth/firebase_auth/auth_util.dart';

DateTime? oneDayAgoreal() {
  return DateTime.now().subtract(Duration(days: 2));
}

DateTime startOfDay(DateTime date) {
  return DateTime(date.year, date.month, date.day);
}

DateTime newCustomFunction(DateTime targetDate) {
  return DateTime(targetDate.year, targetDate.month, targetDate.day, 22, 0, 0);
}

dynamic countEmojiFrequency(List<UserPostRecord> posts) {
  final Map<String, int> emojiCount = {};

  for (final post in posts) {
    final emoji = post.emoji;
    if (emoji != null && emoji.isNotEmpty) {
      emojiCount[emoji] = (emojiCount[emoji] ?? 0) + 1;
    }
  }

  final sorted = Map.fromEntries(
    emojiCount.entries.toList()..sort((a, b) => b.value.compareTo(a.value)),
  );

  return sorted;
}
