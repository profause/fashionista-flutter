import 'package:fashionista/presentation/widgets/default_profile_avatar_color_pair.dart';
import 'package:flutter/material.dart';

class DefaultProfileAvatar extends StatelessWidget {
  final String uid;
  final String? name;
  final double size;

  const DefaultProfileAvatar({
    super.key,
    required this.uid,
    this.name,
    this.size = 60,
  });

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return "";
    final parts = name.trim().split(" ");
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final pair = DefaultProfileAvatarColorPair.getColorPair(uid);
    final initials = _getInitials(name);

    return CircleAvatar(
      radius: size / 2,
      backgroundColor: pair["background"],
      child: initials.isEmpty
          ? Icon(Icons.person, color: pair["foreground"], size: size / 2)
          : Text(
              initials,
              style: TextStyle(
                color: pair["foreground"],
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }
}
