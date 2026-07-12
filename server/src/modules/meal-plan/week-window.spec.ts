import {
  addDays,
  isMonday,
  mealPlanWindow,
  mondayOfWeek,
  todayInParis,
} from './week-window';

describe('week-window', () => {
  it('addDays traverse les mois et les années', () => {
    expect(addDays('2026-07-06', 7)).toBe('2026-07-13');
    expect(addDays('2026-12-28', 7)).toBe('2027-01-04');
    expect(addDays('2026-07-06', -7)).toBe('2026-06-29');
  });

  it('mondayOfWeek retombe sur le lundi, dimanche inclus', () => {
    expect(mondayOfWeek('2026-07-06')).toBe('2026-07-06'); // lundi
    expect(mondayOfWeek('2026-07-11')).toBe('2026-07-06'); // samedi
    expect(mondayOfWeek('2026-07-12')).toBe('2026-07-06'); // dimanche
  });

  it('isMonday', () => {
    expect(isMonday('2026-07-06')).toBe(true);
    expect(isMonday('2026-07-07')).toBe(false);
  });

  it('todayInParis rend le jour civil parisien (UTC+2 en été)', () => {
    // 22h30 UTC un samedi = déjà dimanche à Paris.
    expect(todayInParis(new Date('2026-07-11T22:30:00Z'))).toBe('2026-07-12');
  });

  it('mealPlanWindow : rétention T-1 → T+2, écriture gratuite T/T+1', () => {
    const w = mealPlanWindow(new Date('2026-07-11T10:00:00Z')); // samedi de T
    expect(w.currentMonday).toBe('2026-07-06');
    expect(w.retentionStart).toBe('2026-06-29');
    expect(w.retentionEndExclusive).toBe('2026-07-27');
    expect(w.freeWriteStart).toBe('2026-07-06');
    expect(w.freeWriteEndExclusive).toBe('2026-07-20');
  });
});
