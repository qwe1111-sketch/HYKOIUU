import 'dart:async';
import 'package:flutter/material.dart' hide CarouselController;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:iconsax/iconsax.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:url_launcher/url_launcher.dart';
import 'package:sport_flutter/domain/entities/video.dart';
import 'package:sport_flutter/domain/repositories/video_repository.dart';
import 'package:sport_flutter/domain/usecases/favorite_video.dart';
import 'package:sport_flutter/domain/usecases/get_videos.dart';
import 'package:sport_flutter/domain/usecases/unfavorite_video.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:sport_flutter/presentation/bloc/recommended_video_bloc.dart';
import 'package:sport_flutter/presentation/bloc/video_bloc.dart';
import 'package:sport_flutter/presentation/bloc/video_event.dart';
import 'package:sport_flutter/presentation/bloc/video_state.dart';
import 'package:sport_flutter/presentation/pages/video_detail_page.dart';
import 'package:sport_flutter/presentation/widgets/translated_text.dart';

class VideosPage extends StatefulWidget {
  const VideosPage({super.key});

  @override
  State<VideosPage> createState() => _VideosPageState();
}

class _VideosPageState extends State<VideosPage> {
  int _selectedDifficultyIndex = 0;
  int? _selectedTypeId;
  List<dynamic> _videoTypes = [];
  late final VideoBloc _currentBloc;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeBloc();
    _loadVideoTypes();
  }

  void _initializeBloc() {
    final videoRepository = RepositoryProvider.of<VideoRepository>(context);
    _currentBloc = VideoBloc(
      getVideos: GetVideos(videoRepository),
      favoriteVideo: FavoriteVideo(videoRepository),
      unfavoriteVideo: UnfavoriteVideo(videoRepository),
      cacheManager: RepositoryProvider.of<CacheManager>(context),
    );
  }

  Future<void> _loadVideoTypes() async {
    try {
      final videoRepository = RepositoryProvider.of<VideoRepository>(context);
      final types = await videoRepository.getVideoTypes();
      if (mounted) {
        setState(() {
          _videoTypes = types;
          // Auto-select first type if available
          if (types.isNotEmpty && _selectedTypeId == null) {
            _selectedTypeId = types.first['id'] as int;
          }
        });
        // Load videos with selected type
        if (_selectedTypeId != null) {
          _currentBloc.add(
            FetchVideos(
              Difficulty.values[_selectedDifficultyIndex],
              typeId: _selectedTypeId,
            ),
          );
          // Also load recommended videos with selected type
          context.read<RecommendedVideoBloc>().add(
            FetchRecommendedVideos(typeId: _selectedTypeId, isRefresh: true),
          );
        }
      }
    } catch (e) {
      // Silently handle error - types will just be empty
    }
  }

  void _onTypeSelected(int? typeId) {
    Navigator.of(context).pop(); // Close drawer
    if (typeId == null) return; // Don't allow null selection
    setState(() {
      _selectedTypeId = typeId;
    });
    _currentBloc.add(
      FetchVideos(Difficulty.values[_selectedDifficultyIndex], typeId: typeId),
    );
    // Also reload recommended videos for the selected type
    context.read<RecommendedVideoBloc>().add(
      FetchRecommendedVideos(typeId: typeId, isRefresh: true),
    );
  }

  @override
  void dispose() {
    _currentBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;
    final l10n = AppLocalizations.of(context)!;

    final List<String> localizedDifficulties = [
      l10n.easy,
      l10n.medium,
      l10n.hard,
      l10n.ultimate,
    ];

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.black,
      drawer: _buildTypeDrawer(l10n),
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 300,
            child: Image.asset(
              'assets/images/home/top.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (context, e, s) => Container(color: Colors.black),
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.1), Colors.black],
                  stops: const [0.0, 0.6],
                ),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: topPadding + 20),
                // Top bar: logo perfectly centered, menu button aligned to left
                SizedBox(
                  height: 44,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Center the logo using Row for guaranteed screen-center
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/images/login/app_logo.svg',
                            height: 32,
                            fit: BoxFit.contain,
                            colorFilter: const ColorFilter.mode(
                              Colors.white,
                              BlendMode.srcIn,
                            ),
                            placeholderBuilder: (context) => Text(
                              l10n.appTitle,
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      // Menu button pinned to the left edge, centered with logo
                      Positioned(left: 24, child: _buildTypeMenuButton()),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const _HomeCarousel(),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _buildDifficultySelector(localizedDifficulties),
                ),
                const SizedBox(height: 16),
                BlocProvider.value(
                  value: _currentBloc,
                  child: BlocBuilder<VideoBloc, VideoState>(
                    builder: (context, state) {
                      if (state is VideoLoaded) {
                        return ListView.builder(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: state.videos.length,
                          itemBuilder: (context, index) {
                            final video = state.videos[index];
                            // 严格过滤：只有难度枚举匹配的才显示在列表中
                            if (video.difficulty !=
                                Difficulty.values[_selectedDifficultyIndex]) {
                              return const SizedBox.shrink();
                            }
                            return _VideoListCard(video: video);
                          },
                        );
                      }
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFCCFF00),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build the type menu button (menu.svg) - opens drawer
  Widget _buildTypeMenuButton() {
    return GestureDetector(
      onTap: () {
        _scaffoldKey.currentState?.openDrawer();
      },
      child: SizedBox(
        width: 32,
        height: 32,
        child: SvgPicture.asset(
          'assets/images/home/menu.svg',
          width: 28,
          height: 28,
          colorFilter: const ColorFilter.mode(
            Color(0xFFCCFF00),
            BlendMode.srcIn,
          ),
        ),
      ),
    );
  }

  // Build the left drawer with type list
  Widget _buildTypeDrawer(AppLocalizations l10n) {
    return Drawer(
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
              child: Row(
                children: [
                  SvgPicture.asset(
                    'assets/images/login/app_logo.svg',
                    height: 28,
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFCCFF00),
                      BlendMode.srcIn,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(
              color: Color(0xFFCCFF00),
              height: 1,
              thickness: 0.5,
              indent: 24,
              endIndent: 24,
            ),
            const SizedBox(height: 8),
            // Type list
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _videoTypes.length,
                itemBuilder: (context, index) {
                  final type = _videoTypes[index];
                  final int typeId = type['id'] as int;
                  final String typeName = type['name'] as String? ?? 'Unknown';
                  return _buildTypeDrawerItem(
                    label: _getTranslatedTypeName(typeName, l10n),
                    iconPath: _getTypeIcon(typeName),
                    isSelected: _selectedTypeId == typeId,
                    onTap: () => _onTypeSelected(typeId),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTranslatedTypeName(String name, AppLocalizations l10n) {
    switch (name.toLowerCase()) {
      case 'football':
      case '足球':
        return l10n.videoFootball;
      case 'volleyball':
      case '排球':
        return l10n.videoVolleyball;
      case 'rugby':
      case '橄榄球':
        return l10n.videoRugby;
      case 'baseball':
      case '棒球':
        return l10n.videoBaseball;
      case 'basketball':
      case '篮球':
        return l10n.videoBasketball;
      case 'badminton':
      case '羽毛球':
        return l10n.videoBadminton;
      case 'snooker':
      case 'billiards':
      case '斯诺克':
        return l10n.videoSnooker;
      case 'tennis':
      case '网球':
        return l10n.videoTennis;
      default:
        return name;
    }
  }

  String? _getTypeIcon(String? iconName) {
    if (iconName == null || iconName.isEmpty) return null;
    final lower = iconName.toLowerCase();
    switch (lower) {
      case 'football':
      case 'soccer':
      case '足球':
        return 'assets/images/home/3.0x/football.svg';
      case 'volleyball':
      case '排球':
        return 'assets/images/home/3.0x/volleyball.svg';
      case 'rugby':
      case '橄榄球':
        return 'assets/images/home/3.0x/rugby.svg';
      case 'baseball':
      case '棒球':
        return 'assets/images/home/3.0x/baseball.svg';
      case 'basketball':
      case '篮球':
        return 'assets/images/home/3.0x/basketball.svg';
      case 'badminton':
      case '羽毛球':
        return 'assets/images/home/3.0x/badminton.svg';
      case 'tennis':
      case '网球':
        return 'assets/images/home/3.0x/Tennis.svg';
      case 'snooker':
      case 'billiards':
      case '斯诺克':
        return 'assets/images/home/3.0x/snooker.svg';
      default:
        return null;
    }
  }

  Widget _buildTypeDrawerItem({
    required String label,
    required String? iconPath,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      child: Material(
        color: isSelected
            ? const Color(0xFFCCFF00).withOpacity(0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: isSelected
                  ? Border.all(
                      color: const Color(0xFFCCFF00).withOpacity(0.5),
                      width: 1,
                    )
                  : null,
            ),
            child: Row(
              children: [
                if (iconPath != null)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: SvgPicture.asset(
                      iconPath,
                      colorFilter: ColorFilter.mode(
                        isSelected
                            ? const Color(0xFFCCFF00)
                            : Colors.white.withOpacity(0.7),
                        BlendMode.srcIn,
                      ),
                      placeholderBuilder: (context) => Icon(
                        Icons.sports,
                        color: isSelected
                            ? const Color(0xFFCCFF00)
                            : Colors.white.withOpacity(0.7),
                        size: 24,
                      ),
                    ),
                  )
                else
                  Icon(
                    Icons.sports,
                    color: isSelected
                        ? const Color(0xFFCCFF00)
                        : Colors.white.withOpacity(0.7),
                    size: 24,
                  ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFCCFF00)
                          : Colors.white.withOpacity(0.85),
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(Icons.check, color: const Color(0xFFCCFF00), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDifficultySelector(List<String> localizedDifficulties) {
    return PopupMenuButton<int>(
      offset: const Offset(0, 0),
      color: const Color(0xFF1C1C1E),
      constraints: const BoxConstraints(minWidth: 150),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Color(0xFFCCFF00), width: 1),
      ),
      elevation: 8,
      onSelected: (int index) {
        setState(() {
          _selectedDifficultyIndex = index;
        });
        _currentBloc.add(
          FetchVideos(Difficulty.values[index], typeId: _selectedTypeId),
        );
      },
      itemBuilder: (BuildContext context) {
        final List<PopupMenuEntry<int>> items = [];
        for (int i = 0; i < localizedDifficulties.length; i++) {
          items.add(
            PopupMenuItem<int>(
              value: i,
              height: 48,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      localizedDifficulties[i],
                      style: const TextStyle(
                        color: Color(0xFFCCFF00),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (i == 0)
                    SvgPicture.asset(
                      'assets/images/home/下拉.svg',
                      width: 14,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFCCFF00),
                        BlendMode.srcIn,
                      ),
                    ),
                ],
              ),
            ),
          );
          if (i < localizedDifficulties.length - 1) {
            items.add(
              PopupMenuDivider(
                height: 1,
                color: Colors.white.withOpacity(0.06),
              ),
            );
          }
        }
        return items;
      },
      child: Container(
        width: 150,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E),
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: const Color(0xFFCCFF00).withOpacity(0.5),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                localizedDifficulties[_selectedDifficultyIndex],
                style: const TextStyle(
                  color: Color(0xFFCCFF00),
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            SvgPicture.asset(
              'assets/images/home/下拉.svg',
              width: 14,
              colorFilter: const ColorFilter.mode(
                Color(0xFFCCFF00),
                BlendMode.srcIn,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeCarousel extends StatelessWidget {
  const _HomeCarousel();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecommendedVideoBloc, RecommendedVideoState>(
      builder: (context, state) {
        if (state is RecommendedVideoLoaded && state.videos.isNotEmpty) {
          return CarouselSlider.builder(
            itemCount: state.videos.length,
            options: CarouselOptions(
              height: 220,
              viewportFraction: 0.88,
              enlargeCenterPage: false,
              enableInfiniteScroll: state.videos.length > 1,
              autoPlay: state.videos.length > 1,
              padEnds: true,
            ),
            itemBuilder: (context, index, realIndex) {
              final video = state.videos[index];
              return _CarouselItem(video: video);
            },
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _CarouselItem extends StatelessWidget {
  final Video video;
  const _CarouselItem({required this.video});

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

  // 改进的视频判定
  bool _isRealVideo(String url) {
    if (url.isEmpty) return false;
    final videoExtensions = ['.mp4', '.m3u8', '.mov', '.avi', '.flv', '.wmv'];
    final lowerUrl = url.toLowerCase();

    if (videoExtensions.any((ext) => lowerUrl.contains(ext))) return true;
    return false;
  }

  Future<void> _onTap(BuildContext context) async {
    final url = video.videoUrl.trim();
    if (url.isEmpty) return;

    if (!_isRealVideo(url)) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => VideoDetailPage(video: video)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final starCount = video.difficulty.index + 1;
    final formattedDate = DateFormat.yMd(
      Localizations.localeOf(context).toString(),
    ).format(video.createdAt);

    final bool isVideo = _isRealVideo(video.videoUrl);

    return GestureDetector(
      onTap: () => _onTap(context),
      child: Container(
        width: double.infinity, // 关键修复：确保宽度占满
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: CachedNetworkImageProvider(video.thumbnailUrl),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(
          width: double.infinity, // 关键修复：确保宽度占满
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: isVideo
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.5),
                      Colors.transparent,
                      Colors.black.withOpacity(0.85),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  )
                : null,
          ),
          padding: const EdgeInsets.all(20),
          child: isVideo
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TranslatedText(
                      text: video.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.videoViews(video.viewCount, formattedDate),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        ...List.generate(4, (index) {
                          return Icon(
                            Iconsax.star1,
                            size: 14,
                            color: index < starCount
                                ? Colors.white
                                : Colors.white.withOpacity(0.3),
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          _getLocalizedDifficulty(context, video.difficulty),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _VideoListCard extends StatelessWidget {
  final Video video;
  const _VideoListCard({required this.video});

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
    final starCount = video.difficulty.index + 1;

    final locale = Localizations.localeOf(context).languageCode;
    final timeAgoText = timeago.format(video.createdAt, locale: locale);

    // Get localized views string
    final viewsSuffix = l10n
        .videoViews(video.viewCount, "")
        .split("•")
        .first
        .trim();

    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => VideoDetailPage(video: video))),
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
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                bottomLeft: Radius.circular(20),
              ),
              child: CachedNetworkImage(
                imageUrl: video.thumbnailUrl,
                width: 140,
                height: 110,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TranslatedText(
                      text: video.title,
                      maxLines: 2,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '$timeAgoText · $viewsSuffix',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(starCount, (index) {
                          return const Padding(
                            padding: EdgeInsets.only(right: 2),
                            child: Icon(
                              Iconsax.star1,
                              size: 14,
                              color: Colors.white60,
                            ),
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          _getLocalizedDifficulty(context, video.difficulty),
                          style: const TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
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
