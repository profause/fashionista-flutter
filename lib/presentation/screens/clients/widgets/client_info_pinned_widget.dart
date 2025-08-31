import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/presentation/screens/clients/client_details_screen.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';

class ClientInfoPinnedWidget extends StatelessWidget {
  final Client clientInfo;
  final VoidCallback? onTap;
  const ClientInfoPinnedWidget({
    super.key,
    required this.clientInfo,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () {
        // Navigate to client details
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClientDetailsScreen(client: clientInfo),
          ),
        );
      },
      child: Column(
        children: [
          DefaultProfileAvatar(name: null, size: 60, uid: clientInfo.uid),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              clientInfo.fullName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textTheme.labelMedium!.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
