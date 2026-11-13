import 'package:material_ui/material_ui.dart';

import '../config/constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_text_styles.dart';

/// Ảnh đại diện đội/người dùng Sleeper (xử lý avatar null và lỗi mạng); nhận [avatar], [teamName], [size].
class TeamAvatar extends StatelessWidget {
  const TeamAvatar({
    super.key,
    required this.avatar,
    required this.teamName,
    this.size = AppSpacing.teamAvatarSize,
  });

  final String? avatar;
  final String teamName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = teamName.trim().isNotEmpty
        ? teamName.trim()[0].toUpperCase()
        : '?';
    final url = AppConstants.userAvatarUrl(avatar);

    if (url == null) {
      return _FallbackTeamAvatar(initial: initial, size: size);
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) =>
              _FallbackTeamAvatar(initial: initial, size: size),
        ),
      ),
    );
  }
}

class _FallbackTeamAvatar extends StatelessWidget {
  const _FallbackTeamAvatar({required this.initial, required this.size});

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
