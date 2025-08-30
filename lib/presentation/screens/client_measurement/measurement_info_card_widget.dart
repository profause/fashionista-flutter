import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/presentation/widgets/custom_context_menu_widget.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class MeasurementInfoCardWidget extends StatelessWidget {
  final Client client;
  final ClientMeasurement measurement;
  final void Function() onDelete;
  final void Function() onEdit;

  const MeasurementInfoCardWidget({
    super.key,
    required this.client,
    required this.measurement,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      //const SizedBox(width: 18),
                      Text(
                        measurement.bodyPart, // e.g. "Chest"
                        style: textTheme.titleMedium!,
                      ),
                      const Spacer(),
                      CustomContextMenuWidget(
                        items: const [
                          ContextMenuItem(
                            value: 'edit',
                            label: 'Edit',
                            icon: Icons.edit,
                          ),
                          // ContextMenuItem(
                          //   value: 'share',
                          //   label: 'Share',
                          //   icon: Icons.share,
                          // ),
                          ContextMenuItem(
                            value: 'delete',
                            label: 'Delete',
                            icon: Icons.delete,
                            isDestructive: true,
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'edit') {
                            onEdit();
                          } else if (value == 'share') {
                            //print("Share clicked");
                          } else if (value == 'delete') {
                            onDelete();
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(0),
                          child: const Icon(Icons.more_horiz),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        //const SizedBox(width: 18),
                        Text(
                          measurement.measuringUnit == 'inches'
                              ? "${inchesToCm(measurement.measuredValue).toStringAsFixed(2)} cm"
                              : "${(measurement.measuredValue).toStringAsFixed(2)} cm",
                          style: textTheme.labelLarge,
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                          height: 16,
                          width: 1,
                          color: AppTheme.lightGrey, // divider color
                        ),
                        Text(
                          measurement.measuringUnit == 'cm'
                              ? "${cmToInches(measurement.measuredValue).toStringAsFixed(2)} inches"
                              : "${(measurement.measuredValue).toStringAsFixed(2)} inches", // e.g. "42 in"
                          style: textTheme.labelLarge,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Icon(Icons.calendar_month),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('yyyy-MM-dd').format(
                            measurement.updatedDate == null
                                ? DateTime.now()
                                : measurement.updatedDate!,
                          ),
                          style: textTheme.labelMedium!,
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.note_alt_outlined),
                      const SizedBox(width: 8),
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        // divider color
                        child: Text(
                          measurement.notes ?? '',
                          style: textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  double cmToInches(double cm) {
    return cm / 2.54; // since 1 inch = 2.54 cm
  }

  double inchesToCm(double inches) {
    return inches * 2.54;
  }
}
