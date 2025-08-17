import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/core/widgets/bloc/button_loading_state_cubit.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/presentation/screens/profile/widgets/custom_chip_form_field_widget.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_text_field_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddClientMeasurementScreen extends StatefulWidget {
  final ClientMeasurement clientMeasurement;
  final String clientUid;
  const AddClientMeasurementScreen({
    super.key,
    required this.clientMeasurement,
    required this.clientUid,
  });

  @override
  State<AddClientMeasurementScreen> createState() =>
      _AddClientMeasurementScreenState();
}

class _AddClientMeasurementScreenState
    extends State<AddClientMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bodyPartController;
  late TextEditingController _measuredValueController;
  late TextEditingController _noteController;
  late TextEditingController _measuringUnitController;
  late ButtonLoadingStateCubit _buttonLoadingStateCubit;

  @override
  void initState() {
    _buttonLoadingStateCubit = context.read<ButtonLoadingStateCubit>();
    _bodyPartController = TextEditingController();
    _measuredValueController = TextEditingController();
    _noteController = TextEditingController();
    _measuringUnitController = TextEditingController();

    _bodyPartController.text = widget.clientMeasurement.bodyPart;
    _measuredValueController.text = widget.clientMeasurement.measuredValue
        .toString();
    _noteController.text = widget.clientMeasurement.notes == null
        ? ''
        : widget.clientMeasurement.notes!;
    _measuringUnitController.text = widget.clientMeasurement.measuringUnit;
    super.initState();
  }

  @override
  void dispose() {
    _bodyPartController.dispose();
    _measuredValueController.dispose();
    _noteController.dispose();
    _measuringUnitController.dispose();

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
          widget.clientMeasurement.bodyPart == ''
              ? 'Add Measurement'
              : widget.clientMeasurement.bodyPart,
          style: textTheme.headlineSmall!.copyWith(fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: SingleChildScrollView(
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
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ProfileInfoTextFieldWidget(
                        label: 'Body Part',
                        controller: _bodyPartController,
                        hint: 'Enter the body part being measured',
                        validator: (value) {
                          // if (value == null || value.isEmpty) {
                          //   return 'Please enter your full name';
                          // }
                          if (!RegExp(
                            r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                          ).hasMatch(value!)) {
                            return 'Enter the body part being measured';
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
                        label: 'Measured Value',
                        controller: _measuredValueController,
                        hint: 'Enter measured value',
                        validator: (value) {
                          // if (value == null || value.isEmpty) {
                          //   return 'Please enter your mobile number';
                          // }
                          if (!RegExp(
                            r'^([1-9][0-9]{0,2}(\.[0-9]{1,2})?|0-9])?',
                          ).hasMatch(value!)) {
                            return 'Enter measured value';
                          }
                          return null;
                        },
                      ),
                      Divider(
                        height: 16,
                        thickness: 1,
                        color: Colors.grey[300],
                      ),
                      CustomChipFormFieldWidget(
                        initialValue: widget.clientMeasurement.measuringUnit,
                        label: 'Measuring Unit',
                        items: ['Centimeter', 'Inch'],
                        onChanged: (unit) {
                          _measuringUnitController.text = unit;
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
                        label: 'Note',
                        controller: _noteController,
                        hint: 'Enter a short note',
                        validator: (value) {
                          // if (value == null || value.isEmpty) {
                          //   return 'Please enter your full name';
                          // }
                          if (!RegExp(
                            r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                          ).hasMatch(value!)) {
                            return 'Enter a short note';
                          }
                          return null;
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
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Hero(
        tag: 'add-measurement-button',
        child: AnimatedPrimaryButton(
          text: "Save",
          onPressed: () async {
            final isValid = true;

            if (!isValid) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("All fields are required."),
                  duration: Duration(seconds: 2),
                ),
              );
              return; // Stop here if invalid
            }
            _saveClientMeasurement();
          },
        ),
      ),
    );
  }

  Future<void> _saveClientMeasurement() async {}
}
