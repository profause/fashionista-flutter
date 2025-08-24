import 'dart:async';

import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/domain/usecases/profile/fetch_user_profile_usecase.dart';
import 'package:fashionista/presentation/screens/main/main_screen.dart';
import 'package:fashionista/presentation/screens/profile/widgets/custom_chip_form_field_widget.dart';
import 'package:fashionista/presentation/screens/profile/widgets/date_picker_form_field_widget.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_text_field_widget.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class CreateProfileScreen extends StatefulWidget {
  const CreateProfileScreen({super.key});

  @override
  State<CreateProfileScreen> createState() => _CreateProfileScreenState();
}

class _CreateProfileScreenState extends State<CreateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _userNameController;
  late TextEditingController _mobileNumberController;
  late TextEditingController _emailController;
  late TextEditingController _locationController;

  late TextEditingController _genderController;
  late TextEditingController _dateOfBirthController;
  late TextEditingController _accountTypeController;

  StreamSubscription<firebase_auth.User?>? _userChangesSubscription;

  // bool _hasMissingRequiredFields() {
  //   return _fullNameController.text.isEmpty ||
  //       _userNameController.text.isEmpty ||
  //       _genderController.text.isEmpty ||
  //       _accountTypeController.text.isEmpty;
  // }

  // Future<bool> _showIncompleteDialog() async {
  //   if (_hasMissingRequiredFields()) {
  //     final shouldLeave = await showDialog<bool>(
  //       context: context,
  //       builder: (context) => AlertDialog(
  //         title: const Text('Incomplete Profile'),
  //         content: const Text(
  //           'Please fill in Full Name, Username, Gender, and Account Type before leaving.',
  //         ),
  //         actions: [
  //           TextButton(
  //             onPressed: () => Navigator.of(context).pop(false), // Stay
  //             child: const Text('Stay'),
  //           ),
  //           // TextButton(
  //           //   onPressed: () => Navigator.of(context).pop(true), // Leave anyway
  //           //   child: const Text('Leave'),
  //           // ),
  //         ],
  //       ),
  //     );
  //     return shouldLeave ?? false;
  //   }
  //   return true; // Allow pop
  // }

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

    // Listen for auth changes
    _userChangesSubscription = firebase_auth.FirebaseAuth.instance
        .userChanges()
        .listen((user) {
          if (user != null) {
            // User is signed in → fetch details
            _getUserDetails();
          } else {
            // User signed out → redirect
            //Navigator.of(context).pushReplacementNamed('/login');
          }
        });
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
        return Scaffold(
          backgroundColor: colorScheme.surface,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            foregroundColor: colorScheme.primary,
            backgroundColor: colorScheme.onPrimary,
            title: Text(
              'Create Profile',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
            ),
            elevation: 0,
            //toolbarHeight: 0,
            // systemOverlayStyle: SystemUiOverlayStyle(
            //   statusBarColor: colorScheme.onPrimary,
            //   statusBarIconBrightness: Brightness.dark,
            //   //systemNavigationBarColor: Colors.white,
            //   systemNavigationBarIconBrightness: Brightness.dark,
            // ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(
                  right: 12.0,
                ), // match iOS trailing spacing
                child: GestureDetector(
                  onTap: () async {
                    // Handle save action
                    await _saveProfile(user);
                  },
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 17, // iOS standard nav bar font size
                      fontWeight: FontWeight.w600, // semi-bold
                      color: colorScheme.primary, // accent color
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Card(
                      color: colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
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
                        borderRadius: BorderRadius.circular(8),
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
                        borderRadius: BorderRadius.circular(8),
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
                                debugPrint('Selected gender: $gender');
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
                        borderRadius: BorderRadius.circular(8),
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
        );
      },
    );
  }

  Future<void> _getUserDetails() async {
    try {
      final userBloc = context.read<UserBloc>();
      final uid = userBloc.state.uid;
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );
      final result = await sl<FetchUserProfileUsecase>().call(uid!);
      result.fold(
        (ifLeft) {
          if (mounted) {
            // Dismiss the dialog manually
            Navigator.of(context, rootNavigator: true).pop();
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ifLeft)));
        },
        (ifRight) {
          userBloc.clear();
          userBloc.add(UpdateUser(ifRight));
          if (mounted) {
            // Dismiss the dialog manually
            Navigator.of(context, rootNavigator: true).pop();
          }
        },
      );
    } catch (e) {
      if (mounted) {
        // Dismiss the dialog manually
        Navigator.of(context, rootNavigator: true).pop();
      }
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
      showDialog(
        context: context,
        barrierDismissible: false, // Prevent dismissing
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

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

      //sync with firestore
      
      await Future.delayed(const Duration(seconds: 2)); // Simulate saving delay

      if (!mounted) return;

      // Close progress dialog
      Navigator.of(context).pop();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    }
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
    _userChangesSubscription?.cancel();
    super.dispose();
  }
}
