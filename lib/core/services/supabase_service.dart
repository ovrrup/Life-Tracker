// lib/core/services/supabase_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/models.dart';

// ─── SUPABASE SQL SCHEMA (run in Supabase SQL editor) ─────────────────────────
// Paste into Supabase → SQL Editor to create all tables:
/*
-- Enable UUID
create extension if not exists "uuid-ossp";

-- USERS PROFILE (extends auth.users)
create table public.profiles (
  id           uuid primary key references auth.users(id) on delete cascade,
  email        text not null,
  display_name text not null default 'User',
  avatar_url   text,
  created_at   timestamptz default now(),
  total_streak int default 0,
  friend_ids   uuid[] default array[]::uuid[]
);
alter table public.profiles enable row level security;
create policy "Users can view own profile" on public.profiles for select using (auth.uid() = id);
create policy "Users can update own profile" on public.profiles for update using (auth.uid() = id);
create policy "Friends can view profiles" on public.profiles for select using (
  auth.uid() = any(friend_ids) or auth.uid() = id
);

-- HABITS
create table public.habits (
  id             uuid primary key default uuid_generate_v4(),
  user_id        uuid not null references auth.users(id) on delete cascade,
  name           text not null,
  color_hex      text not null default '#3ECFCA',
  active_days    int[] not null default array[0,1,2,3,4,5,6],
  is_active      boolean not null default true,
  current_streak int not null default 0,
  longest_streak int not null default 0,
  created_at     timestamptz default now()
);
alter table public.habits enable row level security;
create policy "Users manage own habits" on public.habits for all using (auth.uid() = user_id);

-- HABIT LOGS
create table public.habit_logs (
  id         uuid primary key default uuid_generate_v4(),
  habit_id   uuid not null references public.habits(id) on delete cascade,
  user_id    uuid not null references auth.users(id) on delete cascade,
  date       date not null,
  completed  boolean not null default false,
  unique(habit_id, date)
);
alter table public.habit_logs enable row level security;
create policy "Users manage own habit logs" on public.habit_logs for all using (auth.uid() = user_id);
-- Friends can see habit logs
create policy "Friends can view habit logs" on public.habit_logs for select using (
  exists (select 1 from public.profiles where id = auth.uid() and user_id = any(friend_ids))
);

-- TASKS
create table public.tasks (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  title      text not null,
  notes      text,
  is_done    boolean not null default false,
  priority   text not null default 'medium',
  date       date not null,
  due_time   timestamptz,
  created_at timestamptz default now()
);
alter table public.tasks enable row level security;
create policy "Users manage own tasks" on public.tasks for all using (auth.uid() = user_id);

-- MOOD ENTRIES
create table public.mood_entries (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  level      text not null default 'neutral',
  note       text,
  tags       text[] default array[]::text[],
  date       date not null,
  created_at timestamptz default now(),
  unique(user_id, date)
);
alter table public.mood_entries enable row level security;
create policy "Users manage own mood" on public.mood_entries for all using (auth.uid() = user_id);

-- JOURNAL ENTRIES
create table public.journal_entries (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  title      text not null default 'Untitled',
  content    text not null default '',
  date       date not null,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);
alter table public.journal_entries enable row level security;
create policy "Users manage own journal" on public.journal_entries for all using (auth.uid() = user_id);

-- GOALS
create table public.goals (
  id          uuid primary key default uuid_generate_v4(),
  user_id     uuid not null references auth.users(id) on delete cascade,
  name        text not null,
  current     numeric not null default 0,
  target      numeric not null default 100,
  unit        text not null default 'count',
  custom_unit text,
  color_hex   text not null default '#3ECFCA',
  deadline    date,
  created_at  timestamptz default now()
);
alter table public.goals enable row level security;
create policy "Users manage own goals" on public.goals for all using (auth.uid() = user_id);

-- FRIEND REQUESTS
create table public.friend_requests (
  id          uuid primary key default uuid_generate_v4(),
  from_id     uuid not null references auth.users(id) on delete cascade,
  to_id       uuid not null references auth.users(id) on delete cascade,
  status      text not null default 'pending',
  created_at  timestamptz default now(),
  unique(from_id, to_id)
);
alter table public.friend_requests enable row level security;
create policy "Users see own requests" on public.friend_requests for select using (auth.uid() = from_id or auth.uid() = to_id);
create policy "Users send requests" on public.friend_requests for insert with check (auth.uid() = from_id);
create policy "Recipients update requests" on public.friend_requests for update using (auth.uid() = to_id);

-- ACTIVITY FEED (for friends)
create table public.activity_feed (
  id         uuid primary key default uuid_generate_v4(),
  user_id    uuid not null references auth.users(id) on delete cascade,
  action     text not null,
  subject    text not null,
  created_at timestamptz default now()
);
alter table public.activity_feed enable row level security;
create policy "Users create own activity" on public.activity_feed for insert with check (auth.uid() = user_id);
create policy "Friends view activity" on public.activity_feed for select using (
  exists (select 1 from public.profiles where id = auth.uid() and user_id = any(friend_ids))
  or auth.uid() = user_id
);

-- Function: auto-create profile on signup
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, split_part(new.email, '@', 1));
  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Realtime
alter publication supabase_realtime add table public.habit_logs;
alter publication supabase_realtime add table public.activity_feed;
alter publication supabase_realtime add table public.friend_requests;
*/

// ─── SERVICE ──────────────────────────────────────────────────────────────────
class SupabaseService {
  SupabaseService._();
  static final SupabaseService instance = SupabaseService._();

  SupabaseClient get _db => Supabase.instance.client;
  String? get currentUserId => _db.auth.currentUser?.id;

  // ── AUTH ──────────────────────────────────────────────────────────────────
  Future<AuthResponse> signUp(String email, String password, String name) async {
    final res = await _db.auth.signUp(email: email, password: password, data: {'display_name': name});
    return res;
  }

  Future<AuthResponse> signIn(String email, String password) =>
    _db.auth.signInWithPassword(email: email, password: password);

  Future<void> signOut() => _db.auth.signOut();

  Stream<AuthState> get authStateChanges => _db.auth.onAuthStateChange;

  // ── PROFILE ───────────────────────────────────────────────────────────────
  Future<AppUser?> getProfile(String userId) async {
    final data = await _db.from('profiles').select().eq('id', userId).maybeSingle();
    if (data == null) return null;
    return AppUser.fromJson(data);
  }

  Future<void> updateProfile(AppUser user) async {
    await _db.from('profiles').update(user.toJson()).eq('id', user.id);
  }

  // ── HABITS ────────────────────────────────────────────────────────────────
  Future<List<Habit>> getHabits() async {
    final uid = currentUserId; if (uid == null) return [];
    final data = await _db.from('habits').select().eq('user_id', uid).order('created_at');
    return (data as List).map((j) => Habit.fromJson(j)).toList();
  }

  Future<Habit> createHabit(Habit habit) async {
        final payload = habit.toJson()..remove('id');
            final data = await _db.from('habits').insert(payload).select().single();
                return Habit.fromJson(data);
  }

  Future<void> updateHabit(Habit habit) async {
    await _db.from('habits').update(habit.toJson()).eq('id', habit.id);
  }

  Future<void> deleteHabit(String id) async {
    await _db.from('habits').delete().eq('id', id);
  }

  // ── HABIT LOGS ────────────────────────────────────────────────────────────
  Future<Map<String, bool>> getHabitLogsForRange(DateTime start, DateTime end) async {
    final uid = currentUserId; if (uid == null) return {};
    final data = await _db.from('habit_logs')
      .select()
      .eq('user_id', uid)
      .gte('date', start.toIso8601String().split('T')[0])
      .lte('date', end.toIso8601String().split('T')[0]);
    final Map<String, bool> result = {};
    for (final j in (data as List)) {
      result['${j['habit_id']}_${j['date']}'] = j['completed'] as bool? ?? false;
    }
    return result;
  }

  Future<void> toggleHabitLog(String habitId, DateTime date, bool completed) async {
    final uid = currentUserId; if (uid == null) return;
    final dateStr = date.toIso8601String().split('T')[0];
    await _db.from('habit_logs').upsert({
      'habit_id': habitId,
      'user_id':  uid,
      'date':     dateStr,
      'completed': completed,
    }, onConflict: 'habit_id,date');
    // Log to activity if completed
    if (completed) {
      final habits = await getHabits();
      final habit = habits.where((h) => h.id == habitId).firstOrNull;
      if (habit != null) {
        await _logActivity('completed habit', habit.name);
      }
    }
  }

  // ── TASKS ──────────────────────────────────────────────────────────────────
  Future<List<Task>> getTasksForDate(DateTime date) async {
    final uid = currentUserId; if (uid == null) return [];
    final data = await _db.from('tasks')
      .select().eq('user_id', uid)
      .eq('date', date.toIso8601String().split('T')[0])
      .order('created_at');
    return (data as List).map((j) => Task.fromJson(j)).toList();
  }

  Future<List<Task>> getAllPendingTasks() async {
    final uid = currentUserId; if (uid == null) return [];
    final data = await _db.from('tasks')
      .select().eq('user_id', uid).eq('is_done', false)
      .order('date').order('created_at');
    return (data as List).map((j) => Task.fromJson(j)).toList();
  }

  Future<Task> createTask(Task task) async {
        final payload = task.toJson()..remove('id');
            final data = await _db.from('tasks').insert(payload).select().single();
                return Task.fromJson(data);
  }

  Future<void> updateTask(Task task) async {
    await _db.from('tasks').update(task.toJson()).eq('id', task.id);
  }

  Future<void> deleteTask(String id) async {
    await _db.from('tasks').delete().eq('id', id);
  }

  // ── MOOD ──────────────────────────────────────────────────────────────────
  Future<List<MoodEntry>> getMoodEntries(int days) async {
    final uid = currentUserId; if (uid == null) return [];
    final since = DateTime.now().subtract(Duration(days: days));
    final data = await _db.from('mood_entries')
      .select().eq('user_id', uid)
      .gte('date', since.toIso8601String().split('T')[0])
      .order('date', ascending: false);
    return (data as List).map((j) => MoodEntry.fromJson(j)).toList();
  }

  Future<MoodEntry?> getTodayMood() async {
    final uid = currentUserId; if (uid == null) return null;
    final today = DateTime.now().toIso8601String().split('T')[0];
    final data = await _db.from('mood_entries')
      .select().eq('user_id', uid).eq('date', today).maybeSingle();
    if (data == null) return null;
    return MoodEntry.fromJson(data);
  }

    Future<void> upsertMood(MoodEntry entry) async {
          final payload = entry.toJson();
              if (entry.id.isEmpty) payload.remove('id');
                  await _db.from('mood_entries').upsert(payload, onConflict: 'user_id,date');
    }

  // ── JOURNAL ───────────────────────────────────────────────────────────────
  Future<List<JournalEntry>> getJournalEntries({int limit = 20, int offset = 0}) async {
    final uid = currentUserId; if (uid == null) return [];
    final data = await _db.from('journal_entries')
      .select().eq('user_id', uid)
      .order('date', ascending: false)
      .range(offset, offset + limit - 1);
    return (data as List).map((j) => JournalEntry.fromJson(j)).toList();
  }

  Future<JournalEntry> createJournalEntry(JournalEntry entry) async {
        final payload = entry.toJson()..remove('id');
            final data = await _db.from('journal_entries').insert(payload).select().single();
                return JournalEntry.fromJson(data);
  }

  Future<void> updateJournalEntry(JournalEntry entry) async {
    entry.updatedAt = DateTime.now();
    await _db.from('journal_entries').update(entry.toJson()).eq('id', entry.id);
  }

  Future<void> deleteJournalEntry(String id) async {
    await _db.from('journal_entries').delete().eq('id', id);
  }

  // ── GOALS ──────────────────────────────────────────────────────────────────
  Future<List<Goal>> getGoals() async {
    final uid = currentUserId; if (uid == null) return [];
    final data = await _db.from('goals').select().eq('user_id', uid).order('created_at');
    return (data as List).map((j) => Goal.fromJson(j)).toList();
  }

  Future<Goal> createGoal(Goal goal) async {
        final payload = goal.toJson()..remove('id');
            final data = await _db.from('goals').insert(payload).select().single();
                return Goal.fromJson(data);
  }

  Future<void> updateGoal(Goal goal) async {
    await _db.from('goals').update(goal.toJson()).eq('id', goal.id);
    // Log if completed
    if (goal.percentage >= 1.0) {
      await _logActivity('reached goal', goal.name);
    }
  }

  Future<void> deleteGoal(String id) async {
    await _db.from('goals').delete().eq('id', id);
  }

  // ── SOCIAL / FRIENDS ──────────────────────────────────────────────────────
  Future<List<AppUser>> getFriends() async {
    final uid = currentUserId; if (uid == null) return [];
    final profile = await getProfile(uid);
    if (profile == null || profile.friendIds.isEmpty) return [];
    final data = await _db.from('profiles')
      .select().inFilter('id', profile.friendIds);
    return (data as List).map((j) => AppUser.fromJson(j)).toList();
  }

  Future<void> sendFriendRequest(String toEmail) async {
    final uid = currentUserId; if (uid == null) return;
    // Find user by email
    final userData = await _db.from('profiles').select().eq('email', toEmail).maybeSingle();
    if (userData == null) throw Exception('User not found');
    final toId = userData['id'] as String;
    await _db.from('friend_requests').insert({
      'from_id': uid, 'to_id': toId, 'status': 'pending',
    });
  }

  Future<void> acceptFriendRequest(String requestId, String fromId) async {
    final uid = currentUserId; if (uid == null) return;
    await _db.from('friend_requests').update({'status': 'accepted'}).eq('id', requestId);
    // Mutual friend add via RPC or edge function
    await _db.rpc('add_friends', params: {'user_a': uid, 'user_b': fromId});
  }

  Future<List<Map<String, dynamic>>> getPendingRequests() async {
    final uid = currentUserId; if (uid == null) return [];
    return await _db.from('friend_requests')
      .select('*, profiles!from_id(display_name, avatar_url)')
      .eq('to_id', uid).eq('status', 'pending');
  }

  Future<List<FriendActivity>> getFriendActivity() async {
    final uid = currentUserId; if (uid == null) return [];
    // Get friend IDs
    final profile = await getProfile(uid);
    if (profile == null || profile.friendIds.isEmpty) return [];
    final data = await _db.from('activity_feed')
      .select('*, profiles!user_id(display_name, avatar_url)')
      .inFilter('user_id', profile.friendIds)
      .order('created_at', ascending: false)
      .limit(20);
    return (data as List).map((j) => FriendActivity(
      userId:    j['user_id'] as String,
      userName:  j['profiles']['display_name'] as String? ?? 'User',
      avatarUrl: j['profiles']['avatar_url'] as String?,
      action:    j['action'] as String,
      subject:   j['subject'] as String,
      time:      DateTime.parse(j['created_at'] as String),
    )).toList();
  }

  // ── REALTIME ──────────────────────────────────────────────────────────────
  RealtimeChannel subscribeToHabitLogs(
    String userId,
    void Function(Map<String, dynamic>) onUpdate,
  ) {
    return _db.channel('habit-logs-$userId')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'habit_logs',
        filter: PostgresChangeFilter(type: PostgresChangeFilterType.eq, column: 'user_id', value: userId),
        callback: (payload) => onUpdate(payload.newRecord),
      )
      .subscribe();
  }

  RealtimeChannel subscribeToFriendActivity(
    void Function(Map<String, dynamic>) onActivity,
  ) {
    return _db.channel('activity-feed')
      .onPostgresChanges(
        event: PostgresChangeEvent.insert,
        schema: 'public',
        table: 'activity_feed',
        callback: (payload) => onActivity(payload.newRecord),
      )
      .subscribe();
  }

  // ── INSIGHTS ──────────────────────────────────────────────────────────────
  Future<Map<String, dynamic>> getInsightData() async {
    final uid = currentUserId; if (uid == null) return {};
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));

    // Parallel fetch
    final results = await Future.wait([
      _db.from('habit_logs').select().eq('user_id', uid)
        .gte('date', thirtyDaysAgo.toIso8601String().split('T')[0])
        .eq('completed', true),
      _db.from('tasks').select().eq('user_id', uid)
        .gte('date', thirtyDaysAgo.toIso8601String().split('T')[0]),
      _db.from('mood_entries').select().eq('user_id', uid)
        .gte('date', thirtyDaysAgo.toIso8601String().split('T')[0]),
    ]);

    return {
      'habit_logs': results[0],
      'tasks':      results[1],
      'mood_entries': results[2],
    };
  }

  // ── PRIVATE ───────────────────────────────────────────────────────────────
  Future<void> _logActivity(String action, String subject) async {
    final uid = currentUserId; if (uid == null) return;
    await _db.from('activity_feed').insert({
      'user_id': uid, 'action': action, 'subject': subject,
    });
  }
}
