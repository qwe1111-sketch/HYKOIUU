import 'package:sport_flutter/domain/entities/video.dart';
import 'package:sport_flutter/domain/repositories/video_repository.dart';

class GetVideos {
  final VideoRepository repository;

  GetVideos(this.repository);

  Future<List<Video>> call({required Difficulty difficulty, int? typeId}) {
    return repository.getVideos(difficulty: difficulty, typeId: typeId);
  }
}
