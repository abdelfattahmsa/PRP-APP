import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/providers/theme_provider.dart';
import '../../../shared/models/all_providers.dart';
import '../../../shared/widgets/placeholders.dart';
import '../../../engines/categories/data/models/user_category_model.dart';

const _uuid = Uuid();

class ProfileAppSettingsScreen extends ConsumerStatefulWidget {
  const ProfileAppSettingsScreen({super.key});

  @override
  ConsumerState<ProfileAppSettingsScreen> createState() =>
      _ProfileAppSettingsScreenState();
}

class _ProfileAppSettingsScreenState
    extends ConsumerState<ProfileAppSettingsScreen> {
  bool _notifyFocus = true;
  bool _notifyGoals = true;
  bool _notifyHabits = false;
  bool _notifyFasting = true;
  bool _compactMode = false;
  String _scheduleMode = 'normal';
  int _dayStartHour = 6;
  int _firstDayOfWeek = 1; // 1=Monday, 7=Sunday
  String _defaultCurrency = 'EGP';

  static const _currencies = ['EGP', 'USD', 'EUR', 'GBP', 'SAR', 'AED'];
  static const _currencyLabels = [
    'EGP — Egyptian Pound',
    'USD — US Dollar',
    'EUR — Euro',
    'GBP — British Pound',
    'SAR — Saudi Riyal',
    'AED — UAE Dirham',
  ];

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _scheduleMode = prefs.getString(AppConstants.prefScheduleMode) ?? 'normal';
      _dayStartHour = prefs.getInt(AppConstants.prefDayStartHour) ?? 6;
      _firstDayOfWeek = prefs.getInt(AppConstants.prefFirstDayOfWeek) ?? 1;
      _defaultCurrency = prefs.getString(AppConstants.prefDefaultCurrency) ?? 'EGP';
    });
  }

  Future<void> _savePref(Future<void> Function(SharedPreferences) fn) async {
    final prefs = await SharedPreferences.getInstance();
    await fn(prefs);
  }

  Future<void> _pickApiKey(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    if (!context.mounted) return;
    final current = prefs.getString(AppConstants.prefAlphaVantageApiKey) ?? '';
    final ctrl = TextEditingController(text: current);
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alpha Vantage API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Get a free key at alphavantage.co (25 req/day)',
                style: TextStyle(fontSize: 12)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Paste your API key here',
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
              child: const Text('Save')),
        ],
      ),
    );
    ctrl.dispose();
    if (saved != null) {
      await prefs.setString(AppConstants.prefAlphaVantageApiKey, saved);
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'App Settings',
              subtitle: 'Theme, notifications, and display',
            ),
            const Gap(24),

            // ── Theme ──────────────────────────────────────────
            const SectionHeader('Appearance'),
            const Gap(12),
            SectionCard(children: [
              Padding(
                padding: const EdgeInsets.all(Spacing.base),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Theme',
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w500),
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        _ThemeOption(
                          label: 'Dark',
                          icon: Icons.dark_mode_rounded,
                          selected: themeMode == ThemeMode.dark,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setMode(ThemeMode.dark),
                        ),
                        const Gap(8),
                        _ThemeOption(
                          label: 'Light',
                          icon: Icons.light_mode_rounded,
                          selected: themeMode == ThemeMode.light,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setMode(ThemeMode.light),
                        ),
                        const Gap(8),
                        _ThemeOption(
                          label: 'System',
                          icon: Icons.brightness_auto_rounded,
                          selected: themeMode == ThemeMode.system,
                          onTap: () => ref
                              .read(themeModeProvider.notifier)
                              .setMode(ThemeMode.system),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: borderColor),
              SettingsSwitchTile(
                title: 'Compact Mode',
                subtitle: 'Reduce spacing for more content',
                leading: const Icon(Icons.compress_rounded, size: 20),
                value: _compactMode,
                onChanged: (v) => setState(() => _compactMode = v),
              ),
            ]),
            const Gap(24),

            // ── Notifications ──────────────────────────────────
            const SectionHeader('Notifications'),
            const Gap(12),
            SectionCard(children: [
              SettingsSwitchTile(
                title: 'Focus Reminders',
                subtitle: 'Remind to start focus sessions',
                leading: const Icon(Icons.timer_outlined, size: 20),
                value: _notifyFocus,
                onChanged: (v) => setState(() => _notifyFocus = v),
              ),
              Divider(height: 1, color: borderColor),
              SettingsSwitchTile(
                title: 'Goal Updates',
                subtitle: 'Notify on goal milestones',
                leading: const Icon(Icons.flag_outlined, size: 20),
                value: _notifyGoals,
                onChanged: (v) => setState(() => _notifyGoals = v),
              ),
              Divider(height: 1, color: borderColor),
              SettingsSwitchTile(
                title: 'Habit Reminders',
                subtitle: 'Daily habit check-in prompts',
                leading: const Icon(Icons.check_circle_outline, size: 20),
                value: _notifyHabits,
                onChanged: (v) => setState(() => _notifyHabits = v),
              ),
              Divider(height: 1, color: borderColor),
              SettingsSwitchTile(
                title: 'Fasting Alerts',
                subtitle: 'Fast start/end reminders',
                leading: const Icon(Icons.hourglass_empty_rounded, size: 20),
                value: _notifyFasting,
                onChanged: (v) => setState(() => _notifyFasting = v),
              ),
            ]),
            const Gap(24),

            // ── Schedule ────────────────────────────────────────
            const SectionHeader('Schedule & Time'),
            const Gap(12),
            SectionCard(children: [
              SettingsTile(
                title: 'Schedule Mode',
                subtitle: _scheduleModeLabel(_scheduleMode),
                leading: const Icon(Icons.view_timeline_outlined, size: 20),
                onTap: () => _pickFromList(
                  context,
                  title: 'Schedule Mode',
                  options: AppConstants.scheduleModes,
                  labels: AppConstants.scheduleModes
                      .map(_scheduleModeLabel)
                      .toList(),
                  selected: _scheduleMode,
                  onPick: (v) {
                    setState(() => _scheduleMode = v);
                    _savePref((p) async =>
                        p.setString(AppConstants.prefScheduleMode, v));
                  },
                ),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Day Start Time',
                subtitle:
                    '${_dayStartHour.toString().padLeft(2, '0')}:00',
                leading: const Icon(Icons.wb_sunny_outlined, size: 20),
                onTap: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime:
                        TimeOfDay(hour: _dayStartHour, minute: 0),
                    helpText: 'Day Start Time',
                  );
                  if (picked != null && mounted) {
                    setState(() => _dayStartHour = picked.hour);
                    _savePref((p) async =>
                        p.setInt(AppConstants.prefDayStartHour, picked.hour));
                  }
                },
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'First Day of Week',
                subtitle: _firstDayOfWeek == 1 ? 'Monday' : 'Sunday',
                leading: const Icon(Icons.date_range_outlined, size: 20),
                onTap: () => _pickFromList(
                  context,
                  title: 'First Day of Week',
                  options: ['1', '7'],
                  labels: const ['Monday', 'Sunday'],
                  selected: _firstDayOfWeek.toString(),
                  onPick: (v) {
                    setState(() => _firstDayOfWeek = int.parse(v));
                    _savePref((p) async =>
                        p.setInt(AppConstants.prefFirstDayOfWeek, int.parse(v)));
                  },
                ),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Schedule Block Categories',
                subtitle: 'Manage your time block categories',
                leading: const Icon(Icons.grid_view_rounded, size: 20),
                onTap: () => _showCategoryManager(context, ref, 'schedule'),
              ),
            ]),
            const Gap(24),

            // ── Finance settings ────────────────────────────────
            const SectionHeader('Finance'),
            const Gap(12),
            SectionCard(children: [
              SettingsTile(
                title: 'Default Currency',
                subtitle: _currencyLabels[_currencies.indexOf(_defaultCurrency)
                    .clamp(0, _currencies.length - 1)],
                leading: const Icon(Icons.attach_money_outlined, size: 20),
                onTap: () => _pickFromList(
                  context,
                  title: 'Default Currency',
                  options: _currencies,
                  labels: _currencyLabels,
                  selected: _defaultCurrency,
                  onPick: (v) {
                    setState(() => _defaultCurrency = v);
                    _savePref((p) async =>
                        p.setString(AppConstants.prefDefaultCurrency, v));
                  },
                ),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Transaction Categories',
                subtitle: 'Manage your spending categories',
                leading: const Icon(Icons.category_outlined, size: 20),
                onTap: () => _showCategoryManager(context, ref, 'transaction'),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Alpha Vantage API Key',
                subtitle: 'For live stock prices in Investments',
                leading: const Icon(Icons.show_chart_rounded, size: 20),
                onTap: () => _pickApiKey(context),
              ),
            ]),
            const Gap(24),

            // ── Energy settings ─────────────────────────────────
            Builder(builder: (ctx) {
              final timer = ref.watch(focusTimerProvider);
              final notifier = ref.read(focusTimerProvider.notifier);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader('Energy'),
                  const Gap(12),
                  SectionCard(children: [
                    SettingsTile(
                      title: 'Focus Duration',
                      subtitle: '${timer.focusDuration} minutes',
                      leading: const Icon(Icons.timer_outlined, size: 20),
                      onTap: () => _pickMinutes(
                        ctx,
                        title: 'Focus Duration',
                        initial: timer.focusDuration,
                        min: 5,
                        max: 120,
                        onPick: (v) => notifier.setDuration(v, timer.breakDuration),
                      ),
                    ),
                    Divider(height: 1, color: borderColor),
                    SettingsTile(
                      title: 'Break Duration',
                      subtitle: '${timer.breakDuration} minutes',
                      leading: const Icon(Icons.coffee_outlined, size: 20),
                      onTap: () => _pickMinutes(
                        ctx,
                        title: 'Break Duration',
                        initial: timer.breakDuration,
                        min: 1,
                        max: 60,
                        onPick: (v) => notifier.setDuration(timer.focusDuration, v),
                      ),
                    ),
                  ]),
                ],
              );
            }),
            const Gap(24),

            // ── Health settings ─────────────────────────────────
            Builder(builder: (ctx) {
              final fasting = ref.watch(fastingProvider);
              final goalHours = fasting.goalHours;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionHeader('Health'),
                  const Gap(12),
                  SectionCard(children: [
                    SettingsTile(
                      title: 'Default Fasting Goal',
                      subtitle: '$goalHours hours ($goalHours:${24 - goalHours} protocol)',
                      leading: const Icon(Icons.hourglass_empty_rounded, size: 20),
                      onTap: () => _pickFromList(
                        ctx,
                        title: 'Fasting Protocol',
                        options: ['12', '14', '16', '18', '20', '24'],
                        labels: const [
                          '12h — 12:12',
                          '14h — 14:10',
                          '16h — 16:8 (recommended)',
                          '18h — 18:6',
                          '20h — 20:4 (OMAD-ish)',
                          '24h — Full day fast',
                        ],
                        selected: goalHours.toString(),
                        onPick: (v) => ref
                            .read(fastingProvider.notifier)
                            .setGoal(int.parse(v)),
                      ),
                    ),
                  ]),
                ],
              );
            }),
            const Gap(24),

            // ── About ───────────────────────────────────────────
            const SectionHeader('About'),
            const Gap(12),
            SectionCard(children: [
              SettingsTile(
                title: 'App Version',
                subtitle: 'PRP System v4.2.0',
                leading:
                    Icon(Icons.info_outline, color: accent, size: 20),
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Terms of Service',
                leading: const Icon(Icons.description_outlined, size: 20),
                onTap: () {},
              ),
              Divider(height: 1, color: borderColor),
              SettingsTile(
                title: 'Privacy Policy',
                leading: const Icon(Icons.privacy_tip_outlined, size: 20),
                onTap: () {},
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _ThemeOption extends StatelessWidget {
  const _ThemeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = Theme.of(context).colorScheme.primary;
    final cardColor = isDark ? AppColors.cardHover : AppColors.lightCardHover;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? accent.withValues(alpha: 0.12) : cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: selected ? accent : borderColor,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: selected ? accent : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
              ),
              const Gap(4),
              Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: selected ? accent : (isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// SETTINGS HELPERS
// ══════════════════════════════════════════════════════════════

String _scheduleModeLabel(String mode) {
  switch (mode) {
    case 'fasting': return 'Fasting Day';
    case 'friday':  return 'Friday';
    case 'cairo':   return 'Cairo Extended';
    default:        return 'Normal';
  }
}

Future<void> _pickMinutes(
  BuildContext context, {
  required String title,
  required int initial,
  required int min,
  required int max,
  required ValueChanged<int> onPick,
}) async {
  int value = initial;
  final result = await showDialog<int>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: StatefulBuilder(
        builder: (ctx, setState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$value minutes',
                style: const TextStyle(
                    fontSize: 24, fontWeight: FontWeight.w700)),
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton.filled(
                  onPressed: value > min
                      ? () => setState(() => value -= 5)
                      : null,
                  icon: const Icon(Icons.remove_rounded),
                ),
                const Gap(16),
                IconButton.filled(
                  onPressed: value < max
                      ? () => setState(() => value += 5)
                      : null,
                  icon: const Icon(Icons.add_rounded),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(ctx, value),
            child: const Text('Save')),
      ],
    ),
  );
  if (result != null) onPick(result);
}

Future<void> _pickFromList(
  BuildContext context, {
  required String title,
  required List<String> options,
  required List<String> labels,
  required String selected,
  required ValueChanged<String> onPick,
}) async {
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => SimpleDialog(
      title: Text(title),
      children: [
        for (int i = 0; i < options.length; i++)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(ctx, options[i]),
            child: Row(
              children: [
                Icon(
                  options[i] == selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 18,
                  color: options[i] == selected
                      ? AppColors.pmp
                      : AppColors.textSecondary,
                ),
                const Gap(12),
                Text(labels[i]),
              ],
            ),
          ),
      ],
    ),
  );
  if (result != null) onPick(result);
}

// ══════════════════════════════════════════════════════════════
// CATEGORY MANAGER
// ══════════════════════════════════════════════════════════════

Future<void> _showCategoryManager(
    BuildContext context, WidgetRef ref, String engine) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => UncontrolledProviderScope(
      container: ProviderScope.containerOf(context),
      child: _CategoryManagerSheet(engine: engine),
    ),
  );
}

class _CategoryManagerSheet extends ConsumerStatefulWidget {
  const _CategoryManagerSheet({required this.engine});
  final String engine;

  @override
  ConsumerState<_CategoryManagerSheet> createState() =>
      _CategoryManagerSheetState();
}

class _CategoryManagerSheetState
    extends ConsumerState<_CategoryManagerSheet> {
  bool _adding = false;
  final _nameCtrl = TextEditingController();
  String _emoji = '📌';

  static const _quickEmojis = [
    '📌', '💰', '🍽️', '🚗', '📋', '🛍️', '💊', '👤', '💼',
    '🔄', '⚗️', '🕌', '📚', '🚶', '🏗️', '💤', '🌙', '🎯',
    '🏋️', '📖', '🧘', '☕', '🎵', '🌿', '✅',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _addCategory() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    final cat = UserCategory(
      id: _uuid.v4(),
      name: name,
      emoji: _emoji,
      engine: widget.engine,
      key: widget.engine == 'schedule'
          ? name.toLowerCase().replaceAll(' ', '_')
          : null,
      order: 99,
    );
    try {
      await ref.read(userCategoriesProvider.notifier).add(cat);
      _nameCtrl.clear();
      setState(() {
        _adding = false;
        _emoji = '📌';
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.surface : AppColors.lightSurface;
    final border = isDark ? AppColors.border : AppColors.lightBorder;
    final accent = Theme.of(context).colorScheme.primary;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    final catsAsync = ref.watch(userCategoriesProvider);
    final cats = (catsAsync.value ?? [])
        .where((c) => c.engine == widget.engine)
        .toList();
    final label = widget.engine == 'schedule'
        ? 'Schedule Categories'
        : 'Transaction Categories';

    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 36, height: 4,
              decoration: BoxDecoration(
                  color: border,
                  borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Text(label,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 20),
          Flexible(
            child: ListView(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16 + bottom),
              shrinkWrap: true,
              children: [
                ...cats.map((cat) => ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 2),
                      leading: Text(cat.emoji,
                          style: const TextStyle(fontSize: 22)),
                      title: Text(cat.name),
                      subtitle: cat.key != null
                          ? Text('key: ${cat.key}',
                              style: const TextStyle(
                                  fontSize: 10, fontFamily: 'IBMPlexMono'))
                          : null,
                      trailing: IconButton(
                        icon: Icon(Icons.delete_outline_rounded,
                            size: 18, color: AppColors.error),
                        onPressed: () => ref
                            .read(userCategoriesProvider.notifier)
                            .delete(cat.id),
                      ),
                    )),
                if (cats.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'No custom categories yet.\nAdd one below.',
                      style: TextStyle(
                          color: isDark
                              ? AppColors.textSecondary
                              : AppColors.lightTextSecondary),
                      textAlign: TextAlign.center,
                    ),
                  ),
                const Gap(8),
                if (!_adding)
                  OutlinedButton.icon(
                    onPressed: () => setState(() => _adding = true),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Category'),
                  )
                else ...[
                  Wrap(
                    spacing: 6, runSpacing: 6,
                    children: _quickEmojis.map((e) {
                      final sel = e == _emoji;
                      return GestureDetector(
                        onTap: () => setState(() => _emoji = e),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 100),
                          width: 40, height: 40,
                          decoration: BoxDecoration(
                            color: sel
                                ? accent.withValues(alpha: 0.15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(8),
                            border:
                                Border.all(color: sel ? accent : border),
                          ),
                          child: Center(
                              child: Text(e,
                                  style:
                                      const TextStyle(fontSize: 18))),
                        ),
                      );
                    }).toList(),
                  ),
                  const Gap(12),
                  Row(children: [
                    Expanded(
                      child: TextField(
                        controller: _nameCtrl,
                        autofocus: true,
                        textCapitalization: TextCapitalization.words,
                        decoration: InputDecoration(
                          hintText: 'Category name',
                          prefixText: '$_emoji  ',
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addCategory(),
                      ),
                    ),
                    const Gap(8),
                    FilledButton(
                      onPressed: _addCategory,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Add'),
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
