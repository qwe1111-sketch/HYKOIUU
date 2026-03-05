import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sport_flutter/presentation/bloc/my_posts_bloc.dart';
import 'package:sport_flutter/presentation/pages/post_detail_page.dart';
import 'package:sport_flutter/l10n/app_localizations.dart'; // Import localizations
import 'package:iconsax/iconsax.dart';

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
    final l10n = AppLocalizations.of(context)!; // Access localizations

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.myPosts), // Localized title
      ),
      body: BlocBuilder<MyPostsBloc, MyPostsState>(
        builder: (context, state) {
          if (state is MyPostsLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is MyPostsLoaded) {
            if (state.posts.isEmpty) {
              return Center(
                child: Text(l10n.noPostsYet), // Localized empty state text
              );
            }
            return ListView.builder(
              itemCount: state.posts.length,
              itemBuilder: (context, index) {
                final post = state.posts[index];
                return ListTile(
                  leading: const Icon(Iconsax.document_text),
                  title: Text(post.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text(post.content, maxLines: 2, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => PostDetailPage(post: post),
                    ));
                  },
                );
              },
            );
          }
          return Center(
            child: Text(l10n.videoLoadError), // Fallback to a localized error message
          );
        },
      ),
    );
  }
}
