import 'package:flutter/material.dart';
import 'package:sport_flutter/presentation/pages/community_page.dart';
import 'package:sport_flutter/presentation/pages/profile_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 2; // 默认选中 Profile

  final List<Widget> _pages = [
    const Center(child: Text('Home', style: TextStyle(color: Colors.white))),
    const CommunityPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      extendBody: true, // 让主体延伸到底部导航栏下方
      // 使用 bottomNavigationBar 属性，但返回我们自定义的 Widget
      bottomNavigationBar: _buildCustomBottomNav(),
    );
  }

  Widget _buildCustomBottomNav() {
    return Container(
      height: 100, // 稍微调高，确保能看到悬浮效果
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      color: Colors.transparent, // 必须透明，否则会有白边
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1C1C1E), // 蓝湖测得的背景色
          borderRadius: BorderRadius.circular(40),
          border: Border.all(color: Colors.white10, width: 0.5), // 增加细微边框感
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(0, 'Home', 'assets/images/profile/home_inactive.png'),
            _buildNavItem(1, 'Community', 'assets/images/profile/community_inactive.png'),
            _buildNavItem(2, 'Profile', 'assets/images/profile/profile_active.png'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String assetPath) {
    bool isSelected = _selectedIndex == index;
    return InkWell( // 增加点击效果
      onTap: () => setState(() => _selectedIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFCCFF00) : Colors.transparent,
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              assetPath,
              width: 24,
              height: 24,
              color: isSelected ? Colors.black : Colors.white54,
              errorBuilder: (context, error, stackTrace) => Icon(
                index == 0 ? Icons.home : index == 1 ? Icons.groups : Icons.person,
                color: isSelected ? Colors.black : Colors.white54,
              ),
            ),
            if (isSelected)
              Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Text(
                  label,
                  style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
