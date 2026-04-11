import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:sport_flutter/presentation/bloc/community_bloc.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class CreatePostPage extends StatefulWidget {
  const CreatePostPage({super.key});

  @override
  State<CreatePostPage> createState() => _CreatePostPageState();
}

class _CreatePostPageState extends State<CreatePostPage> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final List<File> _selectedFiles = [];

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _contentController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _showMediaPickerOptions() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedFiles.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fileLimitExceeded(6))),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.1)),
                      ),
                      child: Column(
                        children: [
                          InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              _pickImages();
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              alignment: Alignment.center,
                              child: Text(
                                l10n.selectPicturesFromAlbum,
                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w400),
                              ),
                            ),
                          ),
                          const Divider(color: Colors.white10, height: 1, indent: 0, endIndent: 0),
                          InkWell(
                            onTap: () {
                              Navigator.of(context).pop();
                              _pickVideo();
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              alignment: Alignment.center,
                              child: Text(
                                l10n.selectVideoFromAlbum,
                                style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w400),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Text(
                          l10n.cancel,
                          style: const TextStyle(
                            color: Color(0xFFCCFF00),
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImages() async {
    final l10n = AppLocalizations.of(context)!;
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage(imageQuality: 80);

    if (!mounted || pickedFiles.isEmpty) return;

    final remainingSpace = 6 - _selectedFiles.length;
    if (pickedFiles.length > remainingSpace) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fileLimitExceeded(remainingSpace))),
      );
    }
    
    setState(() {
      _selectedFiles.addAll(pickedFiles.take(remainingSpace).map((file) => File(file.path)));
    });
  }

  Future<void> _pickVideo() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedFiles.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fileLimitExceeded(6))),
      );
      return;
    }
    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedFiles.add(File(pickedFile.path));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bool canPost = _titleController.text.isNotEmpty && _contentController.text.isNotEmpty;

    return BlocListener<CommunityBloc, CommunityState>(
      listener: (context, state) {
        if (state is CommunityPostSuccess) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        body: Column(
          children: [
            // AppBar
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    Text(
                      l10n.createPost,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    BlocBuilder<CommunityBloc, CommunityState>(
                      builder: (context, state) {
                        final isSubmitting = state is CommunityLoading;
                        return GestureDetector(
                          onTap: canPost && !isSubmitting
                              ? () {
                                  context.read<CommunityBloc>().add(AddPost(
                                        title: _titleController.text,
                                        content: _contentController.text,
                                        mediaFiles: _selectedFiles,
                                      ));
                                }
                              : null,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: canPost && !isSubmitting ? const Color(0xFFCCFF00) : Colors.grey.shade800,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: isSubmitting
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                                : Text(
                                    l10n.publish,
                                    style: TextStyle(
                                      color: canPost && !isSubmitting ? Colors.black : Colors.white38,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8), // 减小顶部边距
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: l10n.enterTitleHint,
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 18),
                        border: InputBorder.none,
                      ),
                    ),
                    const Divider(color: Colors.white12, thickness: 1, height: 16), // 减小高度
                    TextField(
                      controller: _contentController,
                      style: const TextStyle(color: Colors.white70, fontSize: 16),
                      decoration: InputDecoration(
                        hintText: l10n.enterContentHint,
                        hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 16),
                        border: InputBorder.none,
                      ),
                      minLines: 1, // 动态高度
                      maxLines: 8,
                    ),
                    const SizedBox(height: 60), // 进一步减小间距
                    _buildMediaGrid(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _selectedFiles.length + (_selectedFiles.length < 6 ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _selectedFiles.length && _selectedFiles.length < 6) {
          return GestureDetector(
            onTap: _showMediaPickerOptions,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCCFF00).withOpacity(0.5), width: 1),
              ),
              child: const Icon(Icons.add, size: 32, color: Color(0xFFCCFF00)),
            ),
          );
        }

        final file = _selectedFiles[index];
        final isImage = ['.jpg', '.jpeg', '.png', '.gif'].any((ext) => file.path.toLowerCase().endsWith(ext));

        return Stack(
          alignment: Alignment.topRight,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: SizedBox(
                width: double.infinity,
                height: double.infinity,
                child: isImage
                    ? Image.file(file, fit: BoxFit.cover)
                    : _VideoThumbnail(videoFile: file),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  _selectedFiles.removeAt(index);
                });
              },
              child: Container(
                margin: const EdgeInsets.all(6),
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Color(0xFF1A1A1A),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Color(0xFFCCFF00), size: 14),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _VideoThumbnail extends StatefulWidget {
  final File videoFile;

  const _VideoThumbnail({Key? key, required this.videoFile}) : super(key: key);

  @override
  _VideoThumbnailState createState() => _VideoThumbnailState();
}

class _VideoThumbnailState extends State<_VideoThumbnail> {
  Uint8List? _thumbnailData;

  @override
  void initState() {
    super.initState();
    _generateThumbnail();
  }

  Future<void> _generateThumbnail() async {
    try {
      final thumbnailData = await VideoThumbnail.thumbnailData(
        video: widget.videoFile.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 256,
        quality: 50,
      );
      if (mounted) {
        setState(() {
          _thumbnailData = thumbnailData;
        });
      }
    } catch (e) {
      debugPrint("Error generating thumbnail: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_thumbnailData == null) {
      return Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: const CircularProgressIndicator(
          strokeWidth: 2.0,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }
    return Image.memory(
      _thumbnailData!,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}
