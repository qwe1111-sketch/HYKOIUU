import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_flutter/common/time_formatter.dart';
import 'package:sport_flutter/domain/entities/comment.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:sport_flutter/presentation/bloc/auth_bloc.dart';
import 'package:sport_flutter/presentation/bloc/comment_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:sport_flutter/presentation/pages/post_detail/widgets/comment_item_placeholder.dart';

/// The main container for the entire comment section.
class CommentSection extends StatefulWidget {
  final int videoId;
  const CommentSection({super.key, required this.videoId});

  @override
  State<CommentSection> createState() => _CommentSectionState();
}

class _CommentSectionState extends State<CommentSection> {
  Comment? _replyingToComment;

  @override
  void initState() {
    super.initState();
    context.read<CommentBloc>().add(FetchComments(widget.videoId));
  }

  void _setReplyingTo(Comment? comment) {
    setState(() => _replyingToComment = comment);
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Column(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () {
              _setReplyingTo(null);
              FocusScope.of(context).unfocus();
            },
            behavior: HitTestBehavior.translucent,
            child: BlocConsumer<CommentBloc, CommentState>(
              listener: (context, state) {
                if (state is CommentPostSuccess) {
                  _setReplyingTo(null);
                }
              },
              builder: (context, state) {
                if (state is CommentLoaded) {
                  if (state.comments.isEmpty) {
                    return Center(
                      child: Text(
                        localizations.beTheFirstToComment,
                        style: const TextStyle(color: Colors.white30, fontSize: 16),
                      ),
                    );
                  }
                  return RefreshIndicator(
                    color: const Color(0xFFCCFF00), 
                    backgroundColor: const Color(0xFF1C1C1E),
                    onRefresh: () async =>
                        context.read<CommentBloc>().add(FetchComments(widget.videoId)),
                    child: ListView.builder(
                      physics: isKeyboardVisible 
                          ? const NeverScrollableScrollPhysics() 
                          : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      itemCount: state.comments.length,
                      itemBuilder: (context, index) => _CommentItem(
                        comment: state.comments[index],
                        videoId: widget.videoId,
                        onReply: _setReplyingTo,
                      ),
                    ),
                  );
                }
                if (state is CommentError) {
                  return Center(child: Text('Error: ${state.message}', style: const TextStyle(color: Colors.white)));
                }
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFCCFF00),
                  ),
                );
              },
            ),
          ),
        ),
        _CommentInputField(
          videoId: widget.videoId,
          replyingToComment: _replyingToComment,
          onCancelReply: () => _setReplyingTo(null),
        ),
      ],
    );
  }
}

class _CommentItem extends StatelessWidget {
  final Comment comment;
  final int videoId;
  final ValueChanged<Comment> onReply;
  final bool isReply;
  final bool showReplyButton;
  final String? repliedToContent;

  const _CommentItem({
    required this.comment,
    required this.videoId,
    required this.onReply,
    this.isReply = false,
    this.showReplyButton = true,
    this.repliedToContent,
  });

  void _showReplySheet(BuildContext context, Comment parentComment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: BlocProvider.of<CommentBloc>(context),
        child: DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (BuildContext context, ScrollController scrollController) {
            return _ReplySheet(
              parentComment: parentComment,
              videoId: videoId,
              scrollController: scrollController,
              onReply: onReply,
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
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
                    child: (comment.userAvatarUrl != null && comment.userAvatarUrl!.isNotEmpty)
                        ? CachedNetworkImage(
                            imageUrl: comment.userAvatarUrl!,
                            fit: BoxFit.cover,
                            errorWidget: (context, url, error) => const Icon(Icons.person, size: 18, color: Colors.white54),
                          )
                        : const Icon(Icons.person, size: 18, color: Colors.white54),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comment.username, style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 6),
                    if (isReply && repliedToContent != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4.0),
                        child: Text(
                          'Replying to $repliedToContent',
                          style: const TextStyle(color: Colors.white30, fontSize: 14, height: 1.4),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Text(
                      comment.content,
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.4),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildActionRow(context),
          if (showReplyButton && comment.replyCount > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12.0, left: 44),
              child: GestureDetector(
                onTap: () => _showReplySheet(context, comment),
                child: Text(
                  localizations.viewAllReplies(comment.replyCount),
                  style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    final bloc = context.read<CommentBloc>();
    final localizations = AppLocalizations.of(context)!;
    final timeString = formatTimestamp(comment.createdAt, localizations);
    final authState = context.watch<AuthBloc>().state;
    String? currentUserId;
    if (authState is AuthAuthenticated) {
      currentUserId = authState.user.id;
    }

    const activeColor = Color(0xFFCCFF00);
    const inactiveColor = Color(0xFF999999);

    return Padding(
      padding: const EdgeInsets.only(left: 44),
      child: Row(
        children: [
          Text(timeString, style: const TextStyle(color: Colors.white30, fontSize: 12)),
          const Spacer(),
          SizedBox(
            width: 45,
            child: _ActionButton(
              assetPath: 'assets/images/community/like.svg',
              color: comment.userVote == 'like' ? activeColor : inactiveColor,
              count: comment.likeCount,
              onTap: () => bloc.add(VoteComment(comment.id, 'like')),
            ),
          ),
          SizedBox(
            width: 45,
            child: _ActionButton(
              assetPath: comment.userVote == 'dislike' ? 'assets/images/community/dislike_filled.svg' : 'assets/images/community/dislike.svg',
              color: comment.userVote == 'dislike' ? activeColor : inactiveColor,
              count: comment.dislikeCount,
              useColorFilter: false, 
              onTap: () => bloc.add(VoteComment(comment.id, 'dislike')),
            ),
          ),
          SizedBox(
            width: 40,
            child: _ActionButton(
              assetPath: 'assets/images/community/comment.svg',
              useColorFilter: false,
              onTap: () => onReply(comment),
            ),
          ),
          if (currentUserId != null && comment.userId == currentUserId)
            SizedBox(
              width: 40,
              child: _ActionButton(
                assetPath: 'assets/images/community/delete_filled.svg',
                useColorFilter: false,
                onTap: () => _showDeleteConfirmation(context),
              ),
            ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => Dialog(
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
                    l10n.delete,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Confirm to delete this comment?',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 14),
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
                      context.read<CommentBloc>().add(DeleteComment(comment.id));
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
}

class _ReplySheet extends StatefulWidget {
  final Comment parentComment;
  final int videoId;
  final ScrollController scrollController;
  final ValueChanged<Comment> onReply;

  const _ReplySheet({
    required this.parentComment,
    required this.videoId,
    required this.scrollController,
    required this.onReply,
  });

  @override
  State<_ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<_ReplySheet> {
  Comment? _localReplyingTo;

  Comment? _findCommentById(List<Comment> comments, int id) {
    for (var c in comments) {
      if (c.id == id) return c;
      if (c.replies.isNotEmpty) {
        final found = _findCommentById(c.replies, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  void _onLocalReplyTapped(Comment comment) {
    setState(() {
      _localReplyingTo = comment;
    });
  }

  void _onCancelLocalReply() {
    setState(() {
      _localReplyingTo = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isKeyboardVisible = bottomInset > 0;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF1C1C1E),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20.0),
          topRight: Radius.circular(20.0),
        ),
      ),
      padding: EdgeInsets.only(bottom: bottomInset),
      child: BlocBuilder<CommentBloc, CommentState>(
        builder: (context, state) {
          if (state is CommentLoaded) {
            final parentComment = _findCommentById(state.comments, widget.parentComment.id);

            if (parentComment == null) {
              return const SizedBox.shrink();
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ),
                _CommentItem(
                  comment: parentComment,
                  videoId: widget.videoId,
                  onReply: _onLocalReplyTapped,
                  isReply: false,
                  showReplyButton: false,
                ),
                const Divider(color: Colors.white10, height: 1, thickness: 1),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _onCancelLocalReply();
                      FocusScope.of(context).unfocus();
                    },
                    behavior: HitTestBehavior.translucent,
                    child: parentComment.replies.isEmpty
                        ? const Center(child: Text('No replies yet', style: TextStyle(color: Colors.white30)))
                        : ListView.builder(
                            controller: widget.scrollController,
                            physics: isKeyboardVisible 
                                ? const NeverScrollableScrollPhysics() 
                                : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            padding: const EdgeInsets.only(top: 8, bottom: 20),
                            itemCount: parentComment.replies.length,
                            itemBuilder: (context, index) {
                              final reply = parentComment.replies[index];
                              return _CommentItem(
                                comment: reply,
                                videoId: widget.videoId,
                                onReply: _onLocalReplyTapped,
                                isReply: true,
                                showReplyButton: true,
                                repliedToContent: parentComment.content,
                              );
                            },
                          ),
                  ),
                ),
                _CommentInputField(
                  videoId: widget.videoId,
                  replyingToComment: _localReplyingTo,
                  fallbackParentComment: parentComment,
                  onCancelReply: _onCancelLocalReply,
                  useBottomPadding: false,
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator(color: Color(0xFFCCFF00)));
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String assetPath;
  final Color? color;
  final int? count;
  final VoidCallback onTap;
  final bool useColorFilter;

  const _ActionButton({
    required this.assetPath,
    this.color,
    this.count,
    required this.onTap,
    this.useColorFilter = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            assetPath,
            width: 18,
            height: 18,
            colorFilter: useColorFilter && color != null 
                ? ColorFilter.mode(color!, BlendMode.srcIn) 
                : null,
          ),
          if (count != null && count! > 0) ...[
            const SizedBox(width: 4),
            Text(
              count.toString(),
              style: TextStyle(color: color ?? const Color(0xFF999999), fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ],
        ],
      ),
    );
  }
}

class _CommentInputField extends StatefulWidget {
  final int videoId;
  final Comment? replyingToComment;
  final Comment? fallbackParentComment;
  final VoidCallback onCancelReply;
  final bool useBottomPadding;

  const _CommentInputField({
    required this.videoId,
    this.replyingToComment,
    this.fallbackParentComment,
    required this.onCancelReply,
    this.useBottomPadding = true,
  });

  @override
  State<_CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<_CommentInputField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant _CommentInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replyingToComment != null && 
        widget.replyingToComment?.id != oldWidget.replyingToComment?.id) {
      _focusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submitComment() {
    if (_controller.text.trim().isEmpty) return;

    final int? parentId = widget.replyingToComment?.id ?? widget.fallbackParentComment?.id;

    context.read<CommentBloc>().add(PostComment(
          widget.videoId,
          _controller.text.trim(),
          parentCommentId: parentId,
        ));
    _controller.clear();
    _focusNode.unfocus();
    widget.onCancelReply();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final displayComment = widget.replyingToComment ?? widget.fallbackParentComment;
    final hintText = displayComment != null
        ? localizations.replyingTo(displayComment.username)
        : localizations.addAComment;

    final bottomInset = widget.useBottomPadding ? MediaQuery.of(context).viewInsets.bottom : 0.0;

    return Container(
      padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + bottomInset), 
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E),
              borderRadius: BorderRadius.circular(24),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    focusNode: _focusNode,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: hintText,
                      hintStyle: const TextStyle(color: Colors.white30, fontSize: 15),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _controller,
                  builder: (context, value, child) {
                    final bool hasText = value.text.trim().isNotEmpty;
                    return GestureDetector(
                      onTap: _submitComment,
                      child: SvgPicture.asset(
                        'assets/images/community/send.svg',
                        width: 20,
                        height: 20,
                        colorFilter: ColorFilter.mode(
                          hasText ? const Color(0xFFCCFF00) : Colors.white54,
                          BlendMode.srcIn,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
