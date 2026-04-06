// lib/core/models/models.dart
import 'package:flutter/material.dart';

// ─── POINTS SYSTEM ────────────────────────────────────────────────────────────

/// Points awarded per action. These mirror the DB constants in supabase_service.
class LTPoints {
  LTPoints._();
  // Tasks
  static const int taskHigh   = 30;
  static const int taskMedium = 15;
  static const int taskLow    = 5;
  // Habits
  static const int habitComplete = 10;
  static const int habitStreak7  = 25;  // bonus at 7-day streak
  static const int habitStreak30 = 100; // bonus at 30-day streak

  static int forTask(TaskPriority p) => switch (p) {
    TaskPriority.high   => taskHigh,
    TaskPriority.medium => taskMedium,
    TaskPriority.low    => taskLow,
  };
}

// ─── HABIT ────────────────────────────────────────────────────────────────────

class Habit {
  final String    id;
  final String    userId;
  final String    name;
  final String    colorHex;
  final List<int> activeDays;
  final bool      isActive;
  final int       sortOrder;
  final DateTime  createdAt;
  final int       currentStreak;
  final int       longestStreak;

  const Habit({
    required this.id,
    required this.userId,
    required this.name,
    required this.colorHex,
    required this.activeDays,
    this.isActive      = true,
    this.sortOrder     = 0,
    required this.createdAt,
    this.currentStreak = 0,
    this.longestStreak = 0,
  });

  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  factory Habit.fromJson(Map<String, dynamic> j) => Habit(
    id:            j['id']             as String,
    userId:        j['user_id']        as String,
    name:          j['name']           as String,
    colorHex:      j['color_hex']      as String?  ?? '#3ECFCA',
    activeDays:    List<int>.from(j['active_days'] ?? [0,1,2,3,4,5,6]),
    isActive:      j['is_active']      as bool?    ?? true,
    sortOrder:     j['sort_order']     as int?     ?? 0,
    createdAt:     DateTime.parse(j['created_at'] as String),
    currentStreak: j['current_streak'] as int?     ?? 0,
    longestStreak: j['longest_streak'] as int?     ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id':          id,
    'user_id':     userId,
    'name':        name,
    'color_hex':   colorHex,
    'active_days': activeDays,
    'is_active':   isActive,
    'sort_order':  sortOrder,
    'created_at':  createdAt.toIso8601String(),
  };

  Habit copyWith({
    String?    name,
    String?    colorHex,
    List<int>? activeDays,
    bool?      isActive,
    int?       sortOrder,
  }) => Habit(
    id:            id,
    userId:        userId,
    createdAt:     createdAt,
    currentStreak: currentStreak,
    longestStreak: longestStreak,
    name:          name       ?? this.name,
    colorHex:      colorHex   ?? this.colorHex,
    activeDays:    activeDays ?? this.activeDays,
    isActive:      isActive   ?? this.isActive,
    sortOrder:     sortOrder  ?? this.sortOrder,
  );
}

// ─── TASK ─────────────────────────────────────────────────────────────────────

enum TaskPriority { high, medium, low }

class Task {
  final String      id;
  final String      userId;
  String            title;
  String?           notes;
  bool              isDone;
  TaskPriority      priority;
  DateTime          date;
  DateTime?         dueTime;
  DateTime?         completedAt;
  final DateTime    createdAt;

  Task({
    required this.id,
    required this.userId,
    required this.title,
    this.notes,
    this.isDone      = false,
    this.priority    = TaskPriority.medium,
    required this.date,
    this.dueTime,
    this.completedAt,
    required this.createdAt,
  });

  factory Task.fromJson(Map<String, dynamic> j) => Task(
    id:          j['id']      as String,
    userId:      j['user_id'] as String,
    title:       j['title']   as String,
    notes:       j['notes']   as String?,
    isDone:      j['is_done'] as bool?   ?? false,
    priority:    TaskPriority.values.firstWhere(
      (e) => e.name == (j['priority'] as String? ?? 'medium'),
      orElse: () => TaskPriority.medium,
    ),
    date:        DateTime.parse(j['date'] as String),
    dueTime:     j['due_time']     != null ? DateTime.parse(j['due_time']     as String) : null,
    completedAt: j['completed_at'] != null ? DateTime.parse(j['completed_at'] as String) : null,
    createdAt:   DateTime.parse(j['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id':           id,
    'user_id':      userId,
    'title':        title,
    'notes':        notes,
    'is_done':      isDone,
    'priority':     priority.name,
    'date':         date.toIso8601String().split('T')[0],
    'due_time':     dueTime?.toIso8601String(),
    'completed_at': completedAt?.toIso8601String(),
    'created_at':   createdAt.toIso8601String(),
  };

  Task copyWith({
    String?       title,
    String?       notes,
    bool?         isDone,
    TaskPriority? priority,
    DateTime?     date,
    DateTime?     completedAt,
  }) => Task(
    id:          id,
    userId:      userId,
    createdAt:   createdAt,
    dueTime:     dueTime,
    title:       title       ?? this.title,
    notes:       notes       ?? this.notes,
    isDone:      isDone      ?? this.isDone,
    priority:    priority    ?? this.priority,
    date:        date        ?? this.date,
    completedAt: completedAt ?? this.completedAt,
  );
}

// ─── MOOD ─────────────────────────────────────────────────────────────────────

enum MoodLevel { terrible, bad, neutral, good, great }

extension MoodLevelX on MoodLevel {
  String get label => const ['Terrible','Bad','Neutral','Good','Great'][index];
  int    get score => index + 1;
  Color  get color => const [
    Color(0xFFD95F5F),
    Color(0xFFC8A84C),
    Color(0xFF888888),
    Color(0xFF4DB87A),
    Color(0xFF3ECFCA),
  ][index];
}

class MoodEntry {
  final String       id;
  final String       userId;
  final MoodLevel    level;
  final String?      note;
  final List<String> tags;
  final DateTime     date;
  final DateTime     createdAt;

  MoodEntry({
    required this.id,
    required this.userId,
    required this.level,
    this.note,
    this.tags     = const [],
    required this.date,
    required this.createdAt,
  });

  factory MoodEntry.fromJson(Map<String, dynamic> j) => MoodEntry(
    id:        j['id']      as String,
    userId:    j['user_id'] as String,
    level:     MoodLevel.values.firstWhere(
      (e) => e.name == (j['level'] as String? ?? 'neutral'),
      orElse: () => MoodLevel.neutral,
    ),
    note:      j['note']    as String?,
    tags:      List<String>.from(j['tags'] ?? []),
    date:      DateTime.parse(j['date']       as String),
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id':         id,
    'user_id':    userId,
    'level':      level.name,
    'note':       note,
    'tags':       tags,
    'date':       date.toIso8601String().split('T')[0],
    'created_at': createdAt.toIso8601String(),
  };

  MoodEntry copyWith({MoodLevel? level, String? note, List<String>? tags}) => MoodEntry(
    id:        id,
    userId:    userId,
    date:      date,
    createdAt: createdAt,
    level:     level ?? this.level,
    note:      note  ?? this.note,
    tags:      tags  ?? this.tags,
  );
}

// ─── JOURNAL ──────────────────────────────────────────────────────────────────

class JournalEntry {
  final String   id;
  final String   userId;
  String         title;
  String         content;
  final DateTime date;
  final DateTime createdAt;
  DateTime       updatedAt;

  int get wordCount => content.trim().isEmpty
      ? 0
      : content.trim().split(RegExp(r'\s+')).length;

  JournalEntry({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
  });

  factory JournalEntry.fromJson(Map<String, dynamic> j) => JournalEntry(
    id:        j['id']         as String,
    userId:    j['user_id']    as String,
    title:     j['title']      as String? ?? 'Untitled',
    content:   j['content']    as String? ?? '',
    date:      DateTime.parse(j['date']       as String),
    createdAt: DateTime.parse(j['created_at'] as String),
    updatedAt: DateTime.parse(j['updated_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id':         id,
    'user_id':    userId,
    'title':      title,
    'content':    content,
    'date':       date.toIso8601String().split('T')[0],
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}

// ─── GOAL ─────────────────────────────────────────────────────────────────────

class Goal {
  final String   id;
  final String   userId;
  String         name;
  double         currentVal;
  double         targetVal;
  String         unit;
  String         colorHex;
  DateTime?      deadline;
  bool           isCompleted;
  final DateTime createdAt;

  Goal({
    required this.id,
    required this.userId,
    required this.name,
    required this.currentVal,
    required this.targetVal,
    required this.unit,
    required this.colorHex,
    this.deadline,
    this.isCompleted = false,
    required this.createdAt,
  });

  double get percentage => targetVal > 0
      ? (currentVal / targetVal).clamp(0.0, 1.0)
      : 0.0;

  Color get color {
    final hex = colorHex.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  factory Goal.fromJson(Map<String, dynamic> j) => Goal(
    id:          j['id']          as String,
    userId:      j['user_id']     as String,
    name:        j['name']        as String,
    currentVal:  (j['current_val'] as num?)?.toDouble() ?? 0.0,
    targetVal:   (j['target_val']  as num?)?.toDouble() ?? 100.0,
    unit:        j['unit']        as String? ?? 'count',
    colorHex:    j['color_hex']   as String? ?? '#3ECFCA',
    deadline:    j['deadline']    != null ? DateTime.parse(j['deadline'] as String) : null,
    isCompleted: j['is_completed'] as bool?  ?? false,
    createdAt:   DateTime.parse(j['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id':           id,
    'user_id':      userId,
    'name':         name,
    'current_val':  currentVal,
    'target_val':   targetVal,
    'unit':         unit,
    'color_hex':    colorHex,
    'deadline':     deadline?.toIso8601String().split('T')[0],
    'is_completed': isCompleted,
    'created_at':   createdAt.toIso8601String(),
  };

  Goal copyWith({
    String? name,
    double? currentVal,
    double? targetVal,
    String? unit,
    String? colorHex,
    bool?   isCompleted,
  }) => Goal(
    id:          id,
    userId:      userId,
    createdAt:   createdAt,
    deadline:    deadline,
    name:        name        ?? this.name,
    currentVal:  currentVal  ?? this.currentVal,
    targetVal:   targetVal   ?? this.targetVal,
    unit:        unit        ?? this.unit,
    colorHex:    colorHex    ?? this.colorHex,
    isCompleted: isCompleted ?? this.isCompleted,
  );
}

// ─── APP USER ─────────────────────────────────────────────────────────────────

class AppUser {
  final String   id;
  final String   email;
  String         username;      // unique handle — primary social identifier
  String         displayName;
  String?        avatarUrl;
  int            totalPoints;   // cumulative XP from tasks + habits
  int            totalStreak;
  int            longestStreak;
  String         timezone;
  final DateTime createdAt;

  AppUser({
    required this.id,
    required this.email,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    this.totalPoints   = 0,
    this.totalStreak   = 0,
    this.longestStreak = 0,
    this.timezone      = 'UTC',
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
    id:            j['id']             as String,
    email:         j['email']          as String?  ?? '',
    username:      j['username']       as String?  ?? '',
    displayName:   j['display_name']   as String?  ?? 'User',
    avatarUrl:     j['avatar_url']     as String?,
    totalPoints:   j['total_points']   as int?     ?? 0,
    totalStreak:   j['total_streak']   as int?     ?? 0,
    longestStreak: j['longest_streak'] as int?     ?? 0,
    timezone:      j['timezone']       as String?  ?? 'UTC',
    createdAt:     DateTime.parse(j['created_at'] as String),
  );

  Map<String, dynamic> toJson() => {
    'id':             id,
    'email':          email,
    'username':       username,
    'display_name':   displayName,
    'avatar_url':     avatarUrl,
    'total_points':   totalPoints,
    'total_streak':   totalStreak,
    'longest_streak': longestStreak,
    'timezone':       timezone,
    'created_at':     createdAt.toIso8601String(),
  };
}

// ─── LEADERBOARD ──────────────────────────────────────────────────────────────

/// One row in the leaderboard — a snapshot of a user's rank + points.
class LeaderboardEntry {
  final int      rank;
  final String   userId;
  final String   username;
  final String   displayName;
  final String?  avatarUrl;
  final int      totalPoints;
  final int      totalStreak;
  final bool     isMe;

  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.displayName,
    this.avatarUrl,
    required this.totalPoints,
    required this.totalStreak,
    required this.isMe,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> j, {
    required int rank,
    required bool isMe,
  }) => LeaderboardEntry(
    rank:         rank,
    userId:       j['id']           as String,
    username:     j['username']     as String?  ?? '',
    displayName:  j['display_name'] as String?  ?? 'User',
    avatarUrl:    j['avatar_url']   as String?,
    totalPoints:  j['total_points'] as int?     ?? 0,
    totalStreak:  j['total_streak'] as int?     ?? 0,
    isMe:         isMe,
  );
}

// ─── POINT EVENT ──────────────────────────────────────────────────────────────

/// A single earned-points record shown in the points history.
class PointEvent {
  final String   id;
  final String   userId;
  final int      points;
  final String   reason;   // 'task_high', 'task_medium', 'task_low', 'habit', 'streak_7', 'streak_30'
  final String?  subject;  // task title or habit name
  final DateTime createdAt;

  const PointEvent({
    required this.id,
    required this.userId,
    required this.points,
    required this.reason,
    this.subject,
    required this.createdAt,
  });

  factory PointEvent.fromJson(Map<String, dynamic> j) => PointEvent(
    id:        j['id']        as String,
    userId:    j['user_id']   as String,
    points:    j['points']    as int,
    reason:    j['reason']    as String,
    subject:   j['subject']   as String?,
    createdAt: DateTime.parse(j['created_at'] as String),
  );

  /// Human-readable label for this reason code.
  String get label => switch (reason) {
    'task_high'   => 'High-priority task',
    'task_medium' => 'Medium-priority task',
    'task_low'    => 'Low-priority task',
    'habit'       => 'Habit completed',
    'streak_7'    => '7-day streak bonus',
    'streak_30'   => '30-day streak bonus',
    _             => reason,
  };

  Color get color => switch (reason) {
    'task_high'         => const Color(0xFFD95F5F),
    'task_medium'       => const Color(0xFFC8A84C),
    'task_low'          => const Color(0xFF4DB87A),
    'habit'             => const Color(0xFF3ECFCA),
    'streak_7'          => const Color(0xFFC8A84C),
    'streak_30'         => const Color(0xFF8B7CF6),
    _                   => const Color(0xFF888888),
  };
}

// ─── INSIGHT CARD ─────────────────────────────────────────────────────────────

enum InsightType { positive, neutral, warning }

class InsightCard {
  final String      title;
  final String      description;
  final InsightType type;
  final double      value;
  final String      unit;

  const InsightCard({
    required this.title,
    required this.description,
    required this.type,
    required this.value,
    required this.unit,
  });
}
