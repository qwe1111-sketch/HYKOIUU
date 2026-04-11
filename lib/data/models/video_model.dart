import 'package:sport_flutter/domain/entities/video.dart';
import 'package:sport_flutter/domain/repositories/video_repository.dart';

class VideoModel extends Video {
  const VideoModel({
    required super.id,
    required super.title,
    super.description,
    required super.videoUrl,
    required super.thumbnailUrl,
    required super.authorName,
    super.userAvatarUrl,
    required super.viewCount,
    required super.likeCount,
    required super.createdAt,
    required super.isFavorited,
    required super.difficulty,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    String authorName = json['author_name'] ?? 'Unknown Author';
    String? userAvatarUrl = json['userAvatarUrl'];

    if (user is Map<String, dynamic>) {
      authorName = user['username'] ?? authorName;
      userAvatarUrl = user['avatar_url'] ?? userAvatarUrl;
    }

    DateTime createdAtDate;
    if (json['created_at'] != null) {
      final parsedDt = DateTime.parse(json['created_at'] as String);
      createdAtDate = DateTime.utc(
        parsedDt.year,
        parsedDt.month,
        parsedDt.day,
        parsedDt.hour,
        parsedDt.minute,
        parsedDt.second,
        parsedDt.millisecond,
        parsedDt.microsecond,
      );
    } else {
      createdAtDate = DateTime.now().toUtc();
    }

    final String title = json['title'] ?? '';
    Difficulty parsedDifficulty = Difficulty.Easy;

    // --- 核心修复：使用正则表达式精准提取标题中的 LEVEL ---
    final levelMatch = RegExp(r'LEVEL\s*(\d)', caseSensitive: false).firstMatch(title);
    if (levelMatch != null) {
      final int? levelNum = int.tryParse(levelMatch.group(1) ?? '');
      if (levelNum != null) {
        if (levelNum >= 4) {
          parsedDifficulty = Difficulty.Ultimate;
        } else if (levelNum == 3) {
          parsedDifficulty = Difficulty.Hard;
        } else if (levelNum == 2) {
          parsedDifficulty = Difficulty.Medium;
        } else {
          parsedDifficulty = Difficulty.Easy;
        }
      }
    } else {
      // 兜底：尝试从传统字段解析
      final dynamic difficultyData = json['difficulty'] ?? json['level'] ?? json['Difficulty'];
      if (difficultyData != null) {
        if (difficultyData is int) {
          int index = difficultyData;
          if (index >= 1 && index <= 4) index -= 1; 
          if (index >= 0 && index < Difficulty.values.length) {
            parsedDifficulty = Difficulty.values[index];
          }
        } else {
          final String diffStr = difficultyData.toString().toLowerCase();
          parsedDifficulty = Difficulty.values.firstWhere(
            (e) => e.name.toLowerCase() == diffStr,
            orElse: () => Difficulty.Easy,
          );
        }
      }
    }

    return VideoModel(
      id: json['id'] ?? 0,
      title: title,
      description: json['description'] ?? json['Description'] ?? json['desc'],
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      authorName: authorName,
      userAvatarUrl: userAvatarUrl,
      viewCount: json['view_count'] ?? 0,
      likeCount: json['like_count'] ?? 0,
      createdAt: createdAtDate,
      isFavorited: json['isFavorited'] ?? false,
      difficulty: parsedDifficulty,
    );
  }
}
