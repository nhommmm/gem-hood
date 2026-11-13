import 'package:material_ui/material_ui.dart';

import '../config/constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Ảnh đại diện cầu thủ NBA từ Sleeper CDN kèm fallback chữ cái đầu; nhận [playerId], [fullName], [size].
class PlayerAvatar extends StatelessWidget {
  const PlayerAvatar({
    super.key,
    required this.playerId,
    required this.fullName,
    this.size = AppSpacing.playerAvatarSize,
  });

  final String playerId;
  final String fullName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = fullName.trim().isNotEmpty
        ? fullName.trim()[0].toUpperCase()
        : '?';

    if (playerId.isEmpty || playerId == '0') {
      return _FallbackAvatar(initial: initial, size: size);
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          AppConstants.playerThumbUrl(playerId),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              _FallbackAvatar(initial: initial, size: size),
        ),
      ),
    );
  }
}

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.initial, required this.size});

  final String initial;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.surfaceElevated,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(initial, style: AppTextStyles.avatarInitial),
    );
  }
}
