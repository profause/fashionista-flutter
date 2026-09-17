import 'package:fashionista/core/service_locator/service_locator.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/core/widgets/animated_primary_button.dart';
import 'package:fashionista/core/widgets/bloc/button_loading_state_cubit.dart';
import 'package:fashionista/core/widgets/tag_input_field.dart';
import 'package:fashionista/data/models/clients/bloc/client_bloc.dart';
import 'package:fashionista/data/models/clients/bloc/client_event.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/data/services/firebase/firebase_clients_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';

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
  final FocusNode _bodyPartFocusNode = FocusNode();
  final FocusNode _measuredValueFocusNode = FocusNode();
  final FocusNode _noteFocusNode = FocusNode();

  @override
  void initState() {
    _buttonLoadingStateCubit = context.read<ButtonLoadingStateCubit>();
    _bodyPartController = TextEditingController();
    _measuredValueController = TextEditingController();
    _noteController = TextEditingController();
    _measuringUnitController = TextEditingController();
    _tagsController = TextEditingController();

    _bodyPartController.text = widget.clientMeasurement.bodyPart;
    widget.clientMeasurement.measuredValue > 0
        ? _measuredValueController.text = widget.clientMeasurement.measuredValue
              .toString()
        : _measuredValueController.text = '';
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
    _bodyPartFocusNode.dispose();
    _measuredValueFocusNode.dispose();
    _noteFocusNode.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.canvasBackground,
      appBar: AppBar(
        foregroundColor: context.onCanvasText,
        backgroundColor: context.canvasBackground,
        surfaceTintColor: Colors.transparent,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text(
          widget.clientMeasurement.bodyPart == ''
              ? 'Add Measurement'
              : widget.clientMeasurement.bodyPart,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: context.onCanvasText,
          ),
        ),
        shape: Border(bottom: BorderSide(color: context.hairline)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: context.cardSurface,
                  borderRadius: BorderRadius.circular(16),
                  //border: Border.all(color: context.hairline),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0D000000),
                      blurRadius: 3,
                      offset: Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildBodyPartField(),
                    Container(height: 1, color: context.hairline),
                    _buildMeasuredValueField(),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              _buildUnitSwitcher(),
              const SizedBox(height: 20),
              _buildNoteField(),
              const SizedBox(height: 20),
              _buildTagField(),
              const SizedBox(height: 20),
              AnimatedPrimaryButton(
                text: "Save Measurement",
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

                  final updatedMeasurement = widget.clientMeasurement
                      .copyWith(
                        uid: widget.clientMeasurement.uid,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBodyPartField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      child: _FieldLabeled(
        label: 'Body Part',
        child: Row(
          children: [
            Expanded(
              child: TextFormField(
                focusNode: _bodyPartFocusNode,
                controller: _bodyPartController,
                validator: (value) {
                  if (!RegExp(
                    r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
                  ).hasMatch(value!)) {
                    return 'Enter the body part being measured';
                  }
                  return null;
                },
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: context.onCanvasText,
                ),
                decoration: InputDecoration(
                  hintText: 'e.g. Chest',
                  hintStyle: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: context.placeholderText,
                  ),
                  border: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            Icon(
              Icons.expand_more,
              size: 20,
              color: context.mutedText,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasuredValueField() {
    return Padding(
      padding: const EdgeInsets.all(14),
      child: _FieldLabeled(
        label: 'Measured Value',
        child: TextFormField(
          focusNode: _measuredValueFocusNode,
          controller: _measuredValueController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          validator: (value) {
            if (!RegExp(
              r'^([1-9][0-9]{0,2}(\.[0-9]{1,2})?|0-9])?',
            ).hasMatch(value!)) {
              return 'Enter measured value';
            }
            return null;
          },
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: context.onCanvasText,
          ),
          decoration: InputDecoration(
            hintText: '0.0',
            hintStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: context.placeholderText,
            ),
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      ),
    );
  }

  Widget _buildUnitSwitcher() {
    final selected = _measuringUnitController.text;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Measuring Unit',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.mutedText,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          height: 52,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(12),
            //border: Border.all(color: context.hairline),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: Row(
            children: [
              _UnitSegment(
                label: 'cm',
                selected: selected == 'cm',
                onTap: () {
                  setState(() {
                    _measuringUnitController.text = 'cm';
                  });
                },
              ),
              const SizedBox(width: 6),
              _UnitSegment(
                label: 'inches',
                selected: selected == 'inches',
                onTap: () {
                  setState(() {
                    _measuringUnitController.text = 'inches';
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNoteField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Note',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.mutedText,
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _noteFocusNode.hasFocus
                  ? context.accent
                  : context.hairline,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: TextFormField(
            focusNode: _noteFocusNode,
            controller: _noteController,
            maxLines: 4,
            minLines: 2,
            validator: (value) {
              if (!RegExp(
                r'^([A-Za-z_][A-Za-z0-9_]\w+)?',
              ).hasMatch(value!)) {
                return 'Enter a short note';
              }
              return null;
            },
            style: TextStyle(
              fontSize: 15,
              height: 1.4,
              color: context.onCanvasText,
            ),
            decoration: InputDecoration(
              hintText: "Enter a short adjustment note (e.g., loose fit)...",
              hintStyle: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: context.placeholderText,
              ),
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Garment type or tags',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: context.mutedText,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: context.cardSurface,
            borderRadius: BorderRadius.circular(12),
            //border: Border.all(color: context.hairline),
            boxShadow: const [
              BoxShadow(
                color: Color(0x0D000000),
                blurRadius: 3,
                offset: Offset(0, 1),
              ),
            ],
          ),
          child: TagInputField(
            hint: 'Type tags and press Enter, Space or Comma...',
            valueIn: widget.clientMeasurement.tags == null
                ? []
                : widget.clientMeasurement.tags == ''
                ? []
                : widget.clientMeasurement.tags!.split('|'),
            valueOut: (value) => _tagsController.text = value.join('|'),
          ),
        ),
      ],
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

class _FieldLabeled extends StatelessWidget {
  final String label;
  final Widget child;
  const _FieldLabeled({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.mutedText,
            letterSpacing: 0.6,
          ),
          maxLines: 1,
        ),
        const SizedBox(height: 4),
        child,
      ],
    );
  }
}

class _UnitSegment extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _UnitSegment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 42,
          decoration: BoxDecoration(
            color: selected ? context.accent : context.iconSubstrate,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (selected) ...[
                Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected
                      ? FontWeight.w600
                      : FontWeight.w400,
                  color: selected ? Colors.white : context.mutedText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
