import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

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
                    'Terms and Conditions',
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
                    '1. Acceptance of Terms',
                    'By accessing and using Chrysalis Secure Messaging, you accept and agree to be bound by the terms and provision of this agreement.',
                  ),
                  
                  _buildSection(
                    context,
                    '2. Use License',
                    'Permission is granted to temporarily use Chrysalis Secure Messaging for personal, non-commercial transitory viewing only. This is the grant of a license, not a transfer of title.',
                  ),
                  
                  _buildSection(
                    context,
                    '3. Privacy Policy',
                    'Your use of our Service is also governed by our Privacy Policy. Please review our Privacy Policy, which also governs the Site and informs users of our data collection practices.',
                  ),
                  
                  _buildSection(
                    context,
                    '4. User Accounts',
                    'When you create an account with us, you must provide us with information that is accurate, complete, and current at all times. You are responsible for safeguarding the password and for all activities that occur under your account.',
                  ),
                  
                  _buildSection(
                    context,
                    '5. Prohibited Uses',
                    'You may not use our Service:\n'
                    '• For any unlawful purpose or to solicit others to perform unlawful acts\n'
                    '• To violate any international, federal, provincial, or state regulations, rules, laws, or local ordinances\n'
                    '• To infringe upon or violate our intellectual property rights or the intellectual property rights of others\n'
                    '• To harass, abuse, insult, harm, defame, slander, disparage, intimidate, or discriminate\n'
                    '• To submit false or misleading information',
                  ),
                  
                  _buildSection(
                    context,
                    '6. Content',
                    'Our Service allows you to post, link, store, share and otherwise make available certain information, text, graphics, or other material. You are responsible for the Content that you post to the Service.',
                  ),
                  
                  _buildSection(
                    context,
                    '7. Termination',
                    'We may terminate or suspend your account immediately, without prior notice or liability, for any reason whatsoever, including without limitation if you breach the Terms.',
                  ),
                  
                  _buildSection(
                    context,
                    '8. Disclaimer',
                    'The information on this Service is provided with the understanding that the Company is not herein engaged in rendering legal, accounting, tax, or other professional advice and services.',
                  ),
                  
                  _buildSection(
                    context,
                    '9. Limitation of Liability',
                    'In no event shall our Company be liable for any special, direct, indirect, consequential, or incidental damages or any damages whatsoever.',
                  ),
                  
                  _buildSection(
                    context,
                    '10. Contact Information',
                    'If you have any questions about these Terms and Conditions, please contact us through the app\'s support feature.',
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