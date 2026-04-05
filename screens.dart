// lib/features/screens.dart
// All feature screens consolidated for clarity

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../core/models/models.dart';
import '../core/services/supabase_service.dart';
import '../core/theme/app_theme.dart';
import '../shared/icons/lt_icons.dart';
import '../shared/widgets/lt_widgets.dart';
import 'dart:math' as math;

// ═══════════════════════════════════════════════════════════════════════════════
//  HABITS SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class HabitsScreen extends StatefulWidget {
  final String userId;
  const HabitsScreen({super.key, required this.userId});
  @override State<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends State<HabitsScreen> {
  final _svc = SupabaseService.instance;
  List<Habit> _habits = [];
  Map<String, bool> _logs = {};
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final results = await Future.wait([
      _svc.getHabits(),
      _svc.getHabitLogsForRange(now.subtract(const Duration(days: 6)), now),
    ]);
    if (!mounted) return;
    setState(() {
      _habits  = results[0] as List<Habit>;
      _logs    = results[1] as Map<String, bool>;
      _loading = false;
    });
  }

  Future<void> _toggle(String habitId, DateTime date) async {
    final key = '${habitId}_${date.toIso8601String().split('T')[0]}';
    final was = _logs[key] ?? false;
    setState(() => _logs[key] = !was);
    await _svc.toggleHabitLog(habitId, date, !was);
  }

  @override Widget build(BuildContext context) {
    final days7 = List.generate(7, (i) => DateTime.now().subtract(Duration(days: 6 - i)));
    return Scaffold(
      backgroundColor: LTColors.bg,
      body: SafeArea(child: Column(children: [
        _TopBar(title: 'Habits', action: LTButton(label: 'New', icon: LTIcons.plus, isPrimary: true, isSmall: true,
          onTap: () => _showHabitForm(context, null))),
        Expanded(child: _loading
          ? const Center(child: CircularProgressIndicator(color: LTColors.cyan))
          : _habits.isEmpty
            ? LTEmptyState(icon: LTIcons.habits, title: 'No habits yet', subtitle: 'Build consistency with daily habits',
                actionLabel: 'Create first habit', onAction: () => _showHabitForm(context, null))
            : ListView(padding: const EdgeInsets.all(20), children: [
                // Week header
                Padding(padding: const EdgeInsets.only(bottom: 8), child: Row(children: [
                  const SizedBox(width: 160),
                  ...days7.map((d) => Expanded(child: Column(children: [
                    Text(DateFormat.E().format(d), style: LTText.label.copyWith(fontSize: 9)),
                    const SizedBox(height: 2),
                    Text('${d.day}', style: LTText.body(11,
                      color: _isToday(d) ? LTColors.cyan : LTColors.text3,
                      weight: _isToday(d) ? FontWeight.w600 : FontWeight.w400)),
                  ]))),
                ])),
                ..._habits.map((h) => _HabitRow(
                  habit: h, days: days7, logs: _logs,
                  onToggle: (date) => _toggle(h.id, date),
                  onEdit: () => _showHabitForm(context, h),
                  onDelete: () async { await _svc.deleteHabit(h.id); _load(); },
                )),
              ]),
        ),
      ])),
    );
  }

  bool _isToday(DateTime d) {
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  void _showHabitForm(BuildContext ctx, Habit? h) => showLTSheet(ctx, (_) =>
    _HabitForm(userId: widget.userId, habit: h, onSave: (saved) async {
      Navigator.pop(ctx);
      if (h == null) await _svc.createHabit(saved); else await _svc.updateHabit(saved);
      _load();
    }),
  );
}

class _HabitRow extends StatelessWidget {
  final Habit habit;
  final List<DateTime> days;
  final Map<String, bool> logs;
  final ValueChanged<DateTime> onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _HabitRow({required this.habit, required this.days, required this.logs, required this.onToggle, required this.onEdit, required this.onDelete});

  @override Widget build(BuildContext context) {
    final today = DateTime.now();
    final isToday = (DateTime d) => d.year == today.year && d.month == today.month && d.day == today.day;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: LTCard(padding: const EdgeInsets.all(12), child: Row(children: [
        Container(width: 4, height: 40, decoration: BoxDecoration(color: habit.color, borderRadius: LTRadius.full)),
        const SizedBox(width: 12),
        SizedBox(width: 100, child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(habit.name, style: LTText.body(13, weight: FontWeight.w500), maxLines: 1, overflow: TextOverflow.ellipsis),
          if (habit.currentStreak > 0) Row(mainAxisSize: MainAxisSize.min, children: [
            LTIcon(LTIcons.fire, size: 10, color: LTColors.gold),
            const SizedBox(width: 3),
            Text('${habit.currentStreak}d', style: LTText.body(10, color: LTColors.gold, weight: FontWeight.w600)),
          ]),
        ])),
        const SizedBox(width: 8),
        ...days.map((d) {
          final key = '${habit.id}_${d.toIso8601String().split('T')[0]}';
          final done = logs[key] ?? false;
          final canToggle = !d.isAfter(today.add(const Duration(hours: 1)));
          return Expanded(child: GestureDetector(
            onTap: canToggle ? () { HapticFeedback.selectionClick(); onToggle(d); } : null,
            child: Center(child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 28, height: 28,
              decoration: BoxDecoration(
                color:        done ? habit.color : LTColors.surface2,
                borderRadius: BorderRadius.circular(7),
                border:       Border.all(color: done ? habit.color : isToday(d) ? LTColors.border3 : LTColors.border1),
              ),
              child: done ? Center(child: LTIcon(LTIcons.check, size: 12, color: const Color(0xFF050505), strokeWidth: 2.2)) : null,
            )),
          ));
        }),
        const SizedBox(width: 8),
        GestureDetector(onTap: onEdit, child: LTIcon(LTIcons.edit, size: 16, color: LTColors.text3)),
        const SizedBox(width: 10),
        GestureDetector(onTap: onDelete, child: LTIcon(LTIcons.trash, size: 16, color: LTColors.text3)),
      ])),
    );
  }
}

class _HabitForm extends StatefulWidget {
  final String userId; final Habit? habit; final ValueChanged<Habit> onSave;
  const _HabitForm({required this.userId, this.habit, required this.onSave});
  @override State<_HabitForm> createState() => _HabitFormState();
}

class _HabitFormState extends State<_HabitForm> {
  late final _nameCtrl = TextEditingController(text: widget.habit?.name ?? '');
  late String _color = widget.habit?.colorHex ?? '#3ECFCA';
  late List<int> _days = List.from(widget.habit?.activeDays ?? [0,1,2,3,4,5,6]);
  final _colors = ['#3ECFCA','#C8A84C','#4DB87A','#D95F5F','#8B7CF6','#F0A868','#E887C4','#7EC8E3'];
  final _dayLabels = ['Mo','Tu','We','Th','Fr','Sa','Su'];

  @override Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(widget.habit == null ? 'New Habit' : 'Edit Habit', style: LTText.heading(20)),
      const SizedBox(height: 20),
      LTInput(placeholder: 'Habit name…', controller: _nameCtrl, label: 'Name'),
      const SizedBox(height: 16),
      Text('COLOR', style: LTText.label),
      const SizedBox(height: 10),
      Row(children: _colors.map((c) {
        final col = Color(int.parse(c.replaceFirst('#', '0xFF')));
        return Padding(padding: const EdgeInsets.only(right: 10), child: GestureDetector(
          onTap: () => setState(() => _color = c),
          child: AnimatedContainer(duration: const Duration(milliseconds: 150), width: 28, height: 28,
            decoration: BoxDecoration(color: col, borderRadius: LTRadius.xs,
              border: Border.all(color: _color == c ? Colors.white : Colors.transparent, width: 2.5))),
        ));
      }).toList()),
      const SizedBox(height: 16),
      Text('ACTIVE DAYS', style: LTText.label),
      const SizedBox(height: 10),
      Row(children: List.generate(7, (i) => Padding(padding: const EdgeInsets.only(right: 8), child:
        GestureDetector(onTap: () => setState(() => _days.contains(i) ? _days.remove(i) : _days.add(i)),
          child: AnimatedContainer(duration: const Duration(milliseconds: 150), width: 38, height: 38,
            decoration: BoxDecoration(
              color:        _days.contains(i) ? Color(int.parse(_color.replaceFirst('#','0xFF'))) : LTColors.surface2,
              borderRadius: BorderRadius.circular(9),
              border: Border.all(color: _days.contains(i) ? Colors.transparent : LTColors.border2)),
            child: Center(child: Text(_dayLabels[i], style: LTText.body(12,
              weight: FontWeight.w600, color: _days.contains(i) ? const Color(0xFF050505) : LTColors.text2)))),
      )))),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: LTButton(
        label: widget.habit == null ? 'Create Habit' : 'Save Changes',
        isPrimary: true, onTap: () {
          if (_nameCtrl.text.trim().isEmpty) return;
          final h = Habit(
            id: widget.habit?.id ?? '', userId: widget.userId, name: _nameCtrl.text.trim(),
            colorHex: _color, activeDays: _days, createdAt: widget.habit?.createdAt ?? DateTime.now(),
          );
          widget.onSave(h);
        },
      )),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  TASKS SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class TasksScreen extends StatefulWidget {
  final String userId;
  const TasksScreen({super.key, required this.userId});
  @override State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> with TickerProviderStateMixin {
  final _svc = SupabaseService.instance;
  List<Task> _tasks = [];
  bool _loading = true;
  late TabController _tab;
  int _tabIndex = 0;

  @override void initState() { super.initState(); _tab = TabController(length: 3, vsync: this); _tab.addListener(() => setState(() => _tabIndex = _tab.index)); _load(); }
  @override void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tasks = await _svc.getAllPendingTasks();
    if (!mounted) return;
    setState(() { _tasks = tasks; _loading = false; });
  }

  List<Task> get _filtered {
    final now = DateTime.now();
    return switch (_tabIndex) {
      0 => _tasks.where((t) => _sameDay(t.date, now)).toList()..sort((a,b) => a.priority.index.compareTo(b.priority.index)),
      1 => _tasks.where((t) => !_sameDay(t.date, now) && t.date.isAfter(now)).toList()..sort((a,b) => a.date.compareTo(b.date)),
      _ => [..._tasks]..sort((a,b) => a.date.compareTo(b.date)),
    };
  }

  bool _sameDay(DateTime a, DateTime b) => a.year==b.year && a.month==b.month && a.day==b.day;

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: LTColors.bg,
    body: SafeArea(child: Column(children: [
      _TopBar(title: 'Tasks', action: LTButton(label: 'New', icon: LTIcons.plus, isPrimary: true, isSmall: true,
        onTap: () => _showTaskForm(context, null))),
      // Tab row
      Container(margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: LTColors.surface2, borderRadius: LTRadius.sm),
        padding: const EdgeInsets.all(3),
        child: TabBar(controller: _tab,
          indicator: BoxDecoration(color: LTColors.surface1, borderRadius: LTRadius.xs),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: LTText.body(13, weight: FontWeight.w600),
          unselectedLabelStyle: LTText.body(13),
          labelColor: LTColors.text1,
          unselectedLabelColor: LTColors.text3,
          tabs: const [Tab(text: 'Today'), Tab(text: 'Upcoming'), Tab(text: 'All')],
        ),
      ),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: LTColors.cyan))
        : _filtered.isEmpty
          ? LTEmptyState(icon: LTIcons.tasks, title: 'All clear', subtitle: 'No tasks here',
              actionLabel: 'Add task', onAction: () => _showTaskForm(context, null))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _filtered.length,
              itemBuilder: (_, i) => _TaskItem(
                task: _filtered[i],
                onToggle: () async {
                  setState(() => _filtered[i].isDone = !_filtered[i].isDone);
                  await _svc.updateTask(_filtered[i]);
                },
                onEdit: () => _showTaskForm(context, _filtered[i]),
                onDelete: () async { await _svc.deleteTask(_filtered[i].id); _load(); },
              ).animate(delay: (i * 30).ms).fadeIn(duration: 200.ms).slideX(begin: 0.05),
            ),
      ),
    ])),
  );

  void _showTaskForm(BuildContext ctx, Task? t) => showLTSheet(ctx, (_) =>
    _TaskForm(userId: widget.userId, task: t, onSave: (saved) async {
      Navigator.pop(ctx);
      if (t == null) await _svc.createTask(saved); else await _svc.updateTask(saved);
      _load();
    }),
  );
}

class _TaskItem extends StatelessWidget {
  final Task task; final VoidCallback onToggle, onEdit, onDelete;
  const _TaskItem({required this.task, required this.onToggle, required this.onEdit, required this.onDelete});

  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: LTCard(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12), child: Row(children: [
      LTCheckbox(checked: task.isDone, onTap: onToggle, size: 22),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(task.title, style: LTText.body(14, color: task.isDone ? LTColors.text3 : LTColors.text1,
          weight: FontWeight.w500), maxLines: 2, overflow: TextOverflow.ellipsis),
        if (task.notes != null && task.notes!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(task.notes!, style: LTText.body(12, color: LTColors.text3), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ])),
      const SizedBox(width: 10),
      LTPriorityBadge(task.priority.name),
      const SizedBox(width: 8),
      GestureDetector(onTap: onEdit, child: LTIcon(LTIcons.edit, size: 15, color: LTColors.text3)),
      const SizedBox(width: 10),
      GestureDetector(onTap: onDelete, child: LTIcon(LTIcons.trash, size: 15, color: LTColors.text3)),
    ])),
  );
}

class _TaskForm extends StatefulWidget {
  final String userId; final Task? task; final ValueChanged<Task> onSave;
  const _TaskForm({required this.userId, this.task, required this.onSave});
  @override State<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends State<_TaskForm> {
  late final _titleCtrl = TextEditingController(text: widget.task?.title ?? '');
  late final _notesCtrl = TextEditingController(text: widget.task?.notes ?? '');
  late TaskPriority _priority = widget.task?.priority ?? TaskPriority.medium;
  late DateTime _date = widget.task?.date ?? DateTime.now();

  @override Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(widget.task == null ? 'New Task' : 'Edit Task', style: LTText.heading(20)),
      const SizedBox(height: 20),
      LTInput(placeholder: 'Task title…', controller: _titleCtrl, label: 'Title'),
      const SizedBox(height: 12),
      LTInput(placeholder: 'Notes (optional)…', controller: _notesCtrl, maxLines: 3, label: 'Notes'),
      const SizedBox(height: 16),
      Text('PRIORITY', style: LTText.label),
      const SizedBox(height: 10),
      Row(children: TaskPriority.values.map((p) => Padding(padding: const EdgeInsets.only(right: 10),
        child: GestureDetector(
          onTap: () => setState(() => _priority = p),
          child: AnimatedContainer(duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _priority == p ? switch(p) { TaskPriority.high => LTColors.redDim, TaskPriority.low => LTColors.greenDim, _ => LTColors.cyanDim } : LTColors.surface2,
              borderRadius: LTRadius.sm,
              border: Border.all(color: _priority == p ? switch(p) { TaskPriority.high => LTColors.red, TaskPriority.low => LTColors.green, _ => LTColors.cyan } : LTColors.border1),
            ),
            child: Text(p.name, style: LTText.body(13, weight: FontWeight.w500,
              color: _priority == p ? switch(p) { TaskPriority.high => LTColors.red, TaskPriority.low => LTColors.green, _ => LTColors.cyan } : LTColors.text3)),
          ),
        ),
      )).toList()),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: LTButton(
        label: widget.task == null ? 'Add Task' : 'Save Changes', isPrimary: true,
        onTap: () {
          if (_titleCtrl.text.trim().isEmpty) return;
          final t = Task(
            id: widget.task?.id ?? '', userId: widget.userId, title: _titleCtrl.text.trim(),
            notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text, priority: _priority,
            date: _date, createdAt: widget.task?.createdAt ?? DateTime.now(),
          );
          widget.onSave(t);
        },
      )),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  MOOD SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class MoodScreen extends StatefulWidget {
  final String userId;
  const MoodScreen({super.key, required this.userId});
  @override State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  final _svc = SupabaseService.instance;
  List<MoodEntry> _entries = [];
  MoodEntry? _today;
  bool _loading = true;
  final _noteCtrl = TextEditingController();
  int? _selectedLevel;

  @override void initState() { super.initState(); _load(); }
  @override void dispose() { _noteCtrl.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([_svc.getMoodEntries(30), _svc.getTodayMood()]);
    if (!mounted) return;
    final today = results[1] as MoodEntry?;
    setState(() {
      _entries       = results[0] as List<MoodEntry>;
      _today         = today;
      _selectedLevel = today?.level.index;
      _noteCtrl.text = today?.note ?? '';
      _loading       = false;
    });
  }

  Future<void> _save() async {
    if (_selectedLevel == null) return;
    final entry = MoodEntry(
      id: _today?.id ?? '', userId: widget.userId,
      level: MoodLevel.values[_selectedLevel!],
      note: _noteCtrl.text.isEmpty ? null : _noteCtrl.text,
      date: DateTime.now(), createdAt: _today?.createdAt ?? DateTime.now(),
    );
    await _svc.upsertMood(entry);
    setState(() => _today = entry);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mood saved'), backgroundColor: LTColors.surface3, behavior: SnackBarBehavior.floating));
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: LTColors.bg,
    body: SafeArea(child: _loading
      ? const Center(child: CircularProgressIndicator(color: LTColors.cyan))
      : ListView(padding: const EdgeInsets.all(20), children: [
          const _PageTitle(title: 'Mood Tracker'),
          const SizedBox(height: 20),

          // Log today
          LTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LTSectionHeader(title: "How are you feeling?"),
            const SizedBox(height: 16),
            LTMoodPicker(selected: _selectedLevel, onSelect: (i) => setState(() => _selectedLevel = i)),
            const SizedBox(height: 16),
            LTInput(placeholder: "What's on your mind? Add a note…", controller: _noteCtrl, maxLines: 4, label: "Note (optional)"),
            const SizedBox(height: 14),
            SizedBox(width: double.infinity, child: LTButton(label: 'Save Mood', isPrimary: true, onTap: _save)),
          ])),

          const SizedBox(height: 20),

          // 14-day history
          if (_entries.isNotEmpty) LTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LTSectionHeader(title: '14-Day History'),
            const SizedBox(height: 14),
            _MoodChart(entries: _entries.take(14).toList().reversed.toList()),
            const SizedBox(height: 16),
            ..._entries.where((e) => e.note != null && e.note!.isNotEmpty).take(5).map((e) =>
              Padding(padding: const EdgeInsets.only(bottom: 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(width: 8, height: 8, decoration: BoxDecoration(color: LTColors.moodColors[e.level.index], shape: BoxShape.circle)),
                  const SizedBox(width: 8),
                  Text(DateFormat('MMM d').format(e.date), style: LTText.body(12, color: LTColors.text3)),
                  const SizedBox(width: 8),
                  Text(e.level.label, style: LTText.body(12, weight: FontWeight.w600, color: LTColors.moodColors[e.level.index])),
                ]),
                const SizedBox(height: 5),
                Text(e.note!, style: LTText.body(13, color: LTColors.text2)),
              ])),
            ),
          ])),
        ]),
    ),
  );
}

class _MoodChart extends StatelessWidget {
  final List<MoodEntry> entries;
  const _MoodChart({required this.entries});

  @override Widget build(BuildContext context) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 100,
      child: LineChart(LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minY: 0, maxY: 4,
        lineBarsData: [LineChartBarData(
          spots: entries.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.level.index.toDouble())).toList(),
          isCurved: true, curveSmoothness: 0.3,
          color: LTColors.cyan,
          barWidth: 2, dotData: const FlDotData(show: false),
          belowBarData: BarAreaData(show: true, color: LTColors.cyanDim),
        )],
      )),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  JOURNAL SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class JournalScreen extends StatefulWidget {
  final String userId;
  const JournalScreen({super.key, required this.userId});
  @override State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final _svc = SupabaseService.instance;
  List<JournalEntry> _entries = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final entries = await _svc.getJournalEntries();
    if (!mounted) return;
    setState(() { _entries = entries; _loading = false; });
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: LTColors.bg,
    body: SafeArea(child: Column(children: [
      _TopBar(title: 'Journal', action: LTButton(label: 'Write', icon: LTIcons.edit, isPrimary: true, isSmall: true,
        onTap: () => _openEditor(context, null))),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: LTColors.cyan))
        : _entries.isEmpty
          ? LTEmptyState(icon: LTIcons.journal, title: 'Start writing', subtitle: 'Capture your thoughts and reflections',
              actionLabel: 'Write first entry', onAction: () => _openEditor(context, null))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _entries.length,
              itemBuilder: (_, i) {
                final e = _entries[i];
                return Padding(padding: const EdgeInsets.only(bottom: 10), child:
                  LTCard(
                    onTap: () => _openEditor(context, e),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(e.title, style: LTText.heading(16), maxLines: 1, overflow: TextOverflow.ellipsis)),
                        GestureDetector(onTap: () async { await _svc.deleteJournalEntry(e.id); _load(); },
                          child: LTIcon(LTIcons.trash, size: 16, color: LTColors.text3)),
                      ]),
                      const SizedBox(height: 6),
                      Text(DateFormat('EEEE, MMMM d').format(e.date), style: LTText.body(12, color: LTColors.text3)),
                      const SizedBox(height: 10),
                      Text(e.content, style: LTText.body(14, color: LTColors.text2), maxLines: 3, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 8),
                      Row(children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: LTColors.surface2, borderRadius: LTRadius.full),
                          child: Text('${e.wordCount} words', style: LTText.label.copyWith(color: LTColors.text3))),
                      ]),
                    ]),
                  ).animate(delay: (i * 30).ms).fadeIn(duration: 250.ms),
                );
              },
            ),
      ),
    ])),
  );

  void _openEditor(BuildContext ctx, JournalEntry? e) => Navigator.push(ctx,
    MaterialPageRoute(builder: (_) => _JournalEditor(userId: widget.userId, entry: e, onSave: (_) => _load())));
}

class _JournalEditor extends StatefulWidget {
  final String userId; final JournalEntry? entry; final VoidCallback onSave;
  const _JournalEditor({required this.userId, this.entry, required this.onSave});
  @override State<_JournalEditor> createState() => _JournalEditorState();
}

class _JournalEditorState extends State<_JournalEditor> {
  final _svc = SupabaseService.instance;
  late final _titleCtrl  = TextEditingController(text: widget.entry?.title ?? '');
  late final _contentCtrl = TextEditingController(text: widget.entry?.content ?? '');
  bool _saving = false;

  int get _wordCount => _contentCtrl.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;

  Future<void> _save() async {
    setState(() => _saving = true);
    final now = DateTime.now();
    if (widget.entry == null) {
      await _svc.createJournalEntry(JournalEntry(
        id: '', userId: widget.userId, title: _titleCtrl.text.isEmpty ? 'Untitled' : _titleCtrl.text,
        content: _contentCtrl.text, date: now, createdAt: now, updatedAt: now,
      ));
    } else {
      widget.entry!.title = _titleCtrl.text.isEmpty ? 'Untitled' : _titleCtrl.text;
      widget.entry!.content = _contentCtrl.text;
      await _svc.updateJournalEntry(widget.entry!);
    }
    widget.onSave();
    if (mounted) Navigator.pop(context);
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: LTColors.bg,
    appBar: AppBar(
      backgroundColor: LTColors.bg,
      leading: GestureDetector(onTap: () => Navigator.pop(context), child: Padding(padding: const EdgeInsets.all(12), child: LTIcon(LTIcons.back, size: 22, color: LTColors.text2))),
      title: AnimatedBuilder(animation: _contentCtrl, builder: (_,__) =>
        Text('${_wordCount} words', style: LTText.body(13, color: LTColors.text3))),
      actions: [
        Padding(padding: const EdgeInsets.fromLTRB(0,8,16,8),
          child: LTButton(label: 'Save', isPrimary: true, isSmall: true, isLoading: _saving, onTap: _save)),
      ],
    ),
    body: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(children: [
        TextField(controller: _titleCtrl, style: LTText.display(26), decoration: InputDecoration.collapsed(hintText: 'Title…', hintStyle: LTText.display(26).copyWith(color: LTColors.text4))),
        const SizedBox(height: 4),
        Text(DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()), style: LTText.body(13, color: LTColors.text3)),
        const SizedBox(height: 16),
        Expanded(child: TextField(controller: _contentCtrl, maxLines: null, expands: true, style: LTText.body(16, color: LTColors.text1), keyboardType: TextInputType.multiline,
          decoration: InputDecoration.collapsed(hintText: 'Start writing…', hintStyle: LTText.body(16, color: LTColors.text3)))),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  GOALS SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class GoalsScreen extends StatefulWidget {
  final String userId;
  const GoalsScreen({super.key, required this.userId});
  @override State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  final _svc = SupabaseService.instance;
  List<Goal> _goals = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final goals = await _svc.getGoals();
    if (!mounted) return;
    setState(() { _goals = goals; _loading = false; });
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: LTColors.bg,
    body: SafeArea(child: Column(children: [
      _TopBar(title: 'Goals', action: LTButton(label: 'New', icon: LTIcons.plus, isPrimary: true, isSmall: true,
        onTap: () => _showForm(context, null))),
      Expanded(child: _loading
        ? const Center(child: CircularProgressIndicator(color: LTColors.cyan))
        : _goals.isEmpty
          ? LTEmptyState(icon: LTIcons.goals, title: 'No goals yet', subtitle: 'Set milestones and track your progress',
              actionLabel: 'Create a goal', onAction: () => _showForm(context, null))
          : ListView(padding: const EdgeInsets.all(20), children: [
              ..._goals.asMap().entries.map((e) => Padding(padding: const EdgeInsets.only(bottom: 12),
                child: _GoalCard(goal: e.value,
                  onUpdate: (v) async { e.value.current = v; await _svc.updateGoal(e.value); _load(); },
                  onEdit: () => _showForm(context, e.value),
                  onDelete: () async { await _svc.deleteGoal(e.value.id); _load(); },
                ).animate(delay: (e.key * 40).ms).fadeIn(duration: 250.ms),
              )),
            ]),
      ),
    ])),
  );

  void _showForm(BuildContext ctx, Goal? g) => showLTSheet(ctx, (_) =>
    _GoalForm(userId: widget.userId, goal: g, onSave: (saved) async {
      Navigator.pop(ctx);
      if (g == null) await _svc.createGoal(saved); else await _svc.updateGoal(saved);
      _load();
    }),
  );
}

class _GoalCard extends StatefulWidget {
  final Goal goal; final ValueChanged<double> onUpdate; final VoidCallback onEdit, onDelete;
  const _GoalCard({required this.goal, required this.onUpdate, required this.onEdit, required this.onDelete});
  @override State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  final _ctrl = TextEditingController();

  @override Widget build(BuildContext context) => LTCard(
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(width: 4, height: 40, decoration: BoxDecoration(color: widget.goal.color, borderRadius: LTRadius.full)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(widget.goal.name, style: LTText.heading(16)),
          Text('${widget.goal.current.toStringAsFixed(0)} / ${widget.goal.target.toStringAsFixed(0)} ${widget.goal.unitLabel}',
            style: LTText.body(12, color: LTColors.text3)),
        ])),
        GestureDetector(onTap: widget.onEdit, child: LTIcon(LTIcons.edit, size: 16, color: LTColors.text3)),
        const SizedBox(width: 12),
        GestureDetector(onTap: widget.onDelete, child: LTIcon(LTIcons.trash, size: 16, color: LTColors.text3)),
      ]),
      const SizedBox(height: 14),
      ClipRRect(borderRadius: LTRadius.full, child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: widget.goal.percentage),
        duration: const Duration(milliseconds: 900), curve: Curves.easeOutCubic,
        builder: (_, val, __) => LinearProgressIndicator(value: val, minHeight: 6, backgroundColor: LTColors.surface3, valueColor: AlwaysStoppedAnimation(widget.goal.color)),
      )),
      const SizedBox(height: 4),
      Align(alignment: Alignment.centerRight, child: Text('${(widget.goal.percentage*100).round()}%', style: LTText.body(12, color: LTColors.text3))),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: TextField(controller: _ctrl, keyboardType: TextInputType.number,
          style: LTText.body(14), decoration: InputDecoration(
            hintText: 'Update progress…', hintStyle: LTText.body(14, color: LTColors.text3),
            filled: true, fillColor: LTColors.surface2,
            border: OutlineInputBorder(borderRadius: LTRadius.sm, borderSide: const BorderSide(color: LTColors.border1)),
            enabledBorder: OutlineInputBorder(borderRadius: LTRadius.sm, borderSide: const BorderSide(color: LTColors.border1)),
            focusedBorder: OutlineInputBorder(borderRadius: LTRadius.sm, borderSide: const BorderSide(color: LTColors.cyan, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          )),
        ),
        const SizedBox(width: 10),
        LTButton(label: 'Set', isPrimary: true, isSmall: true, onTap: () {
          final v = double.tryParse(_ctrl.text);
          if (v != null) { widget.onUpdate(v); _ctrl.clear(); }
        }),
      ]),
    ]),
  );
}

class _GoalForm extends StatefulWidget {
  final String userId; final Goal? goal; final ValueChanged<Goal> onSave;
  const _GoalForm({required this.userId, this.goal, required this.onSave});
  @override State<_GoalForm> createState() => _GoalFormState();
}

class _GoalFormState extends State<_GoalForm> {
  late final _nameCtrl    = TextEditingController(text: widget.goal?.name ?? '');
  late final _currentCtrl = TextEditingController(text: widget.goal?.current.toStringAsFixed(0) ?? '0');
  late final _targetCtrl  = TextEditingController(text: widget.goal?.target.toStringAsFixed(0) ?? '100');
  late final _unitCtrl    = TextEditingController(text: widget.goal?.unitLabel ?? '');
  late String _color = widget.goal?.colorHex ?? '#3ECFCA';
  final _colors = ['#3ECFCA','#C8A84C','#4DB87A','#D95F5F','#8B7CF6','#F0A868'];

  @override Widget build(BuildContext context) => SingleChildScrollView(
    padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.of(context).viewInsets.bottom + 24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
      Text(widget.goal == null ? 'New Goal' : 'Edit Goal', style: LTText.heading(20)),
      const SizedBox(height: 20),
      LTInput(placeholder: 'Goal name…', controller: _nameCtrl, label: 'Name'),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: LTInput(placeholder: '0', controller: _currentCtrl, label: 'Current', keyboardType: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: LTInput(placeholder: '100', controller: _targetCtrl, label: 'Target', keyboardType: TextInputType.number)),
        const SizedBox(width: 12),
        Expanded(child: LTInput(placeholder: 'books', controller: _unitCtrl, label: 'Unit')),
      ]),
      const SizedBox(height: 16),
      Text('COLOR', style: LTText.label),
      const SizedBox(height: 10),
      Row(children: _colors.map((c) {
        final col = Color(int.parse(c.replaceFirst('#', '0xFF')));
        return Padding(padding: const EdgeInsets.only(right: 10), child: GestureDetector(
          onTap: () => setState(() => _color = c),
          child: AnimatedContainer(duration: const Duration(milliseconds: 150), width: 28, height: 28,
            decoration: BoxDecoration(color: col, borderRadius: LTRadius.xs, border: Border.all(color: _color == c ? Colors.white : Colors.transparent, width: 2.5))),
        ));
      }).toList()),
      const SizedBox(height: 24),
      SizedBox(width: double.infinity, child: LTButton(label: widget.goal == null ? 'Create Goal' : 'Save Changes', isPrimary: true, onTap: () {
        if (_nameCtrl.text.trim().isEmpty) return;
        widget.onSave(Goal(
          id: widget.goal?.id ?? '', userId: widget.userId, name: _nameCtrl.text.trim(),
          current: double.tryParse(_currentCtrl.text) ?? 0, target: double.tryParse(_targetCtrl.text) ?? 100,
          unit: GoalUnit.custom, customUnit: _unitCtrl.text.isEmpty ? null : _unitCtrl.text,
          colorHex: _color, createdAt: widget.goal?.createdAt ?? DateTime.now(),
        ));
      })),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  INSIGHTS SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class InsightsScreen extends StatefulWidget {
  final String userId;
  const InsightsScreen({super.key, required this.userId});
  @override State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  final _svc = SupabaseService.instance;
  Map<String, dynamic> _data = {};
  List<Habit> _habits = [];
  List<Goal> _goals = [];
  bool _loading = true;

  @override void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([_svc.getInsightData(), _svc.getHabits(), _svc.getGoals()]);
    if (!mounted) return;
    setState(() { _data = results[0] as Map<String,dynamic>; _habits = results[1] as List<Habit>; _goals = results[2] as List<Goal>; _loading = false; });
  }

  // Build 30-day habit completion data
  Map<DateTime, double> _habitHeatmap() {
    final logs = (_data['habit_logs'] as List? ?? []);
    final byDate = <String, int>{};
    for (final l in logs) {
      if (l['completed'] == true) {
        final d = l['date'] as String;
        byDate[d] = (byDate[d] ?? 0) + 1;
      }
    }
    final total = _habits.length.clamp(1, 9999);
    return Map.fromEntries(byDate.entries.map((e) => MapEntry(DateTime.parse(e.key), e.value / total)));
  }

  List<double> _taskCompletionByDay() {
    final tasks = (_data['tasks'] as List? ?? []);
    return List.generate(7, (i) {
      final day = DateTime.now().subtract(Duration(days: 6 - i));
      final dayStr = day.toIso8601String().split('T')[0];
      final total = tasks.where((t) => (t['date'] as String?)?.startsWith(dayStr) == true).length;
      final done  = tasks.where((t) => (t['date'] as String?)?.startsWith(dayStr) == true && t['is_done'] == true).length;
      return total == 0 ? 0.0 : done / total;
    });
  }

  List<InsightCard> _generateInsights() {
    final habits = _habits;
    final logs   = (_data['habit_logs'] as List? ?? []);
    final moodEntries = (_data['mood_entries'] as List? ?? []);

    final insights = <InsightCard>[];
    if (habits.isNotEmpty) {
      final completionRate = logs.length / (habits.length * 30).clamp(1, 9999);
      insights.add(InsightCard(
        title: 'Habit Consistency', value: completionRate * 100, unit: '%',
        description: completionRate > 0.7 ? 'Excellent! You\'re completing ${(completionRate*100).round()}% of habits.' : completionRate > 0.4 ? 'Good progress at ${(completionRate*100).round()}%. Push for 70%+.' : 'Low completion at ${(completionRate*100).round()}%. Try fewer habits.',
        type: completionRate > 0.7 ? InsightType.positive : completionRate > 0.4 ? InsightType.neutral : InsightType.warning,
      ));
    }
    if (moodEntries.isNotEmpty) {
      final avgMood = moodEntries.map((e) => MoodLevel.values.firstWhere((l) => l.name == (e['level'] as String? ?? 'neutral'), orElse: () => MoodLevel.neutral).index + 1).reduce((a,b)=>a+b) / moodEntries.length;
      insights.add(InsightCard(
        title: 'Average Mood', value: avgMood, unit: '/ 5',
        description: avgMood >= 3.5 ? 'Your mood is consistently positive.' : avgMood >= 2.5 ? 'Mood is neutral. Consider what boosts your energy.' : 'Mood has been low. Small habits can make a big difference.',
        type: avgMood >= 3.5 ? InsightType.positive : avgMood >= 2.5 ? InsightType.neutral : InsightType.warning,
      ));
    }
    for (final g in _goals.take(2)) {
      if (g.percentage > 0.5) insights.add(InsightCard(title: g.name, value: g.percentage * 100, unit: '%', description: 'You\'re ${(g.percentage*100).round()}% of the way to your goal!', type: InsightType.positive));
    }
    return insights;
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: LTColors.bg,
    body: SafeArea(child: _loading
      ? const Center(child: CircularProgressIndicator(color: LTColors.cyan))
      : ListView(padding: const EdgeInsets.all(20), children: [
          const _PageTitle(title: 'Insights'),
          const SizedBox(height: 20),

          // Habit heatmap
          LTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LTSectionHeader(title: '12-Week Habit Activity'),
            const SizedBox(height: 14),
            LTHeatmap(data: _habitHeatmap()),
          ])),
          const SizedBox(height: 14),

          // Task completion bars
          LTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LTSectionHeader(title: 'Task Completion (7 days)'),
            const SizedBox(height: 14),
            LTMiniBarChart(
              values: _taskCompletionByDay(),
              labels: List.generate(7, (i) {
                final d = DateTime.now().subtract(Duration(days: 6 - i));
                return DateFormat.E().format(d);
              }),
              barColor: LTColors.gold,
            ),
          ])),
          const SizedBox(height: 14),

          // AI insights
          LTSectionHeader(title: 'Your Insights'),
          const SizedBox(height: 10),
          ..._generateInsights().map((c) => Padding(padding: const EdgeInsets.only(bottom: 10), child:
            _InsightCard(card: c))),

          // Goals overview
          if (_goals.isNotEmpty) ...[
            const SizedBox(height: 14),
            LTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LTSectionHeader(title: 'Goal Progress'),
              const SizedBox(height: 14),
              ..._goals.map((g) => Padding(padding: const EdgeInsets.only(bottom: 14), child:
                Row(children: [
                  LTProgressRing(value: g.percentage, size: 44, color: g.color, strokeWidth: 4, label: '${(g.percentage*100).round()}%'),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(g.name, style: LTText.body(14, weight: FontWeight.w500)),
                    Text('${g.current.toStringAsFixed(0)} / ${g.target.toStringAsFixed(0)} ${g.unitLabel}', style: LTText.body(12, color: LTColors.text3)),
                  ])),
                ]),
              )),
            ])),
          ],
          const SizedBox(height: 100),
        ]),
    ),
  );
}

class _InsightCard extends StatelessWidget {
  final InsightCard card;
  const _InsightCard({required this.card});

  @override Widget build(BuildContext context) {
    final (color, bg) = switch (card.type) {
      InsightType.positive => (LTColors.green, LTColors.greenDim),
      InsightType.warning  => (LTColors.red,   LTColors.redDim),
      InsightType.neutral  => (LTColors.gold,  LTColors.goldDim),
    };
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: LTColors.surface1, borderRadius: LTRadius.md, border: Border.all(color: color.withOpacity(0.2))),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 3, height: 50, decoration: BoxDecoration(color: color, borderRadius: LTRadius.full)),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(card.title, style: LTText.body(14, weight: FontWeight.w600)),
            const Spacer(),
            Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: bg, borderRadius: LTRadius.full),
              child: Text('${card.value.round()}${card.unit}', style: LTText.label.copyWith(color: color))),
          ]),
          const SizedBox(height: 5),
          Text(card.description, style: LTText.body(13, color: LTColors.text2)),
        ])),
      ]),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SOCIAL / MULTIPLAYER SCREEN
// ═══════════════════════════════════════════════════════════════════════════════
class SocialScreen extends StatefulWidget {
  final String userId;
  const SocialScreen({super.key, required this.userId});
  @override State<SocialScreen> createState() => _SocialScreenState();
}

class _SocialScreenState extends State<SocialScreen> {
  final _svc = SupabaseService.instance;
  List<AppUser> _friends = [];
  List<FriendActivity> _activity = [];
  List<Map<String,dynamic>> _pendingRequests = [];
  bool _loading = true;
  final _emailCtrl = TextEditingController();
  late RealtimeChannel _activityChannel;

  @override void initState() { super.initState(); _load(); _subscribeActivity(); }
  @override void dispose() { _activityChannel.unsubscribe(); _emailCtrl.dispose(); super.dispose(); }

  void _subscribeActivity() {
    _activityChannel = _svc.subscribeToFriendActivity((data) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([_svc.getFriends(), _svc.getFriendActivity(), _svc.getPendingRequests()]);
    if (!mounted) return;
    setState(() {
      _friends         = results[0] as List<AppUser>;
      _activity        = results[1] as List<FriendActivity>;
      _pendingRequests = results[2] as List<Map<String,dynamic>>;
      _loading         = false;
    });
  }

  Future<void> _sendRequest() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) return;
    try {
      await _svc.sendFriendRequest(email);
      _emailCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Friend request sent!'), backgroundColor: LTColors.surface3, behavior: SnackBarBehavior.floating));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: LTColors.red, behavior: SnackBarBehavior.floating));
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: LTColors.bg,
    body: SafeArea(child: _loading
      ? const Center(child: CircularProgressIndicator(color: LTColors.cyan))
      : ListView(padding: const EdgeInsets.all(20), children: [
          const _PageTitle(title: 'Community'),
          const SizedBox(height: 20),

          // Add friend
          LTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LTSectionHeader(title: 'Add a Friend'),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: LTInput(placeholder: 'friend@email.com', controller: _emailCtrl, keyboardType: TextInputType.emailAddress)),
              const SizedBox(width: 10),
              LTButton(label: 'Send', isPrimary: true, isSmall: true, onTap: _sendRequest),
            ]),
          ])),
          const SizedBox(height: 14),

          // Pending requests
          if (_pendingRequests.isNotEmpty) ...[
            LTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LTSectionHeader(title: 'Requests (${_pendingRequests.length})'),
              const SizedBox(height: 12),
              ..._pendingRequests.map((r) => Padding(padding: const EdgeInsets.only(bottom: 10), child:
                Row(children: [
                  LTAvatar(name: r['profiles']['display_name'] as String? ?? 'User', size: 36),
                  const SizedBox(width: 12),
                  Expanded(child: Text(r['profiles']['display_name'] as String? ?? 'User', style: LTText.body(14, weight: FontWeight.w500))),
                  LTButton(label: 'Accept', isPrimary: true, isSmall: true, onTap: () async {
                    await _svc.acceptFriendRequest(r['id'] as String, r['from_id'] as String);
                    _load();
                  }),
                ]),
              )),
            ])),
            const SizedBox(height: 14),
          ],

          // Friends
          if (_friends.isNotEmpty) ...[
            LTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              LTSectionHeader(title: 'Friends (${_friends.length})'),
              const SizedBox(height: 12),
              ..._friends.map((f) => Padding(padding: const EdgeInsets.only(bottom: 12), child:
                Row(children: [
                  LTAvatar(name: f.displayName, url: f.avatarUrl, size: 40),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(f.displayName, style: LTText.body(14, weight: FontWeight.w500)),
                    if (f.totalStreak > 0) Row(mainAxisSize: MainAxisSize.min, children: [
                      LTIcon(LTIcons.fire, size: 11, color: LTColors.gold),
                      const SizedBox(width: 4),
                      Text('${f.totalStreak} day streak', style: LTText.body(12, color: LTColors.gold)),
                    ]),
                  ])),
                ]),
              )),
            ])),
            const SizedBox(height: 14),
          ],

          // Activity feed
          LTCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            LTSectionHeader(title: 'Activity Feed'),
            const SizedBox(height: 12),
            if (_activity.isEmpty) Text('No activity yet. Add friends to see their progress!', style: LTText.body(14, color: LTColors.text3))
            else ..._activity.map((a) => Padding(padding: const EdgeInsets.only(bottom: 12), child:
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                LTAvatar(name: a.userName, url: a.avatarUrl, size: 34),
                const SizedBox(width: 10),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  RichText(text: TextSpan(style: LTText.body(13), children: [
                    TextSpan(text: a.userName, style: LTText.body(13, weight: FontWeight.w600)),
                    TextSpan(text: ' ${a.action} '),
                    TextSpan(text: a.subject, style: LTText.body(13, color: LTColors.cyan)),
                  ])),
                  const SizedBox(height: 3),
                  Text(_timeAgo(a.time), style: LTText.body(11, color: LTColors.text3)),
                ])),
              ]),
            )),
          ])),
          const SizedBox(height: 100),
        ]),
    ),
  );

  String _timeAgo(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inHours < 1) return '${diff.inMinutes}m ago';
    if (diff.inDays < 1) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  AUTH SCREENS
// ═══════════════════════════════════════════════════════════════════════════════
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});
  @override State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _svc       = SupabaseService.instance;
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  final _nameCtrl  = TextEditingController();
  bool _isSignUp   = false;
  bool _loading    = false;
  String? _error;

  Future<void> _submit() async {
    setState(() { _loading = true; _error = null; });
    try {
      if (_isSignUp) {
        await _svc.signUp(_emailCtrl.text.trim(), _passCtrl.text, _nameCtrl.text.trim());
      } else {
        await _svc.signIn(_emailCtrl.text.trim(), _passCtrl.text);
      }
    } catch (e) {
      setState(() { _error = e.toString().replaceAll('Exception: ', ''); });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: LTColors.bg,
    body: SafeArea(child: Center(child: SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Logo
        Text('Life', style: LTText.display(44).copyWith(color: LTColors.text1)).animate().fadeIn(duration: 500.ms),
        Text('track', style: LTText.display(44).copyWith(color: LTColors.cyan, fontStyle: FontStyle.italic)).animate().fadeIn(delay: 100.ms, duration: 500.ms),
        const SizedBox(height: 8),
        Text('Your personal growth companion', style: LTText.body(15, color: LTColors.text3)).animate().fadeIn(delay: 200.ms, duration: 500.ms),
        const SizedBox(height: 40),

        if (_isSignUp) ...[
          LTInput(placeholder: 'Your name', controller: _nameCtrl, label: 'Name'),
          const SizedBox(height: 14),
        ],
        LTInput(placeholder: 'you@email.com', controller: _emailCtrl, keyboardType: TextInputType.emailAddress, label: 'Email'),
        const SizedBox(height: 14),
        LTInput(placeholder: '••••••••', controller: _passCtrl, obscureText: true, label: 'Password'),

        if (_error != null) ...[
          const SizedBox(height: 12),
          Container(padding: const EdgeInsets.all(12), decoration: BoxDecoration(color: LTColors.redDim, borderRadius: LTRadius.sm),
            child: Text(_error!, style: LTText.body(13, color: LTColors.red))),
        ],
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: LTButton(
          label: _isSignUp ? 'Create Account' : 'Sign In',
          isPrimary: true, isLoading: _loading, onTap: _submit,
        )),
        const SizedBox(height: 16),
        Center(child: GestureDetector(
          onTap: () => setState(() => _isSignUp = !_isSignUp),
          child: Text(_isSignUp ? 'Already have an account? Sign in' : 'New here? Create account',
            style: LTText.body(14, color: LTColors.cyan)),
        )),
      ]),
    ))),
  );
}

// ═══════════════════════════════════════════════════════════════════════════════
//  SHARED WIDGETS (page-level)
// ═══════════════════════════════════════════════════════════════════════════════
class _TopBar extends StatelessWidget {
  final String title; final Widget? action;
  const _TopBar({required this.title, this.action});

  @override Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
    child: Row(children: [
      Expanded(child: Text(title, style: LTText.heading(22))),
      if (action != null) action!,
    ]),
  );
}

class _PageTitle extends StatelessWidget {
  final String title;
  const _PageTitle({required this.title});
  @override Widget build(BuildContext context) => Text(title, style: LTText.heading(22));
}
