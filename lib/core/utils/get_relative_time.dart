String formatRelativeTime(int millis) {
  final date = DateTime.fromMillisecondsSinceEpoch(millis);
  final now = DateTime.now();
  final difference = now.difference(date);

  final duration = difference.abs();
  final isFuture = difference.isNegative;

  String prefix = isFuture ? 'in ' : '';
  String suffix = isFuture ? '' : ' ago';

  if (duration.inSeconds < 60) {
    return '$prefix${duration.inSeconds}s$suffix';
  } else if (duration.inMinutes < 60) {
    return '$prefix${duration.inMinutes}m$suffix';
  } else if (duration.inHours < 24) {
    return '$prefix${duration.inHours}h$suffix';
  } else if (duration.inDays == 1) {
    return isFuture ? 'Tmrw' : '$prefix${duration.inDays}d$suffix';
  } else if (duration.inDays < 7) {
    return '$prefix${duration.inDays}d$suffix';
  } else if (duration.inDays < 30) {
    final weeks = (duration.inDays / 7).floor();
    return '$prefix${weeks}w$suffix';
  } else if (duration.inDays < 365) {
    final months = (duration.inDays / 30).floor();
    return '$prefix${months}mo$suffix';
  } else {
    final years = (duration.inDays / 365).floor();
    return '$prefix${years}y$suffix';
  }
}
