import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../providers/onboarding_providers.dart';
import '../widgets/onboarding_widgets.dart';
import 'ai_suggestions_screen.dart';

const _kTotalPages = 5;

const _kLifeAreas = [
  ('health', 'Health', Icons.favorite_border_rounded),
  ('career', 'Career', Icons.work_outline_rounded),
  ('learning', 'Learning', Icons.school_outlined),
  ('relationships', 'Relationships', Icons.people_outline_rounded),
  ('spirituality', 'Spirituality', Icons.self_improvement_rounded),
  ('finance', 'Finance', Icons.savings_outlined),
  ('mindset', 'Mindset', Icons.psychology_outlined),
  ('productivity', 'Productivity', Icons.bolt_outlined),
];

const _kIdentityOptions = [
  'Confident Person', 'Reader', 'Athlete', 'Entrepreneur', 'Programmer',
  'Leader', 'Disciplined Person', 'Healthy Person', 'Early Riser', 'Deep Worker',
];

const _kCommonHabits = ['Exercise', 'Reading', 'Meditation', 'Journaling', 'Prayer', 'Healthy Eating'];
const _kCommonBadHabits = ['Procrastination', 'Phone overuse', 'Poor sleep', 'Junk food', 'Skipping workouts'];

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  int _page = 0;

  // Local controllers for free-text fields (kept outside Riverpod state to
  // avoid rebuilding the whole tree on every keystroke).
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _occupationController = TextEditingController();
  final _dreamsController = TextEditingController();
  final _goalsController = TextEditingController();

  String? _gender;
  TimeOfDay _wakeUp = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay _sleep = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _missionTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _checkinTime = const TimeOfDay(hour: 20, minute: 0);

  final Set<String> _currentHabits = {};
  final Set<String> _badHabits = {};
  final Set<String> _identities = {};
  final Map<String, int> _priorities = {for (final a in _kLifeAreas) a.$1: 5};

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _occupationController.dispose();
    _dreamsController.dispose();
    _goalsController.dispose();
    super.dispose();
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  bool get _canContinuePage0 =>
      _nameController.text.trim().isNotEmpty && _ageController.text.trim().isNotEmpty && _gender != null;

  bool get _canContinuePage3 => _identities.isNotEmpty;

  void _next() {
    if (_page < _kTotalPages - 1) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    } else {
      _submit();
    }
  }

  void _back() {
    if (_page > 0) {
      _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  Future<void> _submit() async {
    final draftNotifier = ref.read(onboardingDraftProvider.notifier);
    draftNotifier
      ..updateBasicInfo(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()),
        gender: _gender,
        occupation: _occupationController.text.trim(),
        language: 'en',
      )
      ..updateSchedule(wakeUpTime: _fmt(_wakeUp), sleepTime: _fmt(_sleep))
      ..updateHabits(currentHabits: _currentHabits.toList(), badHabits: _badHabits.toList())
      ..updatePrioritiesAndDreams(
        lifePriorities: _priorities,
        bigDreams: _dreamsController.text.trim().isEmpty ? [] : [_dreamsController.text.trim()],
        goalsFreeText: _goalsController.text.trim(),
        desiredIdentities: _identities.toList(),
      )
      ..updateNotificationTimes([_fmt(_missionTime), _fmt(_checkinTime)]);

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AiSuggestionsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            children: [
              Row(
                children: [
                  if (_page > 0)
                    IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded), onPressed: _back)
                  else
                    const SizedBox(width: 48),
                  Expanded(
                    child: OnboardingProgressBar(currentPage: _page, totalPages: _kTotalPages),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _page = i),
                  children: [
                    _buildBasicInfoPage(),
                    _buildSchedulePage(),
                    _buildHabitsPage(),
                    _buildIdentitiesAndPrioritiesPage(),
                    _buildDreamsAndNotificationsPage(),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isCurrentPageValid() ? _next : null,
                  child: Text(_page == _kTotalPages - 1 ? 'Analyze My Journey' : 'Continue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  bool _isCurrentPageValid() {
    switch (_page) {
      case 0:
        return _canContinuePage0;
      case 3:
        return _canContinuePage3;
      default:
        return true;
    }
  }

  // Page 1 — Basic info
  Widget _buildBasicInfoPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingHeading(
            title: 'Let\'s get to know you',
            subtitle: 'This helps TBVOY personalize everything for you.',
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Your name'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _ageController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Age'),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            children: [
              for (final g in const ['male', 'female', 'other', 'prefer_not_to_say'])
                MultiSelectChip(
                  label: g == 'prefer_not_to_say' ? 'Prefer not to say' : g[0].toUpperCase() + g.substring(1),
                  selected: _gender == g,
                  onTap: () => setState(() => _gender = g),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _occupationController,
            decoration: const InputDecoration(labelText: 'Occupation (optional)'),
          ),
        ],
      ),
    );
  }

  // Page 2 — Schedule
  Widget _buildSchedulePage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingHeading(
            title: 'Your daily rhythm',
            subtitle: 'We use this to build your Discipline Score.',
          ),
          const SizedBox(height: AppSpacing.xl),
          _timePickerTile('Wake-up time', _wakeUp, (t) => setState(() => _wakeUp = t)),
          const SizedBox(height: AppSpacing.md),
          _timePickerTile('Sleep time', _sleep, (t) => setState(() => _sleep = t)),
        ],
      ),
    );
  }

  // Page 3 — Habits
  Widget _buildHabitsPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingHeading(
            title: 'Your habits today',
            subtitle: 'No judgment — just a starting point.',
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Habits you already have', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final h in _kCommonHabits)
                MultiSelectChip(
                  label: h,
                  selected: _currentHabits.contains(h),
                  onTap: () => setState(() =>
                      _currentHabits.contains(h) ? _currentHabits.remove(h) : _currentHabits.add(h)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('Habits you want to change', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final h in _kCommonBadHabits)
                MultiSelectChip(
                  label: h,
                  selected: _badHabits.contains(h),
                  onTap: () =>
                      setState(() => _badHabits.contains(h) ? _badHabits.remove(h) : _badHabits.add(h)),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Page 4 — Identities + Wheel of Life priorities
  Widget _buildIdentitiesAndPrioritiesPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingHeading(
            title: 'Who do you want to become?',
            subtitle: 'Pick as many as resonate with you.',
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (final id in _kIdentityOptions)
                MultiSelectChip(
                  label: id,
                  selected: _identities.contains(id),
                  onTap: () =>
                      setState(() => _identities.contains(id) ? _identities.remove(id) : _identities.add(id)),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('How important is each area right now?', style: Theme.of(context).textTheme.titleLarge),
          for (final area in _kLifeAreas)
            LifeAreaSlider(
              label: area.$2,
              icon: area.$3,
              value: _priorities[area.$1] ?? 5,
              onChanged: (v) => setState(() => _priorities[area.$1] = v),
            ),
        ],
      ),
    );
  }

  // Page 5 — Dreams, goals, notification preferences
  Widget _buildDreamsAndNotificationsPage() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const OnboardingHeading(
            title: 'Your dreams & reminders',
            subtitle: 'Almost done.',
          ),
          const SizedBox(height: AppSpacing.xl),
          TextField(
            controller: _dreamsController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'One big dream you have'),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _goalsController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'A goal for the next 90 days'),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text('When should we reach out?', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.sm),
          _timePickerTile('Morning mission', _missionTime, (t) => setState(() => _missionTime = t)),
          const SizedBox(height: AppSpacing.md),
          _timePickerTile('Evening check-in', _checkinTime, (t) => setState(() => _checkinTime = t)),
        ],
      ),
    );
  }

  Widget _timePickerTile(String label, TimeOfDay value, ValueChanged<TimeOfDay> onChanged) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      onTap: () async {
        final picked = await showTimePicker(context: context, initialTime: value);
        if (picked != null) onChanged(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label),
            Row(children: [
              const Icon(Icons.access_time_rounded, size: 18, color: AppColors.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(value.format(context), style: const TextStyle(fontWeight: FontWeight.w600)),
            ]),
          ],
        ),
      ),
    );
  }
}
