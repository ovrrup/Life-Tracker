// lib/core/models/models.dart
import 'package:flutter/material.dart';

// ─── HABIT ────────────────────────────────────────────────────────────────────
class Habit {
  final String id;
  final String userId;
  final String name;
  final String colorHex;
  final List<int> activeDays; // 0=Mon … 6=Sun
  final bool isActive;
  final DateTime createdAt;
  int currentStreak;
  int longestStreak;

  Habit({
    required this.id,
    required this.userId,
    required this.name,
    required this.colorHex,
    required this.activeDays,
    this.isActive = true,
    required this.createdAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  Color get color => Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
    id:             j['id'] as String,
    userId:         j['user_id'] as String,
    name:           j['name'] as String,
    colorHex:       j['color_hex'] as String? ?? '#3ECFCA',
    activeDays:     List<int>.from(j['active_days'] ?? [0,1,2,3,4,5,6]),
    isActive:       j['is_active'] as bool? ?? true,
    createdAt:      DateTime.parse(j['created_at'] as String),
    currentStreak:  j['current_streak'] as int? ?? 0,
    longestStreak:  j['longest_streak'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id':             id,
    'user_id':        userId,
    'name':           name,
    'color_hex':      colorHex,
    'active_days':    activeDays,
    'is_active':      isActive,
    'created_at':     createdAt.toIso8601String(),
    'current_streak': currentStreak,
    'longest_streak': longestStreak,
  };

  Habit copyWith({String? name, String? colorHex, List<int>? activeDays, bool? isActive, int? currentStreak, int? longestStreak}) => Habit(
    id: id, userId: userId,
    name:           name ?? this.name,
    colorHex:       colorHex ?? this.colorHex,
    activeDays:     activeDays ?? this.activeDays,
    isActive:       isActive ?? this.isActive,
    createdAt:      createdAt,
    currentStreak:  currentStreak ?? this.currentStreak,
    longestStreak:  longestStreak ?? this.longestStreak,
  );
}

// ─── HABIT LOG ────────────────────────────────────────────────────────────────
class HabitLog {
  final String id;
  final String habitId;
  final String userId;
  final DateTime date;
  final bool completed;

  HabitLog({
    required this.id,
    required this.habitId,
    required this.userId,
    required this.date,
    required this.completed,
  });

  factory HabitLog.fromJson(Map<String, dynamic> j) => HabitLog(
    id:        j['id'] as String,
    habitId:   j['habit_id'] as String,
    userId:    j['user_id'] as String,
    date:      DateTime.parse(j['date'] as String),
    completed: j['completed'] as bool? ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'habit_id': habitId, 'user_id': userId,
    'date': date.toIso8601String().split('T')[0],
    'completed': completed,
  };
}

// ─── TASK ─────────────────────────────────────────────────────────────────────
enum TaskPriority { high, medium, low }

class Task {
  final String id;
  final String userId;
  String title;
  String? notes;
  bool isDone;
  TaskPriority priority;
  DateTime date;
  DateTime? dueTime;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.notes,
    this.isDone = false,
    this.priority = TaskPriority.medium,
    required this.date,
    this.dueTime,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id:        j['id'] as String,
    userId:    j['user_id'] as String,
    title:     j['title'] as String,
    notes:     j['notes'] as String?,
    isDone:    j['is_done'] as bool? ?? false,
    priority:  TaskPriority.values.firstWhere(
      (e) => e.name == (j['priority'] as String? ?? 'medium'),
      orElse: () => TaskPriority.medium,
    ),
    date:      DateTime.parse(j['date'] as String),
    dueTime:   j['due_time'] != null ? DateTime.parse(j['due_time'] as String) : null,
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'title': title, 'notes': notes,
    'is_done': isDone, 'priority': priority.name,
    'date': date.toIso8601String().split('T')[0],
    'due_time': dueTime?.toIso8601String(),
    'created_at': createdAt.toIso8601String(),
  };

  Task copyWith({String? title, String? notes, bool? isDone, TaskPriority? priority, DateTime? date}) => Task(
    id: id, userId: userId, createdAt: createdAt,
    title:    title    ?? this.title,
    notes:    notes    ?? this.notes,
    isDone:   isDone   ?? this.isDone,
    priority: priority ?? this.priority,
    date:     date     ?? this.date,
  );
}

// ─── MOOD ENTRY ───────────────────────────────────────────────────────────────
enum MoodLevel { terrible, bad, neutral, good, great }

extension MoodLevelX on MoodLevel {
  String get label => ['Terrible','Bad','Neutral','Good','Great'][index];
  int get value => index + 1;
}

class MoodEntry {
  final String id;
  final String userId;
  final MoodLevel level;
  final String? note;
  final List<String> tags;
  final DateTime date;
  final DateTime createdAt;

  MoodEntry({
    required this.id,
    required this.userId,
    required this.level,
    this.note,
    this.tags = const [],
    required this.date,
    required this.createdAt,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> j) => MoodEntry(
    id:        j['id'] as String,
    userId:    j['user_id'] as String,
    level:     MoodLevel.values.firstWhere(
      (e) => e.name == (j['level'] as String? ?? 'neutral'),
      orElse: () => MoodLevel.neutral,
    ),
    note:      j['note'] as String?,
    tags:      List<String>.from(j['tags'] ?? []),
    date:      DateTime.parse(j['date'] as String),
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'level': level.name, 'note': note,
    'tags': tags,
    'date': date.toIso8601String().split('T')[0],
    'created_at': createdAt.toIso8601String(),
  };
}

// ─── JOURNAL ENTRY ────────────────────────────────────────────────────────────
class JournalEntry {
  final String id;
  final String userId;
  String title;
  String content;
  final DateTime date;
  final DateTime createdAt;
  DateTime updatedAt;
  int wordCount;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  }) : wordCount = content.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
    id:        j['id'] as String,
    userId:    j['user_id'] as String,
    title:     j['title'] as String? ?? 'Untitled',
    content:   j['content'] as String? ?? '',
    date:      DateTime.parse(j['date'] as String),
    createdAt: DateTime.parse(j['created_at'] as String),
    updatedAt: DateTime.parse(j['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'title': title, 'content': content,
    'date': date.toIso8601String().split('T')[0],
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

// ─── GOAL ─────────────────────────────────────────────────────────────────────
enum GoalUnit { count, percentage, pages, km, kg, hours, dollars, custom }

class Goal {
  final String id;
  final String userId;
  String name;
  double current;
  double target;
  GoalUnit unit;
  String? customUnit;
  String colorHex;
  final DateTime createdAt;
  DateTime? deadline;

  Goal({
    required this.id,
    required this.userId,
    required this.name,
    required this.current,
    required this.target,
    required this.unit,
    this.customUnit,
    required this.colorHex,
    required this.createdAt,
    this.deadline,
  });

  double get percentage => target > 0 ? (current / target).clamp(0.0, 1.0) : 0;
  Color get color => Color(int.parse(colorHex.replaceFirst('#', '0xFF')));
  String get unitLabel => unit == GoalUnit.custom ? (customUnit ?? '') : unit.name;

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
    id:         j['id'] as String,
    userId:     j['user_id'] as String,
    name:       j['name'] as String,
    current:    (j['current'] as num?)?.toDouble() ?? 0,
    target:     (j['target'] as num?)?.toDouble() ?? 100,
    unit:       GoalUnit.values.firstWhere((e) => e.name == (j['unit'] as String? ?? 'count'), orElse: () => GoalUnit.count),
    customUnit: j['custom_unit'] as String?,
    colorHex:   j['color_hex'] as String? ?? '#3ECFCA',
    createdAt:  DateTime.parse(j['created_at'] as String),
    deadline:   j['deadline'] != null ? DateTime.parse(j['deadline'] as String) : null,
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'user_id': userId, 'name': name,
    'current': current, 'target': target, 'unit': unit.name,
    'custom_unit': customUnit, 'color_hex': colorHex,
    'created_at': createdAt.toIso8601String(),
    'deadline': deadline?.toIso8601String(),
  };

  Goal copyWith({String? name, double? current, double? target, String? colorHex}) => Goal(
    id: id, userId: userId, unit: unit, customUnit: customUnit,
    createdAt: createdAt, deadline: deadline,
    name:     name     ?? this.name,
    current:  current  ?? this.current,
    target:   target   ?? this.target,
    colorHex: colorHex ?? this.colorHex,
  );
}

// ─── APP USER ─────────────────────────────────────────────────────────────────
class AppUser {
  final String id;
  final String email;
  String displayName;
  String? avatarUrl;
  final DateTime createdAt;
  int totalStreak;
  List<String> friendIds;

  AppUser({
    required this.id,
    required this.email,
    required this.displayName,
    this.avatarUrl,
    required this.createdAt,
    this.totalStreak = 0,
    this.friendIds = const [],
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id:           j['id'] as String,
    email:        j['email'] as String? ?? '',
    displayName:  j['display_name'] as String? ?? 'User',
    avatarUrl:    j['avatar_url'] as String?,
    createdAt:    DateTime.parse(j['created_at'] as String),
    totalStreak:  j['total_streak'] as int? ?? 0,
    friendIds:    List<String>.from(j['friend_ids'] ?? []),
  );

  Map<String, dynamic> toJson() => {
    'id': id, 'email': email, 'display_name': displayName,
    'avatar_url': avatarUrl, 'created_at': createdAt.toIso8601String(),
    'total_streak': totalStreak, 'friend_ids': friendIds,
  };
}

// ─── FRIEND ACTIVITY ──────────────────────────────────────────────────────────
class FriendActivity {
  final String userId;
  final String userName;
  final String? avatarUrl;
  final String action;     // e.g. "completed habit", "reached goal"
  final String subject;    // name of habit/goal
  final DateTime time;

  FriendActivity({
    required this.userId,
    required this.userName,
    this.avatarUrl,
    required this.action,
    required this.subject,
    required this.time,
  });

  factory FriendActivity.fromJson(Map<String, dynamic> j) => FriendActivity(
    userId:    j['user_id'] as String,
    userName:  j['user_name'] as String,
    avatarUrl: j['avatar_url'] as String?,
    action:    j['action'] as String,
    subject:   j['subject'] as String,
    time:      DateTime.parse(j['time'] as String),
  );
}

// ─── INSIGHT ──────────────────────────────────────────────────────────────────
class InsightCard {
  final String title;
  final String description;
  final InsightType type;
  final double value;
  final String unit;

  const InsightCard({
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.unit,
  });
}

enum InsightType { positive, neutral, warning }
