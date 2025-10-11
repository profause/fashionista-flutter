import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/core/widgets/bloc/button_loading_state_cubit.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/models/profile/bloc/user_bloc.dart';
import 'package:fashionista/data/models/profile/models/user.dart';
import 'package:fashionista/domain/usecases/clients/add_client_usecase.dart';
import 'package:fashionista/presentation/screens/profile/widgets/custom_chip_form_field_widget.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_text_field_widget.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

class AddClientScreen extends StatefulWidget {
  const AddClientScreen({super.key});

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
    //if (mounted) {
    //_authProviderCubit = context.read<AuthProviderCubit>();
    _buttonLoadingStateCubit = context.read<ButtonLoadingStateCubit>();
    _fullNameController = TextEditingController();
    _genderController = TextEditingController();
    _genderController.text = 'Male';
    _mobileNumberController = TextEditingController();
    //}
    userBloc = context.read<UserBloc>();
    super.initState();
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
          padding: const EdgeInsets.all(8),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
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

      final result = await sl<AddClientUsecase>().call(newClient);

      result.fold(
        (l) {
          _buttonLoadingStateCubit.setLoading(false);
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(l)));
        },
        (r) {
          _buttonLoadingStateCubit.setLoading(false);
          //context.read<ClientBloc>().add(LoadClientsCacheFirstThenNetwork(''));
          //BlocProvider.of<ClientBloc>(context).add(const LoadClientsCacheFirstThenNetwork(''));
          if (!mounted) return;
          //Navigator.pop(context);
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Client added successfully!')));
          Navigator.pop(context, true);
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
}
