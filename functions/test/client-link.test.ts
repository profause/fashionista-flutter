import { buildClientLinkedNotification } from '../src/triggers/client-link.triggers';

const input = {
  userId: 'user_1',
  clientId: 'client_1',
  designerId: 'designer_1',
  designerName: 'Akosua Mensah',
};

describe('buildClientLinkedNotification', () => {
  it('welcomes the linked user', () => {
    const payload = buildClientLinkedNotification(input);

    expect(payload).not.toBeNull();
    expect(payload?.recipientUserId).toBe('user_1');
    expect(payload?.title).toBe('New Client');
    expect(payload?.body).toBe('Akosua Mensah has added you as a client');
    expect(payload?.type).toBe('client');
    expect(payload?.event).toBe('client_linked');
    expect(payload?.refId).toBe('client_1');
    expect(payload?.refType).toBe('client');
    expect(payload?.audience).toBe('client');
    expect(payload?.designerId).toBe('designer_1');
  });

  it('falls back to a neutral designer name', () => {
    const payload = buildClientLinkedNotification({
      ...input,
      designerName: '   ',
    });

    expect(payload?.body).toBe('A designer has added you as a client');
  });

  it('trims the designer name', () => {
    const payload = buildClientLinkedNotification({
      ...input,
      designerName: '  Akosua  ',
    });

    expect(payload?.body).toBe('Akosua has added you as a client');
  });

  it('never notifies a designer about their own link', () => {
    expect(
      buildClientLinkedNotification({ ...input, userId: 'designer_1' })
    ).toBeNull();
  });

  it('returns null when an id is missing', () => {
    expect(
      buildClientLinkedNotification({ ...input, userId: '' })
    ).toBeNull();
    expect(
      buildClientLinkedNotification({ ...input, clientId: '' })
    ).toBeNull();
    expect(
      buildClientLinkedNotification({ ...input, designerId: '' })
    ).toBeNull();
  });

  it('keys the idempotency key on the user and the client record', () => {
    const payload = buildClientLinkedNotification(input);

    expect(payload?.idempotencyKey).toBe('client__linked__user_1__client_1');
  });

  it('carries the client id for diagnostics', () => {
    const payload = buildClientLinkedNotification(input);

    expect(payload?.data).toEqual({ client_id: 'client_1' });
  });
});
