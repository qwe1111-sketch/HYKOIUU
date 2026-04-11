import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sport_flutter/domain/entities/user.dart';
import 'package:sport_flutter/presentation/bloc/auth_bloc.dart';
import 'package:sport_flutter/presentation/bloc/locale_bloc.dart';
import 'package:sport_flutter/presentation/pages/edit_profile_page.dart';
import 'package:sport_flutter/presentation/pages/favorites_page.dart';
import 'package:sport_flutter/presentation/pages/login_page.dart';
import 'package:sport_flutter/presentation/pages/my_posts_page.dart';
import 'package:sport_flutter/presentation/pages/privacy_policy_page.dart';
import 'package:sport_flutter/presentation/pages/reset_password_page.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  static final List<Map<String, String>> _supportedLanguages = [
    {'name': 'English', 'code': 'en'},
    {'name': '中文', 'code': 'zh'},
    {'name': 'Français', 'code': 'fr'},
    {'name': 'Deutsch', 'code': 'de'},
    {'name': 'Русский', 'code': 'ru'},
    {'name': 'Español', 'code': 'es'},
    {'name': '日本語', 'code': 'ja'},
    {'name': '한국어', 'code': 'ko'},
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final topPadding = MediaQuery.of(context).padding.top;
    final currentLanguageCode = Localizations.localeOf(context).languageCode;
    final currentLanguageName = _supportedLanguages.firstWhere(
      (lang) => lang['code'] == currentLanguageCode,
      orElse: () => _supportedLanguages.first,
    )['name'];

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const LoginPage()),
              (route) => false,
            );
          }
        },
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final user = state.user;
            return Stack(
              children: [
                // 1. 全局底层背景图
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 350, 
                  child: Image.asset(
                    'assets/images/profile/top.png',
                    fit: BoxFit.cover,
                    alignment: Alignment.topCenter,
                  ),
                ),
                // 2. 黑色渐变遮罩
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 350,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.1),
                          Colors.black.withOpacity(0.5),
                          Colors.black,
                        ],
                        stops: const [0.0, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                // 3. 滚动内容层
                SingleChildScrollView(
                  padding: EdgeInsets.only(top: topPadding + 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          l10n.myProfile,
                          style: const TextStyle(
                            fontSize: 32, 
                            fontWeight: FontWeight.bold, 
                            color: Colors.white,
                            letterSpacing: -1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 25),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: _buildUserIdentity(user, l10n),
                      ),
                      const SizedBox(height: 30),
                      // 功能卡片组
                      _buildGroup([
                        _buildCustomTile(l10n.myPosts, 'assets/images/profile/my_posts.svg', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MyPostsPage()))),
                        _buildCustomTile(l10n.myFavorites, 'assets/images/profile/favorites.svg', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FavoritesPage()))),
                      ]),
                      _buildGroup([
                        _buildCustomTile(
                          l10n.language, 
                          'assets/images/profile/language.svg', 
                          () => _showLanguageDialog(context, l10n),
                          trailingText: currentLanguageName,
                        ),
                        _buildCustomTile(l10n.editProfile, 'assets/images/profile/edit_profile.svg', () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfilePage(user: user)))),
                        _buildCustomTile(l10n.resetPassword, 'assets/images/profile/reset_password.svg', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPasswordPage()))),
                      ]),
                      _buildGroup([
                        _buildCustomTile(l10n.privacyPolicy, 'assets/images/profile/privacy_policy.svg', () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PrivacyPolicyPage()))),
                      ]),
                      const SizedBox(height: 35),
                      _buildLogoutButton(context, l10n),
                      Center(child: _buildDeleteAccountButton(context, l10n)),
                      const SizedBox(height: 120),
                    ],
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildUserIdentity(User user, AppLocalizations l10n) {
    return Row(
      children: [
        // 头像外圈荧光绿边框
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFCCFF00), width: 1), // 荧光绿边框
          ),
          child: ClipOval(
            child: Container(
              width: 68, // 稍微缩小一点以适配外圈
              height: 68,
              color: Colors.white10,
              child: (user.avatarUrl != null && user.avatarUrl!.isNotEmpty)
                  ? CachedNetworkImage(
                      imageUrl: user.avatarUrl!,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => const Icon(Icons.person, size: 32, color: Colors.white54),
                    )
                  : const Icon(Icons.person, size: 32, color: Colors.white54),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                user.username,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              const SizedBox(height: 4),
              Text(
                (user.bio == null || user.bio!.isEmpty) ? l10n.defaultBio : user.bio!,
                style: const TextStyle(color: Colors.white70, fontSize: 14),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGroup(List<Widget> children) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFCCFF00).withOpacity(0.3), width: 1), 
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        clipBehavior: Clip.antiAlias,
        child: Column(children: children),
      ),
    );
  }

  Widget _buildCustomTile(String title, String assetPath, VoidCallback onTap, {String? trailingText}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Row(
          children: [
            SvgPicture.asset(
              assetPath, 
              width: 26, height: 26,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
              errorBuilder: (context, error, stackTrace) => const Icon(Icons.circle, size: 6, color: Colors.white10),
            ),
            const SizedBox(width: 16),
            Text(
              title, 
              style: const TextStyle(
                color: Colors.white, 
                fontSize: 16, 
                fontWeight: FontWeight.w400, 
                height: 22 / 16, 
                letterSpacing: 0, 
              ),
            ),
            const Spacer(),
            if (trailingText != null)
              Text(
                trailingText, 
                style: const TextStyle(
                  color: Colors.white54, 
                  fontSize: 14,
                  height: 22 / 14,
                )
              ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
          ],
        ),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: const Color(0xFF1C1C1E),
          insetPadding: const EdgeInsets.symmetric(horizontal: 40),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 24),
              // 1. 标题
              Text(
                l10n.selectLanguage, 
                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500)
              ),
              const SizedBox(height: 16),
              // 2. 顶头分割线
              const Divider(color: Colors.white24, height: 1, thickness: 0.5),
              // 3. 语言列表
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: _supportedLanguages.asMap().entries.map((entry) {
                      final index = entry.key;
                      final lang = entry.value;
                      return Column(
                        children: [
                          InkWell(
                            onTap: () {
                              context.read<LocaleBloc>().add(ChangeLocale(Locale(lang['code']!)));
                              Navigator.of(dialogContext).pop();
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              alignment: Alignment.center,
                              child: Text(
                                lang['name']!,
                                style: const TextStyle(
                                  color: Color(0xFFCCFF00), 
                                  fontSize: 18,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ),
                          ),
                          if (index < _supportedLanguages.length - 1)
                            const Divider(color: Colors.white10, height: 1, thickness: 0.5), // 移除缩进，顶头显示
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: () => context.read<AuthBloc>().add(LogoutEvent()),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFCCFF00), 
            foregroundColor: Colors.black,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
            elevation: 0,
          ),
          child: Text(l10n.logout, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context, AppLocalizations l10n) {
    return TextButton(
      onPressed: () {
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
                        l10n.deleteAccount,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        l10n.deleteAccountConfirmation,
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
                          Navigator.of(dialogContext).pop();
                          context.read<AuthBloc>().add(DeleteAccountEvent());
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          alignment: Alignment.center,
                          child: Text(
                            l10n.confirmDeleteAccount,
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
      },
      child: Text(
        l10n.deleteAccount,
        style: const TextStyle(
          color: Color(0xFFCCFF00), 
          decoration: TextDecoration.underline,
          fontSize: 13,
        ),
      ),
    );
  }
}
