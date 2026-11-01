import 'drift_insights_repository.dart';
import 'insights_repository.dart';

class InsightsRepositoryProvider {
  InsightsRepositoryProvider._();

  /// Real SQLite / on-device Drift DB active.
  static InsightsRepository current = DriftInsightsRepository();
}
