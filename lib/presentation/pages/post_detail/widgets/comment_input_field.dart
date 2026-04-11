import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_flutter/domain/entities/post_comment.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:sport_flutter/presentation/bloc/post_comment_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CommentInputField extends StatefulWidget {
  final int postId;
  final PostComment? replyingTo;
  final PostComment? fallbackParent;
  final VoidCallback onCancelReply;

  const CommentInputField({
    super.key,
    required this.postId,
    required this.replyingTo,
    this.fallbackParent,
    required this.onCancelReply,
  });

  @override
  State<CommentInputField> createState() => _CommentInputFieldState();
}

class _CommentInputFieldState extends State<CommentInputField> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant CommentInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.replyingTo != null && widget.replyingTo?.id != oldWidget.replyingTo?.id) {
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

    final int? parentId = widget.replyingTo?.id ?? widget.fallbackParent?.id;

    context.read<PostCommentBloc>().add(CreateComment(
      postId: widget.postId,
      content: _controller.text.trim(),
      parentCommentId: parentId,
    ));

    _controller.clear();
    _focusNode.unfocus(); 
    widget.onCancelReply();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final displayComment = widget.replyingTo ?? widget.fallbackParent;
    final hintText = displayComment != null
        ? localizations.replyingTo(displayComment.username)
        : localizations.postYourComment;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Colors.white10, width: 0.5)),
      ),
      child: Container(
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
    );
  }
}
