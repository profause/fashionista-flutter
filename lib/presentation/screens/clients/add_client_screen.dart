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
import 'package:fashionista/presentation/screens/profile/widgets/custom_chip_form_field_widget.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
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

  @override
  void initState() {
    super.initState();

    _fullNameController = TextEditingController();
    _genderController = TextEditingController(text: "Male");
    _mobileNumberController = TextEditingController();
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          'Add Client',
          style: textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CustomTextInputFieldWidget(
                          autofocus: true,
                          controller: _fullNameController,
                          hint: 'Full Name',
                          validator: (value) {
                            if (!RegExp(
                              r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                            ).hasMatch(value!)) {
                              return 'Please enter a valid name';
                            }
                            return null;
                          },
                        ),
                      ),
                      const Divider(height: .1, thickness: .1),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: IntlPhoneField(
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
                          obscureText: false,
                          decoration: InputDecoration(
                            hintText: 'Mobile Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            hintStyle: textTheme.titleSmall,
                            filled: true,
                            fillColor: Colors.transparent,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 12,
                            ),
                          ),
                          initialCountryCode: 'GH',
                          disableLengthCheck: true,
                          onChanged: (phone) {
                            _mobileNumberController.text =
                                (phone.completeNumber);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: colorScheme.onPrimary,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomChipFormFieldWidget(
                          initialValue: 'Male',
                          label: 'Gender',
                          items: ['Male', 'Female'],
                          onChanged: (gender) {
                            _genderController.text = gender;
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Hero(
        tag: 'add-client-button',
        child: Container(
          margin: const EdgeInsets.all(16),
          child: AnimatedPrimaryButton(
            text: "Save",
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
      ),
    );
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
