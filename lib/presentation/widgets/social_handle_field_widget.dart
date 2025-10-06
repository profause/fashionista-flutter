import 'package:fashionista/data/models/designers/social_handle_model.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

class SocialHandleFieldWidget extends StatefulWidget {
  final String provider;
  final List<SocialHandle> socialHandles;
  final void Function(SocialHandle)? valueOut;

  const SocialHandleFieldWidget({
    super.key,
    required this.provider,
    required this.socialHandles,
    this.valueOut,
  });

  @override
  State<SocialHandleFieldWidget> createState() =>
      _SocialHandleFieldWidgetState();
}

class _SocialHandleFieldWidgetState extends State<SocialHandleFieldWidget> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();

    final handle = widget.socialHandles.firstWhere(
      (h) => h.provider.toLowerCase() == widget.provider.toLowerCase(),
      orElse: () => SocialHandle.defaults().first,
    );

    setState(() {
      final url = buildSocialProfileUrl(handle.provider, handle.handle);
      widget.valueOut?.call(handle.copyWith(url: url, handle: handle.handle, provider: widget.provider));
    });
    _controller = TextEditingController(text: handle.handle);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _updateUrl(String value) {
    final index = widget.socialHandles.indexWhere(
      (h) => h.provider.toLowerCase() == widget.provider.toLowerCase(),
    );

    if (index != -1) {
      SocialHandle s = widget.socialHandles[index];
      final url = buildSocialProfileUrl(s.provider, value);
      final ss = s.copyWith(url: url, handle: value, provider: widget.provider);
      widget.socialHandles[index] = ss;
 
      setState(() {
        widget.valueOut?.call(ss);
      });
    } else {
      final s = SocialHandle.fromJson({
        "handle": value,
        "url": buildSocialProfileUrl(widget.provider, value),
        "provider": widget.provider,
      });
      widget.socialHandles.add(s);
      setState(() {
        widget.valueOut?.call(s);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return TextField(
      controller: _controller,
      style: textTheme.titleMedium,
      decoration: InputDecoration(
        labelText: "${widget.provider} Handle",
        prefixIcon: Icon(_getIconForProvider(widget.provider)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: textTheme.titleSmall,
        filled: true,
        fillColor: Colors.transparent,
      ),
      onChanged: _updateUrl,
    );
  }

  /// Helper: pick an icon for each provider
  IconData _getIconForProvider(String provider) {
    switch (provider.toLowerCase()) {
      case "facebook":
        return HugeIcons.strokeRoundedFacebook01;
      case "instagram":
        return HugeIcons.strokeRoundedInstagram;
      case "x":
        return HugeIcons.strokeRoundedNewTwitter; // (can replace with custom icon)
      case "tiktok":
        return  HugeIcons.strokeRoundedTiktok;
      default:
        return Icons.link;
    }
  }

  String buildSocialProfileUrl(String provider, String username) {
    if (username.isEmpty) return "";

    switch (provider.toLowerCase()) {
      case "facebook":
        return "https://www.facebook.com/$username";
      case "instagram":
        return "https://www.instagram.com/$username";
      case "x": // Twitter / X
      case "twitter":
        return "https://x.com/$username";
      case "tiktok":
        return "https://www.tiktok.com/@$username";
      default:
        return username; // fallback: just return raw input
    }
  }
}
