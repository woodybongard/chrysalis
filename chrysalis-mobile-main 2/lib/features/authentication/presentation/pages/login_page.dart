import 'package:chrysalis_mobile/core/localization/localization.dart';
import 'package:chrysalis_mobile/core/route/app_routes.dart';
import 'package:chrysalis_mobile/core/socket/bloc/socket_connection_cubit.dart';
import 'package:chrysalis_mobile/core/theme/app_colors.dart';
import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/core/widgets/custom_button.dart';
import 'package:chrysalis_mobile/core/widgets/custom_text_field.dart';
import 'package:chrysalis_mobile/core/widgets/modern_snackbar.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/bloc/login_bloc/login_bloc.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/bloc/login_bloc/login_event.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/bloc/login_bloc/login_state.dart';
import 'package:chrysalis_mobile/features/authentication/presentation/pages/web_login_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;

    if(kIsWeb){
      return const WebLoginPage();
    }

    return BlocConsumer<LoginBloc, LoginState>(
      listener: (context, state) {
        if (state is LoginError) {
          showModernSnackbar(context, state.message);
        }
        if (state is LoginSuccess) {
          if (!state.response.keys.hasKeys) {
            context.read<LoginBloc>().add(RegisterKeyEvent());
          } else {

            context.read<SocketConnectionCubit>().connect();
            context.go(AppRoutes.home);
          }
        }
        if (state is RegisterKeySuccess) {

          context.read<SocketConnectionCubit>().connect();
          context.go(AppRoutes.home);
        }
      },
      builder: (context, state) {
        final isLoading = state is LoginLoading;
        final isValid = state is LoginInitial && state.isValid;

        return Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: AppColors.white,
          appBar: AppBar(
            backgroundColor: AppColors.white,
            elevation: 0,
            leading: Navigator.canPop(context)
                ? IconButton(
                    icon: Icon(
                      Icons.arrow_back,
                      color: AppColors.black,
                      size: 24 * scaleWidth,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  )
                : null,
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                reverse: true, // scrolls when keyboard opens
                padding: EdgeInsets.symmetric(horizontal: 16 * scaleWidth),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24 * scaleHeight),
                        Text(
                          Translator.translate(context, 'login_title'),
                          style: AppTextStyles.h2bold(
                            context,
                          ).copyWith(color: AppColors.black),
                        ),
                        SizedBox(height: 12 * scaleHeight),
                        Text(
                          Translator.translate(context, 'login_subtitle'),
                          style: AppTextStyles.p1regular(
                            context,
                          ).copyWith(color: AppColors.neural200),
                        ),
                        SizedBox(height: 24 * scaleHeight),
                        Text(
                          'ID',
                          style: AppTextStyles.p1bold(context).copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 6 * scaleHeight),
                        CustomTextField(
                          controller: _idController,
                          hintText: Translator.translate(
                            context,
                            'login_id_hint',
                          ),
                          onChanged: (value) {
                            context.read<LoginBloc>().add(
                              LoginIdChanged(value),
                            );
                          },
                        ),
                        SizedBox(height: 24 * scaleHeight),
                        Text(
                          'Password',
                          style: AppTextStyles.p1bold(context).copyWith(
                            color: AppColors.black,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                        SizedBox(height: 6 * scaleHeight),
                        CustomTextField(
                          controller: _passwordController,
                          hintText: Translator.translate(
                            context,
                            'login_password_hint',
                          ),
                          obscureText: _obscurePassword,
                          onChanged: (value) {
                            context.read<LoginBloc>().add(
                              LoginPasswordChanged(value),
                            );
                          },
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                              color: AppColors.neural400,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Spacer(), // pushes button to bottom if enough space
                      CustomButton(
                        text: Translator.translate(context, 'login_button'),
                        isLoading: isLoading,
                        onPressed: isValid && !isLoading
                            ? () {
                                FocusScope.of(context).unfocus();
                                context.read<LoginBloc>().add(
                                  LoginSubmitted(),
                                );
                              }
                            : null,
                      ),
                        SizedBox(height: 32 * scaleHeight),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
