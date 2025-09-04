import 'package:equatable/equatable.dart';

import '../../../data/models/analytics_data.dart';

/// Base class for all analytics states
abstract class AnalyticsState extends Equatable {
  const AnalyticsState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the BLoC is created
class AnalyticsInitial extends AnalyticsState {}

/// State when loading analytics data
class AnalyticsLoading extends AnalyticsState {}

/// State when analytics data has been successfully loaded
class AnalyticsLoaded extends AnalyticsState {
  const AnalyticsLoaded(this.analyticsData);

  final AnalyticsData analyticsData;

  @override
  List<Object?> get props => [analyticsData];
}

/// State when an error occurs
class AnalyticsError extends AnalyticsState {
  const AnalyticsError(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}