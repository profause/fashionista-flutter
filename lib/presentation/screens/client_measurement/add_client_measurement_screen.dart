import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/core/widgets/bloc/button_loading_state_cubit.dart';
import 'package:fashionista/core/widgets/tag_input_field.dart';
import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/services/firebase/firebase_clients_service.dart';
import 'package:fashionista/presentation/screens/profile/widgets/custom_chip_form_field_widget.dart';
import 'package:fashionista/presentation/widgets/custom_text_input_field_widget.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AddClientMeasurementScreen extends StatefulWidget {
  final ClientMeasurement clientMeasurement;
  final Client client;
  const AddClientMeasurementScreen({
    super.key,
    required this.clientMeasurement,
    required this.client,
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
  late TextEditingController _tagsController;
  late ButtonLoadingStateCubit _buttonLoadingStateCubit;

  @override
  void initState() {
    _buttonLoadingStateCubit = context.read<ButtonLoadingStateCubit>();
    _bodyPartController = TextEditingController();
    _measuredValueController = TextEditingController();
    _noteController = TextEditingController();
    _measuringUnitController = TextEditingController();
    _tagsController = TextEditingController();

    _bodyPartController.text = widget.clientMeasurement.bodyPart;
    _measuredValueController.text = widget.clientMeasurement.measuredValue
        .toString();
    _noteController.text = widget.clientMeasurement.notes == null
        ? ''
        : widget.clientMeasurement.notes!;
    _measuringUnitController.text = widget.clientMeasurement.measuringUnit == ''
        ? 'cm'
        : widget.clientMeasurement.measuringUnit;
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
                        controller: _bodyPartController,
                        hint: 'Body Part',
                        validator: (value) {
                          if (!RegExp(
                            r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                          ).hasMatch(value!)) {
                            return 'Enter the body part being measured';
                          }
                          return null;
                        },
                      ),
                    ),
                    const Divider(height: .1, thickness: .1),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CustomTextInputFieldWidget(
                        controller: _measuredValueController,
                        label: 'Measured Value',
                        hint: 'Enter measured value',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
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
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CustomChipFormFieldWidget(
                        initialValue: _measuringUnitController.text,
                        label: 'Measuring Unit',
                        items: ['cm', 'inches'],
                        onChanged: (unit) {
                          _measuringUnitController.text = unit;
                        },
                      ),
                    ],
                  ),
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

                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: CustomTextInputFieldWidget(
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
                    ),
                    const Divider(height: .1, thickness: .1),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TagInputField(
                        label: 'Garment type or tags',
                        hint:
                            'Type and press Enter, Space or Comma to add a tag',
                        valueIn: widget.clientMeasurement.tags == null
                            ? []
                            : widget.clientMeasurement.tags == ''
                            ? []
                            : widget.clientMeasurement.tags!.split('|'),
                        valueOut: (value) =>
                            _tagsController.text = value.join('|'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Hero(
        tag: 'add-measurement-button',
        child: Container(
          margin: const EdgeInsets.all(16),
          child: AnimatedPrimaryButton(
            text: "Save",
            onPressed: () async {
              final isValid = _bodyPartController.text.isNotEmpty;
              if (!isValid) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("All fields are required."),
                    duration: Duration(seconds: 2),
                  ),
                );
                return; // Stop here if invalid
              }

              final updatedMeasurement = widget.clientMeasurement.copyWith(
                bodyPart: _bodyPartController.text.trim(),
                measuredValue: double.parse(
                  _measuredValueController.text.trim(),
                ),
                notes: _noteController.text.trim(),
                measuringUnit: _measuringUnitController.text.trim(),
                updatedDate: DateTime.now(),
                tags: _tagsController.text.trim(),
              );
              final List<ClientMeasurement> measurements = List.from(
                widget.client.measurements,
              );

              // check if bodyPart already exists
              final index = measurements.indexWhere(
                (m) =>
                    m.bodyPart.toLowerCase() ==
                    updatedMeasurement.bodyPart.toLowerCase(),
              );

              if (index != -1) {
                // update existing
                measurements[index] = updatedMeasurement;
              } else {
                // add new
                measurements.add(updatedMeasurement);
              }
              // now create updated client with new list
              final updatedClient = widget.client.copyWith(
                measurements: measurements,
              );

              context.read<ClientBloc>().add(UpdateClient(updatedClient));
              _saveClientMeasurement(updatedClient);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _saveClientMeasurement(Client client) async {
    try {
      _buttonLoadingStateCubit.setLoading(true);

      final result = await sl<FirebaseClientsService>().updateClientMeasurement(
        client,
      );

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
          if (!mounted) return;
          Navigator.pop(context);
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
