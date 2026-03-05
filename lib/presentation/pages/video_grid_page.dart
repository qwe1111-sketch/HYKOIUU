import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:sport_flutter/domain/entities/video.dart';
import 'package:sport_flutter/domain/repositories/video_repository.dart';
import 'package:sport_flutter/domain/usecases/favorite_video.dart';
import 'package:sport_flutter/domain/usecases/get_videos.dart';
import 'package:sport_flutter/domain/usecases/unfavorite_video.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:sport_flutter/presentation/bloc/video_bloc.dart';
import 'package:sport_flutter/presentation/bloc/video_event.dart';
import 'package:sport_flutter/presentation/bloc/video_state.dart';
import 'package:sport_flutter/presentation/pages/video_detail_page.dart';
import 'package:sport_flutter/presentation/widgets/translated_text.dart';

class VideoGridPage extends StatefulWidget {
  final Difficulty difficulty;

  const VideoGridPage({
    super.key,
    required this.difficulty,
    @Deprecated('Title is now derived from difficulty for localization') String? title,
  });

  @override
  State<VideoGridPage> createState() => _VideoGridPageState();
}

class _VideoGridPageState extends State<VideoGridPage> {
  late final VideoBloc _videoBloc;

  @override
  void initState() {
    super.initState();
    final getVideosUseCase = RepositoryProvider.of<GetVideos>(context, listen: false);
    final favoriteVideoUseCase = RepositoryProvider.of<FavoriteVideo>(context, listen: false);
    final unfavoriteVideoUseCase = RepositoryProvider.of<UnfavoriteVideo>(context, listen: false);
    final cacheManager = RepositoryProvider.of<CacheManager>(context, listen: false);

    _videoBloc = VideoBloc(
      getVideos: getVideosUseCase,
      favoriteVideo: favoriteVideoUseCase,
      unfavoriteVideo: unfavoriteVideoUseCase,
      cacheManager: cacheManager,
    )..add(FetchVideos(widget.difficulty));
  }

  @override
  void dispose() {
    _videoBloc.close();
    super.dispose();
  }

  String _getTitle(AppLocalizations l10n) {
    switch (widget.difficulty) {
      case Difficulty.Easy: return l10n.easy;
      case Difficulty.Medium: return l10n.medium;
      case Difficulty.Hard: return l10n.hard;
      case Difficulty.Ultimate: return l10n.ultimate;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle(l10n)),
      ),
      body: BlocProvider.value(
        value: _videoBloc,
        child: BlocBuilder<VideoBloc, VideoState>(
          builder: (context, state) {
            if (state is VideoLoaded) {
              if (state.videos.isEmpty) {
                return Center(child: Text(l10n.noVideosFound));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(8.0),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 8.0,
                  mainAxisSpacing: 8.0,
                  childAspectRatio: 0.75,
                ),
                itemCount: state.videos.length,
                itemBuilder: (context, index) {
                  final video = state.videos[index];
                  return _GridItem(video: video);
                },
              );
            }
            if (state is VideoError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        l10n.videoLoadError,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () => _videoBloc.add(FetchVideos(widget.difficulty)),
                      icon: const Icon(Icons.refresh),
                      label: Text(l10n.retry),
                    ),
                  ],
                ),
              );
            }
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }
}

class _GridItem extends StatelessWidget {
  final Video video;

  const _GridItem({required this.video});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VideoDetailPage(
              video: video,
            ),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        color: Colors.white,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
                child: CachedNetworkImage(
                  imageUrl: video.thumbnailUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[200],
                    child: const Icon(Icons.error_outline, color: Colors.grey),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: TranslatedText(
                key: ValueKey('${video.title}_${locale.languageCode}'),
                text: video.title,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
