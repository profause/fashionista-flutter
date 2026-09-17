import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase/firebase_user_service.dart';
import 'package:fashionista/domain/usecases/profile/update_user_profile_usecase.dart';
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
            backgroundColor: context.canvasBackground,
            appBar: AppBar(
              foregroundColor: context.onCanvasText,
              backgroundColor: context.canvasBackground,
              surfaceTintColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
              centerTitle: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, size: 22),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
              title: const Text(
                'Edit Profile',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await _saveProfile(user);
                    }
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: context.accent,
                    ),
                  ),
                ),
              ],
            ),

            body: SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Account credentials
                      _EditTextField(
                        label: 'Full Name',
                        controller: _fullNameController,
                        hint: 'Enter your full name',
                        validator: (value) {
                          if (!RegExp(
                            r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                          ).hasMatch(value!)) {
                            return 'Please enter a valid name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _EditTextField(
                        label: 'User Name',
                        controller: _userNameController,
                        hint: 'Enter your user name',
                        validator: (value) {
                          if (!RegExp(
                            r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                          ).hasMatch(value!)) {
                            return 'Please enter a valid name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Contact information
                      _EditTextField(
                        label: 'Mobile Number',
                        controller: _mobileNumberController,
                        hint: 'Enter your mobile number',
                        keyboardType: TextInputType.phone,
                        validator: (value) {
                          if (!RegExp(
                            r'^((\+?\d{1,2}\s?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$)?',
                          ).hasMatch(value!)) {
                            return 'Please enter a valid mobile number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _EditTextField(
                        label: 'Email',
                        controller: _emailController,
                        hint: 'Enter your email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (!RegExp(
                            r'^([\w-\.]+@([\w-]+\.)+[\w-]{2,4}$)?',
                          ).hasMatch(value!)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _EditTextField(
                        label: 'Location',
                        controller: _locationController,
                        hint: 'Enter your location',
                        validator: (value) {
                          if (!RegExp(
                            r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                          ).hasMatch(value!)) {
                            return 'Please enter a valid location';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Gender selection
                      _EditChipGroup(
                        label: 'Gender',
                        items: const ['Male', 'Female'],
                        initialValue: user.gender,
                        onChanged: (gender) {
                          _genderController.text = gender;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Date of birth
                      _EditDateBox(
                        label: 'Date of Birth',
                        initialDate: user.dateOfBirth,
                        firstDate: DateTime(1900),
                        lastDate: DateTime.now().subtract(
                          const Duration(days: 365 * 14),
                        ),
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
                      const SizedBox(height: 20),

                      // Account type selection
                      _EditChipGroup(
                        label: 'Account Type',
                        items: const ['Regular', 'Designer'],
                        initialValue: user.accountType,
                        onChanged: (value) {
                          _accountTypeController.text = value;
                        },
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

class _EditTextField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;

  const _EditTextField({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType,
  });

  @override
  State<_EditTextField> createState() => _EditTextFieldState();
}

class _EditTextFieldState extends State<_EditTextField> {
  late final FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()
      ..addListener(() {
        if (mounted) setState(() => _focused = _focusNode.hasFocus);
      });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 54),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _focused ? context.accent : context.hairline,
          width: _focused ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 0,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: context.secondaryLabel,
            ),
          ),
          const SizedBox(height: 4),
          TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            focusNode: _focusNode,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: context.secondaryLabel,
              ),
              border: InputBorder.none,
              errorStyle: TextStyle(
                fontSize: 11,
                color: context.accent.withValues(alpha: 0.9),
              ),
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }
}

class _EditChipGroup extends StatefulWidget {
  final String label;
  final List<String> items;
  final String initialValue;
  final ValueChanged<String> onChanged;

  const _EditChipGroup({
    required this.label,
    required this.items,
    required this.initialValue,
    required this.onChanged,
  });

  @override
  State<_EditChipGroup> createState() => _EditChipGroupState();
}

class _EditChipGroupState extends State<_EditChipGroup> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: widget.items.map((item) {
            final bool isSelected = _selected == item;
            return GestureDetector(
              onTap: () {
                setState(() => _selected = item);
                widget.onChanged(item);
              },
              child: Container(
                height: 36,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: isSelected
                      ? context.accent
                      : context.iconSubstrate,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? context.accent : context.hairline,
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Color(0x0D000000),
                            blurRadius: 2,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isSelected) ...[
                      const Icon(Icons.check, size: 14, color: Colors.white),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      item,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        color: isSelected
                            ? Colors.white
                            : context.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _EditDateBox extends StatelessWidget {
  final String label;
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final ValueChanged<DateTime?> onChanged;
  final FormFieldValidator<String>? validator;

  const _EditDateBox({
    required this.label,
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: initialDate == null
          ? ''
          : DateFormat('yyyy-MM-dd').format(initialDate!),
      validator: validator,
      builder: (state) {
        final DateTime? shownDate = state.value == null ||
                (state.value?.isEmpty ?? true)
            ? null
            : DateTime.tryParse(state.value!);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: shownDate ?? lastDate,
                  firstDate: firstDate,
                  lastDate: lastDate,
                );

                if (picked != null) {
                  state.didChange(DateFormat('yyyy-MM-dd').format(picked));
                  onChanged(picked);
                }
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 54),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: context.cardSurface,
                  borderRadius: BorderRadius.circular(12),
                  //border: Border.all(color: context.hairline),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 0,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: context.secondaryLabel,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            shownDate == null
                                ? ''
                                : DateFormat.yMMMd().format(shownDate),
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: context.accent,
                    ),
                  ],
                ),
              ),
            ),
            if (state.hasError)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  state.errorText ?? '',
                  style: TextStyle(
                    fontSize: 11,
                    color: context.accent.withValues(alpha: 0.9),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}