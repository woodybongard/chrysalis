import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:flutter/material.dart';

class NotificationPreferencesSection extends StatelessWidget {
  final bool isPushNotificationEnabled;
  final VoidCallback onPushNotificationToggle;

  const NotificationPreferencesSection({
    super.key,
    required this.isPushNotificationEnabled,
    required this.onPushNotificationToggle,
  });

  Widget _buildToggleSwitch({
    required bool isEnabled,
    required VoidCallback onToggle,
  }) {
    return GestureDetector(
      onTap: onToggle,
      child: Container(
        width: 44,
        height: 24,
        decoration: BoxDecoration(
          color: isEnabled ? const Color(0xFF31C875) : Colors.grey[300],
          borderRadius: BorderRadius.circular(40),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 200),
          alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9999),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 6,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notification preferences',
          style: TextStyle(
            fontFamily: 'SF Pro Text',
            fontWeight: FontWeight.w600,
            fontSize: 16,
            height: 1.4,
            letterSpacing: -0.3,
            color: Colors.black,
          ),
        ),
        SizedBox(height: 8 * scaleHeight),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            border: Border.all(
              color: const Color(0xFFE5E5E5),
              width: 0.956,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: 12 * scaleWidth,
              vertical: 16 * scaleHeight,
            ),
            child: Column(
              children: [
                // Push Notifications
                Container(
                  padding: EdgeInsets.only(bottom: 16 * scaleHeight),
                  decoration: const BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Color(0xFFEFEFEF),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Push notifications',
                          style: TextStyle(
                            fontFamily: 'SF Pro Text',
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            height: 1.3,
                            letterSpacing: -0.3,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      _buildToggleSwitch(
                        isEnabled: isPushNotificationEnabled,
                        onToggle: onPushNotificationToggle,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24 * scaleHeight),
                // Email Notifications
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Email notifications',
                        style: TextStyle(
                          fontFamily: 'SF Pro Text',
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          height: 1.3,
                          letterSpacing: -0.3,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    _buildToggleSwitch(
                      isEnabled: true, // Always enabled for now
                      onToggle: () {}, // TODO: Implement email notifications toggle
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}