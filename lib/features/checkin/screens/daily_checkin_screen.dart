import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/checkin/data/models/checkin_models.dart';
import '../../../engines/checkin/providers/checkin_providers.dart';

// ══════════════════════════════════════════════════════════════
// DAILY CHECK-IN SCREEN
// Shown as a modal-style screen; user swipes or taps to dismiss.
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
  final _textCtrl = TextEditingController();
  bool _saving = false;
  bool _done = false;

  bool get _isMorning => widget.mode == 'morning';

  List<String> get _emojis => _isMorning ? kEnergyEmojis : kMoodEmojis;
  List<String> get _labels => _isMorning ? kEnergyLabels : kMoodLabels;

  String get _title =>
      _isMorning ? 'Morning Check-in' : 'Evening Check-in';

  String get _scoreLabel =>
      _isMorning ? 'Energy level' : 'How was your day?';

  String get _textHint => _isMorning
      ? "Today's top priority..."
      : 'What did you accomplish?';

  String get _textLabel => _isMorning ? "Today's focus" : 'Accomplishments';

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      if (_isMorning) {
        await ref.read(todayCheckinProvider.notifier).saveMorning(
              energy: _score,
              priority: _textCtrl.text.trim(),
            );
      } else {
        await ref.read(todayCheckinProvider.notifier).saveEvening(
              mood: _score,
              accomplishment: _textCtrl.text.trim(),
            );
      }
      if (mounted) setState(() => _done = true);
      await Future.delayed(const Duration(milliseconds: 800));
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
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.textSecondary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          _title,
          style: const TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 17),
        ),
        centerTitle: true,
      ),
      body: _done ? _DoneState(isMorning: _isMorning) : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Score label ──────────────────────────────────
          Text(
            _scoreLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const Gap(16),

          // ── Emoji selector ───────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) {
              final val = i + 1;
              final isSelected = _score == val;
              return GestureDetector(
                onTap: () => setState(() => _score = val),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 56,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.accentFaint : AppColors.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color:
                          isSelected ? AppColors.accent : AppColors.border,
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_emojis[i],
                          style: TextStyle(
                              fontSize: isSelected ? 28 : 22)),
                      const Gap(4),
                      Text(
                        '$val',
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.accent
                              : AppColors.textMuted,
                          fontSize: 11,
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
              _labels[_score - 1],
              style: const TextStyle(
                color: AppColors.accent,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),

          const Gap(28),

          // ── Text input ───────────────────────────────────
          Text(
            _textLabel,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const Gap(10),
          TextField(
            controller: _textCtrl,
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: _textHint,
              contentPadding: const EdgeInsets.all(16),
            ),
          ),

          const Gap(32),

          // ── Save button ──────────────────────────────────
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
              child: const Text('Skip for today',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }
}

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
        ? 'How did your day go?'
        : 'How are you feeling today?';

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
