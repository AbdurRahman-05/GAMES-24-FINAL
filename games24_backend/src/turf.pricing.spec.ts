import { describe, expect, it } from 'vitest';
import {
  isBookingSlotEnded,
  isRevenueBooking,
  isValidDateString,
  parseSlotEndMinutes,
  parseSlotStartMinutes,
  priceForSlot,
  resolveTurfRates,
  PENDING_PAYMENT_STATUS,
} from './turf.service.js';

const rates = { dayRate: 1000, nightRate: 1400, weekdayRate: 1000, weekendRate: 1600 };

describe('slot time parsing', () => {
  it('parses start and end of a normal slot', () => {
    expect(parseSlotStartMinutes('06:00 PM - 07:00 PM')).toBe(18 * 60);
    expect(parseSlotEndMinutes('06:00 PM - 07:00 PM')).toBe(19 * 60);
  });

  it('treats a slot ending at midnight as ending at the end of the day', () => {
    expect(parseSlotEndMinutes('11:00 PM - 12:00 AM')).toBe(24 * 60);
  });

  it('uses the last sub-slot of a multi-slot booking', () => {
    expect(parseSlotEndMinutes('09:00 PM - 10:00 PM, 10:00 PM - 11:00 PM, 11:00 PM - 12:00 AM')).toBe(24 * 60);
  });

  it('does not mark a 11 PM booking as ended during its own day', () => {
    expect(isBookingSlotEnded('2026-11-26', '11:00 PM - 12:00 AM', '2026-11-26', 23 * 60 + 30)).toBe(false);
    expect(isBookingSlotEnded('2026-11-26', '11:00 PM - 12:00 AM', '2026-11-27', 10)).toBe(true);
  });
});

describe('priceForSlot', () => {
  it('charges day rate on weekday mornings', () => {
    const p = priceForSlot(rates, false, '08:00 AM - 09:00 AM');
    expect(p.price).toBe(1000);
    expect(p.rateType).toBe('Weekday Day Rate');
  });

  it('charges night rate on weekday evenings', () => {
    expect(priceForSlot(rates, false, '07:00 PM - 08:00 PM').price).toBe(1400);
  });

  it('adds the night premium on weekend evenings', () => {
    expect(priceForSlot(rates, true, '07:00 PM - 08:00 PM').price).toBe(1600 + 400);
  });

  it('applies percentage offers to the time-based price', () => {
    const p = priceForSlot(rates, false, '07:00 PM - 08:00 PM', { offerType: 'PERCENT', discountPercent: 25 });
    expect(p.price).toBe(1050);
    expect(p.originalPrice).toBe(1400);
  });

  it('applies fixed-price offers', () => {
    const p = priceForSlot(rates, false, '08:00 AM - 09:00 AM', { offerType: 'PRICE', offerPrice: 700, originalPrice: 1000 });
    expect(p.price).toBe(700);
  });
});

describe('resolveTurfRates', () => {
  it('uses the sport hourly rate when the sport has default weekday/weekend values', () => {
    const r = resolveTurfRates({ dayRate: 900 }, [
      { name: 'Badminton', hourlyRate: 500, weekdayRate: 1200, weekendRate: 1600, nightRate: 1400, courtsAvailable: 1 },
    ], 'badminton');
    expect(r).toEqual({ dayRate: 500, nightRate: 500, weekdayRate: 500, weekendRate: 500 });
  });
});

describe('helpers', () => {
  it('validates calendar dates', () => {
    expect(isValidDateString('2026-11-26')).toBe(true);
    expect(isValidDateString('2026-02-30')).toBe(false);
    expect(isValidDateString('26-11-2026')).toBe(false);
    expect(isValidDateString(undefined)).toBe(false);
  });

  it('excludes unpaid holds and cancellations from revenue', () => {
    expect(isRevenueBooking({ status: 'Confirmed' })).toBe(true);
    expect(isRevenueBooking({ status: PENDING_PAYMENT_STATUS })).toBe(false);
    expect(isRevenueBooking({ status: 'Cancelled' })).toBe(false);
  });
});
