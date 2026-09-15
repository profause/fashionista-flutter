import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ClientInfoCardWidget extends StatefulWidget {
  final Client clientInfo;
  final VoidCallback? onTap; // Callback for navigation or action

  const ClientInfoCardWidget({super.key, required this.clientInfo, this.onTap});

  @override
  State<ClientInfoCardWidget> createState() => _ClientInfoCardWidgetState();
}

class _ClientInfoCardWidgetState extends State<ClientInfoCardWidget> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap:
          widget.onTap ??
          () {
            context.push('/clients/view/${widget.clientInfo.uid}');
          },
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: context.cardSurface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.hairline),
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
            DefaultProfileAvatar(
              key: ValueKey(widget.clientInfo.uid),
              name: widget.clientInfo.fullName,
              size: 44,
              uid: widget.clientInfo.uid,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.clientInfo.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.onCanvasText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      widget.clientInfo.mobileNumber,
                      if (widget.clientInfo.gender.isNotEmpty)
                        widget.clientInfo.gender,
                    ].join('  •  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color: context.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: Color(0xFF9CA3AF),
            ),
          ],
        ),
      ),
    );
  }
}
