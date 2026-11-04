import 'package:cached_network_image/cached_network_image.dart';
import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/bookings/booking_client_model.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';

/// Client identity chip shown on appointment cards and detail sheets.
///
/// Renders the stored booking snapshot, so no Firestore read is required.
class BookingClientTile extends StatelessWidget {
  final BookingClient? client;

  /// Fallback id used when the snapshot is missing.
  final String fallbackId;

  final double avatarSize;

  /// Hides the phone number for compact card layouts.
  final bool showMobile;

  const BookingClientTile({
    super.key,
    required this.client,
    this.fallbackId = '',
    this.avatarSize = 36,
    this.showMobile = true,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final value = client ?? const BookingClient();

    return Row(
      children: [
        _Avatar(
          client: value,
          fallbackId: fallbackId,
          size: avatarSize,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value.displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.bodyMedium?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (showMobile && value.mobileNumber.isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(
                  value.mobileNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: context.secondaryLabel,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  final BookingClient client;
  final String fallbackId;
  final double size;

  const _Avatar({
    required this.client,
    required this.fallbackId,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    if (!client.hasAvatar) {
      return DefaultProfileAvatar(
        uid: client.id.isEmpty ? fallbackId : client.id,
        name: client.name,
        size: size,
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: client.avatar!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, _) => DefaultProfileAvatar(
          uid: client.id.isEmpty ? fallbackId : client.id,
          name: client.name,
          size: size,
        ),
        errorWidget: (_, _, _) => DefaultProfileAvatar(
          uid: client.id.isEmpty ? fallbackId : client.id,
          name: client.name,
          size: size,
        ),
      ),
    );
  }
}
