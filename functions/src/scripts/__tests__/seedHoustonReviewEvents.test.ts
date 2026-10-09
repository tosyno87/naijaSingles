import {assertProjectAllowed, parseArgs} from '../seedHoustonReviewEvents';

describe('seedHoustonReviewEvents', () => {
  describe('parseArgs', () => {
    it('parses --project and boolean --i-am-sure', () => {
      expect(
        parseArgs(['--project', 'naijasingles-staging', '--i-am-sure']),
      ).toEqual({
        project: 'naijasingles-staging',
        'i-am-sure': 'true',
      });
    });
  });

  describe('assertProjectAllowed', () => {
    it('allows staging without --i-am-sure', () => {
      expect(() =>
        assertProjectAllowed('naijasingles-staging', false),
      ).not.toThrow();
    });

    it('refuses production by default', () => {
      expect(() =>
        assertProjectAllowed('naijasingles-74a75', false),
      ).toThrow(/Refusing to seed production/);
    });

    it('allows production only with --i-am-sure', () => {
      expect(() =>
        assertProjectAllowed('naijasingles-74a75', true),
      ).not.toThrow();
    });
  });
});
