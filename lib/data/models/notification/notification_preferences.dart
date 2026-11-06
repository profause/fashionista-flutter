import 'package:equatable/equatable.dart';

/// Which notification category a user can switch off.
///
/// The [firestoreKey] strings are the contract shared with the Cloud Functions
/// (`functions/src/notifications/types.ts`). Changing one on either side
/// silently disables the gate, so a test asserts both lists match.
enum NotificationPreferenceKey {
  trendLike(
    firestoreKey: 'trend_like',
    section: NotificationPreferenceSection.social,
    label: 'Likes on my trends',
    description: 'When someone likes a trend you posted',
    legacyKey: 'social',
  ),
  trendComment(
    firestoreKey: 'trend_comment',
    section: NotificationPreferenceSection.social,
    label: 'Comments on my trends',
    description: 'When someone comments on a trend you posted',
    legacyKey: 'social',
  ),
  appointments(
    firestoreKey: 'appointments',
    section: NotificationPreferenceSection.appointments,
    label: 'Appointment updates',
    description: 'New bookings, confirmations and cancellations',
  ),
  appointmentReminder(
    firestoreKey: 'appointment_reminder',
    section: NotificationPreferenceSection.appointments,
    label: 'Appointment reminders',
    description: 'Reminders before an upcoming appointment',
    legacyKey: 'reminders',
  ),
  designerRating(
    firestoreKey: 'designer_rating',
    section: NotificationPreferenceSection.designer,
    label: 'Ratings and reviews',
    description: 'When a client rates or reviews you',
    legacyKey: 'social',
  ),
  orderUpdates(
    firestoreKey: 'order_updates',
    section: NotificationPreferenceSection.fashion,
    label: 'Order updates',
    description: 'Progress and status changes on your orders',
    legacyKey: 'orders',
  ),
  // No producer yet: the measurement trigger was removed.
  measurementUpdates(
    firestoreKey: 'measurement_updates',
    section: NotificationPreferenceSection.fashion,
    label: 'Measurement updates',
    description: 'When a designer updates your measurements',
    legacyKey: 'measurements',
    visible: false,
  ),
  clients(
    firestoreKey: 'clients',
    section: NotificationPreferenceSection.designer,
    label: 'Added as a client',
    description: 'When a designer adds you as their client',
  );

  const NotificationPreferenceKey({
    required this.firestoreKey,
    required this.section,
    required this.label,
    required this.description,
    this.legacyKey,
    this.visible = true,
  });

  /// Field name in `users/{uid}/settings/notifications`.
  final String firestoreKey;

  final NotificationPreferenceSection section;
  final String label;
  final String description;

  /// Key used before the taxonomy change; read as a fallback only.
  final String? legacyKey;

  /// Whether the settings sheet renders a row for this key.
  ///
  /// Hidden keys still exist in the schema with a `true` default, so adding a
  /// producer later needs no migration.
  final bool visible;

  /// Keys the app writes, in display order.
  static List<NotificationPreferenceKey> get visibleKeys =>
      values.where((key) => key.visible).toList(growable: false);

  static NotificationPreferenceKey? fromFirestoreKey(String key) {
    for (final candidate in values) {
      if (candidate.firestoreKey == key) return candidate;
    }
    return null;
  }
}

/// Grouping used by the settings sheet.
enum NotificationPreferenceSection {
  social('Social activity'),
  appointments('Appointments'),
  designer('Designer activity'),
  fashion('Fashion updates');

  const NotificationPreferenceSection(this.title);

  final String title;

  /// Visible keys in this section, in declaration order.
  List<NotificationPreferenceKey> get keys => NotificationPreferenceKey
      .visibleKeys
      .where((key) => key.section == this)
      .toList(growable: false);
}

/// A user's notification preferences.
///
/// Every key defaults to `true`; a missing document and a missing field behave
/// identically so new keys can be introduced without a migration.
class NotificationPreferences extends Equatable {
  final bool trendLike;
  final bool trendComment;
  final bool appointments;
  final bool appointmentReminder;
  final bool designerRating;
  final bool orderUpdates;
  final bool measurementUpdates;
  final bool clients;

  /// Fields this build does not know about, kept so a save does not drop them.
  ///
  /// Excluded from equality: they never affect the UI.
  final Map<String, dynamic> unknown;

  const NotificationPreferences({
    this.trendLike = true,
    this.trendComment = true,
    this.appointments = true,
    this.appointmentReminder = true,
    this.designerRating = true,
    this.orderUpdates = true,
    this.measurementUpdates = true,
    this.clients = true,
    this.unknown = const {},
  });

  /// Everything enabled — what a user with no document effectively has.
  factory NotificationPreferences.defaults() => const NotificationPreferences();

  factory NotificationPreferences.fromMap(Map<String, dynamic> map) {
    bool? read(NotificationPreferenceKey key) {
      final current = map[key.firestoreKey];
      if (current is bool) return current;

      final legacy = key.legacyKey;
      if (legacy != null) {
        final legacyValue = map[legacy];
        if (legacyValue is bool) return legacyValue;
      }

      return null;
    }

    final known = {
      for (final key in NotificationPreferenceKey.values) key.firestoreKey,
      for (final key in NotificationPreferenceKey.values)
        if (key.legacyKey != null) key.legacyKey!,
      'updated_at',
    };

    return NotificationPreferences(
      trendLike: read(NotificationPreferenceKey.trendLike) ?? true,
      trendComment: read(NotificationPreferenceKey.trendComment) ?? true,
      appointments: read(NotificationPreferenceKey.appointments) ?? true,
      appointmentReminder:
          read(NotificationPreferenceKey.appointmentReminder) ?? true,
      designerRating: read(NotificationPreferenceKey.designerRating) ?? true,
      orderUpdates: read(NotificationPreferenceKey.orderUpdates) ?? true,
      measurementUpdates:
          read(NotificationPreferenceKey.measurementUpdates) ?? true,
      clients: read(NotificationPreferenceKey.clients) ?? true,
      unknown: {
        for (final entry in map.entries)
          if (!known.contains(entry.key)) entry.key: entry.value,
      },
    );
  }

  /// Writable map. `updated_at` is added by the service on save.
  Map<String, dynamic> toMap() {
    return {
      NotificationPreferenceKey.trendLike.firestoreKey: trendLike,
      NotificationPreferenceKey.trendComment.firestoreKey: trendComment,
      NotificationPreferenceKey.appointments.firestoreKey: appointments,
      NotificationPreferenceKey.appointmentReminder.firestoreKey:
          appointmentReminder,
      NotificationPreferenceKey.designerRating.firestoreKey: designerRating,
      NotificationPreferenceKey.orderUpdates.firestoreKey: orderUpdates,
      NotificationPreferenceKey.measurementUpdates.firestoreKey:
          measurementUpdates,
      NotificationPreferenceKey.clients.firestoreKey: clients,
      ...unknown,
    };
  }

  bool isEnabled(NotificationPreferenceKey key) {
    switch (key) {
      case NotificationPreferenceKey.trendLike:
        return trendLike;
      case NotificationPreferenceKey.trendComment:
        return trendComment;
      case NotificationPreferenceKey.appointments:
        return appointments;
      case NotificationPreferenceKey.appointmentReminder:
        return appointmentReminder;
      case NotificationPreferenceKey.designerRating:
        return designerRating;
      case NotificationPreferenceKey.orderUpdates:
        return orderUpdates;
      case NotificationPreferenceKey.measurementUpdates:
        return measurementUpdates;
      case NotificationPreferenceKey.clients:
        return clients;
    }
  }

  NotificationPreferences withValue(NotificationPreferenceKey key, bool value) {
    switch (key) {
      case NotificationPreferenceKey.trendLike:
        return _copy(trendLike: value);
      case NotificationPreferenceKey.trendComment:
        return _copy(trendComment: value);
      case NotificationPreferenceKey.appointments:
        return _copy(appointments: value);
      case NotificationPreferenceKey.appointmentReminder:
        return _copy(appointmentReminder: value);
      case NotificationPreferenceKey.designerRating:
        return _copy(designerRating: value);
      case NotificationPreferenceKey.orderUpdates:
        return _copy(orderUpdates: value);
      case NotificationPreferenceKey.measurementUpdates:
        return _copy(measurementUpdates: value);
      case NotificationPreferenceKey.clients:
        return _copy(clients: value);
    }
  }

  NotificationPreferences _copy({
    bool? trendLike,
    bool? trendComment,
    bool? appointments,
    bool? appointmentReminder,
    bool? designerRating,
    bool? orderUpdates,
    bool? measurementUpdates,
    bool? clients,
  }) {
    return NotificationPreferences(
      trendLike: trendLike ?? this.trendLike,
      trendComment: trendComment ?? this.trendComment,
      appointments: appointments ?? this.appointments,
      appointmentReminder: appointmentReminder ?? this.appointmentReminder,
      designerRating: designerRating ?? this.designerRating,
      orderUpdates: orderUpdates ?? this.orderUpdates,
      measurementUpdates: measurementUpdates ?? this.measurementUpdates,
      clients: clients ?? this.clients,
      unknown: unknown,
    );
  }

  @override
  List<Object?> get props => [
    trendLike,
    trendComment,
    appointments,
    appointmentReminder,
    designerRating,
    orderUpdates,
    measurementUpdates,
    clients,
  ];
}
