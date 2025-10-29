import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase/firebase_user_service.dart';
import 'package:fashionista/domain/usecases/profile/update_user_profile_usecase.dart';
import 'package:fashionista/presentation/screens/profile/widgets/custom_chip_form_field_widget.dart';
import 'package:fashionista/presentation/screens/profile/widgets/date_picker_form_field_widget.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_text_field_widget.dart';
import 'package:fashionista/presentation/widgets/custom_icon_button_rounded.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _userNameController;
  late TextEditingController _mobileNumberController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;

  late TextEditingController _genderController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _accountTypeController;

  bool _hasMissingRequiredFields() {
    return _fullNameController.text.isEmpty ||
        _userNameController.text.isEmpty ||
        _genderController.text.isEmpty ||
        _accountTypeController.text.isEmpty;
  }

  Future<bool> _showIncompleteDialog() async {
    if (_hasMissingRequiredFields()) {
      final shouldLeave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Incomplete Profile'),
          content: const Text(
            'Please fill in Full Name, Username, Gender, and Account Type before leaving.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false), // Stay
              child: const Text('Stay'),
            ),
            // TextButton(
            //   onPressed: () => Navigator.of(context).pop(true), // Leave anyway
            //   child: const Text('Leave'),
            // ),
          ],
        ),
      );
      return shouldLeave ?? false;
    }
    return true; // Allow pop
  }

  @override
  void initState() {
    super.initState();
    // Initialize controllers with empty strings first
    _fullNameController = TextEditingController();
    _userNameController = TextEditingController();
    _mobileNumberController = TextEditingController();

    _emailController = TextEditingController();
    _locationController = TextEditingController();
    _genderController = TextEditingController();

    _dateOfBirthController = TextEditingController();
    _accountTypeController = TextEditingController();
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _userNameController.dispose();
    _mobileNumberController.dispose();

    _emailController.dispose();
    _locationController.dispose();
    _genderController.dispose();

    _dateOfBirthController.dispose();
    _accountTypeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<UserBloc, User>(
      builder: (context, user) {
        _fullNameController.text = user.fullName;
        _userNameController.text = user.userName;
        _mobileNumberController.text = user.mobileNumber;
        _emailController.text = user.email;
        _locationController.text = user.location;
        _genderController.text = user.gender;
        _dateOfBirthController.text = user.dateOfBirth == null
            ? ''
            : user.dateOfBirth.toString();
        _accountTypeController.text = user.accountType;
        return PopScope(
          canPop: false, // We decide manually
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) return; // Already popped
            if (_hasMissingRequiredFields()) {
              bool leave = await _showIncompleteDialog();
              if (leave) {} //Navigator.of(context).pop(result);
            } else {
              Navigator.of(context).pop(result);
            }
          },
          child: Scaffold(
            backgroundColor: colorScheme.surface,
            appBar: AppBar(
              foregroundColor: colorScheme.primary,
              backgroundColor: colorScheme.onPrimary,
              title: Text(
                'Edit Profile',
                style: Theme.of(context).textTheme.headlineSmall!.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              elevation: 0,
              actions: [
                Padding(
                  padding: const EdgeInsets.only(
                    right: 12.0,
                  ), // match iOS trailing spacing
                  child: CustomIconButtonRounded(
                    onPressed: () async {
                      if (_formKey.currentState!.validate()) {
                        await _saveProfile(user);
                        //Navigator.of(context).pop();
                      }
                    },
                    iconData: Icons.check,
                  ),
                ),
              ],
            ),

            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Card(
                        color: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProfileInfoTextFieldWidget(
                                label: 'Full Name',
                                controller: _fullNameController,
                                hint: 'Enter your full name',
                                validator: (value) {
                                  // if (value == null || value.isEmpty) {
                                  //   return 'Please enter your full name';
                                  // }
                                  if (!RegExp(
                                    r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                                  ).hasMatch(value!)) {
                                    return 'Please enter a valid name';
                                  }
                                  return null;
                                },
                              ),
                              Divider(
                                height: 16,
                                thickness: 1,
                                color: Colors.grey[300],
                              ),
                              ProfileInfoTextFieldWidget(
                                label: 'User Name',
                                controller: _userNameController,
                                hint: 'Enter your user name',
                                validator: (value) {
                                  // if (value == null || value.isEmpty) {
                                  //   return 'Please enter your user name';
                                  // }
                                  if (!RegExp(
                                    r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                                  ).hasMatch(value!)) {
                                    return 'Please enter a valid name';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ProfileInfoTextFieldWidget(
                                label: 'Mobile Number',
                                controller: _mobileNumberController,
                                hint: 'Enter your mobile number',
                                validator: (value) {
                                  // if (value == null || value.isEmpty) {
                                  //   return 'Please enter your mobile number';
                                  // }
                                  if (!RegExp(
                                    r'^((\+?\d{1,2}\s?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$)?',
                                  ).hasMatch(value!)) {
                                    return 'Please enter a valid mobile number';
                                  }
                                  return null;
                                },
                              ),
                              Divider(
                                height: 16,
                                thickness: 1,
                                color: Colors.grey[300],
                              ),
                              ProfileInfoTextFieldWidget(
                                label: 'Email',
                                controller: _emailController,
                                hint: 'Enter your email',
                                validator: (value) {
                                  // if (value == null || value.isEmpty) {
                                  //   return 'Please enter your email';
                                  // }
                                  if (!RegExp(
                                    r'^([\w-\.]+@([\w-]+\.)+[\w-]{2,4}$)?',
                                  ).hasMatch(value!)) {
                                    return 'Please enter a valid email';
                                  }
                                  return null;
                                },
                              ),
                              Divider(
                                height: 16,
                                thickness: 1,
                                color: Colors.grey[300],
                              ),
                              ProfileInfoTextFieldWidget(
                                label: 'Location',
                                controller: _locationController,
                                hint: 'Enter your location',
                                validator: (value) {
                                  // if (value == null || value.isEmpty) {
                                  //   return 'Please enter your location';
                                  // }
                                  if (!RegExp(
                                    r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                                  ).hasMatch(value!)) {
                                    return 'Please enter a valid location';
                                  }
                                  return null;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Card(
                        color: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomChipFormFieldWidget(
                                initialValue: user.gender,
                                label: 'Gender',
                                items: ['Male', 'Female'],
                                onChanged: (gender) {
                                  _genderController.text = gender;
                                },
                              ),
                              Divider(
                                height: 16,
                                thickness: 1,
                                color: Colors.grey[300],
                              ),
                              DatePickerFormField(
                                label: 'Date of Birth',
                                initialDate: user.dateOfBirth ?? DateTime.now(),
                                firstDate: DateTime(1900),
                                lastDate: DateTime.now(),
                                controller: _dateOfBirthController,
                                validator: (value) =>
                                    value == null || value.isEmpty
                                    ? 'Please select a date'
                                    : null,
                                onChanged: (date) {
                                  if (date != null) {
                                    final formattedDate = DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(date);
                                    _dateOfBirthController.text = formattedDate;
                                    debugPrint('Selected date: $formattedDate');
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      Card(
                        color: colorScheme.onPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                        elevation: 0,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              CustomChipFormFieldWidget(
                                initialValue: user.accountType,
                                label: 'Account Type',
                                items: ['Regular', 'Designer'],
                                onChanged: (value) {
                                  _accountTypeController.text = value;
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false, // prevent accidental dismiss
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void dismissLoadingDialog(BuildContext context) {
    if (Navigator.canPop(context)) {
      Navigator.of(context, rootNavigator: true).pop();
    }
  }

  Future<void> _saveProfile(User user) async {
    if (!mounted) return;
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    if (_formKey.currentState?.validate() ?? false) {
      // final scaffoldMessenger = ScaffoldMessenger.of(context);

      // Check required fields
      if (_fullNameController.text.isEmpty ||
          _userNameController.text.isEmpty ||
          _genderController.text.isEmpty ||
          _accountTypeController.text.isEmpty) {
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(
              'Please fill in Full Name, Username, Gender, and Account Type.',
              style: textTheme.bodyMedium!.copyWith(
                color: colorScheme.onPrimary,
              ),
            ),
            backgroundColor: colorScheme.primary,
          ),
        );
        return; // Stop save process
      }
      // Show progress dialog
      showLoadingDialog(context);

      final updatedUser = user.copyWith(
        fullName: _fullNameController.text,
        userName: _userNameController.text,
        mobileNumber: _mobileNumberController.text,
        email: _emailController.text,
        location: _locationController.text,
        gender: _genderController.text,
        dateOfBirth: _dateOfBirthController.text.isNotEmpty
            ? DateTime.parse(_dateOfBirthController.text)
            : null,
        accountType: _accountTypeController.text,
      );

      context.read<UserBloc>().add(UpdateUser(updatedUser));

      final authProviderCubit = context.read<AuthProviderCubit>();
      authProviderCubit.setAuthState(
        updatedUser.fullName,
        updatedUser.userName,
        updatedUser.mobileNumber,
        true,
      );

      final updateUserResult = await sl<UpdateUserProfileUsecase>().call(
        updatedUser,
      );

      updateUserResult.fold(
        (ifLeft) {
          if (mounted) {
            // Dismiss the dialog manually
            dismissLoadingDialog(context);
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ifLeft)));
        },
        (ifRight) async {
          await sl<FirebaseUserService>().updateUserDisplayName(
            updatedUser.fullName,
          );
          if (mounted) {
            // Dismiss the dialog manually
            dismissLoadingDialog(context);
            context.pop(); // Go back to previous page
          }
        },
      );
    }
  }
}
