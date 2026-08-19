import 'package:sport_flutter/domain/entities/video.dart';
import 'package:sport_flutter/domain/repositories/video_repository.dart';

class GetRecommendedVideos {
  final VideoRepository repository;

  GetRecommendedVideos(this.repository);

  Future<List<Video>> call({int? typeId}) async {
    return await repository.getRecommendedVideos(typeId: typeId);
  }
}
