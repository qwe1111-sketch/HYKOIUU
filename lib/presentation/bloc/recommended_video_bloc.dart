import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:sport_flutter/domain/entities/video.dart';
import 'package:sport_flutter/domain/usecases/get_recommended_videos.dart';

// Events
abstract class RecommendedVideoEvent extends Equatable {
  const RecommendedVideoEvent();

  @override
  List<Object> get props => [];
}

class FetchRecommendedVideos extends RecommendedVideoEvent {
  final bool isRefresh;
  final int? typeId;

  const FetchRecommendedVideos({this.isRefresh = false, this.typeId});

  @override
  List<Object> get props => [isRefresh, typeId ?? 0];
}

// States
abstract class RecommendedVideoState extends Equatable {
  const RecommendedVideoState();

  @override
  List<Object> get props => [];
}

class RecommendedVideoInitial extends RecommendedVideoState {}

class RecommendedVideoLoading extends RecommendedVideoState {}

class RecommendedVideoLoaded extends RecommendedVideoState {
  final List<Video> videos;

  const RecommendedVideoLoaded(this.videos);

  @override
  List<Object> get props => [videos];
}

class RecommendedVideoError extends RecommendedVideoState {
  final String message;

  const RecommendedVideoError(this.message);

  @override
  List<Object> get props => [message];
}

// Bloc
class RecommendedVideoBloc
    extends Bloc<RecommendedVideoEvent, RecommendedVideoState> {
  final GetRecommendedVideos getRecommendedVideos;

  RecommendedVideoBloc({required this.getRecommendedVideos})
    : super(RecommendedVideoInitial()) {
    on<FetchRecommendedVideos>(_onFetchRecommendedVideos);
  }

  Future<void> _onFetchRecommendedVideos(
    FetchRecommendedVideos event,
    Emitter<RecommendedVideoState> emit,
  ) async {
    // Only fetch videos if the list is not already loaded, unless a refresh is forced.
    // Also force fetch if typeId changes
    final isLoaded = state is RecommendedVideoLoaded;
    if (!isLoaded || event.isRefresh || event.typeId != null) {
      if (!isLoaded) {
        // Show loading only on initial load
        emit(RecommendedVideoLoading());
      }
      try {
        final videos = await getRecommendedVideos(typeId: event.typeId);
        emit(RecommendedVideoLoaded(videos));
      } catch (e) {
        emit(RecommendedVideoError(e.toString()));
      }
    }
  }
}
