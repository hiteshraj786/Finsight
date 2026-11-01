import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';

import 'drift_insights_repository.dart';
import 'insight_job_runner.dart';
import 'insight_notification_service.dart';

const _dailyTask = 'finsight-daily-insights';
const _periodicTask = 'finsight-periodic-insights';

@pragma('vm:entry-point')
void insightWorkmanagerDispatcher() {
  Workmanager().executeTask((task, _) async {
    await InsightNotificationService.initialize();
    final runner = InsightJobRunner(
      repository: DriftInsightsRepository(),
      clock: DateTime.now,
    );
    if (task == _dailyTask) {
      await runner.runDaily();
    } else if (task == _periodicTask) {
      await runner.runPeriodicInsights();
    }
    return true;
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
  }
}
