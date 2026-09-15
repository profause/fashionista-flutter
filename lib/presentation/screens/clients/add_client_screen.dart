import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/core/widgets/bloc/button_loading_state_cubit.dart';
import 'package:fashionista/data/models/author/author_model.dart';
import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/models/notification/notification_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/data/services/firebase/firebase_notification_service.dart';
import 'package:fashionista/data/services/firebase/firebase_user_service.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:uuid/uuid.dart';

class AddClientScreen extends StatefulWidget {
  final String? clientMobileNumber;
  const AddClientScreen({super.key, this.clientMobileNumber});

  @override
  State<AddClientScreen> createState() => _AddClientScreenState();
}

class _AddClientScreenState extends State<AddClientScreen> {
  final _formKey = GlobalKey<FormState>();
  //late AuthProviderCubit _authProviderCubit;
  late TextEditingController _fullNameController;
  late TextEditingController _mobileNumberController;
  late TextEditingController _genderController;
  late ButtonLoadingStateCubit _buttonLoadingStateCubit;
  late UserBloc userBloc;
  final FocusNode _fullNameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController();
    _genderController = TextEditingController(text: "Male");
    _mobileNumberController = TextEditingController();

    _fullNameFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
    _phoneFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
  }

  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_initialized) {
      _buttonLoadingStateCubit = context.read<ButtonLoadingStateCubit>();
      userBloc = context.read<UserBloc>();

      if (widget.clientMobileNumber != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          findUserByMobileNumber(widget.clientMobileNumber!);
        });
      }

      _initialized = true;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _genderController.dispose();
    _mobileNumberController.dispose();
    _fullNameFocusNode.dispose();
    _phoneFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        foregroundColor: context.onCanvasText,
        backgroundColor: context.canvasBackground,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: Border(bottom: BorderSide(color: context.hairline, width: 1)),
        title: const Text(
          'Add Client',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildFullNameField(),
                      const SizedBox(height: 16),
                      _buildMobileNumberField(),
                      const SizedBox(height: 16),
                      _buildGenderBlock(),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              child: AnimatedPrimaryButton(
                text: "Save Client",
                onPressed: () async {
                  final number = _mobileNumberController.text.trim();
                  final isValid = RegExp(
                    r'^(\+?\d{1,2}\s?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$',
                  ).hasMatch(number);

                  if (!isValid) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Enter mobile number to proceed"),
                        duration: Duration(seconds: 2),
                      ),
                    );
                    return; // Stop here if invalid
                  }
                  _saveClient(Client.empty());
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullNameField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _fullNameFocusNode.hasFocus
              ? context.accent
              : context.hairline,
          width: _fullNameFocusNode.hasFocus ? 1.5 : 1,
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
            'FULL NAME',
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
            focusNode: _fullNameFocusNode,
            autofocus: true,
            controller: _fullNameController,
            validator: (value) {
              if (!RegExp(r'^([A-Za-z_][A-Za-z0-9_]\w+)?').hasMatch(value!)) {
                return 'Please enter a valid name';
              }
              return null;
            },
            style: TextStyle(fontSize: 15, color: context.onCanvasText),
            decoration: InputDecoration(
              isDense: true,
              hintText: 'e.g. Davlynx Mensah',
              hintStyle: TextStyle(
                fontSize: 15,
                color: context.placeholderText,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              disabledBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileNumberField() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: context.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _phoneFocusNode.hasFocus ? context.accent : context.hairline,
          width: _phoneFocusNode.hasFocus ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D1A1C1E),
            blurRadius: 2,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: IntlPhoneField(
        focusNode: _phoneFocusNode,
        initialValue: widget.clientMobileNumber,
        validator: (value) {
          if (!RegExp(
            r'^((\+?\d{1,2}\s?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$)?',
          ).hasMatch(value!.completeNumber)) {
            return 'Please enter a valid mobile number';
          }
          return null;
        },
        keyboardType: TextInputType.phone,
        decoration: InputDecoration(
          hintText: 'Mobile Number',
          hintStyle: TextStyle(fontSize: 15, color: context.placeholderText),
          border: InputBorder.none,
          isDense: true,
          counterText: '',
          //contentPadding: EdgeInsets.zero,
          enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
        ),
        initialCountryCode: 'GH',
        disableLengthCheck: true,
        onChanged: (phone) {
          _mobileNumberController.text = (phone.completeNumber);
        },
      ),
    );
  }

  Widget _buildGenderBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            'Gender',
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
            _GenderPill(
              selected: _selectedGender == 'Male',
              label: 'Male',
              onTap: () => _selectGender('Male'),
            ),
            const SizedBox(width: 10),
            _GenderPill(
              selected: _selectedGender == 'Female',
              label: 'Female',
              onTap: () => _selectGender('Female'),
            ),
          ],
        ),
      ],
    );
  }

  void _selectGender(String gender) {
    setState(() => _selectedGender = gender);
    _genderController.text = gender;
  }

  Future<void> findUserByMobileNumber(String mobileNumber) async {
    showLoadingDialog(context);
    final result = await sl<FirebaseUserService>().findUserByMobileNumber(
      mobileNumber,
    );
    result.fold(
      (l) {
        dismissLoadingDialog(context);
      },
      (r) {
        dismissLoadingDialog(context);
        setState(() {
          _fullNameController.text = r.fullName;
          _mobileNumberController.text = r.mobileNumber;
          _genderController.text = r.gender;
          _selectedGender = r.gender;
        });
      },
    );
  }

  Future<void> _saveClient(Client client) async {
    try {
      User user = userBloc.state;
      String createdBy =
          user.uid ?? firebase_auth.FirebaseAuth.instance.currentUser!.uid;
      _buttonLoadingStateCubit.setLoading(true);
      final fullName = _fullNameController.text.trim();
      final gender = _genderController.text.trim();
      final mobileNumber = _mobileNumberController.text.trim();
      final fullNameInit = fullName.substring(0, 2);

      final materialColorPair = getRandomColorPair();
      final bg = materialColorPair['background']!;
      final fg = materialColorPair['foreground']!;

      final imageUrl =
          'https://dummyimage.com/128.png/$bg/$fg&text=$fullNameInit';

      final measeurementTemplate = ClientMeasurement.getMeasurementTemplate(
        gender,
      );
      final uid = Uuid().v4();
      final createdDate = DateTime.now();
      final newClient = client.copyWith(
        uid: uid,
        fullName: fullName,
        gender: gender,
        mobileNumber: mobileNumber,
        imageUrl: imageUrl,
        createdBy: createdBy,
        createdDate: createdDate,
        measurements: measeurementTemplate
            .map((e) => ClientMeasurement.empty().copyWith(bodyPart: e))
            .toList(),
      );

      //final result = await sl<AddClientUsecase>().call(newClient);

      context.read<ClientBloc>().add(AddClient(newClient));

      final userResult = await sl<FirebaseUserService>().findUserByMobileNumber(
        mobileNumber,
      );

      userResult.fold(
        (l) {
          //AppToast.error(context, 'An error occurred, please try again');
          _buttonLoadingStateCubit.setLoading(false);
          if (mounted) {
            context.pop();
          }
        },
        (r) async {
          if (r.uid != null) {
            //send notification to user who created the client
            final authorUser = AuthorModel.empty().copyWith(
              uid: user.uid,
              name: user.fullName,
              avatar: user.profileImage,
              mobileNumber: user.mobileNumber,
            );

            final notification = NotificationModel.empty().copyWith(
              uid: Uuid().v4(),
              title: 'New Client',
              description: '${user.fullName} has added you as a client',
              createdAt: DateTime.now().millisecondsSinceEpoch,
              type: 'info',
              refId: uid,
              refType: "client",
              from: user.uid,
              to: r.uid,
              author: authorUser,
              status: 'new',
            );

            await sl<FirebaseNotificationService>().createNotification(
              notification,
            );

            _buttonLoadingStateCubit.setLoading(false);
            if (mounted) {
              context.pop();
            }
          }
        },
      );
    } on FirebaseException catch (e) {
      _buttonLoadingStateCubit.setLoading(false);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
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
}

class _GenderPill extends StatelessWidget {
  final bool selected;
  final String label;
  final VoidCallback onTap;

  const _GenderPill({
    required this.selected,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? context.accent : context.cardSurface,
          borderRadius: BorderRadius.circular(999),
          border: selected ? null : Border.all(color: context.hairline),
          boxShadow: selected
              ? const [
                  BoxShadow(
                    color: Color(0x1FFF5A00),
                    blurRadius: 6,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (selected) ...[
              const Icon(Icons.check, size: 14, color: Colors.white),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected ? Colors.white : context.mutedText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
