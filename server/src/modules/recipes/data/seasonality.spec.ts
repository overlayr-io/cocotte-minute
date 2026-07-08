import { isSeasonal, normalizeName } from './seasonality';

describe('seasonality', () => {
  describe('normalizeName', () => {
    it('strips accents and lowercases', () => {
      expect(normalizeName('Courgette RÔTIE')).toBe('courgette rotie');
      expect(normalizeName('Pêche')).toBe('peche');
    });
  });

  describe('isSeasonal', () => {
    it('flags a recipe with an in-season produce (courge en octobre)', () => {
      expect(isSeasonal(['Courge butternut', 'Crème'], 10)).toBe(true);
    });

    it('is false when the produce is out of season (fraise en décembre)', () => {
      expect(isSeasonal(['Fraises', 'Sucre'], 12)).toBe(false);
    });

    it('matches on a substring of the ingredient name', () => {
      // "Velouté de potimarron" contient "potimarron" (courge) → saison auto/hiver.
      expect(isSeasonal(['Velouté de potimarron'], 11)).toBe(true);
    });

    it('ignores accents when matching (pêche en juillet)', () => {
      expect(isSeasonal(['Pêche jaune'], 7)).toBe(true);
    });

    it('is false without any recognized produce', () => {
      expect(isSeasonal(['Farine', 'Sel', 'Eau'], 6)).toBe(false);
    });

    it('is false for an empty ingredient list', () => {
      expect(isSeasonal([], 5)).toBe(false);
    });

    it('is false for an out-of-range month', () => {
      expect(isSeasonal(['Courge'], 0)).toBe(false);
      expect(isSeasonal(['Courge'], 13)).toBe(false);
    });
  });
});
