import { createHmac } from 'node:crypto';

import {
  isValidTrendId,
  sanitizeSegment,
  signUploadParams,
  trendVideoFolder,
} from '../src/cloudinary/signature';
import {
  buildUploadSignature,
  SignatureError,
} from '../src/video/upload-signature';

const secret = 'test-secret';

describe('signUploadParams', () => {
  it('matches an independently computed HMAC over sorted params', () => {
    const params = { folder: 'fashionista/trends/videos/u1', public_id: 'abc123', timestamp: 1700 };
    const expected = createHmac('sha1', secret)
      .update('folder=fashionista/trends/videos/u1&public_id=abc123&timestamp=1700')
      .digest('hex');

    expect(signUploadParams(params, secret)).toBe(expected);
  });

  it('changes when a signed parameter changes', () => {
    const base = signUploadParams({ folder: 'a', public_id: 'b', timestamp: 1 }, secret);

    expect(signUploadParams({ folder: 'a2', public_id: 'b', timestamp: 1 }, secret)).not.toBe(base);
    expect(signUploadParams({ folder: 'a', public_id: 'b2', timestamp: 1 }, secret)).not.toBe(base);
    expect(signUploadParams({ folder: 'a', public_id: 'b', timestamp: 2 }, secret)).not.toBe(base);
  });

  it('refuses to sign without a secret', () => {
    expect(() => signUploadParams({ folder: 'a', public_id: 'b', timestamp: 1 }, '')).toThrow();
  });
});

describe('folders', () => {
  it('builds one folder per user', () => {
    expect(trendVideoFolder('fashionista', 'u1')).toBe('fashionista/trends/videos/u1');
  });

  it('strips path traversal and separators from the uid', () => {
    expect(sanitizeSegment('../evil/u2')).toBe('evilu2');
    expect(trendVideoFolder('fashionista', '../evil/u2')).toBe('fashionista/trends/videos/evilu2');
    expect(() => trendVideoFolder('fashionista', '..')).toThrow();
  });

  it('validates trend ids', () => {
    expect(isValidTrendId('8f14e45f-ceea-467a-9a3f-1b2c3d4e5f60')).toBe(true);
    expect(isValidTrendId('short')).toBe(false);
    expect(isValidTrendId('bad id with spaces')).toBe(false);
    expect(isValidTrendId('')).toBe(false);
  });
});

describe('buildUploadSignature', () => {
  const input = {
    uid: 'u1',
    trendId: 'trend_123456',
    baseFolder: 'fashionista',
    cloudName: 'cloud',
    apiKey: 'key',
    apiSecret: secret,
    now: 1700000000,
  };

  it('derives the folder from the caller, not from input', () => {
    const result = buildUploadSignature(input);

    expect(result.folder).toBe('fashionista/trends/videos/u1');
    expect(result.publicId).toBe('trend_123456');
    expect(result.timestamp).toBe(1700000000);
  });

  it('signs exactly the folder, public id and timestamp it returns', () => {
    const result = buildUploadSignature(input);

    expect(result.signature).toBe(
      signUploadParams(
        { folder: result.folder, public_id: result.publicId, timestamp: result.timestamp },
        secret,
      ),
    );
  });

  it('rejects anonymous callers', () => {
    expect(() => buildUploadSignature({ ...input, uid: undefined })).toThrow(SignatureError);
  });

  it('rejects a tampered trend id', () => {
    expect(() => buildUploadSignature({ ...input, trendId: '../x' } as never)).toThrow(
      SignatureError,
    );
    expect(() => buildUploadSignature({ ...input, trendId: 42 } as never)).toThrow(SignatureError);
  });

  it('rejects missing configuration', () => {
    expect(() => buildUploadSignature({ ...input, apiKey: '' })).toThrow(SignatureError);
  });
});
