import { sanitizeSegment, trendVideoFolder } from '../src/cloudinary/folder';

describe('sanitizeSegment', () => {
  it('strips anything that could escape a folder', () => {
    expect(sanitizeSegment(' ../../etc ')).toBe('etc');
    expect(sanitizeSegment('user/../id')).toBe('userid');
    expect(sanitizeSegment('a b c')).toBe('abc');
  });

  it('keeps letters, digits, dash and underscore', () => {
    expect(sanitizeSegment('user_1-2')).toBe('user_1-2');
  });

  it('tolerates missing values', () => {
    expect(sanitizeSegment(undefined as unknown as string)).toBe('');
  });
});

describe('trendVideoFolder', () => {
  it('appends trends/videos/<uid> to the base folder', () => {
    expect(trendVideoFolder('fashionista', 'u1')).toBe('fashionista/trends/videos/u1');
  });

  it('requires a user id', () => {
    expect(() => trendVideoFolder('fashionista', '')).toThrow();
  });
});
