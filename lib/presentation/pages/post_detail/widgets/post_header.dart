import 'dart:async';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sport_flutter/data/cache/video_cache_manager.dart';
import 'package:sport_flutter/domain/entities/community_post.dart';
import 'package:video_player/video_player.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_svg/flutter_svg.dart';
import './media_gallery.dart';
import './full_screen_media_viewer.dart';

class PostHeader extends StatefulWidget {
  final CommunityPost post;

  const PostHeader({super.key, required this.post});

  @override
  State<PostHeader> createState() => _PostHeaderState();
}

class _PostHeaderState extends State<PostHeader> {
  VideoPlayerController? _controller;
  Future<void>? _initializeVideoPlayerFuture;

  void _videoPlayerListener() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.post.videoUrls.isNotEmpty) {
      _initializeVideoPlayerFuture = _initializePlayer();
    }
  }

  Future<void> _initializePlayer() async {
    final url = widget.post.videoUrls.first;
    final fileInfo = await CustomVideoCacheManager().instance.getFileFromCache(url);

    if (fileInfo != null) {
      _controller = VideoPlayerController.file(fileInfo.file);
    } else {
      _controller = VideoPlayerController.networkUrl(Uri.parse(url));
      CustomVideoCacheManager().instance.downloadFile(url);
    }

    _controller!.addListener(_videoPlayerListener);
    await _controller!.initialize();
    if (mounted) setState(() {});
    _controller!.setLooping(true);
  }

  @override
  void dispose() {
    _controller?.removeListener(_videoPlayerListener);
    _controller?.dispose();
    super.dispose();
  }

  Widget _buildVideoPlayer() {
    return FutureBuilder(
      future: _initializeVideoPlayerFuture,
      builder: (context, snapshot) {
        if (_controller != null && _controller!.value.isInitialized) {
          return AspectRatio(
            aspectRatio: 16 / 9,
            child: Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => FullScreenMediaViewer(
                          mediaUrls: widget.post.videoUrls,
                          initialIndex: 0,
                        ),
                      ));
                    },
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: _controller!.value.aspectRatio,
                        child: VideoPlayer(_controller!),
                      ),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.center,
                  child: GestureDetector(
                    onTap: () {
                      _controller!.value.isPlaying ? _controller!.pause() : _controller!.play();
                    },
                    child: AnimatedOpacity(
                      opacity: _controller!.value.isPlaying ? 0.0 : 1.0,
                      duration: const Duration(milliseconds: 300),
                      child: SvgPicture.asset(
                        'assets/images/community/play.svg',
                        width: 50,
                        height: 50,
                        placeholderBuilder: (context) => Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Iconsax.play, color: Colors.white, size: 30),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_controller!.value.isPlaying)
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: VideoProgressIndicator(
                      _controller!,
                      allowScrubbing: true,
                      padding: const EdgeInsets.all(8.0),
                      colors: const VideoProgressColors(
                        playedColor: Color(0xFFCCFF00),
                        bufferedColor: Colors.white24,
                        backgroundColor: Colors.black26,
                      ),
                    ),
                  ),
              ],
            ),
          );
        } else {
          return const SizedBox(height: 200, child: Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00))));
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 0, 0, 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Media at the top
          if (widget.post.imageUrls.isNotEmpty)
            MediaGallery(imageUrls: widget.post.imageUrls),

          if (widget.post.videoUrls.isNotEmpty)
            ClipRRect(
              borderRadius: BorderRadius.circular(0),
              child: _buildVideoPlayer(),
            ),

          const SizedBox(height: 16.0),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
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
                          width: 34,
                          height: 34,
                          color: Colors.white10,
                          child: widget.post.userAvatarUrl != null && widget.post.userAvatarUrl!.isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: widget.post.userAvatarUrl!,
                                  fit: BoxFit.cover,
                                  errorWidget: (context, url, error) => const Icon(Icons.person, size: 20, color: Colors.white54),
                                )
                              : const Icon(Icons.person, size: 20, color: Colors.white54),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      widget.post.username,
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  widget.post.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.post.content,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
