import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import './full_screen_media_viewer.dart';

class MediaGallery extends StatefulWidget {
  final List<String> imageUrls;

  const MediaGallery({super.key, required this.imageUrls});

  @override
  State<MediaGallery> createState() => _MediaGalleryState();
}

class _MediaGalleryState extends State<MediaGallery> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      if (_pageController.page?.round() != _currentPage) {
        setState(() {
          _currentPage = _pageController.page!.round();
        });
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.imageUrls.isEmpty) return const SizedBox.shrink();
    
    return Column(
      children: [
        AspectRatio(
          aspectRatio: 4 / 3, // 更接近设计图比例
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.imageUrls.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => FullScreenMediaViewer(
                      mediaUrls: widget.imageUrls,
                      initialIndex: index,
                    ),
                  ));
                },
                child: CachedNetworkImage(
                  imageUrl: widget.imageUrls[index],
                  fit: BoxFit.cover,
                  fadeInDuration: Duration.zero,
                  fadeOutDuration: Duration.zero,
                  placeholder: (context, url) => Container(color: Colors.white10),
                  errorWidget: (context, url, error) => Container(color: Colors.white10, child: const Icon(Icons.error, color: Colors.grey)),
                ),
              );
            },
          ),
        ),
        if (widget.imageUrls.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(widget.imageUrls.length, (index) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == index ? 8 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == index ? const Color(0xFFCCFF00) : Colors.white24,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          )
      ],
    );
  }
}
