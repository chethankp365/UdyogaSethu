import 'package:flutter/foundation.dart';
import 'package:udyogasethu/features/job_execution/domain/worker_schedule_item.dart';

@immutable
class RouteStop {
  final int sequence;
  final WorkerScheduleItem item;
  final double distanceToNextKm;
  final int travelMinutesToNext;

  const RouteStop({
    required this.sequence,
    required this.item,
    required this.distanceToNextKm,
    required this.travelMinutesToNext,
  });
}

@immutable
class RouteOrderPlan {
  final DateTime date;
  final List<RouteStop> stops;
  final double totalDistanceKm;
  final int totalTravelMinutes;
  final int timeSavedMinutes;
  final double originalDistanceKm;

  const RouteOrderPlan({
    required this.date,
    required this.stops,
    required this.totalDistanceKm,
    required this.totalTravelMinutes,
    required this.timeSavedMinutes,
    required this.originalDistanceKm,
  });

  bool get hasMultipleStops => stops.length > 1;
}
