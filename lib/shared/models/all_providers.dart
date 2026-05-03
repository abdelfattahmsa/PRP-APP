// Barrel file — re-exports all providers for backward compatibility.
// New code should import directly from engine provider files.
export '../../engines/money/providers/money_providers.dart';
export '../../engines/time/providers/time_providers.dart';
export '../../engines/time/data/models/task_model.dart';
export '../../engines/energy/providers/energy_providers.dart';
export '../../engines/energy/data/models/energy_models.dart'
    show PlannedSession, FocusQueueState, FocusTimerState, FocusSession, MoodEntry;
export '../../engines/health/providers/health_providers.dart';
export '../../engines/health/providers/fasting_provider.dart';
export '../../engines/goals/providers/goals_providers.dart';
export '../../engines/categories/providers/user_categories_provider.dart';
export '../../core/providers/resource_scores_provider.dart';
export '../../services/fx_rates_service.dart';
export '../../core/providers/app_settings_provider.dart';
