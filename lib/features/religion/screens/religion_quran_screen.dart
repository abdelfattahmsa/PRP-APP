import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/theme/app_theme.dart';
import '../../../engines/religion/data/models/religion_models.dart';
import '../../../engines/religion/providers/religion_providers.dart';
import '../../../shared/widgets/placeholders.dart';

const _prefCurrentSurah = 'quran_current_surah';
const _prefCurrentAyah  = 'quran_current_ayah';

class ReligionQuranScreen extends ConsumerStatefulWidget {
  const ReligionQuranScreen({super.key});

  @override
  ConsumerState<ReligionQuranScreen> createState() => _ReligionQuranScreenState();
}

class _ReligionQuranScreenState extends ConsumerState<ReligionQuranScreen> {
  int _currentSurah = 1;
  int _currentAyah  = 1;

  @override
  void initState() {
    super.initState();
    _loadPosition();
  }

  Future<void> _loadPosition() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _currentSurah = prefs.getInt(_prefCurrentSurah) ?? 1;
      _currentAyah  = prefs.getInt(_prefCurrentAyah) ?? 1;
    });
  }

  Future<void> _savePosition(int surah, int ayah) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_prefCurrentSurah, surah);
    await prefs.setInt(_prefCurrentAyah, ayah);
    if (mounted) setState(() { _currentSurah = surah; _currentAyah = ayah; });
  }

  Future<void> _showLogSessionDialog(BuildContext context) async {
    int minutes = 20;
    int fromSurah = _currentSurah;
    int toSurah = _currentSurah;
    String type = 'reading';
    String notes = '';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Log Quran Session'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type
                const Text('Session Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Gap(8),
                Wrap(
                  spacing: 8,
                  children: ['reading', 'memorization', 'revision'].map((t) =>
                    ChoiceChip(
                      label: Text(t[0].toUpperCase() + t.substring(1)),
                      selected: type == t,
                      onSelected: (_) => setS(() => type = t),
                    ),
                  ).toList(),
                ),
                const Gap(16),
                // Duration
                const Text('Duration (minutes)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: minutes.toDouble(),
                        min: 5,
                        max: 120,
                        divisions: 23,
                        label: '$minutes min',
                        onChanged: (v) => setS(() => minutes = v.round()),
                      ),
                    ),
                    Text('$minutes min', style: const TextStyle(fontWeight: FontWeight.w600)),
                  ],
                ),
                const Gap(16),
                // Surah range
                const Text('Surah Range (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Gap(8),
                Row(
                  children: [
                    Expanded(
                      child: _SurahDropdown(
                        label: 'From',
                        value: fromSurah,
                        onChanged: (v) => setS(() => fromSurah = v),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: _SurahDropdown(
                        label: 'To',
                        value: toSurah,
                        onChanged: (v) => setS(() { toSurah = v; _savePosition(v, 1); }),
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                // Notes
                const Text('Notes (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const Gap(8),
                TextField(
                  onChanged: (v) => notes = v,
                  decoration: const InputDecoration(
                    hintText: 'e.g. Memorized 5 ayat of Al-Baqarah',
                    isDense: true,
                  ),
                  maxLines: 2,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Log')),
          ],
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final session = QuranSession(
        id: '',
        userId: '',
        date: dateStr,
        minutes: minutes,
        type: type,
        fromSurah: fromSurah,
        toSurah: toSurah,
        notes: notes.isEmpty ? null : notes,
      );
      await ref.read(quranSessionsProvider.notifier).add(session);
    }
  }

  Future<void> _showUpdatePositionDialog(BuildContext context) async {
    int surah = _currentSurah;
    int ayah = _currentAyah;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          title: const Text('Update Current Position'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SurahDropdown(
                label: 'Surah',
                value: surah,
                onChanged: (v) => setS(() { surah = v; ayah = 1; }),
              ),
              const Gap(12),
              Row(
                children: [
                  const Expanded(child: Text('Ayah', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
                  SizedBox(
                    width: 80,
                    child: TextFormField(
                      initialValue: '$ayah',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(isDense: true),
                      onChanged: (v) => ayah = int.tryParse(v) ?? 1,
                    ),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
          ],
        ),
      ),
    );
    if (confirmed == true) await _savePosition(surah, ayah);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.card : AppColors.lightCard;
    final borderColor = isDark ? AppColors.border : AppColors.lightBorder;
    final textSecondary = isDark ? AppColors.textSecondary : AppColors.lightTextSecondary;
    final accent = Theme.of(context).colorScheme.primary;

    final sessionsAsync = ref.watch(quranSessionsProvider);
    final weekMinutes = ref.watch(quranWeekMinutesProvider);

    final surahName = _currentSurah >= 1 && _currentSurah <= 114
        ? kSurahNames[_currentSurah]
        : '—';

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          children: [
            const ScreenHeader(
              title: 'Quran',
              subtitle: 'Reading & memorization tracker',
            ),
            const Gap(24),

            // ── Current position card ───────────────────────────
            GestureDetector(
              onTap: () => _showUpdatePositionDialog(context),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.deen.withValues(alpha: 0.12),
                    AppColors.deen.withValues(alpha: 0.04),
                  ]),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.deen.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    const Text('📖', style: TextStyle(fontSize: 36)),
                    const Gap(16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Current Position',
                              style: TextStyle(fontSize: 11, color: textSecondary)),
                          const Gap(2),
                          Text(
                            'Surah $surahName',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.deen,
                                ),
                          ),
                          Text(
                            'Ayah $_currentAyah  •  Surah $_currentSurah / 114',
                            style: TextStyle(fontSize: 12, color: textSecondary),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.edit_rounded, size: 16, color: textSecondary),
                  ],
                ),
              ),
            ),
            const Gap(16),

            // ── Stats row ───────────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  _QuranStat(
                    label: 'This Week',
                    value: '$weekMinutes min',
                    icon: Icons.calendar_today_rounded,
                    accent: accent,
                  ),
                  Container(width: 1, height: 40, color: borderColor, margin: const EdgeInsets.symmetric(horizontal: 16)),
                  _QuranStat(
                    label: 'Total Sessions',
                    value: '${sessionsAsync.asData?.value.length ?? 0}',
                    icon: Icons.bar_chart_rounded,
                    accent: accent,
                  ),
                  Container(width: 1, height: 40, color: borderColor, margin: const EdgeInsets.symmetric(horizontal: 16)),
                  _QuranStat(
                    label: 'All Time',
                    value: '${(sessionsAsync.asData?.value ?? []).fold(0, (s, e) => s + e.minutes)} min',
                    icon: Icons.all_inclusive_rounded,
                    accent: accent,
                  ),
                ],
              ),
            ),
            const Gap(24),

            // ── Session history ─────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const SectionHeader('Sessions'),
                FilledButton.tonal(
                  onPressed: () => _showLogSessionDialog(context),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_rounded, size: 16),
                      Gap(4),
                      Text('Log Session', style: TextStyle(fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(12),
            sessionsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: AppColors.error)),
              data: (sessions) => sessions.isEmpty
                  ? _EmptyState(onLog: () => _showLogSessionDialog(context))
                  : Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: sessions.asMap().entries.map((entry) {
                          final i = entry.key;
                          final s = entry.value;
                          return Column(
                            children: [
                              if (i > 0) Divider(height: 1, color: borderColor),
                              _SessionTile(
                                session: s,
                                accent: accent,
                                textSecondary: textSecondary,
                                onDelete: () => ref.read(quranSessionsProvider.notifier).delete(s.id),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Surah dropdown ────────────────────────────────────────────

class _SurahDropdown extends StatelessWidget {
  const _SurahDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<int>(
      initialValue: value,
      decoration: InputDecoration(labelText: label, isDense: true),
      isExpanded: true,
      menuMaxHeight: 300,
      items: List.generate(
        114,
        (i) => DropdownMenuItem(
          value: i + 1,
          child: Text('${i + 1}. ${kSurahNames[i + 1]}',
              style: const TextStyle(fontSize: 13)),
        ),
      ),
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}

// ── Session tile ──────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  const _SessionTile({
    required this.session,
    required this.accent,
    required this.textSecondary,
    required this.onDelete,
  });
  final QuranSession session;
  final Color accent;
  final Color textSecondary;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final typeIcon = switch (session.type) {
      'memorization' => '🧠',
      'revision'     => '🔄',
      _              => '📖',
    };
    final surahRange = session.fromSurah != null && session.toSurah != null
        ? '${kSurahNames[session.fromSurah!]} → ${kSurahNames[session.toSurah!]}'
        : null;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Text(typeIcon, style: const TextStyle(fontSize: 22)),
      title: Row(
        children: [
          Text(
            '${session.minutes} min',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const Gap(8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              session.type[0].toUpperCase() + session.type.substring(1),
              style: TextStyle(fontSize: 10, color: accent),
            ),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (surahRange != null)
            Text(surahRange, style: TextStyle(fontSize: 11, color: textSecondary)),
          if (session.notes != null)
            Text(session.notes!, style: TextStyle(fontSize: 11, color: textSecondary)),
          Text(session.date, style: TextStyle(fontSize: 10, color: textSecondary)),
        ],
      ),
      trailing: IconButton(
        icon: Icon(Icons.delete_outline_rounded, size: 18, color: textSecondary),
        onPressed: onDelete,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      ),
    );
  }
}

class _QuranStat extends StatelessWidget {
  const _QuranStat({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 16, color: accent),
          const Gap(4),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
          Text(label,
              style: TextStyle(fontSize: 9, color: AppColors.textSecondary, fontFamily: 'Roboto'),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onLog});
  final VoidCallback onLog;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            const Text('📖', style: TextStyle(fontSize: 48)),
            const Gap(16),
            Text(
              'No sessions yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            Text(
              'Log your first Quran session to start tracking.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              textAlign: TextAlign.center,
            ),
            const Gap(16),
            FilledButton(
              onPressed: onLog,
              child: const Text('Log First Session'),
            ),
          ],
        ),
      ),
    );
  }
}
