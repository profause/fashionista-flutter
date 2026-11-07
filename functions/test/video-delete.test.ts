import {
  assertAssetOwnership,
  destroyCloudinaryAsset,
  DeleteAssetError,
} from '../src/video/delete-asset';

const ownAsset = 'fashionista/trends/videos/u1/trend_123456';

describe('assertAssetOwnership', () => {
  it('accepts the owner with an asset inside their folder', () => {
    expect(() =>
      assertAssetOwnership({ uid: 'u1', assetId: ownAsset, ownerId: 'u1', baseFolder: 'fashionista' }),
    ).not.toThrow();
  });

  it('rejects someone else\'s trend document', () => {
    expect(() =>
      assertAssetOwnership({ uid: 'u1', assetId: ownAsset, ownerId: 'u2', baseFolder: 'fashionista' }),
    ).toThrow(DeleteAssetError);
  });

  it('rejects an asset outside the caller folder', () => {
    expect(() =>
      assertAssetOwnership({
        uid: 'u1',
        assetId: 'fashionista/trends/videos/u2/trend_123456',
        ownerId: 'u1',
        baseFolder: 'fashionista',
      }),
    ).toThrow(DeleteAssetError);
  });

  it('rejects anonymous callers', () => {
    expect(() =>
      assertAssetOwnership({ uid: undefined, assetId: ownAsset, ownerId: null, baseFolder: 'fashionista' }),
    ).toThrow(DeleteAssetError);
  });
});

describe('destroyCloudinaryAsset', () => {
  it('calls the video destroy endpoint with basic auth', async () => {
    let seenUrl = '';
    let seenInit: RequestInit | undefined;

    const fetchImpl = (async (url: string, init: RequestInit) => {
      seenUrl = url;
      seenInit = init;
      return { ok: true, json: async () => ({ result: 'ok' }) } as Response;
    }) as unknown as typeof fetch;

    await destroyCloudinaryAsset({
      cloudName: 'cloud',
      apiKey: 'key',
      apiSecret: 'secret',
      assetId: ownAsset,
      fetchImpl,
    });

    expect(seenUrl).toBe('https://api.cloudinary.com/v1_1/cloud/video/destroy');
    expect(seenInit?.method).toBe('POST');
    expect((seenInit?.headers as Record<string, string>).Authorization).toBe(
      `Basic ${Buffer.from('key:secret').toString('base64')}`,
    );
    expect((seenInit?.body as URLSearchParams).get('public_id')).toBe(ownAsset);
    expect((seenInit?.body as URLSearchParams).get('invalidate')).toBe('true');
  });

  it('surfaces a not-found result instead of pretending it deleted', async () => {
    const fetchImpl = (async () =>
      ({ ok: true, json: async () => ({ result: 'not found' }) }) as Response) as unknown as typeof fetch;

    const result = await destroyCloudinaryAsset({
      cloudName: 'cloud',
      apiKey: 'key',
      apiSecret: 'secret',
      assetId: ownAsset,
      fetchImpl,
    });

    expect(result.result).toBe('not found');
  });

  it('throws when Cloudinary rejects the request', async () => {
    const fetchImpl = (async () =>
      ({ ok: false, status: 401, json: async () => ({}) }) as Response) as unknown as typeof fetch;

    await expect(
      destroyCloudinaryAsset({
        cloudName: 'cloud',
        apiKey: 'key',
        apiSecret: 'secret',
        assetId: ownAsset,
        fetchImpl,
      }),
    ).rejects.toThrow(DeleteAssetError);
  });

  it('refuses to run without configuration', async () => {
    await expect(
      destroyCloudinaryAsset({ cloudName: '', apiKey: 'k', apiSecret: 's', assetId: ownAsset }),
    ).rejects.toThrow(DeleteAssetError);
  });
});
