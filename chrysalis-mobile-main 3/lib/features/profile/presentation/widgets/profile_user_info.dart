import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

class ProfileUserInfo extends StatefulWidget {
  final String displayName;
  final String username;
  final String? avatarUrl;
  final String initials;
  final VoidCallback onCameraTap;

  const ProfileUserInfo({
    super.key,
    required this.displayName,
    required this.username,
    this.avatarUrl,
    required this.initials,
    required this.onCameraTap,
  });

  @override
  State<ProfileUserInfo> createState() => _ProfileUserInfoState();
}

class _ProfileUserInfoState extends State<ProfileUserInfo> {
  String? _lastAvatarUrl;
  String? _cachedAvatarUrl;

  @override
  void initState() {
    super.initState();
    _lastAvatarUrl = widget.avatarUrl;
    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
      _cachedAvatarUrl = widget.avatarUrl;
    }
  }

  @override
  void didUpdateWidget(ProfileUserInfo oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Create cache-busted URL when avatar URL changes
    if (widget.avatarUrl != _lastAvatarUrl) {
      _lastAvatarUrl = widget.avatarUrl;
      
      if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
        _cachedAvatarUrl = widget.avatarUrl!.contains('?') 
            ? '${widget.avatarUrl!}&v=${DateTime.now().millisecondsSinceEpoch}'
            : '${widget.avatarUrl!}?v=${DateTime.now().millisecondsSinceEpoch}';
      } else {
        _cachedAvatarUrl = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;

    return Column(
      children: [
        SizedBox(
          width: 130,
          height: 120,
          child: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: widget.avatarUrl == null ? Colors.grey[300] : null,
                  ),
                  child: widget.avatarUrl != null
                      ? ClipOval(
                          child: Image.network(
                            _cachedAvatarUrl ?? widget.avatarUrl!,
                            width: 110,
                            height: 110,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey[300],
                                ),
                                child: Center(
                                  child: Text(
                                    widget.initials,
                                    style: const TextStyle(
                                      fontSize: 40,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        )
                      : Center(
                          child: Text(
                            widget.initials,
                            style: const TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
              // Camera Button
              Positioned(
                bottom: 4,
                right: 4,
                child: GestureDetector(
                  onTap: widget.onCameraTap,
                  child: Container(
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          offset: const Offset(0, 4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: SvgPicture.asset(Assets.iconsIcCamera),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 8 * scaleHeight),
        Text(
          widget.displayName,
          style: AppTextStyles.titleBold24(context).copyWith(
            fontSize: 20 * context.scaleHeight,
            height: 1.0,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 4 * scaleHeight),
        Text(
          '@${widget.username}',
          style: AppTextStyles.bodyMedium(context).copyWith(
            height: 1.3,
            letterSpacing: -0.3,
            color: const Color(0xFF666666),
          ),
        ),
      ],
    );
  }
}