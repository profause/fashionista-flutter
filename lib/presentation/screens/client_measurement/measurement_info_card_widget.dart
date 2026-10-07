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
  final bool showActions;

  const MeasurementInfoCardWidget({
    super.key,
    required this.client,
    required this.measurement,
    required this.onDelete,
    required this.onEdit,
    this.showActions = true,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showDetailsBottomSheet(context),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
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
                      style: TextStyle(fontSize: 12, color: context.mutedText),
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
          if (showActions) ...[
            const SizedBox(width: 12),
            CustomContextMenuWidget(
              items: [
                ContextMenuItem(
                  value: 'edit',
                  label: 'Edit',
                  icon: Icons.edit,
                  iconColor: context.onCanvasText,
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
                } else if (value == 'delete') {
                  onDelete();
                }
              },
              child: Icon(Icons.more_vert, size: 18, color: context.mutedText),
            ),
          ],
        ],
      ),
    );
  }

  void _showDetailsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardSurface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isInches = measurement.measuringUnit == 'inches';
        final cmValue = isInches
            ? inchesToCm(measurement.measuredValue)
            : measurement.measuredValue;
        final inchesValue = isInches
            ? measurement.measuredValue
            : cmToInches(measurement.measuredValue);
        final tags = (measurement.tags ?? '')
            .split('|')
            .map((tag) => tag.trim())
            .where((tag) => tag.isNotEmpty)
            .toList();
        final notes = measurement.notes?.trim() ?? '';
        final updatedDate = measurement.updatedDate ?? DateTime.now();

        return SafeArea(
          top: false,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(ctx).size.height * 0.8,
            ),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.hairline,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          measurement.bodyPart,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: context.onCanvasText,
                          ),
                        ),
                      ),
                      if (showActions) ...[
                        _sheetActionButton(
                          ctx,
                          icon: Icons.edit_outlined,
                          tooltip: 'Edit',
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            onEdit();
                          },
                        ),
                        const SizedBox(width: 8),
                        _sheetActionButton(
                          ctx,
                          icon: Icons.delete_outline,
                          tooltip: 'Delete',
                          color: Colors.red,
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            onDelete();
                          },
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month,
                        size: 14,
                        color: context.mutedText,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        DateFormat('yyyy-MM-dd').format(updatedDate),
                        style: TextStyle(
                          fontSize: 12,
                          color: context.mutedText,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _sectionLabel(context, 'Measurement'),
                  const SizedBox(height: 8),
                  _valueRow(
                    context,
                    '${cmValue.toStringAsFixed(2)} cm',
                    '${inchesValue.toStringAsFixed(2)} inches',
                  ),
                  const SizedBox(height: 20),
                  _sectionLabel(context, 'Tags'),
                  const SizedBox(height: 8),
                  if (tags.isEmpty)
                    _emptyText(context, 'No tags')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final tag in tags)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: context.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.accent,
                              ),
                            ),
                          ),
                      ],
                    ),
                  const SizedBox(height: 20),
                  _sectionLabel(context, 'Notes'),
                  const SizedBox(height: 8),
                  if (notes.isEmpty)
                    _emptyText(context, 'No notes')
                  else
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: context.canvasBackground,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: context.hairline),
                      ),
                      child: Text(
                        notes,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: context.onCanvasText,
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _sectionLabel(context, 'Previous Values'),
                  const SizedBox(height: 8),
                  if (measurement.previousValues.isEmpty)
                    _emptyText(context, 'No previous values')
                  else
                    Column(
                      children: [
                        for (
                          var i = 0;
                          i < measurement.previousValues.length;
                          i++
                        )
                          Padding(
                            padding: EdgeInsets.only(
                              bottom: i == measurement.previousValues.length - 1
                                  ? 0
                                  : 8,
                            ),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: context.canvasBackground,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: context.hairline),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      measurement.previousValues[i]
                                          .toStringAsFixed(2),
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: context.onCanvasText,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    isInches
                                        ? '${cmToInches(measurement.previousValues[i]).toStringAsFixed(2)} cm'
                                        : '${inchesToCm(measurement.previousValues[i]).toStringAsFixed(2)} inches',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: context.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(BuildContext context, String text) {
    return Text(
      text.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: context.mutedText,
      ),
    );
  }

  Widget _sheetActionButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    Color? color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: context.canvasBackground,
        shape: BoxShape.circle,
        border: Border.all(color: context.hairline),
      ),
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        iconSize: 18,
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: color ?? context.onCanvasText),
      ),
    );
  }

  Widget _emptyText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontStyle: FontStyle.italic,
        color: context.placeholderText,
      ),
    );
  }

  Widget _valueRow(BuildContext context, String primary, String secondary) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: context.canvasBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.hairline),
      ),
      child: Row(
        children: [
          Text(
            primary,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: context.onCanvasText,
            ),
          ),
          Container(
            width: 1,
            height: 14,
            margin: const EdgeInsets.symmetric(horizontal: 10),
            color: context.hairline,
          ),
          Text(
            secondary,
            style: TextStyle(fontSize: 13, color: context.mutedText),
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
