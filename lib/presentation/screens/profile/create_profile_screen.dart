import 'dart:async';

import 'package:fashionista/core/auth/auth_provider_cubit.dart';
import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/domain/usecases/profile/fetch_user_profile_usecase.dart';
import 'package:fashionista/domain/usecases/profile/update_user_profile_usecase.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
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

  bool _redirected = false;

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
        if (user.mobileNumber.isEmpty && !_redirected) {
          _redirected = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/sign-in');
          });
        }
        return Scaffold(
          backgroundColor: context.canvasBackground,
          appBar: AppBar(
            automaticallyImplyLeading: false,
            backgroundColor: context.cardSurface,
            foregroundColor: context.onCanvasText,
            elevation: 0,
            scrolledUnderElevation: 0,
            title: Text(
              'Create Profile',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: context.onCanvasText,
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: SizedBox(
                height: 1,
                child: ColoredBox(color: context.hairline),
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      await _saveProfile(user);
                    }
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: context.accent,
                    textStyle: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Save'),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _ProfileField(
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _fullNameController,
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
                  _ProfileField(
                    label: 'User Name',
                    hint: 'Enter your user name',
                    controller: _userNameController,
                    validator: (value) {
                      if (!RegExp(
                        r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                      ).hasMatch(value!)) {
                        return 'Please enter a valid name';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _ProfileField(
                    label: 'Mobile Number',
                    hint: 'Enter your mobile number',
                    controller: _mobileNumberController,
                    enabled: false,
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
                  _ProfileField(
                    label: 'Email',
                    hint: 'Enter your email',
                    controller: _emailController,
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
                  _ProfileField(
                    label: 'Location',
                    hint: 'Enter your location',
                    controller: _locationController,
                    validator: (value) {
                      if (!RegExp(
                        r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                      ).hasMatch(value!)) {
                        return 'Please enter a valid location';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _PillSelector(
                    label: 'Gender',
                    initialValue: user.gender.trim(),
                    items: const ['Male', 'Female'],
                    onChanged: (gender) {
                      _genderController.text = gender;
                    },
                  ),
                  const SizedBox(height: 16),
                  _DateField(
                    label: 'Date of Birth',
                    initialDate: user.dateOfBirth ??
                        DateTime.now().subtract(const Duration(days: 365 * 14)),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now().subtract(
                      const Duration(days: 365 * 14),
                    ),
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
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  _PillSelector(
                    label: 'Account Type',
                    initialValue: user.accountType.trim(),
                    items: const ['Regular', 'Designer'],
                    onChanged: (value) {
                      _accountTypeController.text = value;
                    },
                  ),
                ],
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

      final result = await sl<FetchUserProfileUsecase>().call(uid!);
      result.fold(
        (ifLeft) {
          if (mounted) {
            // Dismiss the dialog manually
            debugPrint(ifLeft);
            //dismissLoadingDialog(context);
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ifLeft)));
        },
        (ifRight) {
          if (ifRight.uid!.isNotEmpty) {
            userBloc.add(UpdateUser(ifRight));
          }
        },
      );
    } catch (e) {
      if (mounted) {
        // Dismiss the dialog manually
        //dismissLoadingDialog(context);
      }
    }
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
        bannerImage:
            user.bannerImage ?? 'https://picsum.photos/300/200?grayscale',
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
      final updateUserResult = await sl<UpdateUserProfileUsecase>().call(
        updatedUser,
      );

      updateUserResult.fold(
        (ifLeft) {
          if (mounted) {
            // Dismiss the dialog manually
            //Navigator.of(context, rootNavigator: true).pop();
            context.pop();
          }
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(ifLeft)));
        },
        (ifRight) {
          // await sl<FirebaseUserService>().updateUserDisplayName(
          //   updatedUser.fullName,
          // );
          if (mounted) {
            // Dismiss the dialog manually
            Navigator.of(context, rootNavigator: true).pop();
            //context.pop();
          }
        },
      );

      if (!mounted) return;
      final uri = Uri(
        path: '/user-interests',
        queryParameters: {'fromwhere': 'CreateProfileScreen'},
      );
      context.go(uri.toString());
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

class _ProfileField extends StatefulWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool enabled;

  const _ProfileField({
    required this.label,
    required this.hint,
    required this.controller,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
  });

  @override
  State<_ProfileField> createState() => _ProfileFieldState();
}

class _ProfileFieldState extends State<_ProfileField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode()..addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focusNode.hasFocus;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: focused ? context.accent : context.hairline,
          width: focused ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1A1C1E),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: context.mutedText,
              letterSpacing: 0.6,
            ),
            maxLines: 1,
          ),
          const SizedBox(height: 2),
          TextFormField(
            controller: widget.controller,
            validator: widget.validator,
            keyboardType: widget.keyboardType,
            enabled: widget.enabled,
            focusNode: _focusNode,
            style: TextStyle(fontSize: 15, color: context.onCanvasText),
            decoration: InputDecoration(
              isDense: true,
              hintText: widget.hint,
              hintStyle: TextStyle(
                fontSize: 15,
                color: context.placeholderText,
              ),
              border: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }
}

class _PillSelector extends StatefulWidget {
  final String label;
  final String? initialValue;
  final List<String> items;
  final ValueChanged<String> onChanged;

  const _PillSelector({
    required this.label,
    this.initialValue,
    required this.items,
    required this.onChanged,
  });

  @override
  State<_PillSelector> createState() => _PillSelectorState();
}

class _PillSelectorState extends State<_PillSelector> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialValue ?? '';
    widget.onChanged(_selected);
  }

  void _select(String value) {
    setState(() => _selected = value);
    widget.onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: context.mutedText,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (final item in widget.items)
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildPill(item),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildPill(String item) {
    final isSelected = item == _selected;
    if (isSelected) {
      return Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: context.accent,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1AFF5A00),
              blurRadius: 4,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, size: 16, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              item,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
    }
    return GestureDetector(
      onTap: () => _select(item),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.hairline),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0D1A1C1E),
              blurRadius: 2,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: Text(
          item,
          style: TextStyle(fontSize: 14, color: context.mutedText),
        ),
      ),
    );
  }
}

class _DateField extends StatefulWidget {
  final String label;
  final DateTime? initialDate;
  final DateTime firstDate;
  final DateTime lastDate;
  final TextEditingController? controller;
  final FormFieldValidator<String>? validator;
  final ValueChanged<DateTime?> onChanged;

  const _DateField({
    required this.label,
    this.initialDate,
    required this.firstDate,
    required this.lastDate,
    this.controller,
    this.validator,
    required this.onChanged,
  });

  @override
  State<_DateField> createState() => _DateFieldState();
}

class _DateFieldState extends State<_DateField> {
  late TextEditingController _controller;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _controller = TextEditingController(
      text: _selectedDate != null
          ? DateFormat.yMMMd().format(_selectedDate!)
          : '',
    );
  }

  Future<void> _pickDate() async {
    DateTime initialDate = _selectedDate ?? DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: widget.firstDate,
      lastDate: widget.lastDate,
    );

    if (!mounted) return;
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _controller.text = DateFormat.yMMMd().format(picked);
      });
      widget.onChanged(picked);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: _controller,
      readOnly: true,
      validator: widget.validator,
      onTap: _pickDate,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: context.onCanvasText,
      ),
      decoration: InputDecoration(
        labelText: widget.label.toUpperCase(),
        labelStyle: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: context.mutedText,
          letterSpacing: 0.6,
        ),
        alignLabelWithHint: true,
        suffixIcon: Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Icon(Icons.calendar_today, color: context.accent, size: 18),
        ),
        suffixIconConstraints: const BoxConstraints(
          minWidth: 30,
          minHeight: 24,
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: context.cardSurface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.hairline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.accent, width: 1.5),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: context.hairline),
        ),
      ),
    );
  }
}