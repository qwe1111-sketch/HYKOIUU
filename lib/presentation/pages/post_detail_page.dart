import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_flutter/domain/entities/community_post.dart';
import 'package:sport_flutter/domain/entities/post_comment.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:sport_flutter/presentation/bloc/auth_bloc.dart';
import 'package:sport_flutter/presentation/bloc/post_comment_bloc.dart';
import 'package:sport_flutter/presentation/pages/post_detail/widgets/comment_input_field.dart';
import 'package:sport_flutter/presentation/pages/post_detail/widgets/comment_section.dart';
import 'package:sport_flutter/presentation/pages/post_detail/widgets/post_header.dart';
import 'package:sport_flutter/presentation/pages/post_detail/widgets/sliver_persistent_header_delegate.dart';
import 'package:sport_flutter/presentation/widgets/shimmer.dart';
import 'package:iconsax/iconsax.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PostDetailPage extends StatefulWidget {
  final CommunityPost post;

  const PostDetailPage({super.key, required this.post});

  @override
  State<PostDetailPage> createState() => _PostDetailPageState();
}

class _PostDetailPageState extends State<PostDetailPage> {
  PostComment? _replyingTo;
  final _scrollController = ScrollController();
  final _postHeaderKey = GlobalKey();
  bool _isAppBarTitleVisible = false;

  @override
  void initState() {
    super.initState();
    context.read<PostCommentBloc>().add(FetchPostComments(widget.post.id));
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_postHeaderKey.currentContext == null) return;

    final renderSliver = _postHeaderKey.currentContext!.findRenderObject() as RenderSliver;
    final postHeaderHeight = renderSliver.geometry!.scrollExtent;

    final shouldShow = _scrollController.offset >= postHeaderHeight;

    if (shouldShow != _isAppBarTitleVisible) {
      setState(() {
        _isAppBarTitleVisible = shouldShow;
      });
    }
  }

  void _onReplyTapped(PostComment comment) {
    setState(() {
      _replyingTo = comment;
    });
  }

  void _onCancelReply() {
    setState(() {
      _replyingTo = null;
    });
  }

  void _showDeleteConfirmationDialog() {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) => Dialog(
        backgroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
              child: Column(
                children: [
                  Text(
                    l10n.deletePost,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.deletePostConfirmation,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white12, height: 1),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Text(l10n.cancel, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                ),
                Container(width: 0.5, height: 50, color: Colors.white12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      context.read<PostCommentBloc>().add(DeletePost(widget.post.id));
                      Navigator.of(dialogContext).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.delete,
                        style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = context.watch<AuthBloc>().state;
    final currentUser = authState is AuthAuthenticated ? authState.user : null;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: Colors.black,
      resizeToAvoidBottomInset: true,
      body: BlocListener<PostCommentBloc, PostCommentState>(
        listener: (context, state) {
          if (state is PostDeletionSuccess) {
            Navigator.of(context).pop(true);
          }
        },
        child: GestureDetector(
          onTap: () {
            FocusScope.of(context).unfocus();
            _onCancelReply();
          },
          child: Column(
            children: [
              // Custom AppBar
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: AnimatedOpacity(
                          opacity: _isAppBarTitleVisible ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundImage: widget.post.userAvatarUrl != null && widget.post.userAvatarUrl!.isNotEmpty
                                    ? CachedNetworkImageProvider(widget.post.userAvatarUrl!)
                                    : null,
                                child: widget.post.userAvatarUrl == null || widget.post.userAvatarUrl!.isEmpty
                                    ? const Icon(Iconsax.profile, size: 14)
                                    : null,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                widget.post.username,
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (currentUser != null && widget.post.userId.toString() == currentUser.id)
                        IconButton(
                          onPressed: _showDeleteConfirmationDialog,
                          icon: SvgPicture.asset(
                            'assets/images/community/delete.svg',
                            width: 22,
                            height: 22,
                            colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                          ),
                        ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  // 关键点：键盘弹起时禁止滚动
                  physics: isKeyboardVisible 
                      ? const NeverScrollableScrollPhysics() 
                      : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                  slivers: [
                    SliverToBoxAdapter(key: _postHeaderKey, child: PostHeader(post: widget.post)),
                    SliverPersistentHeader(
                      pinned: true,
                      delegate: SportSliverPersistentHeaderDelegate(
                        maxHeight: 50,
                        minHeight: 50,
                        child: Container(
                          color: Colors.black,
                          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
                          alignment: Alignment.centerLeft,
                          child: Text(
                            l10n.comments,
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                    BlocBuilder<PostCommentBloc, PostCommentState>(
                      builder: (context, state) {
                        if (state is PostCommentLoading) {
                          return const SliverToBoxAdapter(child: SizedBox(height: 200, child: ShimmerLoading()));
                        }
                        if (state is PostCommentLoaded) {
                          if (state.comments.isEmpty) {
                            return SliverToBoxAdapter(
                              child: Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 60.0),
                                  child: Text(
                                    l10n.beTheFirstToComment,
                                    style: const TextStyle(color: Colors.white30, fontSize: 16),
                                  ),
                                ),
                              ),
                            );
                          }
                          return CommentSection(postId: widget.post.id, onReplyTapped: _onReplyTapped);
                        }
                        return const SliverToBoxAdapter(child: SizedBox.shrink());
                      },
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ),
              CommentInputField(
                postId: widget.post.id,
                replyingTo: _replyingTo,
                onCancelReply: _onCancelReply,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
