import 'package:fashionista/data/models/clients/client_measurement_model.dart';
import 'package:fashionista/data/models/clients/client_measurement_relationship.dart';
import 'package:fashionista/data/models/clients/client_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ClientMeasurement Firestore mapping', () {
    test('serializes to the measurement subcollection payload', () {
      final measurement = ClientMeasurement(
        uid: 'measurement_123',
        bodyPart: 'Chest',
        measuredValue: 92.5,
        measuringUnit: 'cm',
        updatedDate: DateTime(2025, 1, 1),
        notes: 'Initial check',
        previousValues: const [88.0, 90.0],
        tags: 'draft|front',
      );

      final payload = measurement.toFirestoreMap(clientId: 'client_456');

      expect(payload['uid'], 'measurement_123');
      expect(payload['client_id'], 'client_456');
      expect(payload['body_part'], 'Chest');
      expect(payload['measured_value'], 92.5);
      expect(payload['measuring_unit'], 'cm');
      expect(payload['tags'], 'draft|front');
      expect(payload['previous_value'], const [88.0, 90.0]);
    });

    test('deserializes legacy and new Firestore fields', () {
      final measurement = ClientMeasurement.fromFirestoreMap({
        'uid': 'measurement_789',
        'client_id': 'client_456',
        'body_part': 'Waist',
        'measured_value': 76,
        'measuring_unit': 'cm',
        'tags': 'daily',
        'previous_value': [70.0, 72.0],
      });

      expect(measurement.uid, 'measurement_789');
      expect(measurement.bodyPart, 'Waist');
      expect(measurement.measuredValue, 76.0);
      expect(measurement.measuringUnit, 'cm');
      expect(measurement.tags, 'daily');
      expect(measurement.previousValues, const [70.0, 72.0]);

      final legacy = ClientMeasurement.fromFirestoreMap({
        'uid': 'measurement_456',
        'client_id': 'client_456',
        'body_part': 'Hip',
        'measured_value': 88,
        'measuring_unit': 'cm',
        'tags': 'legacy',
        'previous_values': [80.0, 82.0],
      });

      expect(legacy.previousValues, const [80.0, 82.0]);
    });

    test('deserializes clients with missing or null measurements safely', () {
      final client = Client.fromJson({
        'uid': 'client_1',
        'created_by': 'creator_1',
        'full_name': 'Ada',
        'mobile_number': '123',
        'gender': 'female',
        'created_date': '2025-01-01T00:00:00.000',
        'measurements': null,
      });

      expect(client.measurements, isEmpty);

      final legacyClient = Client.fromJson({
        'uid': 'client_2',
        'created_by': 'creator_1',
        'full_name': 'Grace',
        'mobile_number': '456',
        'gender': 'female',
        'created_date': '2025-01-01T00:00:00.000',
      });

      expect(legacyClient.measurements, isEmpty);
    });

    test('serializes the user/client relationship document contract', () {
      const relationship = ClientMeasurementRelationship(
        clientId: 'client_999',
        isDefault: true,
      );

      final json = relationship.toJson();
      expect(json['client_id'], 'client_999');
      expect(json['is_default'], isTrue);
      expect(json.containsKey('design_id'), isFalse);

      final restored = ClientMeasurementRelationship.fromJson(json);
      expect(restored, relationship);
    });
  });
}
