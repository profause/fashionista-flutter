import { setGlobalOptions } from 'firebase-functions/v2';
import { onDocumentCreated, onDocumentUpdated, onDocumentWritten } from 'firebase-functions/v2/firestore';
import { initializeApp } from 'firebase-admin/app';

import { onBookingCreated, onBookingUpdated } from './triggers/booking.triggers';
import {
  onWorkOrderCreated,
  onWorkOrderProgressCreated,
  onWorkOrderUpdated,
} from './triggers/work-order.triggers';
import { onMeasurementWritten } from './triggers/measurement.triggers';

initializeApp();

// Keep concurrency modest: each invocation fans out to FCM.
setGlobalOptions({ region: 'us-central1', maxInstances: 10 });

export const bookingCreated = onDocumentCreated(
  'bookings/{bookingId}',
  async (event) => {
    await onBookingCreated(event);
  }
);

export const bookingStatusChanged = onDocumentUpdated(
  'bookings/{bookingId}',
  async (event) => {
    await onBookingUpdated(event);
  }
);

export const workOrderCreated = onDocumentCreated(
  'work_orders/{workOrderId}',
  async (event) => {
    await onWorkOrderCreated(event);
  }
);

export const workOrderStatusChanged = onDocumentUpdated(
  'work_orders/{workOrderId}',
  async (event) => {
    await onWorkOrderUpdated(event);
  }
);

export const workOrderProgressCreated = onDocumentCreated(
  'work_orders/{workOrderId}/status_progress/{progressId}',
  async (event) => {
    await onWorkOrderProgressCreated(event);
  }
);

export const measurementWritten = onDocumentWritten(
  'clients/{clientId}/measurements/{measurementId}',
  async (event) => {
    await onMeasurementWritten(event);
  }
);
