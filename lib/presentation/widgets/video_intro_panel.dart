import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sport_flutter/domain/entities/video.dart';
import 'package:sport_flutter/domain/repositories/video_repository.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:sport_flutter/presentation/widgets/video_action_buttons.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sport_flutter/presentation/widgets/translated_text.dart';

class VideoIntroPanel extends StatefulWidget {
  final Video currentVideo;
  final List<Video> recommendedVideos;
  final bool isLiked;
  final bool isDisliked;
  final bool isFavorited;
  final bool isInteracting;
  final Function(Video) onChangeVideo;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onFavorite;

  const VideoIntroPanel({
    super.key,
    required this.currentVideo,
    required this.recommendedVideos,
    required this.isLiked,
    required this.isDisliked,
    required this.isFavorited,
    required this.isInteracting,
    required this.onChangeVideo,
    required this.onLike,
    required this.onDislike,
    required this.onFavorite,
  });

  @override
  State<VideoIntroPanel> createState() => _VideoIntroPanelState();
}

class _VideoIntroPanelState extends State<VideoIntroPanel> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildAuthorInfo(context),
                const SizedBox(height: 16),
                TranslatedText(
                  text: widget.currentVideo.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  l10n.videoViews(widget.currentVideo.viewCount, _formatDate(context, widget.currentVideo.createdAt)),
                  style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 13),
                ),
                const SizedBox(height: 20),
                VideoActionButtons(
                  isLiked: widget.isLiked,
                  isDisliked: widget.isDisliked,
                  isFavorited: widget.isFavorited,
                  isInteracting: widget.isInteracting,
                  likeCount: widget.currentVideo.likeCount,
                  onLike: widget.onLike,
                  onDislike: widget.onDislike,
                  onFavorite: widget.onFavorite,
                ),
                const SizedBox(height: 12),
                _buildDescriptionSection(context),
                const SizedBox(height: 24),
                Text(
                  l10n.upNext,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.only(bottom: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (c, i) {
                final v = widget.recommendedVideos[i];
                if (v.id == widget.currentVideo.id) return const SizedBox.shrink();
                return _buildRecommendedItem(c, v);
              },
              childCount: widget.recommendedVideos.length,
            ),
          ),
        )
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context) {
    final description = widget.currentVideo.description;
    if (description == null || description.isEmpty) {
      return const SizedBox.shrink();
    }

    final textStyle = TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 32, color: Colors.white12),
        TranslatedText(
          text: description,
          style: textStyle,
          maxLines: _isExpanded ? null : 2,
        ),
        GestureDetector(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          child: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              _isExpanded ? l10n.showLess : l10n.showMore,
              style: const TextStyle(color: Color(0xFFCCFF00), fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthorInfo(BuildContext context) {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFCCFF00), width: 1.5),
          ),
          child: CircleAvatar(
            radius: 18,
            backgroundColor: Colors.transparent,
            backgroundImage: widget.currentVideo.userAvatarUrl != null && widget.currentVideo.userAvatarUrl!.isNotEmpty
                ? NetworkImage(widget.currentVideo.userAvatarUrl!)
                : null,
            child: widget.currentVideo.userAvatarUrl == null || widget.currentVideo.userAvatarUrl!.isEmpty
                ? const Icon(Iconsax.profile, color: Colors.white, size: 20)
                : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            widget.currentVideo.authorName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendedItem(BuildContext context, Video video) {
    const double imageWidth = 120.0;
    const double imageHeight = 80.0;
    final l10n = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
      child: InkWell(
        onTap: () => widget.onChangeVideo(video),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFF1C1C1E),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  width: imageWidth,
                  height: imageHeight,
                  fit: BoxFit.cover,
                  placeholder: (c, u) => Container(color: Colors.grey[900]),
                  errorWidget: (c, u, e) => const Icon(Icons.error, color: Colors.white24),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      text: video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.videoViews(video.viewCount, _formatDate(context, video.createdAt)),
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _buildDifficultyStars(video.difficulty),
                        const SizedBox(width: 4),
                        Text(
                          _getDifficultyText(context, video.difficulty),
                          style: const TextStyle(color: Colors.white30, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultyStars(Difficulty difficulty) {
    int starCount = 1;
    switch (difficulty) {
      case Difficulty.Easy:
        starCount = 1;
        break;
      case Difficulty.Medium:
        starCount = 2;
        break;
      case Difficulty.Hard:
        starCount = 3;
        break;
      case Difficulty.Ultimate:
        starCount = 4;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        starCount,
        (index) => Padding(
          padding: const EdgeInsets.only(right: 1.0),
          child: SvgPicture.asset(
            'assets/images/home/难度3.svg',
            width: 12,
            height: 12,
            colorFilter: ColorFilter.mode(Colors.white.withOpacity(0.4), BlendMode.srcIn),
          ),
        ),
      ),
    );
  }

  String _getDifficultyText(BuildContext context, Difficulty difficulty) {
    final l10n = AppLocalizations.of(context)!;
    switch (difficulty) {
      case Difficulty.Easy:
        return l10n.easy;
      case Difficulty.Medium:
        return l10n.medium;
      case Difficulty.Hard:
        return l10n.hard;
      case Difficulty.Ultimate:
        return l10n.ultimate;
    }
  }

  String _formatDate(BuildContext context, DateTime d) {
    final l10n = AppLocalizations.of(context)!;
    final diff = DateTime.now().difference(d);

    if (diff.inDays >= 365) {
      final years = (diff.inDays / 365).floor();
      return l10n.yearsAgo(years);
    } else if (diff.inDays >= 30) {
      final months = (diff.inDays / 30).floor();
      return l10n.monthsAgo(months);
    } else if (diff.inDays >= 7) {
      final weeks = (diff.inDays / 7).floor();
      return l10n.weeksAgo(weeks);
    } else if (diff.inDays >= 1) {
      return l10n.daysAgo(diff.inDays);
    } else if (diff.inHours >= 1) {
      return l10n.hoursAgo(diff.inHours);
    } else if (diff.inMinutes >= 1) {
      return l10n.minutesAgo(diff.inMinutes);
    }
    return l10n.justNow;
  }
}
