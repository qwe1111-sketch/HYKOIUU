import 'package:sport_flutter/domain/entities/video.dart';

enum Difficulty { Easy, Medium, Hard, Ultimate }

abstract class VideoRepository {
  Future<Video> getVideoById(int id);
  Future<List<Video>> getVideos({required Difficulty difficulty, int? typeId});
  Future<void> favoriteVideo(int videoId);
  Future<void> unfavoriteVideo(int videoId);
  Future<List<Video>> getFavoriteVideos();
  Future<List<Video>> getRecommendedVideos({int? typeId});
  Future<List<dynamic>> getVideoTypes();
}
