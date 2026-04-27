import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:sport_flutter/presentation/pages/community_page.dart';
import 'package:sport_flutter/presentation/pages/profile_page.dart';
import 'package:sport_flutter/presentation/pages/videos_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    final List<Widget> widgetOptions = [
      VideosPage(key: ValueKey('videos_${locale.languageCode}')),
      const CommunityPage(),
      const ProfilePage(),
    ];

    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _selectedIndex,
        children: widgetOptions,
      ),
      extendBody: true, 
      bottomNavigationBar: _buildCustomBottomNav(context),
    );
  }

  Widget _buildCustomBottomNav(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final screenWidth = MediaQuery.of(context).size.width;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    // 如果没有系统底部间距（旧款手机），给一个 15 像素的基础边距
    // 如果有系统底部间距（如 iPhone 15），则只需微调 5 像素，防止太靠下，
    // 这样总的高度看起来就会很和谐，不会由于 SafeArea 叠加 margin 显得过高。
    final double extraMargin = bottomPadding > 0 ? 5 : 15;
    
    final navWidth = screenWidth - 40; 
    final tabAreaWidth = navWidth / 3;

    double getSliderWidth() {
      if (_selectedIndex == 1) return tabAreaWidth * 1.3;
      return tabAreaWidth * 1.05;
    }

    double sliderWidth = getSliderWidth();
    double rawLeft = (_selectedIndex * tabAreaWidth) + (tabAreaWidth - sliderWidth) / 2;
    double sliderLeft = rawLeft.clamp(4.0, navWidth - sliderWidth - 4.0);

    return Container(
      // 移除原有的 SafeArea，改用内部 padding 精确控制位置
      padding: EdgeInsets.only(bottom: bottomPadding + extraMargin),
      child: Container(
        height: 68,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(34),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF1D2B00).withOpacity(0.7), 
                    borderRadius: BorderRadius.circular(34),
                    border: Border.all(
                      color: const Color(0xFFCCFF00).withOpacity(0.35),
                      width: 1.2,
                    ),
                  ),
                ),
              ),
            ),
            AnimatedPositioned(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              left: sliderLeft,
              width: sliderWidth,
              height: 56,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFF00),
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFCCFF00).withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
              ),
            ),
            Row(
              children: [
                _buildNavItem(0, l10n.home, 'assets/images/profile/home_inactive.svg', tabAreaWidth),
                _buildNavItem(1, l10n.community, 'assets/images/profile/community_inactive.svg', tabAreaWidth),
                _buildNavItem(2, l10n.profile, 'assets/images/profile/profile_active.svg', tabAreaWidth),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String assetPath, double width) {
    bool isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: width,
        height: double.infinity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            SvgPicture.asset(
              assetPath,
              width: 24,
              height: 24,
              colorFilter: ColorFilter.mode(
                isSelected ? Colors.black : const Color(0xFFCCFF00).withOpacity(0.7),
                BlendMode.srcIn,
              ),
              placeholderBuilder: (context) => Icon(
                index == 0 ? Icons.home : index == 1 ? Icons.groups : Icons.person,
                color: isSelected ? Colors.black : Colors.white24,
                size: 24,
              ),
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isSelected
                  ? Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        label,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
