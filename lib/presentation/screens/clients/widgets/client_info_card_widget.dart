import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:fashionista/presentation/screens/clients/client_details_screen.dart';
import 'package:fashionista/presentation/widgets/default_profile_avatar_widget.dart';
import 'package:flutter/material.dart';

class ClientInfoCardWidget extends StatefulWidget {
  final Client clientInfo;
  final VoidCallback? onTap; // Callback for navigation or action

  const ClientInfoCardWidget({super.key, required this.clientInfo, this.onTap});

  @override
  State<ClientInfoCardWidget> createState() => _ClientInfoCardWidgetState();
}

class _ClientInfoCardWidgetState extends State<ClientInfoCardWidget> {
  //bool _isImageLoading = false;

  @override
  void initState() {
    //_isImageLoading = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap:
          widget.onTap ??
          () {
            //context.read<ClientCubit>().updateClient(widget.clientInfo);
            // Example: Navigate to Client Details Screen
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    ClientDetailsScreen(client: widget.clientInfo),
              ),
            );
          },
      child: Card(
        color: colorScheme.onPrimary,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Avatar
              DefaultProfileAvatar(name:null,size: 60,uid: widget.clientInfo.uid,),
              // ClipOval(
              //   child:
              //       widget.clientInfo.imageUrl != null &&
              //           widget.clientInfo.imageUrl!.isNotEmpty
              //       ? CircleAvatar(
              //           radius: 30,
              //           backgroundColor: AppTheme.lightGrey,
              //           backgroundImage: CachedNetworkImageProvider(
              //             widget.clientInfo.imageUrl!,
              //           ),
              //         )
              //       : _buildInitialsAvatar(colorScheme),
              // ),
              const SizedBox(width: 12),
              // Client info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          widget.clientInfo.fullName,
                          style: textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          widget.clientInfo.createdDate != null &&
                                  widget.clientInfo.createdDate!.year ==
                                      DateTime.now().year &&
                                  widget.clientInfo.createdDate!.month ==
                                      DateTime.now().month &&
                                  widget.clientInfo.createdDate!.day ==
                                      DateTime.now().day
                              ? 'New'
                              : '',
                          style: textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 4),
                    Text(
                      widget.clientInfo.mobileNumber,
                      style: textTheme.bodySmall!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(widget.clientInfo.gender, style: textTheme.bodySmall),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget _buildInitialsAvatar(ColorScheme colorScheme) {
  //   String initials = widget.clientInfo.fullName.isNotEmpty
  //       ? widget.clientInfo.fullName
  //             .trim()
  //             .split(' ')
  //             .map((word) => word.isNotEmpty ? word[0] : '')
  //             .take(2)
  //             .join()
  //             .toUpperCase()
  //       : '?';

  //   return Container(
  //     width: 62,
  //     height: 62,
  //     decoration: BoxDecoration(
  //       shape: BoxShape.circle,
  //       color: colorScheme.primary.withValues(alpha: 0.1),
  //     ),
  //     alignment: Alignment.center,
  //     child: Text(
  //       initials,
  //       style: TextStyle(
  //         color: colorScheme.primary,
  //         fontWeight: FontWeight.bold,
  //         fontSize: 18,
  //       ),
  //     ),
  //   );
  // }
}
