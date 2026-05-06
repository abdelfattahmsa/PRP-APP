import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/checkin/data/models/checkin_models.dart';
import '../../../engines/checkin/providers/checkin_providers.dart';

// ══════════════════════════════════════════════════════════════
// DAILY CHECK-IN SCREEN
// 4-resource check-in: Energy/Mood + Money + Time + Health
// ══════════════════════════════════════════════════════════════
class DailyCheckinScreen extends ConsumerStatefulWidget {
  /// 'morning' or 'evening'
  final String mode;
  const DailyCheckinScreen({super.key, required this.mode});

  @override
  ConsumerState<DailyCheckinScreen> createState() =>
      _DailyCheckinScreenState();
}

class _DailyCheckinScreenState extends ConsumerState<DailyCheckinScreen> {
  int _score = 3; // 1–5
  final _priorityCtrl  = TextEditingController(); // Energy: focus / accomplishment
  final _moneyCtrl     = TextEditingController();
  final _timeCtrl      = TextEditingController();
  final _healthCtrl    = TextEditingController();
  bool _saving = false;
  bool _done   = false;

  bool get _isMorning => widget.mode == 'morning';

  List<String> get _emojis => _isMorning ? kEnergyEmojis : kMoodEmojis;
  List<String> get _labels => _isMorning ? kEnergyLabels : kMoodLabels;

  @override
  void dispose() {
    _priorityCtrl.dispose();
    _moneyCtrl.dispose();
    _timeCtrl.dispose();
    _healthCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final moneyNote  = _moneyCtrl.text.trim().isNotEmpty ? _moneyCtrl.text.trim() : null;
      final timeNote   = _timeCtrl.text.trim().isNotEmpty  ? _timeCtrl.text.trim()  : null;
      final healthNote = _healthCtrl.text.trim().isNotEmpty ? _healthCtrl.text.trim() : null;

      if (_isMorning) {
        await ref.read(todayCheckinProvider.notifier).saveMorning(
              energy: _score,
              priority: _priorityCtrl.text.trim(),
              moneyNote: moneyNote,
              timeNote: timeNote,
              healthNote: healthNote,
            );
      } else {
        await ref.read(todayCheckinProvider.notifier).saveEvening(
              mood: _score,
              accomplishment: _priorityCtrl.text.trim(),
              moneyNote: moneyNote,
              timeNote: timeNote,
              healthNote: healthNote,
            );
      }
      if (mounted) setState(() => _done = true);
      await Future.delayed(const Duration(milliseconds: 900));
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to save: $e'),
              backgroundColor: AppColors.error),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.bg : AppColors.lightBg;
    final title = _isMorning ? 'Morning Check-in' : 'Evening Check-in';

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close_rounded,
              color: isDark ? AppColors.textSecondary : AppColors.lightTextSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        centerTitle: true,
      ),
      body: _done ? _DoneState(isMorning: _isMorning) : _buildForm(isDark),
    );
  }

  Widget _buildForm(bool isDark) {
    final textSec = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Section 1: Energy / Mood ──────────────────────
          _SectionHeader(
            emoji: _isMorning ? '⚡' : '😊',
            title: _isMorning ? 'Energy level' : 'How was your day?',
            color: AppColors.accent,
          ),
          const Gap(14),
          _EmojiPicker(
            emojis: _emojis,
            labels: _labels,
            selected: _score,
            onSelect: (v) => setState(() => _score = v),
            isDark: isDark,
          ),
          const Gap(10),
          _NoteField(
            controller: _priorityCtrl,
            hint: _isMorning ? "Today's top focus or intention…" : 'What did you accomplish?',
            isDark: isDark,
          ),

          const Gap(24),
          Divider(color: isDark ? AppColors.border : AppColors.lightBorder, height: 1),
          const Gap(24),

          // ─── Section 2: Money ─────────────────────────────
          _SectionHeader(
            emoji: '💰',
            title: _isMorning ? 'Money intention' : 'Money reflection',
            color: AppColors.finance,
          ),
          const Gap(12),
          _NoteField(
            controller: _moneyCtrl,
            hint: _isMorning
                ? 'Any financial goal or focus today? (optional)'
                : 'Any money win, expense, or lesson? (optional)',
            isDark: isDark,
          ),

          const Gap(24),
          Divider(color: isDark ? AppColors.border : AppColors.lightBorder, height: 1),
          const Gap(24),

          // ─── Section 3: Time ──────────────────────────────
          _SectionHeader(
            emoji: '⏰',
            title: _isMorning ? 'Time priority' : 'Time reflection',
            color: AppColors.info,
          ),
          const Gap(12),
          _NoteField(
            controller: _timeCtrl,
            hint: _isMorning
                ? 'How will you spend your time today? (optional)'
                : 'How did you use your time? (optional)',
            isDark: isDark,
          ),

          const Gap(24),
          Divider(color: isDark ? AppColors.border : AppColors.lightBorder, height: 1),
          const Gap(24),

          // ─── Section 4: Health ────────────────────────────
          _SectionHeader(
            emoji: '💚',
            title: _isMorning ? 'Health intention' : 'Health reflection',
            color: AppColors.health,
          ),
          const Gap(12),
          _NoteField(
            controller: _healthCtrl,
            hint: _isMorning
                ? 'Any health goal today — sleep, exercise, nutrition? (optional)'
                : 'How was your sleep, movement, or nutrition? (optional)',
            isDark: isDark,
          ),

          const Gap(36),

          // ─── Save button ──────────────────────────────────
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.black))
                  : Text(
                      _isMorning ? 'Start the day 🌅' : 'Close the day 🌙',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15),
                    ),
            ),
          ),

          const Gap(12),
          Center(
            child: TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Skip for today',
                style: TextStyle(color: textSec, fontSize: 12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.emoji,
    required this.title,
    required this.color,
  });
  final String emoji;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 18)),
        const Gap(8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

class _EmojiPicker extends StatelessWidget {
  const _EmojiPicker({
    required this.emojis,
    required this.labels,
    required this.selected,
    required this.onSelect,
    required this.isDark,
  });
  final List<String> emojis;
  final List<String> labels;
  final int selected;
  final ValueChanged<int> onSelect;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final cardColor  = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(5, (i) {
            final val = i + 1;
            final isSelected = selected == val;
            return GestureDetector(
              onTap: () => onSelect(val),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 54,
                height: 68,
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.accentFaint : cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.accent : borderColor,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(emojis[i],
                        style: TextStyle(fontSize: isSelected ? 26 : 20)),
                    const Gap(4),
                    Text(
                      '$val',
                      style: TextStyle(
                        color: isSelected ? AppColors.accent : AppColors.textMuted,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
        const Gap(6),
        Center(
          child: Text(
            labels[selected - 1],
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}

class _NoteField extends StatelessWidget {
  const _NoteField({
    required this.controller,
    required this.hint,
    required this.isDark,
  });
  final TextEditingController controller;
  final String hint;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: TextStyle(
        color: isDark ? AppColors.textPrimary : AppColors.lightTextPrimary,
        fontSize: 14,
      ),
      maxLines: 2,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}

// ── Done state ─────────────────────────────────────────────────
class _DoneState extends StatelessWidget {
  const _DoneState({required this.isMorning});
  final bool isMorning;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isMorning ? '🌅' : '🌙',
            style: const TextStyle(fontSize: 64),
          ),
          const Gap(20),
          Text(
            isMorning ? 'Have a great day!' : 'Rest well!',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const Gap(8),
          Text(
            isMorning
                ? 'Your morning intention is set.'
                : 'Your day is logged.',
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// CHECK-IN BANNER WIDGET
// Shown on Overview to prompt morning / evening check-in
// ══════════════════════════════════════════════════════════════
class CheckinBanner extends ConsumerWidget {
  const CheckinBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkinAsync = ref.watch(todayCheckinProvider);
    final checkin = checkinAsync.asData?.value;

    final hour = DateTime.now().hour;
    final isEvening = hour >= 18; // after 6PM = evening session

    // Morning: show if no morning check-in yet and it's morning/afternoon
    final needsMorning = checkin?.hasMorning != true && !isEvening;
    // Evening: show if no evening check-in yet and it's evening/night
    final needsEvening = checkin?.hasEvening != true && isEvening;

    if (!needsMorning && !needsEvening) return const SizedBox.shrink();
    if (checkinAsync.isLoading) return const SizedBox.shrink();

    final mode = isEvening ? 'evening' : 'morning';
    final emoji = isEvening ? '🌙' : '🌅';
    final label = isEvening ? 'Evening check-in' : 'Morning check-in';
    final sublabel = isEvening
        ? 'How did your day go across all 4 areas?'
        : 'How are you starting the day?';

    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => UncontrolledProviderScope(
          container: ProviderScope.containerOf(context),
          child: DailyCheckinScreen(mode: mode),
        ),
      )),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.accentFaint,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.accentDim),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    sublabel,
                    style: const TextStyle(
                        color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.accent, size: 20),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// ENERGY CHIP — compact display on Overview
// ══════════════════════════════════════════════════════════════
class EnergyMoodChip extends ConsumerWidget {
  const EnergyMoodChip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkin = ref.watch(todayCheckinProvider).asData?.value;
    if (checkin == null) return const SizedBox.shrink();

    final hasEnergy = checkin.morningEnergy != null;
    final hasMood = checkin.eveningMood != null;
    if (!hasEnergy && !hasMood) return const SizedBox.shrink();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hasEnergy) ...[
          _Chip(
            emoji: kEnergyEmojis[checkin.morningEnergy! - 1],
            label: 'Energy',
            value: '${checkin.morningEnergy}/5',
          ),
        ],
        if (hasEnergy && hasMood) const Gap(8),
        if (hasMood) ...[
          _Chip(
            emoji: kMoodEmojis[checkin.eveningMood! - 1],
            label: 'Mood',
            value: '${checkin.eveningMood}/5',
          ),
        ],
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.emoji, required this.label, required this.value});
  final String emoji, label, value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const Gap(6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 9,
                      fontWeight: FontWeight.w600)),
              Text(value,
                  style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ],
          ),
        ],
      ),
    );
  }
}
