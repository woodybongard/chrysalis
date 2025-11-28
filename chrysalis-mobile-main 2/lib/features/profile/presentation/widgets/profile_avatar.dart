import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ProfileAvatar extends StatefulWidget {
  const ProfileAvatar({
    required this.initials,
    this.imageUrl,
    this.size = 48.0,
    super.key,
  });

  final String? imageUrl;
  final String initials;
  final double size;

  @override
  State<ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<ProfileAvatar> {
  bool _isLoading = false;
  bool _hasError = false;
  String? _lastImageUrl;
  String? _cachedImageUrl;

  @override
  void didUpdateWidget(ProfileAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset error state and create cache-busted URL when imageUrl changes
    if (widget.imageUrl != _lastImageUrl) {
      _hasError = false;
      _lastImageUrl = widget.imageUrl;
      
      // Create cache-busted URL only when URL actually changes
      if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
        _cachedImageUrl = widget.imageUrl!.contains('?') 
            ? '${widget.imageUrl!}&v=${DateTime.now().millisecondsSinceEpoch}'
            : '${widget.imageUrl!}?v=${DateTime.now().millisecondsSinceEpoch}';
      } else {
        _cachedImageUrl = null;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _lastImageUrl = widget.imageUrl;
    if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      _cachedImageUrl = widget.imageUrl;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scaleWidth = context.scaleWidth;
    final avatarSize = widget.size * scaleWidth;

    if (widget.imageUrl == null || widget.imageUrl!.isEmpty || _hasError) {
      return _buildInitialsAvatar(avatarSize);
    }

    if (_isLoading) {
      return _buildShimmerAvatar(avatarSize);
    }

    return _buildNetworkAvatar(avatarSize);
  }

  Widget _buildNetworkAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
      ),
      child: ClipOval(
        child: Image.network(
          _cachedImageUrl ?? widget.imageUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) {
              _isLoading = false;
              return child;
            }
            _isLoading = true;
            return _buildShimmerAvatar(size);
          },
          errorBuilder: (context, error, stackTrace) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _isLoading = false;
                });
              }
            });
            return _buildInitialsAvatar(size);
          },
        ),
      ),
    );
  }

  Widget _buildShimmerAvatar(double size) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[200]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: size,
        height: size,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildInitialsAvatar(double size) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: AppColors.primaryMain,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          widget.initials,
          style: AppTextStyles.p2SemiBold(context).copyWith(
            color: AppColors.white,
            fontSize: (size * 0.4).clamp(12.0, 24.0),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}