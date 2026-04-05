// lib/features/dashboard/dashboard_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../core/models/models.dart';
import '../../core/services/supabase_service.dart';
import '../../core/theme/app_theme.dart';
import '../../shared/icons/lt_icons.dart';
import '../../shared/widgets/lt_widgets.dart';
import 'dart:math' as math;

class DashboardScreen extends StatefulWidget {
  final String userId;
  const DashboardScreen({super.key, required this.userId});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _svc = SupabaseService.instance;

  List<Habit>         _habits   = [];
  List<Task>          _tasks    = [];
  List<Goal>          _goals    = [];
  MoodEntry?          _todayMood;
  Map<String, bool>   _logs     = {};
  AppUser?            _user;
  bool                _loading  = true;

  final _newTaskCtrl = TextEditingController();
  bool _addingTask   = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _newTaskCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final now = DateTime.now();
    final results = await Future.wait([
      _svc.getHabits(),
      _svc.getTasksForDate(now),
      _svc.getGoals(),
      _svc.getTodayMood(),
      _svc.getProfile(widget.userId),
      _svc.getHabitLogsForRange(now.subtract(const Duration(days: 1)), now),
    ]);
    if (!mounted) return;
    setState(() {
      _habits    = results[0] as List<Habit>;
      _tasks     = results[1] as List<Task>;
      _goals     = results[2] as List<Goal>;
      _todayMood = results[3] as MoodEntry?;
      _user      = results[4] as AppUser?;
      _logs      = results[5] as Map<String, bool>;
      _loading   = false;
    });
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 18) return 'Good afternoon';
    return 'Good evening';
  }

  int get _completedHabits {
    final today = _todayDateStr;
    return _habits.where((h) => _logs['${h.id}_$today'] == true).length;
  }

  int get _completedTasks => _tasks.where((t) => t.isDone).length;
  double get _habitPct => _habits.isEmpty ? 0 : _completedHabits / _habits.length;
  String get _todayDateStr => DateTime.now().toIso8601String().split('T')[0];

  Future<void> _toggleHabit(Habit h) async {
    final today = DateTime.now();
    final key = '${h.id}_${_todayDateStr}';
    final was = _logs[key] ?? false;
    setState(() => _logs[key] = !was);
    await _svc.toggleHabitLog(h.id, today, !was);
  }

  Future<void> _toggleTask(Task t) async {
    setState(() => t.isDone = !t.isDone);
    await _svc.updateTask(t);
  }

  Future<void> _quickAddTask() async {
    final text = _newTaskCtrl.text.trim();
    if (text.isEmpty) return;
    final task = Task(
      id: '', userId: widget.userId,
      title: text, date: DateTime.now(),
      createdAt: DateTime.now(),
    );
    final created = await _svc.createTask(task);
    setState(() { _tasks.add(created); _newTaskCtrl.clear(); _addingTask = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return _buildSkeleton();

    return RefreshIndicator(
      onRefresh: _load,
      color: LTColors.cyan,
      backgroundColor: LTColors.surface2,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // ── Header ─────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildHeader().animate().fadeIn(duration: 300.ms).slideY(begin: -0.1),
          ),

          // ── Stats row ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildStatsRow().animate().fadeIn(delay: 60.ms, duration: 300.ms),
          ),

          // ── Habit quick-check ──────────────────────────────────────────
          if (_habits.isNotEmpty) SliverToBoxAdapter(
            child: _buildHabitsSection().animate().fadeIn(delay: 120.ms, duration: 300.ms),
          ),

          // ── Task manager (interactive) ─────────────────────────────────
          SliverToBoxAdapter(
            child: _buildTasksSection().animate().fadeIn(delay: 180.ms, duration: 300.ms),
          ),

          // ── Goals progress ─────────────────────────────────────────────
          if (_goals.isNotEmpty) SliverToBoxAdapter(
            child: _buildGoalsSection().animate().fadeIn(delay: 240.ms, duration: 300.ms),
          ),

          // ── Mood log ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: _buildMoodSection().animate().fadeIn(delay: 300.ms, duration: 300.ms),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  // ─── HEADER ──────────────────────────────────────────────────────────────
  Widget _buildHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
    child: Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(_greeting, style: LTText.body(14, color: LTColors.text3)),
              const SizedBox(height: 2),
              Text(
                _user?.displayName ?? 'Loading…',
                style: LTText.display(28),
              ),
              const SizedBox(height: 8),
              _buildStreakPill(),
            ],
          ),
        ),
        const SizedBox(width: 16),
        LTProgressRing(
          value: _habitPct,
          size: 68,
          strokeWidth: 5,
          label: '${(_habitPct * 100).round()}%',
        ),
      ],
    ),
  );

  Widget _buildStreakPill() {
    final streak = _user?.totalStreak ?? 0;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: LTColors.goldDim, borderRadius: LTRadius.full, border: Border.all(color: LTColors.gold.withOpacity(0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          LTIcon(LTIcons.fire, size: 13, color: LTColors.gold, strokeWidth: 1.8),
          const SizedBox(width: 5),
          Text('$streak day streak', style: LTText.body(12, weight: FontWeight.w600, color: LTColors.gold)),
        ],
      ),
    );
  }

  // ─── STATS ROW ────────────────────────────────────────────────────────────
  Widget _buildStatsRow() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: Row(
      children: [
        Expanded(child: LTStatTile(
          value: '$_completedHabits/${_habits.length}',
          label: 'Habits',
          valueColor: LTColors.cyan,
        )),
        const SizedBox(width: 10),
        Expanded(child: LTStatTile(
          value: '$_completedTasks/${_tasks.length}',
          label: 'Tasks',
        )),
        const SizedBox(width: 10),
        Expanded(child: LTStatTile(
          value: _goals.isEmpty ? '—' : '${(_goals.map((g) => g.percentage).reduce((a, b) => a + b) / _goals.length * 100).round()}%',
          label: 'Goals avg',
          valueColor: LTColors.gold,
        )),
      ],
    ),
  );

  // ─── HABITS ───────────────────────────────────────────────────────────────
  Widget _buildHabitsSection() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: LTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LTSectionHeader(title: "Today's Habits", action: 'See all'),
          const SizedBox(height: 14),
          ...(_habits.take(5).map((h) {
            final done = _logs['${h.id}_$_todayDateStr'] ?? false;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: GestureDetector(
                onTap: () => _toggleHabit(h),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                  decoration: BoxDecoration(
                    color: done ? h.color.withOpacity(0.08) : LTColors.surface2,
                    borderRadius: LTRadius.sm,
                    border: Border.all(color: done ? h.color.withOpacity(0.3) : LTColors.border1),
                  ),
                  child: Row(
                    children: [
                      LTCheckbox(checked: done, onTap: () => _toggleHabit(h), color: h.color, size: 22),
                      const SizedBox(width: 12),
                      Expanded(child: Text(h.name, style: LTText.body(14, weight: FontWeight.w500,
                        color: done ? LTColors.text2 : LTColors.text1))),
                      if (h.currentStreak > 0)
                        Row(mainAxisSize: MainAxisSize.min, children: [
                          LTIcon(LTIcons.fire, size: 12, color: LTColors.gold, strokeWidth: 1.8),
                          const SizedBox(width: 4),
                          Text('${h.currentStreak}', style: LTText.body(12, color: LTColors.gold, weight: FontWeight.w600)),
                        ]),
                    ],
                  ),
                ),
              ),
            );
          })),
        ],
      ),
    ),
  );

  // ─── TASKS ────────────────────────────────────────────────────────────────
  Widget _buildTasksSection() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: LTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LTSectionHeader(
            title: "Tasks",
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${_completedTasks}/${_tasks.length}', style: LTText.body(13, color: LTColors.text3)),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: () => setState(() => _addingTask = !_addingTask),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(color: LTColors.cyanDim, borderRadius: LTRadius.xs),
                    child: LTIcon(LTIcons.plus, size: 14, color: LTColors.cyan, strokeWidth: 2.2),
                  ),
                ),
              ],
            ),
          ),
          if (_addingTask) ...[
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: LTInput(placeholder: 'New task…', controller: _newTaskCtrl, onEditingComplete: _quickAddTask)),
              const SizedBox(width: 10),
              LTButton(label: 'Add', onTap: _quickAddTask, isPrimary: true, isSmall: true),
            ]),
          ],
          const SizedBox(height: 12),
          if (_tasks.isEmpty)
            Padding(padding: const EdgeInsets.symmetric(vertical: 16), child:
              Text('No tasks for today', style: LTText.body(14, color: LTColors.text3)))
          else
            ..._tasks.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  LTCheckbox(
                    checked: t.isDone, onTap: () => _toggleTask(t),
                    size: 22,
                    color: switch (t.priority) {
                      TaskPriority.high   => LTColors.red,
                      TaskPriority.low    => LTColors.green,
                      TaskPriority.medium => LTColors.cyan,
                    },
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(t.title, style: LTText.body(14,
                    color: t.isDone ? LTColors.text3 : LTColors.text1),
                    maxLines: 1, overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  LTPriorityBadge(t.priority.name),
                ],
              ),
            )),
        ],
      ),
    ),
  );

  // ─── GOALS ────────────────────────────────────────────────────────────────
  Widget _buildGoalsSection() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: LTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LTSectionHeader(title: 'Goals', action: 'Edit'),
          const SizedBox(height: 14),
          ..._goals.take(3).map((g) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Expanded(child: Text(g.name, style: LTText.body(14, weight: FontWeight.w500))),
                  Text('${(g.percentage * 100).round()}%', style: LTText.body(13, color: LTColors.text3)),
                ]),
                const SizedBox(height: 7),
                ClipRRect(
                  borderRadius: LTRadius.full,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: g.percentage),
                    duration: const Duration(milliseconds: 900),
                    curve: Curves.easeOutCubic,
                    builder: (_, val, __) => LinearProgressIndicator(
                      value: val,
                      minHeight: 5,
                      backgroundColor: LTColors.surface3,
                      valueColor: AlwaysStoppedAnimation(g.color),
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Text('${g.current.toStringAsFixed(g.current == g.current.round() ? 0 : 1)} / ${g.target.toStringAsFixed(0)} ${g.unitLabel}',
                  style: LTText.body(12, color: LTColors.text3)),
              ],
            ),
          )),
        ],
      ),
    ),
  );

  // ─── MOOD ─────────────────────────────────────────────────────────────────
  Widget _buildMoodSection() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
    child: LTCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LTSectionHeader(
            title: "Today's Mood",
            trailing: _todayMood != null
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: LTColors.cyanDim, borderRadius: LTRadius.full),
                  child: Text(_todayMood!.level.label, style: LTText.body(12, color: LTColors.cyan, weight: FontWeight.w600)),
                )
              : null,
          ),
          const SizedBox(height: 14),
          LTMoodPicker(
            selected: _todayMood?.level.index,
            onSelect: (i) async {
              final level = MoodLevel.values[i];
              final entry = MoodEntry(
                id: _todayMood?.id ?? '',
                userId: widget.userId,
                level: level,
                date: DateTime.now(),
                createdAt: _todayMood?.createdAt ?? DateTime.now(),
              );
              setState(() => _todayMood = entry);
              await _svc.upsertMood(entry);
            },
          ),
        ],
      ),
    ),
  );

  // ─── SKELETON ─────────────────────────────────────────────────────────────
  Widget _buildSkeleton() => Padding(
    padding: const EdgeInsets.all(20),
    child: Column(children: List.generate(4, (_) =>
      Padding(padding: const EdgeInsets.only(bottom: 14), child:
        Container(height: 100, decoration: BoxDecoration(color: LTColors.surface2, borderRadius: LTRadius.lg))
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1200.ms, color: LTColors.surface3),
      ),
    )),
  );
}
