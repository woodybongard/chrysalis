import 'dart:io';
import 'package:chrysalis_mobile/generated/assets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EditProfileImageSection extends StatelessWidget {
  final String? avatarUrl;
  final String initials;
  final dynamic selectedImage; // Can be File on mobile or XFile/bytes on web
  final VoidCallback onCameraTap;

  const EditProfileImageSection({
    super.key,
    this.avatarUrl,
    required this.initials,
    this.selectedImage,
    required this.onCameraTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
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
                image: avatarUrl != null
                    ? DecorationImage(
                        image: NetworkImage(avatarUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                color: avatarUrl == null ? Colors.grey[300] : null,
              ),
              child: avatarUrl == null
                  ? Center(
                      child: Text(
                        initials,
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          // Camera Button
          Positioned(
            bottom: 4,
            right: 4,
            child: GestureDetector(
              onTap: onCameraTap,
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
    );
  }
}

