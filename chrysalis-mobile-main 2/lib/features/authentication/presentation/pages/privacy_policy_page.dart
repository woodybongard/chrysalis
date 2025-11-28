import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    
    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 20 : screenSize.width * 0.2,
            vertical: 20,
          ),
          child: Center(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: isSmallScreen ? double.infinity : 800,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Privacy Policy',
                    style: AppTextStyles.h2bold(context).copyWith(
                      color: AppColors.black,
                      fontSize: isSmallScreen ? 24 : 28,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Last updated: January 2025',
                    style: AppTextStyles.p1regular(context).copyWith(
                      color: AppColors.neural500,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 30),
                  
                  _buildSection(
                    context,
                    '1. Information We Collect',
                    'We collect information you provide directly to us, such as when you create an account, send messages, or contact us for support. This may include:\n'
                    '• Name and contact information\n'
                    '• Account credentials\n'
                    '• Messages and communications\n'
                    '• Device information and identifiers',
                  ),
                  
                  _buildSection(
                    context,
                    '2. How We Use Your Information',
                    'We use the information we collect to:\n'
                    '• Provide, maintain, and improve our services\n'
                    '• Send you technical notices and support messages\n'
                    '• Respond to your comments and questions\n'
                    '• Protect against fraudulent or illegal activity\n'
                    '• Enforce our Terms of Service',
                  ),
                  
                  _buildSection(
                    context,
                    '3. End-to-End Encryption',
                    'Chrysalis uses end-to-end encryption to protect your messages. This means that only you and the people you communicate with can read or listen to what is sent, and nobody in between, not even Chrysalis.',
                  ),
                  
                  _buildSection(
                    context,
                    '4. Data Storage and Security',
                    'We implement appropriate technical and organizational measures to protect your personal information against unauthorized or unlawful processing, accidental loss, destruction, or damage. Your data is stored on secure servers with restricted access.',
                  ),
                  
                  _buildSection(
                    context,
                    '5. Information Sharing',
                    'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except:\n'
                    '• To comply with legal obligations\n'
                    '• To protect our rights and safety\n'
                    '• With service providers who assist in our operations\n'
                    '• In connection with a merger or acquisition',
                  ),
                  
                  _buildSection(
                    context,
                    '6. Data Retention',
                    'We retain your personal information for as long as necessary to provide our services and fulfill the purposes described in this policy. When you delete your account, we delete your information from our active databases but may retain some information for legal or legitimate business purposes.',
                  ),
                  
                  _buildSection(
                    context,
                    '7. Your Rights',
                    'You have the right to:\n'
                    '• Access your personal information\n'
                    '• Correct inaccurate data\n'
                    '• Request deletion of your data\n'
                    '• Object to processing of your data\n'
                    '• Data portability\n'
                    '• Withdraw consent at any time',
                  ),
                  
                  _buildSection(
                    context,
                    '8. Children\'s Privacy',
                    'Our Service is not intended for children under 13 years of age. We do not knowingly collect personal information from children under 13. If you are a parent or guardian and believe your child has provided us with personal information, please contact us.',
                  ),
                  
                  _buildSection(
                    context,
                    '9. International Data Transfers',
                    'Your information may be transferred to and maintained on servers located outside of your state, province, country, or other governmental jurisdiction where data protection laws may differ from those in your jurisdiction.',
                  ),
                  
                  _buildSection(
                    context,
                    '10. Changes to This Policy',
                    'We may update our Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.',
                  ),
                  
                  _buildSection(
                    context,
                    '11. Contact Us',
                    'If you have any questions about this Privacy Policy, please contact us through the app\'s support feature or email us at privacy@chrysalis.com',
                  ),
                  
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildSection(BuildContext context, String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.p1bold(context).copyWith(
              color: AppColors.black,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: AppTextStyles.p1regular(context).copyWith(
              color: AppColors.neural500,
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}