import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:sport_flutter/domain/entities/video.dart';
import 'package:sport_flutter/domain/repositories/video_repository.dart';
import 'package:sport_flutter/presentation/bloc/favorites_bloc.dart';
import 'package:sport_flutter/presentation/pages/video_detail_page.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  @override
  void initState() {
    super.initState();
    context.read<FavoritesBloc>().add(FetchFavorites());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: topPadding + 10, left: 8, bottom: 20),
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: SvgPicture.asset(
                    'assets/images/community/back.svg',
                    width: 24,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.myFavorites,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<FavoritesBloc, FavoritesState>(
              builder: (context, state) {
                if (state is FavoritesLoading) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (state is FavoritesLoaded) {
                  if (state.videos.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noVideosFound,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: state.videos.length,
                    itemBuilder: (context, index) {
                      final video = state.videos[index];
                      return _FavoriteVideoCard(video: video);
                    },
                  );
                }
                return Center(
                  child: Text(l10n.videoLoadError, style: const TextStyle(color: Colors.white)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FavoriteVideoCard extends StatelessWidget {
  final Video video;
  const _FavoriteVideoCard({required this.video});

  String _getLocalizedDifficulty(BuildContext context, Difficulty difficulty) {
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    // 难度星级映射：Easy=1, Medium=2, Hard=3, Ultimate=4
    final starCount = video.difficulty.index + 1;
    final formattedViews = NumberFormat('#,###').format(video.viewCount);
    
    // 使用本地化的 timeago
    final locale = Localizations.localeOf(context).languageCode;
    final timeAgo = timeago.format(video.createdAt, locale: locale);

    // 获取本地化的观看次数后缀
    final viewsSuffix = l10n.videoViews(video.viewCount, "").split("•").first.trim();

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => VideoDetailPage(video: video)),
        ).then((isFavorited) {
          if (isFavorited is bool && !isFavorited) {
            context.read<FavoritesBloc>().add(RemoveFavorite(video));
          }
        });
      },
      child: Container(
        height: 110,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
              child: CachedNetworkImage(
                imageUrl: video.thumbnailUrl,
                width: 140,
                height: 110,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      video.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$timeAgo · $viewsSuffix',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 12),
                    ),
                    Row(
                      children: [
                        // 根据真实难度循环显示切图星级
                        ...List.generate(starCount, (index) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 2),
                            child: SvgPicture.asset(
                              'assets/images/home/难度.svg',
                              height: 12,
                              colorFilter: const ColorFilter.mode(Colors.white60, BlendMode.srcIn),
                            ),
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          _getLocalizedDifficulty(context, video.difficulty),
                          style: const TextStyle(color: Colors.white38, fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
