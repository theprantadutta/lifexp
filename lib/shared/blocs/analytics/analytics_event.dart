import 'package:equatable/equatable.dart';

/// Base class for all analytics events
abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();

  @override
  List<Object?> get props => [];
}

/// Event to load analytics data for a user
class LoadAnalyticsData extends AnalyticsEvent {
  const LoadAnalyticsData({required this.userId});

  final String userId;

  @override
  List<Object?> get props => [userId];
}