import 'package:chrysalis_mobile/core/localization/localization.dart';
import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/core/socket/bloc/socket_connection_cubit.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/widgets/modern_snackbar.dart';
import 'package:chrysalis_mobile/core/widgets/web_custom_button.dart';
import 'package:chrysalis_mobile/core/widgets/web_custom_text_field.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/bloc/login_bloc/login_bloc.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/bloc/login_bloc/login_event.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/bloc/login_bloc/login_state.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/widget/contact_admin_button.dart';
import 'package:chrysalis_mobile/core/utils/contact_admin_utils.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/widget/term_section.dart';
import 'package:chrysalis_mobile/generated/assets.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

class WebLoginPage extends StatefulWidget {
  const WebLoginPage({super.key});

  @override
  State<WebLoginPage> createState() => _WebLoginPageState();
}

class _WebLoginPageState extends State<WebLoginPage> {
  bool _obscurePassword = true;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginError) {
          showModernSnackbar(context, state.message);
        }
        if (state is LoginSuccess) {
          if (!state.response.keys.hasKeys) {
            context.read<LoginBloc>().add(RegisterKeyEvent());
          } else {
            // Navigate immediately without waiting for socket connection on web
            if (kIsWeb) {
              context.go(AppRoutes.webMainChat);
              // Connect socket after navigation to prevent UI freeze
              Future.microtask(() {
                if (context.mounted) {
                  context.read<SocketConnectionCubit>().connect();
                }
              });
            } else {
              context.read<SocketConnectionCubit>().connect();
              context.go(AppRoutes.home);
            }
          }
        }
        if (state is RegisterKeySuccess) {
          // Navigate immediately without waiting for socket connection on web
          if (kIsWeb) {
            context.go(AppRoutes.webMainChat);
            // Connect socket after navigation to prevent UI freeze
            Future.microtask(() {
              if (context.mounted) {
                context.read<SocketConnectionCubit>().connect();
              }
            });
          } else {
            context.read<SocketConnectionCubit>().connect();
            context.go(AppRoutes.home);
          }
        }
      },
      builder: (context, state) {
        final isLoading = state is LoginLoading;
        final isValid = state is LoginInitial && state.isValid;

        return Scaffold(
          backgroundColor: AppColors.white,
          body: Stack(
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.only(top: 40.h),
                  child: Image.asset(
                    Assets.imagesAppLogo,
                    width: 50.h,
                    height: 50.h,
                  ),
                ),
              ),

              Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: EdgeInsets.only(bottom: 40.h),
                  child: const TermsSection(),
                ),
              ),
              Align(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: SizedBox(
                    width: 396.w,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Align(
                          child: Text(
                            textAlign: TextAlign.center,
                            Translator.translate(
                              context,
                              'Sign in to Chrysalis Secure\nMessaging',
                            ),
                            style: AppTextStyles.h2bold(
                              context,
                            ).copyWith(color: AppColors.black),
                          ),
                        ),

                        SizedBox(height: 24.h),
                        Text(
                          'ID',
                          style: AppTextStyles.p1bold(context).copyWith(
                            color: AppColors.neural500,
                            fontWeight: FontWeight.w400,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        WebCustomTextField(
                          controller: _idController,
                          hintText: '',
                          prefixIcon: IconButton(
                            icon: SvgPicture.asset(Assets.iconsSms),
                            onPressed: null,
                          ),
                          onChanged: (value) {
                            context.read<LoginBloc>().add(
                              LoginIdChanged(value),
                            );
                          },
                        ),
                        SizedBox(height: 24.h),
                        Text(
                          'Password',
                          style: AppTextStyles.p1bold(context).copyWith(
                            color: AppColors.neural500,
                            fontWeight: FontWeight.w400,
                            fontSize: 14.sp,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        WebCustomTextField(
                          controller: _passwordController,
                          hintText: '',
                          obscureText: _obscurePassword,
                          prefixIcon: IconButton(
                            icon: SvgPicture.asset(Assets.iconsSecuritySafe),
                            onPressed: null,
                          ),
                          onChanged: (value) {
                            context.read<LoginBloc>().add(
                              LoginPasswordChanged(value),
                            );
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: AppColors.neural500,
                              size: 18.w,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        SizedBox(height: 48.h),
                        WebCustomButton(
                          text: Translator.translate(context, 'Continue'),
                          isLoading: isLoading,
                          borderRadius: 12.r,
                          onPressed: isValid && !isLoading
                              ? () {
                                  FocusScope.of(context).unfocus();
                                  context.read<LoginBloc>().add(
                                    LoginSubmitted(),
                                  );
                                }
                              : null,
                        ),
                        SizedBox(height: 24.h),

                        const Divider(color: Color(0xFFD7D7D7)),

                        SizedBox(height: 24.h),

                        ContactAdminButton(
                          svgPath: Assets.iconsProfile,
                          text: 'Contact admin',
                          onTap: () => ContactAdminUtils.launchContactAdmin(context),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
