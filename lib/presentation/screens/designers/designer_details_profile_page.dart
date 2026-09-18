import 'package:fashionista/core/theme/app.theme.dart';
import 'package:fashionista/data/models/designers/bloc/designer_bloc.dart';
import 'package:fashionista/data/models/designers/bloc/designer_event.dart';
import 'package:fashionista/data/models/designers/bloc/designer_state.dart';
import 'package:fashionista/data/models/designers/designer_model.dart';
import 'package:fashionista/data/models/designers/social_handle_model.dart';
import 'package:fashionista/presentation/screens/designers/widgets/featured_images_widget.dart';
import 'package:fashionista/presentation/screens/profile/widgets/profile_info_card_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

class DesignerDetailsProfilePage extends StatefulWidget {
  final Designer designer;
  const DesignerDetailsProfilePage({super.key, required this.designer});

  @override
  State<DesignerDetailsProfilePage> createState() =>
      _DesignerDetailsProfilePageState();
}

class _DesignerDetailsProfilePageState
    extends State<DesignerDetailsProfilePage> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => DesignerBloc()..add(UpdateDesigner(widget.designer)),
      child: BlocBuilder<DesignerBloc, DesignerState>(
        builder: (context, state) {
          switch (state) {
            case DesignerLoading():
              return const Center(child: CircularProgressIndicator());
            case DesignerLoaded(:final designer):
              return _buildContent(context, designer);
            case DesignerError(:final message):
              return Center(child: Text("Error: $message"));
            default:
              return const Center(child: Text("No designer data"));
          }
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, Designer designer) {
    final List<SocialHandle> socials = designer.socialHandles ?? [];

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        const SizedBox(height: 8),
        ProfileInfoCardWidget(
          items: [
            ProfileInfoItem(
              icon: Icons.person_outline_outlined,
              title: 'Name',
              value: designer.name,
            ),
            ProfileInfoItem(
              icon: Icons.phone_android_outlined,
              title: 'Mobile Number',
              value: designer.mobileNumber.isEmpty
                  ? 'No phone number'
                  : designer.mobileNumber,
              suffix: designer.mobileNumber.isEmpty
                  ? null
                  : IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'Copy number',
                      icon: Icon(
                        Icons.content_copy,
                        size: 18,
                        color: context.secondaryLabel,
                      ),
                      onPressed: () => _copyToClipboard(context, 'Mobile number copied', designer.mobileNumber),
                    ),
            ),
            ProfileInfoItem(
              icon: Icons.store_mall_directory_outlined,
              title: 'Business Name',
              value: designer.businessName.isEmpty
                  ? 'No business name'
                  : designer.businessName,
            ),
            ProfileInfoItem(
              icon: Icons.map_outlined,
              title: 'Location',
              value: designer.location.isEmpty
                  ? 'No location'
                  : designer.location,
              suffix: designer.location.isEmpty
                  ? null
                  : IconButton(
                      visualDensity: VisualDensity.compact,
                      tooltip: 'View on map',
                      icon: Icon(
                        Icons.navigation_outlined,
                        size: 18,
                        color: context.secondaryLabel,
                      ),
                      onPressed: () => _openMaps(context, designer.location),
                    ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FeaturedImagesWidget(designer: designer, isEditable: false),
        if (socials.isNotEmpty) ...[
          const SizedBox(height: 16),
          _SocialsCard(socials: socials),
        ],
        if (designer.tags.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          _TagsCard(designer: designer),
        ],
        const SizedBox(height: 16),
        _BookConsultationCard(
          onBookNow: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Consultation booking is coming soon'),
              ),
            );
          },
        ),
      ],
    );
  }

  void _copyToClipboard(BuildContext context, String message, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _openMaps(BuildContext context, String location) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query='
      '${Uri.encodeComponent(location)}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        messenger.showSnackBar(
          const SnackBar(content: Text('Could not open maps')),
        );
      }
    } catch (_) {
      // ignore: avoid_print
      debugPrint('Could not open maps');
    }
  }
}

class _SocialsCard extends StatelessWidget {
  final List<SocialHandle> socials;
  const _SocialsCard({required this.socials});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Socials', style: textTheme.titleSmall),
            const SizedBox(height: 12),
            Row(
              children: [
                for (final (index, handle) in socials.take(4).indexed) ...[
                  if (index > 0) const SizedBox(width: 12),
                  Expanded(child: _SocialTile(handle: handle)),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SocialTile extends StatelessWidget {
  final SocialHandle handle;
  const _SocialTile({required this.handle});

  IconData _socialIcon(String provider) {
    final p = provider.toLowerCase();
    if (p.contains('facebook')) return HugeIcons.strokeRoundedFacebook01;
    if (p.contains('instagram')) return HugeIcons.strokeRoundedInstagram;
    if (p.contains('tiktok')) return HugeIcons.strokeRoundedTiktok;
    if (p.contains('threads')) return HugeIcons.strokeRoundedThreads;
    if (p.contains('whatsapp')) return HugeIcons.strokeRoundedWhatsapp;
    if (p.contains('x') || p.contains('twitter')) {
      return HugeIcons.strokeRoundedNewTwitter;
    }
    return Icons.alternate_email;
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final String label = handle.provider.isEmpty
        ? 'Social'
        : handle.provider
              .split(' ')
              .where((w) => w.isNotEmpty)
              .map((w) => w[0].toUpperCase() + w.substring(1))
              .join(' ');
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _visit(context),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.iconSubstrate,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _socialIcon(handle.provider),
              size: 24,
              color: context.secondaryLabel,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: textTheme.labelSmall!.copyWith(
              color: context.onCanvasText,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Future<void> _visit(BuildContext context) async {
    final url = handle.url.trim();
    final messenger = ScaffoldMessenger.of(context);
    if (url.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text("This social isn't linked yet")),
      );
      return;
    }
    final uri = Uri.tryParse(url.startsWith('http') ? url : 'https://$url');
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not open that profile')),
      );
    }
  }
}

class _TagsCard extends StatelessWidget {
  final Designer designer;
  const _TagsCard({required this.designer});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final List<String> tags = designer.tags
        .split('|')
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .map((tag) => tag.startsWith('#') ? tag : '#$tag')
        .toList();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Featured Tags', style: textTheme.titleSmall),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tag in tags)
                  Chip(
                    backgroundColor: context.cardSurface,
                    side: BorderSide(color: context.hairline),
                    label: Text(
                      tag,
                      style: textTheme.labelMedium!.copyWith(
                        color: context.onCanvasText,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BookConsultationCard extends StatelessWidget {
  final VoidCallback onBookNow;
  const _BookConsultationCard({required this.onBookNow});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Book Fitting Consultation',
                    style: textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '3 slots available this week',
                    style: textTheme.bodySmall!.copyWith(
                      color: context.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: context.accent,
                minimumSize: const Size(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 20),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              onPressed: onBookNow,
              child: const Text('Book Now'),
            ),
          ],
        ),
      ),
    );
  }
}