import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'drift_insights_repository.dart';
import 'insight_job_runner.dart';
import 'insight_notification_service.dart';

const _dailyTask = 'finsight-daily-insights';
const _periodicTask = 'finsight-periodic-insights';
const _weeklyDigestTask = 'finsight-weekly-digest';
const _monthlyDigestTask = 'finsight-monthly-digest';

@pragma('vm:entry-point')
void insightWorkmanagerDispatcher() {
  Workmanager().executeTask((task, _) async {
    await InsightNotificationService.initialize();
    final runner = InsightJobRunner(
      repository: DriftInsightsRepository(),
      clock: DateTime.now,
    );
    try {
      if (task == _dailyTask) {
        await runner.runDaily();
        await runner.runDigest(
          window: const Duration(days: 1),
          label: 'Daily',
        );
      } else if (task == _periodicTask) {
        await runner.runPeriodicInsights();
      } else if (task == _weeklyDigestTask) {
        await runner.runDigest(
          window: const Duration(days: 7),
          label: 'Weekly',
        );
      } else if (task == _monthlyDigestTask) {
        await runner.runDigest(
          window: const Duration(days: 30),
          label: 'Monthly',
        );
      } else {
        return false;
      }
      return true;
    } catch (error) {
      debugPrint('Insights background task failed: $task $error');
      return false;
    }
  });
}

class InsightBackgroundJobs {
  static Future<void> initializeAndSchedule() async {
    await Workmanager().initialize(insightWorkmanagerDispatcher, isInDebugMode: kDebugMode);
    await Workmanager().registerPeriodicTask(
      _dailyTask,
      _dailyTask,
      frequency: const Duration(hours: 24),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
    await Workmanager().registerPeriodicTask(
      _periodicTask,
      _periodicTask,
      frequency: const Duration(days: 7),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
    await Workmanager().registerPeriodicTask(
      _weeklyDigestTask,
      _weeklyDigestTask,
      frequency: const Duration(days: 7),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
    await Workmanager().registerPeriodicTask(
      _monthlyDigestTask,
      _monthlyDigestTask,
      frequency: const Duration(days: 30),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    );
  }
}
