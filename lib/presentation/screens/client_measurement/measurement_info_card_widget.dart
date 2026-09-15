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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  measurement.bodyPart,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: context.onCanvasText,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      measurement.measuringUnit == 'inches'
                          ? '${inchesToCm(measurement.measuredValue).toStringAsFixed(2)} cm'
                          : '${measurement.measuredValue.toStringAsFixed(2)} cm',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: context.onCanvasText,
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 12,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      color: context.hairline,
                    ),
                    Text(
                      measurement.measuringUnit == 'cm'
                          ? '${cmToInches(measurement.measuredValue).toStringAsFixed(2)} inches'
                          : '${measurement.measuredValue.toStringAsFixed(2)} inches',
                      style: TextStyle(
                        fontSize: 12,
                        color: context.mutedText,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Row(
            children: [
              Icon(Icons.calendar_month, size: 14, color: context.mutedText),
              const SizedBox(width: 6),
              Text(
                DateFormat('yyyy-MM-dd').format(
                  measurement.updatedDate == null
                      ? DateTime.now()
                      : measurement.updatedDate!,
                ),
                style: TextStyle(fontSize: 11.5, color: context.mutedText),
              ),
            ],
          ),
          const SizedBox(width: 12),
          CustomContextMenuWidget(
            items: const [
              ContextMenuItem(
                value: 'edit',
                label: 'Edit',
                icon: Icons.edit,
              ),
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
            child: Icon(
              Icons.more_vert,
              size: 18,
              color: context.mutedText,
            ),
          ),
        ],
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
