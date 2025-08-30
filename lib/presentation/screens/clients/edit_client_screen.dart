import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/core/widgets/bloc/button_loading_state_cubit.dart';
import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/domain/usecases/clients/update_client_usecase.dart';
import 'package:fashionista/presentation/screens/profile/widgets/custom_chip_form_field_widget.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_text_field_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class EditClientScreen extends StatefulWidget {
  final Client client;
  const EditClientScreen({super.key, required this.client});

  @override
  State<EditClientScreen> createState() => _EditClientScreenState();
}

class _EditClientScreenState extends State<EditClientScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _mobileNumberController;
  late TextEditingController _genderController;
  late ButtonLoadingStateCubit _buttonLoadingStateCubit;

  @override
  void initState() {
    super.initState();
    _buttonLoadingStateCubit = context.read<ButtonLoadingStateCubit>();
    _fullNameController = TextEditingController(text: widget.client.fullName);
    _genderController = TextEditingController(text: widget.client.gender);
    _mobileNumberController = TextEditingController(
      text: widget.client.mobileNumber,
    );
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
    final client = widget.client; // keep client local

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        foregroundColor: colorScheme.primary,
        backgroundColor: colorScheme.onPrimary,
        title: Text(
          client.fullName,
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
                            if (!RegExp(
                              r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                            ).hasMatch(value ?? "")) {
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
                            if (!RegExp(
                              r'^((\+?\d{1,2}\s?)?\(?\d{3}\)?[\s.-]?\d{3}[\s.-]?\d{4}$)?',
                            ).hasMatch(value ?? "")) {
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
                    child: CustomChipFormFieldWidget(
                      initialValue: client.gender,
                      label: 'Gender',
                      items: ['Male', 'Female'],
                      onChanged: (gender) {
                        _genderController.text = gender;
                      },
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
        tag: 'edit-client-button',
        child: Container(
          margin: const EdgeInsets.all(16),
          child: AnimatedPrimaryButton(
            text: "Save",
            onPressed: () async {
              if (!_formKey.currentState!.validate()) return;

              final updatedClient = client.copyWith(
                fullName: _fullNameController.text.trim(),
                gender: _genderController.text.trim(),
                mobileNumber: _mobileNumberController.text.trim(),
                imageUrl: _generateImageUrl(_fullNameController.text.trim()),
                updatedAt: DateTime.now().millisecondsSinceEpoch,
              );

              await _saveClient(updatedClient);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _saveClient(Client updatedClient) async {
    try {
      _buttonLoadingStateCubit.setLoading(true);
      final result = await sl<UpdateClientUsecase>().call(updatedClient);

      result.fold(
        (failure) {
          _buttonLoadingStateCubit.setLoading(false);
          if (!mounted) return;
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(failure)));
        },
        (success) {
          _buttonLoadingStateCubit.setLoading(false);
          context.read<ClientBloc>().add(UpdateClient(updatedClient));
          if (!mounted) return;
           Navigator.pop(context); // ❌ no need for `true`
        },
      );
    } on FirebaseException catch (e) {
      _buttonLoadingStateCubit.setLoading(false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Something went wrong")),
      );
    }
  }

  String _generateImageUrl(String fullName) {
    final fullNameInit = fullName.substring(0, 2);
    final materialColorPair = getRandomColorPair();
    final bg = materialColorPair['background']!;
    final fg = materialColorPair['foreground']!;
    return 'https://dummyimage.com/128.png/$bg/$fg&text=$fullNameInit';
  }
}
