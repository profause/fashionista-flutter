import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/core/widgets/bloc/button_loading_state_cubit.dart';
import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

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
  final FocusNode _fullNameFocusNode = FocusNode();
  final FocusNode _phoneFocusNode = FocusNode();
  String _selectedGender = 'Male';

  @override
  void initState() {
    super.initState();
    _buttonLoadingStateCubit = context.read<ButtonLoadingStateCubit>();
    _fullNameController = TextEditingController(text: widget.client.fullName);
    _genderController = TextEditingController(text: widget.client.gender);
    _mobileNumberController = TextEditingController(
      text: widget.client.mobileNumber,
    );

    _fullNameFocusNode.addListener(() {
      if (mounted) setState(() {});
    });

    _phoneFocusNode.addListener(() {
      if (mounted) setState(() {});
    });
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
    //final colorScheme = Theme.of(context).colorScheme;
    //final textTheme = Theme.of(context).textTheme;
    final client = widget.client; // keep client local

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
          'Edit Client',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(12),
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
        initialValue: widget.client.mobileNumber,
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

  Future<void> _saveClient(Client updatedClient) async {
    try {
      _buttonLoadingStateCubit.setLoading(true);

      context.read<ClientBloc>().add(UpdateClient(updatedClient));
      _buttonLoadingStateCubit.setLoading(false);

      if (!mounted) return;
      Navigator.pop(context); // ❌ no need for `true`
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
