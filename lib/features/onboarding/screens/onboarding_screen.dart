import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/providers/pillar_provider.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/health/data/models/health_models.dart';
import '../../../shared/models/all_providers.dart';

const _uuid = Uuid();

// ══════════════════════════════════════════════════════════════
// ONBOARDING SCREEN
// ══════════════════════════════════════════════════════════════
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _controller = PageController();
  int _currentPage = 0;

  // Step 3 — currency
  String _selectedCurrency = 'EGP';
  static const _currencies = ['EGP', 'USD', 'EUR', 'GBP', 'SAR', 'AED'];
  static const _currencyFlags = ['🇪🇬', '🇺🇸', '🇪🇺', '🇬🇧', '🇸🇦', '🇦🇪'];
  static const _currencyLabels = [
    'Egyptian Pound',
    'US Dollar',
    'Euro',
    'British Pound',
    'Saudi Riyal',
    'UAE Dirham',
  ];

  // Step 4 — first habit
  final _habitCtrl = TextEditingController();
  String _habitIcon = '⭐';
  bool _habitSaved = false;

  static const _habitSuggestions = [
    ('⭐', 'Morning routine'),
    ('📖', 'Read 20 minutes'),
    ('🏃', 'Exercise'),
    ('🕌', 'Pray Fajr'),
    ('💧', 'Drink 2L water'),
    ('😴', 'Sleep before midnight'),
  ];

  static const _totalPages = 5;

  @override
  void initState() {
    super.initState();
    _loadCurrencyPref();
  }

  Future<void> _loadCurrencyPref() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _selectedCurrency =
          prefs.getString(AppConstants.prefDefaultCurrency) ?? 'EGP';
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _habitCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _skip() => _finish();

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefOnboarded, true);
    if (mounted) context.go(Routes.overview);
  }

  Future<void> _saveCurrency(String currency) async {
    setState(() => _selectedCurrency = currency);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefDefaultCurrency, currency);
  }

  Future<void> _saveHabit() async {
    final name = _habitCtrl.text.trim();
    if (name.isEmpty) return;
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      icon: _habitIcon,
    );
    await ref.read(habitsProvider.notifier).add(habit);
    if (mounted) setState(() => _habitSaved = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Progress + Skip ──────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: [
                  // Progress dots
                  Row(
                    children: List.generate(_totalPages, (i) {
                      final isActive = i == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 6),
                        width: isActive ? 24 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.accent
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Skip button (hidden on last page)
                  if (_currentPage < _totalPages - 1)
                    TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                      ),
                      child: const Text('Skip',
                          style: TextStyle(fontSize: 13)),
                    ),
                ],
              ),
            ),

            const Gap(8),

            // ── Page content ────────────────────────────────
            Expanded(
              child: PageView(
                controller: _controller,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _WelcomePage(),
                  _PillarsPage(),
                  _CurrencyPage(
                    selected: _selectedCurrency,
                    currencies: _currencies,
                    flags: _currencyFlags,
                    labels: _currencyLabels,
                    onSelect: _saveCurrency,
                  ),
                  _FirstHabitPage(
                    ctrl: _habitCtrl,
                    icon: _habitIcon,
                    saved: _habitSaved,
                    suggestions: _habitSuggestions,
                    onIconSelect: (ic) => setState(() => _habitIcon = ic),
                    onSave: _saveHabit,
                  ),
                  _AllSetPage(),
                ],
              ),
            ),

            // ── Bottom button ────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  child: Text(
                    _currentPage == _totalPages - 1
                        ? 'Open PRP'
                        : _currentPage == 3
                            ? 'Continue'
                            : 'Next →',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PAGE 1 — Welcome
// ══════════════════════════════════════════════════════════════
class _WelcomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo / icon
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.accentFaint,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.accentDim, width: 1.5),
            ),
            child: const Center(
              child: Text('🧭', style: TextStyle(fontSize: 48)),
            ),
          ),
          const Gap(32),
          Text(
            'Welcome to PRP',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          Text(
            'Your Personal Resource Planner.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.accent,
                  fontWeight: FontWeight.w600,
                ),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          Text(
            'PRP helps you manage the four resources that determine the quality of your life:',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
          const Gap(28),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            alignment: WrapAlignment.center,
            children: const [
              _ResourceChip(emoji: '⏰', label: 'Time'),
              _ResourceChip(emoji: '💰', label: 'Money'),
              _ResourceChip(emoji: '⚡', label: 'Energy'),
              _ResourceChip(emoji: '❤️', label: 'Health'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ResourceChip extends StatelessWidget {
  const _ResourceChip({required this.emoji, required this.label});
  final String emoji;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const Gap(8),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PAGE 2 — Choose Pillars
// ══════════════════════════════════════════════════════════════
class _PillarsPage extends ConsumerWidget {
  static const _pillars = [
    (id: 'time',     emoji: '⏰', label: 'Time',    desc: 'Schedule, calendar & tasks'),
    (id: 'finance',  emoji: '💰', label: 'Finance', desc: 'Accounts, transactions & investments'),
    (id: 'energy',   emoji: '⚡', label: 'Energy',  desc: 'Focus sessions, goals & ideas'),
    (id: 'health',   emoji: '❤️', label: 'Health',  desc: 'Habits, fasting & health tracking'),
    (id: 'religion', emoji: '🕌', label: 'Deen',    desc: 'Salah, Quran & Zakat (opt-in)'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(pillarProvider).asData?.value ?? kDefaultActivePillars;
    final canDisable = active.length > 1;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(16),
          Text(
            'Choose your pillars',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const Gap(8),
          Text(
            'Enable the areas you want to track. You can change this anytime in Settings.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const Gap(24),
          Expanded(
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _pillars.length,
              separatorBuilder: (_, __) => const Gap(10),
              itemBuilder: (ctx, i) {
                final p = _pillars[i];
                final isActive = active.contains(p.id);
                final isDisabled = isActive && !canDisable;

                return AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.accentFaint
                        : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isActive ? AppColors.accentDim : AppColors.border,
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: ListTile(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: Text(p.emoji,
                        style: const TextStyle(fontSize: 24)),
                    title: Text(
                      p.label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isActive
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      p.desc,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 12),
                    ),
                    trailing: Switch(
                      value: isActive,
                      onChanged: isDisabled
                          ? null
                          : (_) =>
                              ref.read(pillarProvider.notifier).toggle(p.id),
                      activeThumbColor: AppColors.accent,
                    ),
                    onTap: isDisabled
                        ? null
                        : () => ref.read(pillarProvider.notifier).toggle(p.id),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PAGE 3 — Currency
// ══════════════════════════════════════════════════════════════
class _CurrencyPage extends StatelessWidget {
  const _CurrencyPage({
    required this.selected,
    required this.currencies,
    required this.flags,
    required this.labels,
    required this.onSelect,
  });

  final String selected;
  final List<String> currencies;
  final List<String> flags;
  final List<String> labels;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(16),
          Text(
            'Default currency',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const Gap(8),
          Text(
            'Used for accounts and transactions. You can change this in Finance settings.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const Gap(24),
          Expanded(
            child: ListView.separated(
              itemCount: currencies.length,
              separatorBuilder: (_, __) => const Gap(10),
              itemBuilder: (ctx, i) {
                final isSelected = currencies[i] == selected;
                return GestureDetector(
                  onTap: () => onSelect(currencies[i]),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.accentFaint : AppColors.card,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected ? AppColors.accentDim : AppColors.border,
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Text(flags[i],
                            style: const TextStyle(fontSize: 24)),
                        const Gap(14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                currencies[i],
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: isSelected
                                      ? AppColors.accent
                                      : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                labels[i],
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded,
                              color: AppColors.accent, size: 20),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PAGE 4 — First Habit
// ══════════════════════════════════════════════════════════════
class _FirstHabitPage extends StatelessWidget {
  const _FirstHabitPage({
    required this.ctrl,
    required this.icon,
    required this.saved,
    required this.suggestions,
    required this.onIconSelect,
    required this.onSave,
  });

  final TextEditingController ctrl;
  final String icon;
  final bool saved;
  final List<(String, String)> suggestions;
  final void Function(String) onIconSelect;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Gap(16),
          Text(
            'Add your first habit',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const Gap(8),
          Text(
            'Small, consistent actions compound. Start with one that matters to you.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
          ),
          const Gap(20),

          // Suggestions
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.map((s) {
              return GestureDetector(
                onTap: () {
                  ctrl.text = s.$2;
                  onIconSelect(s.$1);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Text(
                    '${s.$1} ${s.$2}',
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 13),
                  ),
                ),
              );
            }).toList(),
          ),

          const Gap(20),

          // Input row
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Icon selector
              GestureDetector(
                onTap: () => _pickEmoji(context),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Center(
                    child: Text(icon, style: const TextStyle(fontSize: 24)),
                  ),
                ),
              ),
              const Gap(12),
              // Name input
              Expanded(
                child: TextField(
                  controller: ctrl,
                  autofocus: false,
                  style: const TextStyle(color: AppColors.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Habit name...',
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  onSubmitted: (_) => onSave(),
                ),
              ),
              const Gap(10),
              // Add button
              ElevatedButton(
                onPressed: saved ? null : onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  saved ? '✓' : 'Add',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),

          const Gap(16),

          // Saved confirmation
          AnimatedOpacity(
            opacity: saved ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.accentFaint,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.accentDim),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.accent, size: 18),
                  const Gap(10),
                  Text(
                    'Habit saved! You can add more in Health → Habits.',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Gap(16),
          Text(
            'You can skip this step and add habits later.',
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Future<void> _pickEmoji(BuildContext context) async {
    const emojis = [
      '⭐', '📖', '🏃', '🕌', '💧', '😴', '🧘', '🏋️', '🍎', '✍️',
      '🎯', '🧠', '💊', '🚶', '🚴', '🎵', '🌅', '🥗', '🏊', '🙏',
    ];
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: emojis.map((e) => GestureDetector(
            onTap: () => Navigator.pop(ctx, e),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                  child: Text(e, style: const TextStyle(fontSize: 24))),
            ),
          )).toList(),
        ),
      ),
    );
    if (picked != null) onIconSelect(picked);
  }
}

// ══════════════════════════════════════════════════════════════
// PAGE 5 — All Set
// ══════════════════════════════════════════════════════════════
class _AllSetPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: AppColors.accentFaint,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: AppColors.accentDim, width: 1.5),
            ),
            child: const Center(
              child: Text('🚀', style: TextStyle(fontSize: 48)),
            ),
          ),
          const Gap(32),
          Text(
            "You're all set!",
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
            textAlign: TextAlign.center,
          ),
          const Gap(16),
          Text(
            'Your PRP is ready. The Overview shows your daily Resource Score — check it every morning.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.6,
                ),
            textAlign: TextAlign.center,
          ),
          const Gap(32),
          _TipCard(
            emoji: '📌',
            title: 'Daily habit',
            body: 'Open PRP each morning for 2 minutes — score your night\'s sleep, log a prayer, check your schedule.',
          ),
          const Gap(12),
          _TipCard(
            emoji: '🔁',
            title: 'Weekly review',
            body: 'Every Sunday, PRP will prompt you to review your week and plan the next one.',
          ),
        ],
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard(
      {required this.emoji, required this.title, required this.body});
  final String emoji;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 22)),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    fontSize: 14,
                  ),
                ),
                const Gap(4),
                Text(
                  body,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
