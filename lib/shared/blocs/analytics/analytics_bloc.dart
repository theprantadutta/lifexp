import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/models/analytics_data.dart';
import 'analytics_event.dart';
import 'analytics_state.dart';

/// BLoC for managing analytics state and business logic
class AnalyticsBloc extends Bloc<AnalyticsEvent, AnalyticsState> {
  AnalyticsBloc() : super(AnalyticsInitial()) {
    on<LoadAnalyticsData>(_onLoadAnalyticsData);
  }

  /// Handles loading analytics data for a user
  Future<void> _onLoadAnalyticsData(
    LoadAnalyticsData event,
    Emitter<AnalyticsState> emit,
  ) async {
    emit(AnalyticsLoading());

    try {
      // In a real implementation, this would fetch data from repositories
      // For now, we'll use sample data
      await Future.delayed(const Duration(milliseconds: 500));
      final data = AnalyticsData.sample();
      emit(AnalyticsLoaded(data));
    } catch (e) {
      emit(AnalyticsError('Failed to load analytics data: $e'));
    }
  }
}