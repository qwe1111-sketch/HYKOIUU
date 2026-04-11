import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sport_flutter/presentation/bloc/my_posts_bloc.dart';
import 'package:sport_flutter/presentation/pages/post_detail_page.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';

class MyPostsPage extends StatefulWidget {
  const MyPostsPage({super.key});

  @override
  State<MyPostsPage> createState() => _MyPostsPageState();
}

class _MyPostsPageState extends State<MyPostsPage> {
  @override
  void initState() {
    super.initState();
    context.read<MyPostsBloc>().add(FetchMyPosts());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.black, // 修改为纯黑色背景
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. 自定义顶部导航
          Padding(
            padding: EdgeInsets.only(top: topPadding + 10, bottom: 20), // 设置 left: 8 将图标向左移动
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  icon: SvgPicture.asset(
                    'assets/images/community/back.svg',
                    width: 24,
                    colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.myPosts,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // 2. 帖子列表
          Expanded(
            child: BlocBuilder<MyPostsBloc, MyPostsState>(
              builder: (context, state) {
                if (state is MyPostsLoading) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (state is MyPostsLoaded) {
                  if (state.posts.isEmpty) {
                    return Center(
                      child: Text(
                        l10n.noPostsYet,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: state.posts.length,
                    separatorBuilder: (context, index) => Divider(
                      color: Colors.white.withOpacity(0.05),
                      height: 32,
                    ),
                    itemBuilder: (context, index) {
                      final post = state.posts[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => PostDetailPage(post: post),
                          ));
                        },
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SvgPicture.asset(
                              'assets/images/community/posts.svg',
                              width: 22,
                              height: 22,
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    post.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    post.content,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.6),
                                      fontSize: 14,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }
                return Center(
                  child: Text(l10n.videoLoadError, style: const TextStyle(color: Colors.white)),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
