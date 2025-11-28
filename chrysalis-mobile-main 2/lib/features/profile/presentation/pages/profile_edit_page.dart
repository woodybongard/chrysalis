import 'package:chrysalis_mobile/core/theme/app_text_styles.dart';
import 'package:chrysalis_mobile/core/utils/size_config.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_bloc.dart';
import 'package:chrysalis_mobile/features/profile/presentation/bloc/profile_event.dart';
import 'package:chrysalis_mobile/features/profile/presentation/widgets/custom_profile_text_field.dart';
import 'package:chrysalis_mobile/features/profile/presentation/widgets/edit_profile_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({super.key});

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  
  String _originalFirstName = '';
  String _originalLastName = '';
  String _originalUsername = '';
  bool _hasNavigatedBack = false;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _initializeData() {
    final state = context.read<ProfileBloc>().state;
    if (state.hasUser) {
      _originalFirstName = state.user!.firstName;
      _originalLastName = state.user!.lastName;
      _originalUsername = state.user!.username;
      
      _firstNameController.text = _originalFirstName;
      _lastNameController.text = _originalLastName;
      _usernameController.text = _originalUsername;
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  bool get _hasChanges {
    return _firstNameController.text != _originalFirstName ||
           _lastNameController.text != _originalLastName ||
           _usernameController.text != _originalUsername;
  }

  bool get _isFormValid {
    return _firstNameController.text.isNotEmpty && 
           _lastNameController.text.isNotEmpty && 
           _usernameController.text.isNotEmpty;
  }


  @override
  Widget build(BuildContext context) {
    final scaleHeight = context.scaleHeight;
    final scaleWidth = context.scaleWidth;

    return BlocListener<ProfileBloc, ProfileState>(
      listenWhen: (previous, current) {
        return (current.hasSuccess && current.successMessage != previous.successMessage) ||
               (current.hasError && current.errorMessage != previous.errorMessage);
      },
      listener: (context, state) {
        if (state.hasSuccess && !state.isProfileUpdateLoading && !_hasNavigatedBack) {
          _hasNavigatedBack = true;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.successMessage!),
              backgroundColor: Colors.green,
            ),
          );
          Future.delayed(const Duration(milliseconds: 100), () {
            if (mounted && context.canPop()) {
              context.pop();
            }
          });
        } else if (state.hasError && !state.isProfileUpdateLoading) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.errorMessage!),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              const EditProfileAppBar(),
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(horizontal: 17 * scaleWidth),
                  child: Column(
                    children: [
                      SizedBox(height: 24 * scaleHeight),
                      
                      // First Name Field
                      CustomProfileTextField(
                        label: 'First name',
                        placeholder: 'Enter first name',
                        controller: _firstNameController,
                        onChanged: (value) => setState(() {}),
                      ),
                      
                      SizedBox(height: 24 * scaleHeight),
                      
                      // Last Name Field
                      CustomProfileTextField(
                        label: 'Last name',
                        placeholder: 'Enter last name',
                        controller: _lastNameController,
                        onChanged: (value) => setState(() {}),
                      ),
                      
                      SizedBox(height: 24 * scaleHeight),
                      
                      // Username Field
                      CustomProfileTextField(
                        label: 'Username',
                        placeholder: 'Enter username',
                        controller: _usernameController,
                        onChanged: (value) => setState(() {}),
                      ),
                      
                      SizedBox(height: 48 * scaleHeight),
                    ],
                  ),
                ),
              ),
              
              // Update Profile Button
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(horizontal: 17 * scaleWidth),
                child: Column(
                  children: [
                    BlocBuilder<ProfileBloc, ProfileState>(
                      builder: (context, state) {
                        final isLoading = state.isProfileUpdateLoading;
                        
                        return Container(
                          width: double.infinity,
                          height: 52 * scaleHeight,
                          decoration: BoxDecoration(
                            color: _isFormValid && _hasChanges && !isLoading 
                                ? const Color(0xFF25253D) 
                                : const Color(0xFF25253D).withValues(alpha: 0.6),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isFormValid && _hasChanges && !isLoading
                                  ? () {
                                      FocusScope.of(context).unfocus();
                                      context.read<ProfileBloc>().add(
                                        UpdateProfileEvent(
                                          firstName: _firstNameController.text,
                                          lastName: _lastNameController.text,
                                          username: _usernameController.text,
                                        ),
                                      );
                                    }
                                  : null,
                              borderRadius: BorderRadius.circular(100),
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : Text(
                                        'Update profile',
                                        style: AppTextStyles.button(context).copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    SizedBox(height: 32 * scaleHeight),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
