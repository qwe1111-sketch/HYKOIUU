import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_flutter/common/time_formatter.dart';
import 'package:sport_flutter/domain/entities/post_comment.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:sport_flutter/presentation/bloc/auth_bloc.dart';
import 'package:sport_flutter/presentation/bloc/post_comment_bloc.dart';
import 'package:sport_flutter/presentation/pages/post_detail/widgets/reply_sheet.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CommentItem extends StatelessWidget {
  final PostComment comment;
  final int postId;
  final Function(PostComment) onReplyTapped;
  final bool isReply;
  final bool showReplyButton;

  const CommentItem({
    super.key,
    required this.comment,
    required this.postId,
    required this.onReplyTapped,
    this.isReply = false,
    this.showReplyButton = true,
  });

  void _showReplySheet(BuildContext context, PostComment parentComment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: BlocProvider.of<PostCommentBloc>(context),
        child: DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          builder: (BuildContext context, ScrollController scrollController) {
            return ReplySheet(
              parentCommentId: parentComment.id,
              postId: postId,
              scrollController: scrollController,
              onReplyTapped: onReplyTapped,
            );
          },
        ),
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
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.deletePostConfirmation.replaceFirst(RegExp(r'post|帖子'), 'comment'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
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
                      child: Text(
                        l10n.cancel,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                ),
                Container(width: 0.5, height: 50, color: Colors.white12),
                Expanded(
                  child: InkWell(
                    onTap: () {
                      context.read<PostCommentBloc>().add(DeleteComment(comment.id));
                      Navigator.of(dialogContext).pop();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      alignment: Alignment.center,
                      child: Text(
                        l10n.delete,
                        style: const TextStyle(
                          color: Color(0xFFCCFF00),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
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
    final localizations = AppLocalizations.of(context)!;
    // 使用新的递归计算的总回复数
    final totalReplies = comment.totalReplyCount;

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
          if (showReplyButton && totalReplies > 0)
            Padding(
              padding: const EdgeInsets.only(top: 12.0, left: 44),
              child: GestureDetector(
                onTap: () => _showReplySheet(context, comment),
                child: Text(
                  localizations.viewAllReplies(totalReplies),
                  style: const TextStyle(color: Color(0xFFCCFF00), fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActionRow(BuildContext context) {
    final bloc = context.read<PostCommentBloc>();
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
              onTap: () => bloc.add(LikeComment(comment.id)),
            ),
          ),
          SizedBox(
            width: 45,
            child: _ActionButton(
              assetPath: comment.userVote == 'dislike' ? 'assets/images/community/dislike_filled.svg' : 'assets/images/community/dislike.svg',
              color: comment.userVote == 'dislike' ? activeColor : inactiveColor,
              count: comment.dislikeCount,
              useColorFilter: false,
              onTap: () => bloc.add(DislikeComment(comment.id)),
            ),
          ),
          SizedBox(
            width: 40,
            child: _ActionButton(
              assetPath: 'assets/images/community/comment.svg',
              useColorFilter: false,
              onTap: () => onReplyTapped(comment),
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
              style: TextStyle(
                color: color ?? const Color(0xFF999999), 
                fontSize: 12, 
                fontWeight: FontWeight.bold
              ),
            ),
          ],
        ],
      ),
    );
  }
}
