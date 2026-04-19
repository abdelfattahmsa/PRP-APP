/// App-wide constants
class AppConstants {
  AppConstants._();

  static const appName = 'PRP';
  static const appVersion = '4.1.0';

  // Supabase
  static const supabaseUrl = 'https://qjqkmvlqrrkowvisvcmc.supabase.co';
  static const supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFqcWttdmxxcnJrb3d2aXN2Y21jIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ3Njg4MjQsImV4cCI6MjA5MDM0NDgyNH0.aB1h2odqDdyAIFWq1_-61wz6_AMJHIQSR0aZl4BKhNQ';

  // Clerk Auth
  static const clerkPublishableKey = 'pk_live_Y2xlcmsucHJwLWFwcC53ZWJzaXRlJA';

  // Hive box names
  static const hiveBoxSettings = 'settings';
  static const hiveBoxCache = 'cache';
  static const hiveBoxSchedule = 'schedule';

  // Shared prefs keys
  static const prefTheme = 'theme_mode';
  static const prefScheduleMode = 'schedule_mode';
  static const prefAlarmsEnabled = 'alarms_enabled';
  static const prefOnboarded = 'onboarded';

  // Default schedule modes
  static const scheduleModes = ['normal', 'fasting', 'friday', 'cairo'];

  // Category keys
  static const categoryKeys = [
    'deen', 'pmp', 'study', 'health', 'kyb',
    'work', 'rest', 'fast', 'com',
  ];

  // Event type keys
  static const eventTypeKeys = [
    'personal', 'milestone', 'islamic', 'work',
    'study', 'kyberia', 'family', 'finance',
    'quran', 'travel', 'done', 'health',
  ];

  // Priority levels
  static const priorities = ['high', 'medium', 'low'];

  // Egypt banks
  static const egyptBanks = [
    'National Bank of Egypt (NBE)',
    'Banque Misr',
    'Banque du Caire',
    'Commercial International Bank (CIB)',
    'QNB Al Ahli',
    'HSBC Egypt',
    'Arab African International Bank (AAIB)',
    'Arab Bank',
    'Emirates NBD Egypt',
    'Faisal Islamic Bank of Egypt',
    'Agricultural Bank of Egypt (ABE)',
    'Abu Dhabi Islamic Bank (ADIB)',
    'Al Baraka Bank Egypt',
    'Bank Audi Egypt',
    'Bank of Alexandria',
    'Crédit Agricole Egypt',
    'Egyptian Arab Land Bank',
    'Egyptian Gulf Bank (EGB)',
    'Export Development Bank of Egypt (EBE)',
    'First Abu Dhabi Bank (FAB) Egypt',
    'Housing and Development Bank (HDB)',
    'Industrial Development Bank',
    'Mashreq Bank Egypt',
    'Misr Iran Development Bank',
    'Principal Bank for Development & Agricultural Credit',
    'Société Arabe Internationale de Banque (SAIB)',
    'Suez Canal Bank',
    'United Bank',
    'Ahly United Bank',
    'Alex Bank',
    'Inbank (formerly Enppi Bank)',
    'Nasser Social Bank',
    'Egypt Post (Savings)',
    'Vodafone Cash',
    'Fawry',
    'Other',
  ];

  // Transaction categories
  static const txCategories = [
    'General', 'Food', 'Transport', 'Bills',
    'Shopping', 'Health', 'Personal', 'Business',
    'Transfer', 'Kyberia',
  ];

  // Focus timer defaults (minutes)
  static const defaultFocusDuration = 25;
  static const defaultBreakDuration = 5;
  static const defaultLongBreakDuration = 15;
}

/// Category display info
class CategoryInfo {
  const CategoryInfo({
    required this.key,
    required this.label,
    required this.emoji,
  });
  final String key;
  final String label;
  final String emoji;
}

const categoryInfoMap = {
  'deen':   CategoryInfo(key: 'deen',   label: 'Deen',    emoji: '🕌'),
  'pmp':    CategoryInfo(key: 'pmp',    label: 'PMP',     emoji: '📋'),
  'study':  CategoryInfo(key: 'study',  label: 'CFI',     emoji: '📚'),
  'health': CategoryInfo(key: 'health', label: 'Health',  emoji: '🚶'),
  'kyb':    CategoryInfo(key: 'kyb',    label: 'Kyberia', emoji: '⚗️'),
  'work':   CategoryInfo(key: 'work',   label: 'Work',    emoji: '🏗️'),
  'rest':   CategoryInfo(key: 'rest',   label: 'Rest',    emoji: '💤'),
  'fast':   CategoryInfo(key: 'fast',   label: 'Fasting', emoji: '🌙'),
  'com':    CategoryInfo(key: 'com',    label: 'Commute', emoji: '🚗'),
};

/// Event type display info
class EventTypeInfo {
  const EventTypeInfo({required this.key, required this.label, required this.emoji});
  final String key;
  final String label;
  final String emoji;
}

const eventTypeInfoMap = {
  'personal':  EventTypeInfo(key: 'personal',  label: 'Personal',  emoji: '👤'),
  'milestone': EventTypeInfo(key: 'milestone', label: 'Milestone', emoji: '🏆'),
  'islamic':   EventTypeInfo(key: 'islamic',   label: 'Islamic',   emoji: '🌙'),
  'work':      EventTypeInfo(key: 'work',      label: 'Work',      emoji: '💼'),
  'study':     EventTypeInfo(key: 'study',     label: 'Study',     emoji: '📚'),
  'kyberia':   EventTypeInfo(key: 'kyberia',   label: 'Kyberia',   emoji: '⚗️'),
  'family':    EventTypeInfo(key: 'family',    label: 'Family',    emoji: '👨‍👩‍👦'),
  'finance':   EventTypeInfo(key: 'finance',   label: 'Finance',   emoji: '💰'),
  'quran':     EventTypeInfo(key: 'quran',     label: 'Quran',     emoji: '📖'),
  'travel':    EventTypeInfo(key: 'travel',    label: 'Travel',    emoji: '✈️'),
  'done':      EventTypeInfo(key: 'done',      label: 'Done ✓',    emoji: '✅'),
  'health':    EventTypeInfo(key: 'health',    label: 'Health',    emoji: '🏃'),
};
