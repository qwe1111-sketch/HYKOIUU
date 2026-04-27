import 'dart:async';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:video_player/video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerController controller;
  final bool isFullScreen;
  final VoidCallback onToggleFullScreen;
  final VoidCallback? onCast;

  const VideoPlayerWidget({
    super.key,
    required this.controller,
    required this.isFullScreen,
    required this.onToggleFullScreen,
    this.onCast,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  bool _showControls = true;
  Timer? _hideControlsTimer;

  @override
  void initState() {
    super.initState();
    _startHideTimer();
    widget.controller.addListener(_onControllerUpdate);
    if (widget.controller.value.isInitialized && !widget.controller.value.hasError) {
      widget.controller.play();
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    widget.controller.removeListener(_onControllerUpdate);
    super.dispose();
  }

  void _onControllerUpdate() {
    if (!mounted) {
      return;
    }
    if (widget.controller.value.hasError) {
      log('VideoPlayer Error: ${widget.controller.value.errorDescription}');
    }
    setState(() {});
  }

  void _startHideTimer() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && widget.controller.value.isPlaying) {
        setState(() => _showControls = false);
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    if (hours > 0) {
      return "$hours:${twoDigits(minutes)}:${twoDigits(seconds)}";
    } else {
      return "${twoDigits(minutes)}:${twoDigits(seconds)}";
    }
  }

  // 判定是否为外部原因并返回本地化消息
  String _getFriendlyErrorMessage(BuildContext context, String? error) {
    final l10n = AppLocalizations.of(context)!;
    if (error == null) return l10n.videoLoadFailed;
    
    final lowerError = error.toLowerCase();
    
    // 1. 硬件/解码不兼容
    if (lowerError.contains("hevc") || 
        lowerError.contains("h.265") || 
        lowerError.contains("mediacodec") || 
        lowerError.contains("exceeds_capabilities")) {
      return l10n.deviceIncompatible;
    }
    
    // 2. OSS问题或权限限制
    if (lowerError.contains("403") || 
        lowerError.contains("denied") || 
        lowerError.contains("disable") || 
        lowerError.contains("-12660") ||
        lowerError.contains("permission")) {
      return l10n.resourceError;
    }
    
    // 3. 网络问题
    if (lowerError.contains("timeout") || lowerError.contains("network")) {
      return l10n.networkError;
    }

    return l10n.videoLoadFailed;
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    Widget playerContent;
    if (controller.value.hasError) {
      playerContent = Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Color(0xFFCCFF00), size: 48),
              const SizedBox(height: 16),
              Text(
                _getFriendlyErrorMessage(context, controller.value.errorDescription),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      );
    } else if (controller.value.isInitialized) {
      playerContent = VideoPlayer(controller);
    } else {
      playerContent = const Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00)));
    }

    return GestureDetector(
      onTap: () {
        if (controller.value.hasError) return;
        setState(() => _showControls = !_showControls);
        if (_showControls) _startHideTimer();
      },
      child: AspectRatio(
        aspectRatio: controller.value.isInitialized && !controller.value.hasError
            ? controller.value.aspectRatio
            : 16 / 9,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              color: Colors.black,
              child: Center(child: playerContent),
            ),
            if (!controller.value.hasError)
              AnimatedOpacity(
                opacity: _showControls ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: _buildControls(context),
              )
          ],
        ),
      ),
    );
  }

  Widget _buildControls(BuildContext context) {
    final isInitialized = widget.controller.value.isInitialized;
    final position = isInitialized ? widget.controller.value.position : Duration.zero;
    final duration = isInitialized ? widget.controller.value.duration : Duration.zero;
    final hasDuration = duration > Duration.zero;

    return Stack(
      children: [
        Center(
          child: IconButton(
            icon: Icon(widget.controller.value.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled),
            onPressed: () {
              _startHideTimer();
              if (widget.controller.value.isPlaying) {
                widget.controller.pause();
              } else {
                if (position >= duration && hasDuration) {
                  widget.controller.seekTo(Duration.zero);
                }
                widget.controller.play();
              }
              setState(() {});
            },
            color: Colors.white,
            iconSize: 60,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: Row(
            children: [
              if (widget.onCast != null)
                IconButton(
                  icon: const Icon(Icons.cast),
                  onPressed: widget.onCast,
                  color: Colors.white,
                ),
            ],
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            color: Colors.black38,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hasDuration)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Row(
                      children: [
                        Text(_formatDuration(position),
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: VideoProgressIndicator(
                              widget.controller,
                              allowScrubbing: true,
                              colors: VideoProgressColors(
                                playedColor: const Color(0xFFCCFF00),
                                bufferedColor: Colors.white.withOpacity(0.3),
                                backgroundColor: Colors.white.withOpacity(0.1),
                              ),
                            ),
                          ),
                        ),
                        Text(_formatDuration(duration),
                            style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    const SizedBox(width: 8),
                    _buildSpeedMenu(),
                    const Spacer(),
                    IconButton(
                      icon: Icon(widget.isFullScreen
                          ? Icons.fullscreen_exit
                          : Icons.fullscreen),
                      onPressed: widget.onToggleFullScreen,
                      color: Colors.white,
                    )
                  ],
                )
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSpeedMenu() {
    final currentSpeed = widget.controller.value.playbackSpeed;
    return PopupMenuButton<double>(
      onSelected: (speed) {
        _startHideTimer();
        widget.controller.setPlaybackSpeed(speed);
      },
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => [0.5, 1.0, 1.5, 2.0]
          .map((speed) => PopupMenuItem<double>(
                value: speed,
                child: Text(
                  '${speed}x',
                  style: TextStyle(
                    color: speed == currentSpeed ? const Color(0xFFCCFF00) : Colors.white,
                    fontWeight: speed == currentSpeed ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ))
          .toList(),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Text(
          '${currentSpeed}x',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
