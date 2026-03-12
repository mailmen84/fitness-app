import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_date_formatter.dart';
import '../../../core/network/app_api_client.dart';
import '../../shared/application/api_client_provider.dart';
import '../domain/progress_models.dart';

abstract class ProgressRepository {
  Future<ProgressOverviewData> fetchOverview();
  Future<List<WeightLogEntry>> fetchWeightLogs();
  Future<WeightLogEntry> createWeightLog({
    required DateTime measuredAt,
    required double weight,
    required String unit,
    String? note,
  });
  Future<List<MeasurementLogEntry>> fetchMeasurementLogs();
  Future<MeasurementLogEntry> createMeasurementLog({
    required String measurementType,
    required DateTime measuredAt,
    required double value,
    required String unit,
    String? note,
  });
}

class ApiProgressRepository implements ProgressRepository {
  const ApiProgressRepository({required this.apiClient});

  final AppApiClient apiClient;

  @override
  Future<ProgressOverviewData> fetchOverview() async {
    final payload = await apiClient.getMap('/progress/overview');
    return ProgressOverviewData.fromJson(payload);
  }

  @override
  Future<List<WeightLogEntry>> fetchWeightLogs() async {
    final payload = await apiClient.getMap('/progress/weight');
    final items = payload['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => WeightLogEntry.fromJson(item as Map<String, dynamic>))
        .toList(growable: false);
  }

  @override
  Future<WeightLogEntry> createWeightLog({
    required DateTime measuredAt,
    required double weight,
    required String unit,
    String? note,
  }) async {
    final payload = await apiClient.postJsonMap(
      '/progress/weight',
      body: {
        'measured_at': formatApiDateTime(measuredAt),
        'weight': weight,
        'unit': unit,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return WeightLogEntry.fromJson(payload);
  }

  @override
  Future<List<MeasurementLogEntry>> fetchMeasurementLogs() async {
    final payload = await apiClient.getMap('/progress/measurements');
    final items = payload['items'] as List<dynamic>? ?? const [];
    return items
        .map(
          (item) => MeasurementLogEntry.fromJson(item as Map<String, dynamic>),
        )
        .toList(growable: false);
  }

  @override
  Future<MeasurementLogEntry> createMeasurementLog({
    required String measurementType,
    required DateTime measuredAt,
    required double value,
    required String unit,
    String? note,
  }) async {
    final payload = await apiClient.postJsonMap(
      '/progress/measurements',
      body: {
        'measurement_type': measurementType,
        'measured_at': formatApiDateTime(measuredAt),
        'value': value,
        'unit': unit,
        if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
      },
    );
    return MeasurementLogEntry.fromJson(payload);
  }
}

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final apiClient = ref.watch(appApiClientProvider);
  return ApiProgressRepository(apiClient: apiClient);
});
