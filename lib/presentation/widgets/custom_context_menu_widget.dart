import 'package:flutter/material.dart';

class ContextMenuItem {
  final String value;
  final String label;
  final IconData? icon;
  final Color? iconColor;
  final bool isDestructive;

  const ContextMenuItem({
    required this.value,
    required this.label,
    this.icon,
    this.iconColor,
    this.isDestructive = false,
  });
}

class CustomContextMenuWidget extends StatelessWidget {
  final Widget child;
  final List<ContextMenuItem> items;
  final void Function(String value) onSelected;

  const CustomContextMenuWidget({
    super.key,
    required this.child,
    required this.items,
    required this.onSelected,
  });

  void _showContextMenu(BuildContext context, Offset position) async {
    final colorScheme = Theme.of(context).colorScheme;
    //final textTheme = Theme.of(context).textTheme;
    final result = await showMenu<String>(
      context: context,
      color: colorScheme.onPrimary,
      position: RelativeRect.fromLTRB(
        position.dx,
        position.dy,
        position.dx,
        position.dy,
      ),
      items: items
          .map(
            (item) => PopupMenuItem<String>(
              value: item.value,
              child: Row(
                children: [
                  if (item.icon != null) ...[
                    Icon(item.icon,
                        size: 18,
                        color: item.iconColor ??
                            (item.isDestructive
                                ? Colors.red
                                : item.iconColor)),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    item.label,
                    style: TextStyle(
                      color:
                          item.isDestructive ? Colors.red : item.iconColor,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );

    if (result != null) {
      onSelected(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        final renderBox = context.findRenderObject() as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        _showContextMenu(context, position);
      },
      onSecondaryTapDown: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      onLongPressStart: (details) {
        _showContextMenu(context, details.globalPosition);
      },
      child: child,
    );
  }
}
