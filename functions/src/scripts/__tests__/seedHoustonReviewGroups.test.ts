import {assertProjectAllowed, parseArgs} from '../seedHoustonReviewEvents';

describe('seedHoustonReviewGroups helpers', () => {
  it('reuses parseArgs for --project', () => {
    expect(parseArgs(['--project', 'naijasingles-staging'])).toEqual({
      project: 'naijasingles-staging',
    });
  });

  it('shares production guard with events seed', () => {
    expect(() =>
      assertProjectAllowed('naijasingles-staging', false),
    ).not.toThrow();
    expect(() => assertProjectAllowed('naijasingles-74a75', false)).toThrow(
      /Refusing to seed production/,
    );
  });
});
