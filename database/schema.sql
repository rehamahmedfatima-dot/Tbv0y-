-- ============================================================
-- TBVOY — The Best Version Of Yourself
-- PostgreSQL Schema (Supabase)
-- ============================================================

create extension if not exists "uuid-ossp";
create extension if not exists "pgcrypto";

-- ============================================================
-- USERS & PROFILE
-- ============================================================

-- users.id IS auth.users.id (Supabase Auth). A trigger (below) creates this
-- row automatically on signup — no manual insert needed from the app.
create table users (
    id uuid primary key references auth.users(id) on delete cascade,
    email text unique,
    display_name text,
    photo_url text,
    is_anonymous boolean default false,
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- Auto-create a public.users row whenever someone signs up via Supabase Auth
-- (covers Google, Apple, Email, and Anonymous sign-ins).
create or replace function public.handle_new_auth_user()
returns trigger as $$
begin
    insert into public.users (id, email, display_name, photo_url, is_anonymous)
    values (
        new.id,
        new.email,
        coalesce(new.raw_user_meta_data ->> 'full_name', new.raw_user_meta_data ->> 'name'),
        new.raw_user_meta_data ->> 'avatar_url',
        new.is_anonymous
    )
    on conflict (id) do nothing;
    return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
    after insert on auth.users
    for each row execute function public.handle_new_auth_user();

create table user_profiles (
    user_id uuid primary key references users(id) on delete cascade,
    age int,
    gender text check (gender in ('male','female','other','prefer_not_to_say')),
    occupation text,
    wake_up_time time,
    sleep_time time,
    preferred_language text default 'en',
    country text,
    timezone text default 'UTC',
    onboarding_completed boolean default false,
    onboarding_data jsonb default '{}'::jsonb,   -- raw onboarding answers (goals, priorities, dreams, bad habits, etc.)
    updated_at timestamptz default now()
);

create table user_settings (
    user_id uuid primary key references users(id) on delete cascade,
    theme_mode text default 'system' check (theme_mode in ('light','dark','system')),
    biometric_enabled boolean default false,
    notifications_enabled boolean default true,
    ai_personality text default 'balanced' check (ai_personality in ('gentle','balanced','tough_love')),
    daily_checkin_time time default '20:00',
    morning_mission_time time default '07:00',
    data_export_enabled boolean default true,
    updated_at timestamptz default now()
);

-- ============================================================
-- IDENTITY BUILDER
-- ============================================================

create table identities (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    title text not null,              -- e.g. "Disciplined Athlete"
    description text,
    icon text,
    color text,
    is_active boolean default true,
    progress_score numeric(5,2) default 0,
    created_at timestamptz default now()
);

-- ============================================================
-- LIFE AREAS (Wheel of Life)
-- ============================================================

create table life_areas (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    area_key text not null check (area_key in
        ('health','career','learning','relationships','spirituality','finance','mindset','productivity')),
    current_score numeric(5,2) default 5,
    target_score numeric(5,2) default 10,
    updated_at timestamptz default now(),
    unique (user_id, area_key)
);

-- ============================================================
-- HABITS
-- ============================================================

create table habit_categories (
    id uuid primary key default uuid_generate_v4(),
    key text unique not null,          -- health, fitness, reading, learning, work, prayer, meditation, finance, relationships, custom
    label text not null,
    icon text,
    color text
);

create table habits (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    identity_id uuid references identities(id) on delete set null,
    category_id uuid references habit_categories(id),
    title text not null,
    description text,
    icon text,
    color text,
    frequency_type text not null check (frequency_type in ('daily','weekly','custom_days','x_times_per_week')),
    frequency_config jsonb default '{}'::jsonb,   -- e.g. {"days":["mon","wed","fri"]} or {"times_per_week":3}
    reminder_times time[],
    priority text default 'medium' check (priority in ('low','medium','high')),
    target_value numeric,              -- e.g. pages, minutes, reps
    target_unit text,
    is_active boolean default true,
    archived_at timestamptz,
    created_at timestamptz default now()
);

create table habit_logs (
    id uuid primary key default uuid_generate_v4(),
    habit_id uuid references habits(id) on delete cascade,
    user_id uuid references users(id) on delete cascade,
    log_date date not null,
    completed boolean default false,
    value numeric,                     -- actual value if habit is quantitative
    note text,
    completed_at timestamptz,
    created_at timestamptz default now(),
    unique (habit_id, log_date)
);

create table habit_streaks (
    habit_id uuid primary key references habits(id) on delete cascade,
    current_streak int default 0,
    longest_streak int default 0,
    last_completed_date date,
    updated_at timestamptz default now()
);

-- ============================================================
-- DISCIPLINE SCORE (daily rollup)
-- ============================================================

create table discipline_scores (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    score_date date not null,
    overall_score numeric(5,2) not null,
    wake_up_score numeric(5,2),
    habit_completion_score numeric(5,2),
    sleep_score numeric(5,2),
    focus_score numeric(5,2),
    journal_score numeric(5,2),
    mood_score numeric(5,2),
    exercise_score numeric(5,2),
    learning_score numeric(5,2),
    prayer_score numeric(5,2),
    deep_work_score numeric(5,2),
    created_at timestamptz default now(),
    unique (user_id, score_date)
);

-- ============================================================
-- JOURNAL
-- ============================================================

create table journal_entries (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    entry_date date not null,
    entry_type text not null check (entry_type in ('morning','evening','gratitude','lesson','freeform')),
    content text,
    ai_summary text,
    mood_at_entry text,
    tags text[],
    created_at timestamptz default now(),
    updated_at timestamptz default now()
);

-- ============================================================
-- MOOD TRACKER
-- ============================================================

create table mood_logs (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    log_date date not null,
    log_time time default current_time,
    mood text not null check (mood in ('great','good','neutral','low','bad')),
    mood_score int check (mood_score between 1 and 10),
    triggers text[],
    note text,
    created_at timestamptz default now()
);

-- ============================================================
-- GOALS
-- ============================================================

create table goals (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    life_area_id uuid references life_areas(id) on delete set null,
    title text not null,
    description text,
    goal_type text default 'short_term' check (goal_type in ('short_term','long_term')),
    target_date date,
    status text default 'active' check (status in ('active','completed','paused','abandoned')),
    progress_percent numeric(5,2) default 0,
    ai_roadmap jsonb default '[]'::jsonb,
    created_at timestamptz default now(),
    completed_at timestamptz
);

create table milestones (
    id uuid primary key default uuid_generate_v4(),
    goal_id uuid references goals(id) on delete cascade,
    title text not null,
    is_completed boolean default false,
    due_date date,
    completed_at timestamptz,
    sort_order int default 0
);

-- ============================================================
-- FOCUS MODE
-- ============================================================

create table focus_sessions (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    session_type text check (session_type in ('pomodoro','deep_work','forest')),
    duration_minutes int not null,
    completed boolean default false,
    interrupted boolean default false,
    started_at timestamptz not null,
    ended_at timestamptz,
    linked_habit_id uuid references habits(id) on delete set null
);

-- ============================================================
-- CHALLENGES
-- ============================================================

create table challenges (
    id uuid primary key default uuid_generate_v4(),
    title text not null,
    description text,
    duration_days int not null,
    is_global boolean default false,
    created_by uuid references users(id) on delete set null,
    created_at timestamptz default now()
);

create table challenge_participants (
    id uuid primary key default uuid_generate_v4(),
    challenge_id uuid references challenges(id) on delete cascade,
    user_id uuid references users(id) on delete cascade,
    start_date date not null,
    current_day int default 0,
    status text default 'active' check (status in ('active','completed','failed','abandoned')),
    unique (challenge_id, user_id)
);

-- ============================================================
-- AI MISSIONS
-- ============================================================

create table ai_missions (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    mission_date date not null,
    title text not null,
    description text,
    is_completed boolean default false,
    completed_at timestamptz,
    generated_context jsonb default '{}'::jsonb,
    unique (user_id, mission_date)
);

-- ============================================================
-- FUTURE SELF / LETTERS
-- ============================================================

create table letters (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    author text default 'user' check (author in ('user','ai')),
    title text,
    content text not null,
    written_at timestamptz default now(),
    open_at timestamptz not null,
    opened boolean default false,
    opened_at timestamptz
);

-- ============================================================
-- GROWTH TREE
-- ============================================================

create table growth_tree_state (
    user_id uuid primary key references users(id) on delete cascade,
    tree_stage int default 1,          -- seed -> sapling -> tree -> blooming
    health numeric(5,2) default 100,
    leaves_count int default 0,
    season text default 'spring',
    last_activity_date date,
    updated_at timestamptz default now()
);

-- ============================================================
-- LEGACY PAGE
-- ============================================================

create table legacy_profiles (
    user_id uuid primary key references users(id) on delete cascade,
    mission_statement text,
    core_values text[],
    vision text,
    life_purpose text,
    dreams text[],
    updated_at timestamptz default now()
);

-- ============================================================
-- SKILLS
-- ============================================================

create table skills (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    title text not null,
    category text,
    level text default 'beginner' check (level in ('beginner','intermediate','advanced','expert')),
    hours_logged numeric(6,2) default 0,
    started_at date,
    certificate_url text,
    created_at timestamptz default now()
);

create table skill_sessions (
    id uuid primary key default uuid_generate_v4(),
    skill_id uuid references skills(id) on delete cascade,
    session_date date not null,
    minutes int not null,
    note text
);

-- ============================================================
-- READING JOURNEY
-- ============================================================

create table books (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    title text not null,
    author text,
    total_pages int,
    pages_read int default 0,
    status text default 'reading' check (status in ('want_to_read','reading','completed','abandoned')),
    started_at date,
    finished_at date,
    rating int check (rating between 1 and 5),
    cover_url text,
    created_at timestamptz default now()
);

create table book_notes (
    id uuid primary key default uuid_generate_v4(),
    book_id uuid references books(id) on delete cascade,
    note_type text default 'note' check (note_type in ('note','quote')),
    content text not null,
    page_number int,
    created_at timestamptz default now()
);

-- ============================================================
-- ACHIEVEMENTS / XP / BADGES
-- ============================================================

create table achievements (
    id uuid primary key default uuid_generate_v4(),
    key text unique not null,
    title text not null,
    description text,
    category text,
    icon text,
    xp_reward int default 0
);

create table user_achievements (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    achievement_id uuid references achievements(id) on delete cascade,
    unlocked_at timestamptz default now(),
    unique (user_id, achievement_id)
);

create table user_levels (
    user_id uuid primary key references users(id) on delete cascade,
    xp int default 0,
    level int default 1,
    updated_at timestamptz default now()
);

-- ============================================================
-- AI CONVERSATIONS (Coach)
-- ============================================================

create table ai_conversations (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    title text,
    conversation_type text default 'general' check
        (conversation_type in ('general','daily_checkin','weekly_review','monthly_report')),
    created_at timestamptz default now()
);

create table ai_messages (
    id uuid primary key default uuid_generate_v4(),
    conversation_id uuid references ai_conversations(id) on delete cascade,
    role text not null check (role in ('user','assistant')),
    content text not null,
    audio_url text,
    created_at timestamptz default now()
);

-- ============================================================
-- ANNUAL / STORY REPORTS
-- ============================================================

create table story_reports (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    report_year int not null,
    title text default 'The Story of Your Best Version',
    content jsonb not null,     -- structured sections: strengths, growth, timeline, before/after
    generated_at timestamptz default now(),
    unique (user_id, report_year)
);

-- ============================================================
-- NOTIFICATIONS LOG
-- ============================================================

create table notification_logs (
    id uuid primary key default uuid_generate_v4(),
    user_id uuid references users(id) on delete cascade,
    type text not null,
    title text not null,
    body text,
    sent_at timestamptz default now(),
    opened boolean default false
);

-- ============================================================
-- INDEXES
-- ============================================================

create index idx_habit_logs_user_date on habit_logs(user_id, log_date);
create index idx_discipline_scores_user_date on discipline_scores(user_id, score_date);
create index idx_journal_user_date on journal_entries(user_id, entry_date);
create index idx_mood_logs_user_date on mood_logs(user_id, log_date);
create index idx_goals_user_status on goals(user_id, status);
create index idx_habits_user_active on habits(user_id, is_active);
create index idx_ai_messages_conversation on ai_messages(conversation_id, created_at);
create index idx_letters_user_open on letters(user_id, open_at);
create index idx_focus_sessions_user on focus_sessions(user_id, started_at);

-- ============================================================
-- ROW LEVEL SECURITY (Supabase)
-- ============================================================

alter table users enable row level security;
alter table habits enable row level security;
alter table habit_logs enable row level security;
alter table journal_entries enable row level security;
alter table mood_logs enable row level security;
alter table goals enable row level security;
alter table letters enable row level security;

-- users.id == auth.uid() directly now, so policies are a simple equality check.
create policy "Users manage own row" on users
    for all using (id = auth.uid());

create policy "Users manage own habits" on habits
    for all using (user_id = auth.uid());

create policy "Users manage own habit_logs" on habit_logs
    for all using (user_id = auth.uid());

create policy "Users manage own journal" on journal_entries
    for all using (user_id = auth.uid());

create policy "Users manage own mood_logs" on mood_logs
    for all using (user_id = auth.uid());

create policy "Users manage own goals" on goals
    for all using (user_id = auth.uid());

create policy "Users manage own letters" on letters
    for all using (user_id = auth.uid());

-- Apply the same pattern to every remaining user-owned table:
alter table user_profiles enable row level security;
alter table user_settings enable row level security;
alter table identities enable row level security;
alter table life_areas enable row level security;
alter table habit_streaks enable row level security;
alter table discipline_scores enable row level security;
alter table goals enable row level security;
alter table milestones enable row level security;
alter table focus_sessions enable row level security;
alter table challenge_participants enable row level security;
alter table ai_missions enable row level security;
alter table growth_tree_state enable row level security;
alter table legacy_profiles enable row level security;
alter table skills enable row level security;
alter table skill_sessions enable row level security;
alter table books enable row level security;
alter table book_notes enable row level security;
alter table user_achievements enable row level security;
alter table user_levels enable row level security;
alter table ai_conversations enable row level security;
alter table ai_messages enable row level security;
alter table story_reports enable row level security;
alter table notification_logs enable row level security;

create policy "Users manage own profile" on user_profiles for all using (user_id = auth.uid());
create policy "Users manage own settings" on user_settings for all using (user_id = auth.uid());
create policy "Users manage own identities" on identities for all using (user_id = auth.uid());
create policy "Users manage own life_areas" on life_areas for all using (user_id = auth.uid());
create policy "Users view own streaks" on habit_streaks for all using
    (habit_id in (select id from habits where user_id = auth.uid()));
create policy "Users manage own discipline_scores" on discipline_scores for all using (user_id = auth.uid());
create policy "Users manage own milestones" on milestones for all using
    (goal_id in (select id from goals where user_id = auth.uid()));
create policy "Users manage own focus_sessions" on focus_sessions for all using (user_id = auth.uid());
create policy "Users manage own challenge_participation" on challenge_participants for all using (user_id = auth.uid());
create policy "Users manage own ai_missions" on ai_missions for all using (user_id = auth.uid());
create policy "Users manage own growth_tree" on growth_tree_state for all using (user_id = auth.uid());
create policy "Users manage own legacy" on legacy_profiles for all using (user_id = auth.uid());
create policy "Users manage own skills" on skills for all using (user_id = auth.uid());
create policy "Users manage own skill_sessions" on skill_sessions for all using
    (skill_id in (select id from skills where user_id = auth.uid()));
create policy "Users manage own books" on books for all using (user_id = auth.uid());
create policy "Users manage own book_notes" on book_notes for all using
    (book_id in (select id from books where user_id = auth.uid()));
create policy "Users view own achievements" on user_achievements for all using (user_id = auth.uid());
create policy "Users view own level" on user_levels for all using (user_id = auth.uid());
create policy "Users manage own ai_conversations" on ai_conversations for all using (user_id = auth.uid());
create policy "Users manage own ai_messages" on ai_messages for all using
    (conversation_id in (select id from ai_conversations where user_id = auth.uid()));
create policy "Users view own story_reports" on story_reports for all using (user_id = auth.uid());
create policy "Users view own notification_logs" on notification_logs for all using (user_id = auth.uid());
