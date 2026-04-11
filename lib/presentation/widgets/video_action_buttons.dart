import 'package:flutter/material.dart';
import 'package:sport_flutter/l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VideoActionButtons extends StatelessWidget {
  final bool isLiked;
  final bool isDisliked;
  final bool isFavorited;
  final bool isInteracting;
  final int likeCount;
  final VoidCallback onLike;
  final VoidCallback onDislike;
  final VoidCallback onFavorite;

  const VideoActionButtons({
    super.key,
    required this.isLiked,
    required this.isDisliked,
    required this.isFavorited,
    required this.isInteracting,
    required this.likeCount,
    required this.onLike,
    required this.onDislike,
    required this.onFavorite,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildActionButton(
          context: context,
          iconPath: isLiked ? 'assets/images/community/like.svg' : 'assets/images/home/like1.svg',
          label: _formatNumber(context, likeCount),
          onPressed: onLike,
          isSelected: isLiked,
          useColorFilter: false, // 全部使用切图原色
        ),
        _buildActionButton(
          context: context,
          iconPath: isDisliked 
              ? 'assets/images/community/dislike_filled.svg' 
              : 'assets/images/community/dislike.svg',
          label: l10n.dislike,
          onPressed: onDislike,
          isSelected: isDisliked,
          useColorFilter: false, // 全部使用切图原色
        ),
        _buildActionButton(
          context: context,
          iconPath: isFavorited ? 'assets/images/home/favorites.svg' : 'assets/images/home/hard.svg',
          label: l10n.favorite,
          onPressed: onFavorite,
          isSelected: isFavorited,
          useColorFilter: false, // 全部使用切图原色
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required String iconPath,
    required String label,
    required bool isSelected,
    VoidCallback? onPressed,
    bool useColorFilter = true,
  }) {
    final bool isButtonDisabled = isInteracting && (onPressed == onLike || onPressed == onDislike);
    
    final Color activeColor = const Color(0xFFCCFF00);
    final Color inactiveColor = Colors.white.withOpacity(0.4);

    return InkWell(
      onTap: isButtonDisabled ? null : onPressed,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              iconPath,
              width: 28,
              height: 28,
              // 全部取消 colorFilter，完全展示切图本身的颜色和细节（如镂空）
              colorFilter: useColorFilter 
                  ? (isSelected ? ColorFilter.mode(activeColor, BlendMode.srcIn) : ColorFilter.mode(inactiveColor, BlendMode.srcIn))
                  : null,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? activeColor : inactiveColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(BuildContext context, int n) {
    final l10n = AppLocalizations.of(context)!;
    if (n >= 10000) {
      return '${(n / 10000).toStringAsFixed(1)}${l10n.tenThousand}';
    }
    return n.toString();
  }
}
