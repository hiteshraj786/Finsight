import 'insights_repository.dart';
import 'mock_insights_repository.dart';

class InsightsRepositoryProvider {
  InsightsRepositoryProvider._();

  /// Change this single instance to DriftInsightsRepository() when switching from mock to on-device DB.
  static InsightsRepository current = MockInsightsRepository();
}
