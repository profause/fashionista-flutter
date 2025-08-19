import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/core/widgets/bloc/button_loading_state_cubit.dart';
import 'package:fashionista/core/widgets/tag_input_field.dart';
import 'package:fashionista/data/models/clients/bloc/client_cubit.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/services/firebase_clients_service.dart';
import 'package:fashionista/presentation/screens/profile/widgets/custom_chip_form_field_widget.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_text_field_widget.dart';
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
                      Divider(
                        height: 16,
                        thickness: 1,
                        color: Colors.grey[300],
                      ),
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
                      Divider(
                        height: 16,
                        thickness: 1,
                        color: Colors.grey[300],
                      ),

                      const SizedBox(height: 16),
                      TagInputField(
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

                      // ProfileInfoTextFieldWidget(
                      //   label: 'Garment type or tags',
                      //   controller: _tagsController,
                      //   hint: 'add garment type or tags',
                      //   validator: (value) {
                      //     if (!RegExp(
                      //       r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                      //     ).hasMatch(value!)) {
                      //       return 'add garment type or tags';
                      //     }
                      //     return null;
                      //   },
                      // ),
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
        child: Container(
          margin: const EdgeInsets.all(16),
          child: AnimatedPrimaryButton(
            text: "Save",
            onPressed: () async {
              debugPrint(_tagsController.text.trim());
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
                measuredValue: double.parse(_measuredValueController.text.trim()),
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
          
              context.read<ClientCubit>().updateClient(updatedClient);
              _saveClientMeasurement(updatedClient);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _saveClientMeasurement(Client client) async {
    debugPrint(client.measurements.toString());
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
      debugPrint(e.toString());
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message!)));
    }
  }

  // Widget _tagWidget(BuildContext context, String text) {
  //   final colorScheme = Theme.of(context).colorScheme;
  //   final textTheme = Theme.of(context).textTheme;
  //   return Container(
  //     margin: const EdgeInsets.only(right: 12),
  //     child: Material(
  //       color: Colors.transparent,
  //       child: InkWell(
  //         onTap: () {},
  //         borderRadius: BorderRadius.circular(30),
  //         child: Container(
  //           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
  //           decoration: BoxDecoration(
  //             color: colorScheme.primary.withValues(alpha: 0.1),
  //             border: Border.all(
  //               color: colorScheme.primary.withValues(alpha: .5),
  //               width: 1.0,
  //             ),
  //             borderRadius: BorderRadius.circular(8),
  //           ),
  //           child: Row(
  //             mainAxisSize: MainAxisSize.min,
  //             children: [
  //               Text(
  //                 text,
  //                 style: textTheme.bodyMedium!.copyWith(
  //                   fontSize: 14,
  //                   fontWeight: FontWeight.w600,
  //                 ),
  //               ),
  //               const SizedBox(width: 8),
  //               GestureDetector(
  //                 onTap: () {
  //                   // Handle tap here (e.g., remove chip or clear text)
  //                   debugPrint("Close icon tapped");
  //                 },
  //                 child: Icon(
  //                   Icons.close_rounded,
  //                   color: colorScheme.primary,
  //                   size: 16,
  //                 ),
  //               ),
  //             ],
  //           ),
  //         ),
  //       ),
  //     ),
  //   );
  // }
}
