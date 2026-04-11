import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_flutter/domain/entities/post_comment.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:sport_flutter/presentation/bloc/post_comment_bloc.dart';
import 'package:sport_flutter/presentation/pages/post_detail/widgets/comment_item.dart';
import 'package:sport_flutter/presentation/pages/post_detail/widgets/comment_input_field.dart';

class ReplySheet extends StatefulWidget {
  final int parentCommentId;
  final int postId;
  final ScrollController scrollController;
  final Function(PostComment) onReplyTapped;

  const ReplySheet({
    super.key, 
    required this.parentCommentId, 
    required this.postId, 
    required this.scrollController,
    required this.onReplyTapped,
  });

  @override
  State<ReplySheet> createState() => _ReplySheetState();
}

class _ReplySheetState extends State<ReplySheet> {
  PostComment? _localReplyingTo;

  PostComment? _findCommentById(List<PostComment> comments, int id) {
    for (var c in comments) {
      if (c.id == id) return c;
      if (c.replies.isNotEmpty) {
        final found = _findCommentById(c.replies, id);
        if (found != null) return found;
      }
    }
    return null;
  }

  void _onLocalReplyTapped(PostComment comment) {
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
    final l10n = AppLocalizations.of(context)!;
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
      child: BlocBuilder<PostCommentBloc, PostCommentState>(
        builder: (context, state) {
          if (state is PostCommentLoaded) {
            final parentComment = _findCommentById(state.comments, widget.parentCommentId);

            if (parentComment == null) {
              return const SizedBox.shrink();
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 顶部关闭按钮
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
                // 父评论区域也增加点击收起键盘逻辑
                GestureDetector(
                  onTap: () {
                    _onCancelLocalReply();
                    FocusScope.of(context).unfocus();
                  },
                  behavior: HitTestBehavior.translucent,
                  child: CommentItem(
                    comment: parentComment,
                    postId: widget.postId,
                    onReplyTapped: _onLocalReplyTapped,
                    isReply: false,
                    showReplyButton: false,
                  ),
                ),
                // 中间分割线
                const Divider(color: Colors.white10, height: 1, thickness: 1),
                // 子评论列表
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      _onCancelLocalReply();
                      FocusScope.of(context).unfocus();
                    },
                    behavior: HitTestBehavior.translucent,
                    child: parentComment.replies.isEmpty
                        ? Center(child: Text(l10n.noRepliesYet, style: const TextStyle(color: Colors.white30)))
                        : ListView.builder(
                            controller: widget.scrollController,
                            // 键盘弹起时禁止滚动
                            physics: isKeyboardVisible 
                                ? const NeverScrollableScrollPhysics() 
                                : const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
                            padding: const EdgeInsets.only(top: 8, bottom: 20),
                            itemCount: parentComment.replies.length,
                            itemBuilder: (context, index) {
                              final reply = parentComment.replies[index];
                              return CommentItem(
                                comment: reply,
                                postId: widget.postId,
                                onReplyTapped: _onLocalReplyTapped,
                                isReply: true, 
                                showReplyButton: true,
                              );
                            },
                          ),
                  ),
                ),
                // 弹窗内部的输入框
                CommentInputField(
                  postId: widget.postId,
                  replyingTo: _localReplyingTo,
                  fallbackParent: parentComment,
                  onCancelReply: _onCancelLocalReply,
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
