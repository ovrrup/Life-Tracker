// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/screens.dart';
import 'shared/icons/lt_icons.dart';
import 'shared/widgets/lt_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  SUPABASE CONFIG  →  Replace with your project URL and anon key
//  Get them from: https://app.supabase.com → Project Settings → API
// ─────────────────────────────────────────────────────────────────────────────
const _supabaseUrl  = 'https://YOUR_PROJECT_ID.supabase.co';
const _supabaseAnon = 'YOUR_ANON_KEY';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Status bar style
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: LTColors.bg,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Init Supabase
  await Supabase.initialize(url: _supabaseUrl, anonKey: _supabaseAnon);

  runApp(const LifetrackApp());
}

// ─── ROOT APP ─────────────────────────────────────────────────────────────────
class LifetrackApp extends StatelessWidget {
  const LifetrackApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Lifetrack',
    theme: LTTheme.dark,
    debugShowCheckedModeBanner: false,
    home: const _AuthGate(),
  );
}

// ─── AUTH GATE ────────────────────────────────────────────────────────────────
class _AuthGate extends StatefulWidget {
  const _AuthGate();
  @override State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  User? _user;
  bool _checked = false;

  @override void initState() {
    super.initState();
    _user = Supabase.instance.client.auth.currentUser;
    Supabase.instance.client.auth.onAuthStateChange.listen((state) {
      if (mounted) setState(() { _user = state.session?.user; _checked = true; });
    });
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted && !_checked) setState(() => _checked = true);
    });
  }

  @override Widget build(BuildContext context) {
    if (!_checked) return const Scaffold(
      backgroundColor: LTColors.bg,
      body: Center(child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(color: LTColors.cyan, strokeWidth: 2))),
    );
    if (_user == null) return const AuthScreen();
    return _MainShell(userId: _user!.id);
  }
}

// ─── MAIN SHELL ───────────────────────────────────────────────────────────────
class _MainShell extends StatefulWidget {
  final String userId;
  const _MainShell({required this.userId});
  @override State<_MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<_MainShell> {
  int _index = 0;

  final _navItems = [
    _NavItem(icon: LTIcons.home,     label: 'Home'),
    _NavItem(icon: LTIcons.habits,   label: 'Habits'),
    _NavItem(icon: LTIcons.tasks,    label: 'Tasks'),
    _NavItem(icon: LTIcons.insights, label: 'Insights'),
    _NavItem(icon: LTIcons.social,   label: 'Friends'),
  ];

  late final List<Widget> _pages;

  @override void initState() {
    super.initState();
    _pages = [
      DashboardScreen(userId: widget.userId),
      HabitsScreen(userId: widget.userId),
      TasksScreen(userId: widget.userId),
      InsightsScreen(userId: widget.userId),
      SocialScreen(userId: widget.userId),
    ];
  }

  @override Widget build(BuildContext context) => Scaffold(
    backgroundColor: LTColors.bg,
    body: IndexedStack(index: _index, children: _pages),
    bottomNavigationBar: _BottomNav(
      items: _navItems,
      selected: _index,
      onSelect: (i) { HapticFeedback.selectionClick(); setState(() => _index = i); },
    ),
    // Floating button for quick actions (opens full feature screens)
    floatingActionButton: _index == 0 ? _QuickActionFAB(userId: widget.userId) : null,
  );
}

// ─── BOTTOM NAV ───────────────────────────────────────────────────────────────
class _NavItem { final LTIconData icon; final String label; _NavItem({required this.icon, required this.label}); }

class _BottomNav extends StatelessWidget {
  final List<_NavItem> items;
  final int selected;
  final ValueChanged<int> onSelect;
  const _BottomNav({required this.items, required this.selected, required this.onSelect});

  @override Widget build(BuildContext context) => Container(
    height: kBottomNavigationBarHeight + MediaQuery.of(context).padding.bottom,
    padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom),
    decoration: const BoxDecoration(
      color: LTColors.surface1,
      border: Border(top: BorderSide(color: LTColors.border1)),
    ),
    child: Row(children: items.asMap().entries.map((e) {
      final isActive = e.key == selected;
      return Expanded(child: GestureDetector(
        onTap: () => onSelect(e.key),
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isActive ? LTColors.cyanDim : Colors.transparent,
                borderRadius: LTRadius.full,
              ),
              child: LTIcon(e.value.icon, size: 20, color: isActive ? LTColors.cyan : LTColors.text3,
                strokeWidth: isActive ? 2.0 : 1.6),
            ),
            const SizedBox(height: 3),
            Text(e.value.label, style: LTText.label.copyWith(
              color: isActive ? LTColors.cyan : LTColors.text3,
              fontSize: 9,
            )),
          ]),
        ),
      ));
    }).toList()),
  );
}

// ─── QUICK ACTION FAB ─────────────────────────────────────────────────────────
class _QuickActionFAB extends StatefulWidget {
  final String userId;
  const _QuickActionFAB({required this.userId});
  @override State<_QuickActionFAB> createState() => _QuickActionFABState();
}

class _QuickActionFABState extends State<_QuickActionFAB> with SingleTickerProviderStateMixin {
  bool _open = false;
  late final _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));

  final _actions = [
    (icon: LTIcons.tasks,   label: 'Task',    color: LTColors.gold),
    (icon: LTIcons.goals,   label: 'Goal',    color: LTColors.green),
    (icon: LTIcons.journal, label: 'Journal', color: LTColors.violet),
    (icon: LTIcons.mood,    label: 'Mood',    color: LTColors.cyan),
  ];

  void _toggle() {
    HapticFeedback.mediumImpact();
    setState(() => _open = !_open);
    if (_open) _ctrl.forward(); else _ctrl.reverse();
  }

  @override Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.end,
    children: [
      ..._actions.asMap().entries.map((e) => AnimatedContainer(
        duration: Duration(milliseconds: 150 + e.key * 30),
        margin: const EdgeInsets.only(bottom: 8, right: 4),
        child: _open ? _FabAction(
          icon: e.value.icon, label: e.value.label, color: e.value.color,
          onTap: () => _handleAction(context, e.value.label),
        ) : const SizedBox.shrink(),
      )),
      FloatingActionButton(
        onPressed: _toggle,
        backgroundColor: LTColors.cyan,
        elevation: 6,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) => Transform.rotate(
            angle: _ctrl.value * 0.785,
            child: LTIcon(LTIcons.plus, size: 22, color: const Color(0xFF050505), strokeWidth: 2.4),
          ),
        ),
      ),
    ],
  );

  void _handleAction(BuildContext ctx, String label) {
    _toggle();
    Navigator.push(ctx, MaterialPageRoute(builder: (_) => switch (label) {
      'Journal' => _JournalQuickEntry(userId: widget.userId),
      'Mood'    => MoodScreen(userId: widget.userId),
      'Goal'    => GoalsScreen(userId: widget.userId),
      _         => TasksScreen(userId: widget.userId),
    }));
  }
}

class _FabAction extends StatelessWidget {
  final LTIconData icon; final String label; final Color color; final VoidCallback onTap;
  const _FabAction({required this.icon, required this.label, required this.color, required this.onTap});

  @override Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(color: LTColors.surface2, borderRadius: LTRadius.sm, border: Border.all(color: LTColors.border2)),
        child: Text(label, style: LTText.body(12, weight: FontWeight.w600, color: LTColors.text1)),
      ),
      const SizedBox(width: 8),
      Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle, border: Border.all(color: color.withOpacity(0.4))),
        child: Center(child: LTIcon(icon, size: 18, color: color, strokeWidth: 1.8))),
    ]),
  );
}

// Quick journal entry sheet
class _JournalQuickEntry extends StatelessWidget {
  final String userId;
  const _JournalQuickEntry({required this.userId});

  @override Widget build(BuildContext context) => JournalScreen(userId: userId);
}
