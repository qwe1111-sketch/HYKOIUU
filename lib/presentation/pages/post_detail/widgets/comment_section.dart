import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_flutter/domain/entities/post_comment.dart';
import 'package:sport_flutter/presentation/bloc/post_comment_bloc.dart';
import 'package:sport_flutter/presentation/pages/post_detail/widgets/comment_item.dart';

class CommentSection extends StatelessWidget {
  final int postId;
  final Function(PostComment) onReplyTapped;
  const CommentSection({super.key, required this.postId, required this.onReplyTapped});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PostCommentBloc, PostCommentState>(
      builder: (context, state) {
        if (state is PostCommentLoading) {
          // 统一修改为荧光绿进度条，移除骨架屏
          return const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: Center(
                child: CircularProgressIndicator(
                  color: Color(0xFFCCFF00),
                ),
              ),
            ),
          );
        }
        if (state is PostCommentLoaded) {
          if (state.comments.isEmpty) {
            return const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text('还没有评论，快来抢个沙发吧！', style: TextStyle(color: Colors.grey)),
                ),
              ),
            );
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => CommentItem(
                comment: state.comments[index],
                postId: postId,
                onReplyTapped: onReplyTapped,
              ),
              childCount: state.comments.length,
            ),
          );
        }
        if (state is PostCommentError) {
          return SliverToBoxAdapter(
            child: Center(
              child: Text('加载评论失败: ${state.message}'),
            ),
          );
        }
        return const SliverToBoxAdapter(child: SizedBox.shrink());
      },
    );
  }
}
