import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sport_flutter/presentation/bloc/community_bloc.dart';
import 'package:sport_flutter/domain/entities/community_post.dart';
import 'package:sport_flutter/presentation/pages/create_post_page.dart';
import 'package:sport_flutter/presentation/pages/post_detail_page.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';

class CommunityPage extends StatefulWidget {
  const CommunityPage({super.key});

  @override
  State<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends State<CommunityPage> {
  @override
  void initState() {
    super.initState();
    context.read<CommunityBloc>().add(FetchPosts());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<CommunityBloc, CommunityState>(
        listener: (context, state) {
          if (state is CommunityError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.message}'), backgroundColor: Colors.redAccent),
            );
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 350, 
                child: Image.asset(
                  'assets/images/community/top.png',
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (context, e, s) => Container(color: Colors.black12),
                ),
              ),
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 350,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.1),
                        Colors.black.withOpacity(0.4),
                        Colors.black,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.fromLTRB(24, topPadding + 20, 24, 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          l10n.community,
                          style: const TextStyle(
                            fontSize: 28, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),
                        GestureDetector(
                          onTap: () => _navigateToCreatePost(context),
                            child: SvgPicture.asset(
                              'assets/images/community/add.svg',
                              width: 20,
                              height: 20,
                              colorFilter: const ColorFilter.mode(Color(0xFFCCFF00), BlendMode.srcIn),
                              placeholderBuilder: (context) => const Icon(Icons.add, color: Color(0xFFCCFF00), size: 20),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _buildContent(state, l10n),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(CommunityState state, AppLocalizations l10n) {
    if (state is CommunityLoaded) {
      if (state.posts.isEmpty) {
        return Center(child: Text(l10n.noPostsYet, style: const TextStyle(color: Colors.white38)));
      }
      return RefreshIndicator(
        onRefresh: () async => context.read<CommunityBloc>().add(FetchPosts()),
        backgroundColor: const Color(0xFF1C1C1E),
        color: const Color(0xFFCCFF00),
        child: ListView.builder(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: state.posts.length,
          // 优化：设置 cacheExtent 增加预加载范围
          cacheExtent: 1000,
          itemBuilder: (context, index) {
            return _PostCard(key: ValueKey(state.posts[index].id), post: state.posts[index]);
          },
        ),
      );
    }
    return const Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00)));
  }

  void _navigateToCreatePost(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<CommunityBloc>(),
          child: const CreatePostPage(),
        ),
      ),
    );
  }
}

// 修改为 StatefulWidget 并使用 AutomaticKeepAliveClientMixin 保持状态
class _PostCard extends StatefulWidget {
  final CommunityPost post;
  const _PostCard({super.key, required this.post});

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true; // 告诉 Flutter 即使滑出屏幕也不要销毁这个卡片

  @override
  Widget build(BuildContext context) {
    super.build(context); // 必须调用 super.build
    return GestureDetector(
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => PostDetailPage(post: widget.post),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFCCFF00), width: 1.5),
                  ),
                  child: ClipOval(
                    child: Container(
                      width: 30,
                      height: 30,
                      color: Colors.white10,
                      child: (widget.post.userAvatarUrl != null && widget.post.userAvatarUrl!.isNotEmpty)
                          ? CachedNetworkImage(
                              imageUrl: widget.post.userAvatarUrl!,
                              fit: BoxFit.cover,
                              errorWidget: (context, url, error) => const Icon(Icons.person, size: 18, color: Colors.white54),
                            )
                          : const Icon(Icons.person, size: 18, color: Colors.white54),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  widget.post.username,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              widget.post.title,
              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              widget.post.content,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white60, fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 12),
            if (widget.post.imageUrls.isNotEmpty || widget.post.videoUrls.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    children: [
                      if (widget.post.imageUrls.isNotEmpty)
                        CachedNetworkImage(
                          imageUrl: widget.post.imageUrls.first,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          memCacheWidth: 800, // 优化内存缓存
                          placeholder: (context, url) => Container(color: Colors.white10),
                          errorWidget: (context, url, error) => Container(color: Colors.white10),
                        )
                      else if (widget.post.videoUrls.isNotEmpty)
                        _VideoThumbnailWidget(videoUrl: widget.post.videoUrls.first),

                      if (widget.post.videoUrls.isNotEmpty)
                        Center(
                          child: SvgPicture.asset(
                            'assets/images/community/play.svg',
                            width: 50,
                            height: 50,
                            placeholderBuilder: (context) => Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.play_arrow_rounded, color: Colors.black, size: 35),
                            ),
                          ),
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

class _VideoThumbnailWidget extends StatefulWidget {
  final String videoUrl;
  const _VideoThumbnailWidget({required this.videoUrl});

  @override
  State<_VideoThumbnailWidget> createState() => _VideoThumbnailWidgetState();
}

class _VideoThumbnailWidgetState extends State<_VideoThumbnailWidget> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String? _thumbnailPath;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    // 简单检查是否已经生成过，防止重复生成
    if (_thumbnailPath != null) return;

    try {
      final String? path = await VideoThumbnail.thumbnailFile(
        video: widget.videoUrl,
        thumbnailPath: (await getTemporaryDirectory()).path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 600,
        quality: 75,
      );
      if (mounted) {
        setState(() {
          _thumbnailPath = path;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    if (_loading) {
      return Container(color: Colors.white10, child: const Center(child: CircularProgressIndicator(strokeWidth: 2)));
    }
    if (_thumbnailPath != null) {
      return Image.file(
        File(_thumbnailPath!),
        fit: BoxFit.cover,
        width: double.infinity,
        cacheWidth: 800, // 优化内存占用
      );
    }
    return Container(color: Colors.white10);
  }
}
