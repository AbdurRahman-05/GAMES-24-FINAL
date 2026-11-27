
import fs from 'fs';
import path from 'path';

export interface TurfSportConfig {
  name: string;
  hourlyRate: number;
  weekdayRate: number;
  weekendRate: number;
  nightRate: number;
  courtsAvailable: number;
}

export const DEFAULT_TURF_SPORTS: TurfSportConfig[] = [
  { name: 'Cricket', hourlyRate: 1000.0, weekdayRate: 1000.0, weekendRate: 1200.0, nightRate: 1200.0, courtsAvailable: 1 },
  { name: 'Football', hourlyRate: 1000.0, weekdayRate: 1000.0, weekendRate: 1200.0, nightRate: 1200.0, courtsAvailable: 1 },
];

function normalizePhotoList(urls: any): string[] {
  if (!Array.isArray(urls) || urls.length === 0) {
    return ['https://picsum.photos/seed/turf1/800/400'];
  }
  const defaultBase = process.env.BASE_URL || 'https://games-24-final.onrender.com';
  return urls.map((u: any) => {
    if (typeof u === 'string' && u.includes('localhost:3000')) {
      return u.replace('http://localhost:3000', defaultBase);
    }
    return String(u);
  });
}

export function getCourtsForTurf(turfId: number, venueName: string, sports: TurfSportConfig[], courtsJson?: any) {
  if (Array.isArray(courtsJson) && courtsJson.length > 0) {
    return courtsJson;
  }
  // When owner has not created multiple courts, this turf has exactly 1 real playing ground
  const primarySport = (sports && sports.length > 0) ? sports[0] : { name: 'Football', hourlyRate: 1000.0 };
  return [
    {
      id: `CRT-${turfId}-1`,
      name: venueName,
      sport: primarySport.name,
      surface: 'Synthetic Turf',
      hourlyRate: primarySport.hourlyRate || 1000.0,
      timings: '06:00 AM - 11:00 PM',
      description: `${venueName} Main Ground`,
      amenities: ['Floodlights', 'Changing Room', 'Parking', 'First Aid'],
      imageUrls: [],
    }
  ];
}
import { Injectable, NotFoundException, BadRequestException, ConflictException } from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from './prisma.service.js';

const FULL_24_SLOTS = [
  '12:00 AM - 01:00 AM',
  '01:00 AM - 02:00 AM',
  '02:00 AM - 03:00 AM',
  '03:00 AM - 04:00 AM',
  '04:00 AM - 05:00 AM',
  '05:00 AM - 06:00 AM',
  '06:00 AM - 07:00 AM',
  '07:00 AM - 08:00 AM',
  '08:00 AM - 09:00 AM',
  '09:00 AM - 10:00 AM',
  '10:00 AM - 11:00 AM',
  '11:00 AM - 12:00 PM',
  '12:00 PM - 01:00 PM',
  '01:00 PM - 02:00 PM',
  '02:00 PM - 03:00 PM',
  '03:00 PM - 04:00 PM',
  '04:00 PM - 05:00 PM',
  '05:00 PM - 06:00 PM',
  '06:00 PM - 07:00 PM',
  '07:00 PM - 08:00 PM',
  '08:00 PM - 09:00 PM',
  '09:00 PM - 10:00 PM',
  '10:00 PM - 11:00 PM',
  '11:00 PM - 12:00 AM',
];

function parseHour(timeStr: string): number {
  if (!timeStr) return 6;
  const cleaned = timeStr.replace(/\s*\([^)]*\)/g, '').trim();
  if (cleaned === '24 Hours') return 0;
  const parts = cleaned.split(' ');
  if (parts.length < 2) return 0;
  const timeParts = parts[0].split(':');
  let hour = parseInt(timeParts[0], 10) || 0;
  const ampm = parts[1].toUpperCase();
  if (ampm === 'PM' && hour < 12) hour += 12;
  else if (ampm === 'AM' && hour === 12) hour = 0;
  return hour;
}

export function parseSlotStartMinutes(slot: string): number {
  if (!slot) return -1;
  const startPart = slot.split('-')[0].trim();
  const [timePart, period] = startPart.split(' ');
  if (!timePart) return -1;
  const [hStr, mStr] = timePart.split(':');
  let hour = parseInt(hStr, 10);
  const minutes = parseInt(mStr || '0', 10);
  if (isNaN(hour)) return -1;
  if (period?.toUpperCase() === 'PM' && hour !== 12) hour += 12;
  if (period?.toUpperCase() === 'AM' && hour === 12) hour = 0;
  return hour * 60 + (isNaN(minutes) ? 0 : minutes);
}

/**
 * Returns the end of the LAST sub-slot in minutes from the start of the booking day.
 * A slot that ends at or before it starts (e.g. "11:00 PM - 12:00 AM") ends on the next
 * day, so 1440 is added; otherwise such bookings were treated as finished all day long.
 */
export function parseSlotEndMinutes(slot: string): number {
  if (!slot) return -1;
  const slotList = slot.split(',').map((s) => s.trim()).filter(Boolean);
  const lastSlot = slotList.length > 0 ? slotList[slotList.length - 1] : slot;
  const parts = lastSlot.split('-');
  const endPart = (parts.length > 1 ? parts[1] : parts[0]).trim();
  const [timePart, period] = endPart.split(' ');
  if (!timePart) return -1;
  const [hStr, mStr] = timePart.split(':');
  let hour = parseInt(hStr, 10);
  const minutes = parseInt(mStr || '0', 10);
  if (isNaN(hour)) return -1;
  if (period?.toUpperCase() === 'PM' && hour !== 12) hour += 12;
  if (period?.toUpperCase() === 'AM' && hour === 12) hour = 0;
  let endMin = hour * 60 + (isNaN(minutes) ? 0 : minutes);
  const lastStart = parseSlotStartMinutes(lastSlot);
  if (parts.length > 1 && lastStart !== -1 && endMin <= lastStart) {
    endMin += 24 * 60;
  }
  return endMin;
}

/** Bookings in these states do not count as sales (but a pending hold still blocks the slot). */
export const PENDING_PAYMENT_STATUS = 'Pending Payment';
export const HOLD_MINUTES = 10;

export function isRevenueBooking(b: { status?: string | null }): boolean {
  const s = (b?.status || '').toLowerCase();
  return s !== 'cancelled' && s !== PENDING_PAYMENT_STATUS.toLowerCase();
}

export interface TurfRates {
  dayRate: number;
  nightRate: number;
  weekdayRate: number;
  weekendRate: number;
}

/** Resolves the hourly rates for a sport at a turf (same rules the slot list has always used). */
export function resolveTurfRates(
  turf: { dayRate?: number | null; nightRate?: number | null; weekendRate?: number | null },
  sportsItems: TurfSportConfig[],
  sport?: string,
): TurfRates {
  let matchedSport: TurfSportConfig | undefined;
  if (sport) {
    const s = sport.toLowerCase();
    matchedSport =
      sportsItems.find((x) => x.name.toLowerCase() === s) ||
      sportsItems.find((x) => x.name.toLowerCase().includes(s) || s.includes(x.name.toLowerCase()));
  }
  const baseSportRate = matchedSport ? matchedSport.hourlyRate : (turf.dayRate || 1000.0);
  const dayRate = baseSportRate;
  const weekdayRate = (matchedSport && matchedSport.weekdayRate && Math.abs(matchedSport.weekdayRate - 1200) > 0.1)
    ? matchedSport.weekdayRate
    : baseSportRate;
  const weekendRate = (matchedSport && matchedSport.weekendRate && Math.abs(matchedSport.weekendRate - 1600) > 0.1)
    ? matchedSport.weekendRate
    : (matchedSport ? matchedSport.hourlyRate : (turf.weekendRate || 1600.0));
  const nightRate = (matchedSport && matchedSport.nightRate && Math.abs(matchedSport.nightRate - 1400) > 0.1)
    ? matchedSport.nightRate
    : (matchedSport ? matchedSport.hourlyRate : (turf.nightRate || 1400.0));
  return { dayRate, nightRate, weekdayRate, weekendRate };
}

export function isWeekendDate(dateStr: string): boolean {
  const [year, month, d] = dateStr.split('-').map(Number);
  const day = new Date(year, month - 1, d).getDay();
  return day === 0 || day === 6;
}

export interface SlotPrice {
  price: number;
  originalPrice: number;
  rateType: string;
  isNight: boolean;
  offer: any;
}

/**
 * Single source of truth for what one slot costs. Used both to DISPLAY slot prices and to
 * CHARGE for a booking, so the amount a player sees is exactly the amount they pay.
 */
export function priceForSlot(rates: TurfRates, isWeekend: boolean, slot: string, offerRecord?: any): SlotPrice {
  const startMin = parseSlotStartMinutes(slot);
  const hour = startMin === -1 ? 12 : Math.floor(startMin / 60);
  const isNight = hour >= 18 || hour < 6;

  let price: number;
  let rateType: string;
  if (isWeekend) {
    if (isNight) {
      price = rates.weekendRate + Math.max(0, rates.nightRate - rates.dayRate);
      rateType = 'Weekend Night Rate';
    } else {
      price = rates.weekendRate;
      rateType = 'Weekend Day Rate';
    }
  } else if (isNight) {
    price = rates.nightRate;
    rateType = 'Weekday Night Rate';
  } else {
    price = rates.dayRate;
    rateType = 'Weekday Day Rate';
  }

  let finalPrice = price;
  let offer: any = null;
  if (offerRecord) {
    if (offerRecord.offerType === 'PERCENT') {
      const disc = offerRecord.discountPercent ?? 20;
      finalPrice = Math.round(price * (1 - disc / 100));
      offer = {
        id: offerRecord.id,
        offerType: 'PERCENT',
        discountPercent: disc,
        tagLabel: offerRecord.tagLabel || `${disc}% OFF`,
        originalPrice: price,
        offerPrice: finalPrice,
        rawOfferString: offerRecord.rawOfferString || `PERCENT|${disc}|${offerRecord.tagLabel || ''}`,
      };
    } else if (offerRecord.offerType === 'PRICE') {
      finalPrice = offerRecord.offerPrice ?? Math.round(price * 0.8);
      const orig = offerRecord.originalPrice ?? price;
      offer = {
        id: offerRecord.id,
        offerType: 'PRICE',
        discountPercent: orig > 0 ? Math.round(((orig - finalPrice) / orig) * 100) : 0,
        tagLabel: offerRecord.tagLabel || 'Special Price',
        originalPrice: orig,
        offerPrice: finalPrice,
        rawOfferString: offerRecord.rawOfferString || `PRICE|${orig}|${finalPrice}`,
      };
    }
  }

  return { price: Math.max(0, finalPrice), originalPrice: price, rateType, isNight, offer };
}

const DATE_RE = /^\d{4}-\d{2}-\d{2}$/;
export function isValidDateString(date: unknown): date is string {
  if (typeof date !== 'string' || !DATE_RE.test(date)) return false;
  const [y, m, d] = date.split('-').map(Number);
  const dt = new Date(y, m - 1, d);
  return dt.getFullYear() === y && dt.getMonth() === m - 1 && dt.getDate() === d;
}

export function getISTDateAndMinutes(): { todayStr: string; currentMinutes: number } {
  try {
    const formatter = new Intl.DateTimeFormat('en-CA', {
      timeZone: 'Asia/Kolkata',
      year: 'numeric',
      month: '2-digit',
      day: '2-digit',
      hour: '2-digit',
      minute: '2-digit',
      hour12: false,
    });
    const parts = formatter.formatToParts(new Date());
    const getP = (t: string) => parts.find((p) => p.type === t)?.value || '0';
    const todayStr = `${getP('year')}-${getP('month')}-${getP('day')}`;
    const currentMinutes = parseInt(getP('hour'), 10) * 60 + parseInt(getP('minute'), 10);
    return { todayStr, currentMinutes };
  } catch {
    const now = new Date();
    const istMs = now.getTime() + (330 + now.getTimezoneOffset()) * 60000;
    const ist = new Date(istMs);
    const todayStr = `${ist.getFullYear()}-${String(ist.getMonth() + 1).padStart(2, '0')}-${String(ist.getDate()).padStart(2, '0')}`;
    const currentMinutes = ist.getHours() * 60 + ist.getMinutes();
    return { todayStr, currentMinutes };
  }
}

export function isBookingSlotEnded(date: string, timeSlot: string, todayStr: string, currentMinutes: number): boolean {
  if (!date) return false;
  const cleanDate = date.trim();
  if (cleanDate < todayStr) return true;
  if (cleanDate > todayStr) return false;
  const endMin = parseSlotEndMinutes(timeSlot);
  if (endMin === -1) return false;
  return currentMinutes >= endMin;
}

export function generateTimeSlots(openingTime: string, closingTime: string): string[] {
  let startHour = parseHour(openingTime || '06:00 AM');
  let endHour = parseHour(closingTime || '11:00 PM');
  if (endHour === 0 && (closingTime || '').toUpperCase().includes('AM')) endHour = 24;
  if (endHour <= startHour) endHour += 24;
  const result: string[] = [];
  for (let h = startHour; h < endHour; h++) {
    result.push(FULL_24_SLOTS[h % 24]);
  }
  return result.length > 0 ? result : FULL_24_SLOTS;
}

@Injectable()
export class TurfService {
  constructor(private readonly prisma: PrismaService) {}

  private turfSportsStore: Record<number, TurfSportConfig[]> = {};
  private sportsFilePath = path.resolve(process.cwd(), 'turf_sports_data.json');

  private ensureSportsLoaded(): void {
    if (Object.keys(this.turfSportsStore).length > 0) return;
    try {
      if (fs.existsSync(this.sportsFilePath)) {
        const raw = fs.readFileSync(this.sportsFilePath, 'utf8');
        this.turfSportsStore = JSON.parse(raw);
      }
    } catch (e) {
      console.error('Error loading turf sports data file:', e);
    }
  }

  private persistSportsToFile(): void {
    try {
      fs.writeFileSync(this.sportsFilePath, JSON.stringify(this.turfSportsStore, null, 2), 'utf8');
    } catch (e) {
      console.error('Error persisting turf sports data to file:', e);
    }
  }

  getSportsForTurf(turfId: number): TurfSportConfig[] {
    this.ensureSportsLoaded();
    if (this.turfSportsStore[turfId] && this.turfSportsStore[turfId].length > 0) {
      return this.turfSportsStore[turfId];
    }
    return DEFAULT_TURF_SPORTS;
  }

  saveSportsForTurf(turfId: number, sports: any[]): TurfSportConfig[] {
    this.ensureSportsLoaded();
    if (Array.isArray(sports) && sports.length > 0) {
      const sanitized: TurfSportConfig[] = sports.map((s: any) => ({
        name: String(s.name || 'Football'),
        hourlyRate: Number(s.hourlyRate || s.dayRate || 1000.0),
        weekdayRate: Number(s.weekdayRate || 1200.0),
        weekendRate: Number(s.weekendRate || 1600.0),
        nightRate: Number(s.nightRate || 1400.0),
        courtsAvailable: Number(s.courtsAvailable || 1),
      }));
      this.turfSportsStore[turfId] = sanitized;
      this.persistSportsToFile();
      return sanitized;
    }
    return this.getSportsForTurf(turfId);
  }

  async getTurfSports(turfId: number) {
    const sportsList = this.getSportsForTurf(turfId);
    return {
      success: true,
      turfId,
      sports: sportsList.map(s => s.name),
      sportsList,
    };
  }

  async saveTurfSports(turfId: number, body: any) {
    const rawSports = Array.isArray(body) ? body : (body?.sports || body?.sportsList || []);
    const updated = this.saveSportsForTurf(turfId, rawSports);
    return {
      success: true,
      turfId,
      message: 'Sports configuration and rates saved successfully',
      sports: updated.map(s => s.name),
      sportsList: updated,
    };
  }

  private async findVerifiedAdmin(id: number, includeDashboard = true, includeBookingsAndBlocked = false): Promise<any> {
    const include: any = {};
    if (includeDashboard) include.dashboard = true;
    if (includeBookingsAndBlocked) {
      include.dashboard = true;
      include.bookings = { orderBy: { createdAt: 'desc' } };
      include.blockedSlots = true;
    }

    // 1. Try by verifiedAdmin.id (primary key)
    let turf = await this.prisma.verifiedAdmin.findUnique({
      where: { id },
      ...(Object.keys(include).length > 0 ? { include } : {}),
    });

    // 2. Try by adminUserId (FK referencing AdminUser)
    if (!turf) {
      turf = await this.prisma.verifiedAdmin.findFirst({
        where: { adminUserId: id },
        ...(Object.keys(include).length > 0 ? { include } : {}),
      });
    }

    // No "first venue" fallback: an unknown id must never resolve to someone else's turf.
    return turf;
  }

  async getAllTurfs() {
    // Only return turfs whose owner subscription is active and verified (not on hold)
    const verified = await this.prisma.verifiedAdmin.findMany({
      where: {
        status: 'VERIFIED',
        isBookingHold: false,
      },
      include: {
        dashboard: true,
      },
      orderBy: { id: 'desc' },
    });

    const istNow = getISTDateAndMinutes();
    return verified.map((t: any) => {
      const photos = normalizePhotoList(t.photoUrls);
      
      const amenities = Array.isArray(t.amenities) && t.amenities.length > 0
        ? t.amenities
        : ['Drinking Water', 'Parking', 'Floodlights', 'Restroom'];

      // Live rate for the current hour in IST, using the same rules as the slot list
      const currentPrice = priceForSlot(
        resolveTurfRates(t, this.getSportsForTurf(t.id)),
        isWeekendDate(istNow.todayStr),
        FULL_24_SLOTS[Math.floor(istNow.currentMinutes / 60) % 24],
      ).price;

      return {
        id: t.id,
        venueName: t.venueName,
        name: t.venueName,
        ownerName: t.ownerName,
        ownerPhone: t.ownerPhone,
        ownerEmail: t.ownerEmail,
        neighborhoodArea: t.neighborhoodArea,
        streetAddress: t.streetAddress,
        location: `${t.neighborhoodArea} • ${t.streetAddress}`,
        photoUrls: photos,
        imageUrl: photos[0],
        amenities,
        facilities: amenities,
        openingTime: t.dashboard?.openingTime || '06:00 AM',
        closingTime: t.dashboard?.closingTime || '10:00 PM',
        dayRate: t.dayRate,
        nightRate: t.nightRate,
        weekdayRate: t.weekdayRate,
        weekendRate: t.weekendRate,
        price: `₹${currentPrice.toLocaleString('en-IN')}`,
        currentRate: currentPrice,
        rating: null, // no review system yet: do not show invented ratings
        reviews: 0,
        sports: this.getSportsForTurf(t.id).map(s => s.name),
        sportsList: this.getSportsForTurf(t.id),
        courts: getCourtsForTurf(t.id, t.venueName, this.getSportsForTurf(t.id), t.courts),
      };
    });
  }

  async getTurfById(id: number) {
    const turf = await this.findVerifiedAdmin(id, true, true);

    if (!turf) {
      throw new NotFoundException(`Turf with ID ${id} not found`);
    }

    const photos = normalizePhotoList(turf.photoUrls);
    
    const amenities = Array.isArray(turf.amenities) && turf.amenities.length > 0
      ? turf.amenities
      : ['Drinking Water', 'Parking', 'Floodlights', 'Restroom'];

    const sportsItems = this.getSportsForTurf(turf.id);
    const courtsList = getCourtsForTurf(turf.id, turf.venueName, sportsItems, turf.courts);

    const { todayStr, currentMinutes } = getISTDateAndMinutes();
    let sanitizedBookings = turf.bookings || [];
    if (sanitizedBookings.length > 0) {
      const unvisitedIds: number[] = [];
      const completedIds: number[] = [];

      for (const b of sanitizedBookings) {
        const s = (b.status || '').toLowerCase();
        if (s === 'cancelled' || s === 'completed' || s === 'not visited') continue;
        if (s === PENDING_PAYMENT_STATUS.toLowerCase()) continue;
        if (isBookingSlotEnded(b.date, b.timeSlot, todayStr, currentMinutes)) {
          if (s === 'checked in') {
            b.status = 'Completed';
            completedIds.push(b.id);
          } else {
            // Player booked but never scanned QR with owner app: did NOT visit the turf!
            b.status = 'Not Visited';
            unvisitedIds.push(b.id);
          }
        }
      }

      if (unvisitedIds.length > 0) {
        this.prisma.turfBooking.updateMany({
          where: { id: { in: unvisitedIds } },
          data: { status: 'Not Visited' },
        }).catch((e) => console.error('Error updating unvisited bookings:', e));
      }

      if (completedIds.length > 0) {
        this.prisma.turfBooking.updateMany({
          where: { id: { in: completedIds } },
          data: { status: 'Completed' },
        }).catch((e) => console.error('Error updating completed bookings:', e));
      }
    }

    return {
      id: turf.id,
      venueName: turf.venueName,
      name: turf.venueName,
      ownerName: turf.ownerName,
      ownerPhone: turf.ownerPhone,
      ownerEmail: turf.ownerEmail,
      neighborhoodArea: turf.neighborhoodArea,
      streetAddress: turf.streetAddress,
      location: `${turf.neighborhoodArea} • ${turf.streetAddress}`,
      photoUrls: photos,
      imageUrl: photos[0],
      amenities,
      facilities: amenities,
      openingTime: turf.dashboard?.openingTime || '06:00 AM',
      closingTime: turf.dashboard?.closingTime || '10:00 PM',
      dayRate: turf.dayRate,
      nightRate: turf.nightRate,
      weekdayRate: turf.weekdayRate,
      weekendRate: turf.weekendRate,
      price: `₹${(turf.dayRate || 1000).toLocaleString('en-IN')}`,
      rating: null, // no review system yet: do not show invented ratings
      reviews: 0,
      sports: sportsItems.map(s => s.name),
      sportsList: sportsItems,
      courts: courtsList,
      dashboard: turf.dashboard,
      bookings: sanitizedBookings,
      blockedSlots: turf.blockedSlots,
    };
  }

  async getTurfSlots(id: number, date?: string, role?: string, sport?: string) {
    const turf = await this.findVerifiedAdmin(id, true, false);

    if (!turf) {
      throw new NotFoundException(`Turf with ID ${id} not found`);
    }

    if (turf.isBookingHold || turf.status === 'HOLD') {
      throw new BadRequestException(`Bookings for "${turf.venueName}" are temporarily on hold by Platform Super Admin.`);
    }
    const verifiedAdminId = turf.id;

    const { todayStr, currentMinutes } = getISTDateAndMinutes();
    const targetDate = date || todayStr;

    if (!isValidDateString(targetDate)) {
      throw new BadRequestException('date must be in YYYY-MM-DD format');
    }

    const [year, month, d] = targetDate.split('-').map(Number);
    const dateObj = new Date(year, month - 1, d);
    const isWeekend = isWeekendDate(targetDate);

    const sportsItems = this.getSportsForTurf(verifiedAdminId);
    const rates = resolveTurfRates(turf, sportsItems, sport);
    const { dayRate, nightRate, weekdayRate, weekendRate } = rates;

    await this.releaseExpiredHolds(verifiedAdminId);

    const openingTime = turf.dashboard?.openingTime || '06:00 AM';
    const closingTime = turf.dashboard?.closingTime || '10:00 PM';
    const allSlots = generateTimeSlots(openingTime, closingTime);

    const bookings = await this.prisma.turfBooking.findMany({
      where: {
        verifiedAdminId,
        date: targetDate,
        status: { not: 'Cancelled' },
      },
    });

    const blocked = await this.prisma.blockedSlot.findMany({
      where: {
        verifiedAdminId,
        date: targetDate,
      },
    });

    const bookedSlotMap = new Map<string, any>();
    for (const b of bookings) {
      const parts = (b.timeSlot || '').split(',').map((s: string) => s.trim()).filter(Boolean);
      for (const p of parts) {
        bookedSlotMap.set(p, b);
      }
      bookedSlotMap.set(b.timeSlot, b);
    }

    const blockedSlotSet = new Set<string>();
    const blockedReasonMap = new Map<string, string>();
    for (const bl of blocked) {
      blockedSlotSet.add(bl.timeSlot);
      blockedReasonMap.set(bl.timeSlot, bl.reason || 'Under Maintenance');
    }

    const offers = await this.prisma.slotOffer.findMany({
      where: {
        verifiedAdminId,
        date: targetDate,
      },
    });

    const offerMap = new Map<string, any>();
    for (const off of offers) {
      offerMap.set(off.timeSlot, off);
    }

    const isOwner = role?.toLowerCase() === 'owner' || role?.toLowerCase() === 'admin';

    // Filter slots based on date and time cutoff
    const filteredSlotStrings = allSlots.filter((slot) => {
      if (isOwner) return true; // Owner/Admin manages all slots for the full day

      // 1. Past dates: all slots expired for player booking
      if (targetDate < todayStr) return false;

      // 2. Future dates: all slots open
      if (targetDate > todayStr) return true;

      // 3. Today (targetDate === todayStr):
      const startMin = parseSlotStartMinutes(slot);
      if (startMin === -1) return true;

      const isBooked = bookedSlotMap.has(slot);
      const isBlocked = blockedSlotSet.has(slot);

      // A. Past / already started slot:
      // If current time is at or past slot start time, completely remove it
      if (currentMinutes >= startMin) {
        return false;
      }

      // B. Upcoming booked or blocked slot:
      // Keep it so users on all devices see that it is Booked / Blocked
      if (isBooked || isBlocked) {
        return true;
      }

      // C. Upcoming unbooked slot: 5-minute cutoff rule
      // If within 5 minutes before start (or closer), hide it from booking!
      // (e.g., 2:00 PM slot: at 1:50 PM, 10 min left -> visible; at 1:55 PM, 5 min left -> hidden)
      if (currentMinutes >= startMin - 5) {
        return false;
      }

      return true;
    });

    const slots = filteredSlotStrings.map((slot) => {
      const isBooked = bookedSlotMap.has(slot);
      const isBlocked = blockedSlotSet.has(slot);
      const startMin = parseSlotStartMinutes(slot);
      const isPast = (targetDate < todayStr) || (targetDate === todayStr && startMin !== -1 && currentMinutes >= startMin);

      let status = 'available';
      if (isPast) status = isBooked ? 'booked' : 'passed';
      else if (isBooked) status = 'booked';
      else if (isBlocked) status = 'blocked';

      const { price, originalPrice: _orig, rateType, isNight, offer } = priceForSlot(
        rates,
        isWeekend,
        slot,
        offerMap.get(slot),
      );
      const finalPrice = price;
      const bookingInfo = isBooked ? bookedSlotMap.get(slot) : null;

      return {
        slot,
        time: slot,
        status,
        reason: isBlocked ? (blockedReasonMap.get(slot) || 'Under Maintenance') : null,
        blockReason: isBlocked ? (blockedReasonMap.get(slot) || 'Under Maintenance') : null,
        isPast,
        originalPrice: _orig,
        price: finalPrice,
        rateType,
        isNight,
        isWeekend,
        // Customer details are only exposed to the owner view; players just see that it is taken.
        booking: bookingInfo && isOwner ? bookingInfo : null,
        isHeld: Boolean(bookingInfo && bookingInfo.status === PENDING_PAYMENT_STATUS),
        offer,
        offerTag: offer ? offer.rawOfferString : null,
      };
    });

    return {
      turfId: verifiedAdminId,
      venueName: turf.venueName,
      date: targetDate,
      dayName: dateObj.toLocaleDateString('en-US', { weekday: 'long' }),
      isWeekend,
      rates: {
        dayRate,
        nightRate,
        weekdayRate,
        weekendRate,
      },
      openingTime,
      closingTime,
      totalSlots: slots.length,
      bookedCount: slots.filter((s) => s.status === 'booked').length,
      blockedCount: slots.filter((s) => s.status === 'blocked').length,
      availableCount: slots.filter((s) => s.status === 'available').length,
      slots,
    };
  }

  /**
   * Cancels payment holds that were never paid within HOLD_MINUTES so their slots become free again.
   */
  async releaseExpiredHolds(verifiedAdminId?: number) {
    const cutoff = new Date(Date.now() - HOLD_MINUTES * 60 * 1000);
    await this.prisma.turfBooking
      .updateMany({
        where: {
          status: PENDING_PAYMENT_STATUS,
          createdAt: { lt: cutoff },
          ...(verifiedAdminId ? { verifiedAdminId } : {}),
        },
        data: { status: 'Cancelled', paymentMethod: 'Payment not completed' },
      })
      .catch((e) => console.error('Error releasing expired payment holds:', e));
  }

  /**
   * Server-side price for a set of slots. Uses the same rules as the slot list (day/night,
   * weekday/weekend, sport rate and slot offers) so the charged amount matches what is shown.
   */
  async quoteSlots(turf: any, date: string, slots: string[], sport?: string) {
    const rates = resolveTurfRates(turf, this.getSportsForTurf(turf.id), sport);
    const weekend = isWeekendDate(date);
    const offers = await this.prisma.slotOffer.findMany({
      where: { verifiedAdminId: turf.id, date, timeSlot: { in: slots } },
    });
    const offerMap = new Map(offers.map((o) => [o.timeSlot, o]));
    const lines = slots.map((s) => ({ slot: s, ...priceForSlot(rates, weekend, s, offerMap.get(s)) }));
    const total = lines.reduce((sum, l) => sum + l.price, 0);
    return { total, lines };
  }

  /**
   * Direct booking without online payment. Restricted to the platform admin (walk-in / manual
   * bookings); players must go through /cashfree/create-order so the slot is paid for.
   */
  async bookSlot(id: number, body: any) {
    const booking = await this.reserveSlots(id, body, { hold: false });
    return {
      success: true,
      message: 'Booking confirmed successfully in realtime!',
      ...booking,
      booking,
    };
  }

  /** Reserves slots for HOLD_MINUTES while the player pays. Confirmed by confirmPaymentHold(). */
  async createPaymentHold(id: number, body: any) {
    return this.reserveSlots(id, body, { hold: true });
  }

  private parseRequestedSlots(body: any): string[] {
    const raw: string[] = Array.isArray(body?.timeSlots) && body.timeSlots.length > 0
      ? body.timeSlots.map((s: any) => String(s))
      : String(body?.timeSlot || '').split(',');
    const cleaned = raw.map((s) => s.trim()).filter(Boolean);
    const unique = Array.from(new Set(cleaned));
    for (const s of unique) {
      if (parseSlotStartMinutes(s) === -1 || !s.includes('-') || s.length > 40) {
        throw new BadRequestException(`Invalid time slot "${s}"`);
      }
    }
    unique.sort((a, b) => parseSlotStartMinutes(a) - parseSlotStartMinutes(b));
    return unique;
  }

  private async reserveSlots(id: number, body: any, opts: { hold: boolean }) {
    const { customerName, customerPhone, sport, courtName, date, paymentMethod } = body || {};

    if (!isValidDateString(date)) {
      throw new BadRequestException('A valid date (YYYY-MM-DD) is required for booking');
    }
    const rawSlots = this.parseRequestedSlots(body);
    if (rawSlots.length === 0) {
      throw new BadRequestException('At least one timeSlot is required for booking');
    }
    if (rawSlots.length > 12) {
      throw new BadRequestException('A single booking can contain at most 12 slots');
    }
    const cleanPhone = String(customerPhone || '').replace(/\D/g, '');
    if (cleanPhone.length < 10) {
      throw new BadRequestException('A valid customer phone number is required for booking');
    }
    const combinedTimeSlot = rawSlots.join(', ');

    // Validate that slot is not in the past or within 5-minute cutoff
    const { todayStr, currentMinutes } = getISTDateAndMinutes();
    if (date < todayStr) {
      throw new BadRequestException('Cannot book slots for a past date');
    }
    if (date === todayStr) {
      for (const s of rawSlots) {
        const startMin = parseSlotStartMinutes(s);
        if (startMin !== -1 && currentMinutes >= startMin - 5) {
          throw new BadRequestException(`Slot "${s}" is no longer available for booking (booking closes 5 minutes before slot start time)`);
        }
      }
    }

    // Exact lookup only: never fall back to another venue for a booking.
    const turf = await this.prisma.verifiedAdmin.findUnique({
      where: { id },
      include: { dashboard: true },
    });
    if (!turf) {
      throw new NotFoundException(`Turf #${id} not found`);
    }

    if (turf.isBookingHold || turf.status !== 'VERIFIED') {
      throw new BadRequestException(`Bookings for "${turf.venueName}" are currently on hold by platform administrator and cannot accept new reservations.`);
    }

    const verifiedAdminId = turf.id;

    // Only slots inside the venue's operating hours can be booked.
    const openSlots = new Set(
      generateTimeSlots(turf.dashboard?.openingTime || '06:00 AM', turf.dashboard?.closingTime || '10:00 PM'),
    );
    for (const s of rawSlots) {
      if (!openSlots.has(s)) {
        throw new BadRequestException(`Slot "${s}" is outside the venue's operating hours`);
      }
    }

    await this.releaseExpiredHolds(verifiedAdminId);

    // Authentic server-side price; any client-sent amount is ignored.
    const quote = await this.quoteSlots(turf, date, rawSlots, sport);
    const bookingAmount = quote.total;

    let booking: any;
    try {
      booking = await this.prisma.$transaction(
        async (tx) => {
          // 1. Atomically check each requested slot
          for (const s of rawSlots) {
            const existing = await tx.turfBooking.findFirst({
              where: {
                verifiedAdminId,
                date,
                timeSlot: { contains: s },
                status: { not: 'Cancelled' },
              },
            });
            if (existing) {
              throw new ConflictException(`Slot "${s}" on ${date} is already booked!`);
            }

            const blocked = await tx.blockedSlot.findFirst({
              where: {
                verifiedAdminId,
                date,
                timeSlot: s,
              },
            });
            if (blocked) {
              throw new BadRequestException(`Slot "${s}" on ${date} is blocked for maintenance by the owner.`);
            }
          }

          // 2. Atomically create the booking (protected by unique index & serializable lock)
          const isOpenMatch = body?.isOpenMatch === true;
          const teamName = String(body?.teamName || '').trim() || String(customerName || '').trim() || 'My Team';
          const teamSize = String(body?.teamSize || '').trim() || '7v7';

          const createdBooking = await tx.turfBooking.create({
            data: {
              verifiedAdminId,
              customerName: String(customerName || '').trim() || 'Player Customer',
              customerPhone: cleanPhone.slice(-10),
              sport: sport || 'Football',
              courtName: courtName || `${turf.venueName} Main Arena`,
              date,
              timeSlot: combinedTimeSlot,
              amount: bookingAmount,
              paymentMethod: opts.hold ? 'Cashfree (awaiting payment)' : (paymentMethod || 'Cash (Venue)'),
              status: opts.hold ? PENDING_PAYMENT_STATUS : 'Confirmed',
              isOpenMatch,
              openMatchStatus: isOpenMatch ? 'WAITING_FOR_OPPONENT' : null,
              teamName: isOpenMatch ? teamName : null,
              teamSize: isOpenMatch ? teamSize : null,
            },
          });

          // Generate formal, permanent booking ID (e.g. G24-BK-0013)
          const formalBookingCode = `G24-BK-${createdBooking.id.toString().padStart(4, '0')}`;
          const updatedWithCode = await tx.turfBooking.update({
            where: { id: createdBooking.id },
            data: { bookingCode: formalBookingCode },
          });

          // A held (unpaid) booking does not advertise an open match yet; that happens on payment.
          if (isOpenMatch && !opts.hold) {
            await this.createChallengeForBooking(tx, updatedWithCode, turf);
          }

          return {
            ...updatedWithCode,
            bookingId: formalBookingCode,
            bookingCode: formalBookingCode,
            turfId: verifiedAdminId,
            turfName: turf.venueName,
            courtName: courtName || `${turf.venueName} Main Arena`,
            location: turf.neighborhoodArea || 'Madurai',
            priceBreakdown: quote.lines.map((l) => ({ slot: l.slot, price: l.price, rateType: l.rateType })),
            holdExpiresAt: opts.hold
              ? new Date(createdBooking.createdAt.getTime() + HOLD_MINUTES * 60 * 1000).toISOString()
              : null,
          };
        },
        {
          isolationLevel: Prisma.TransactionIsolationLevel.Serializable,
        },
      );
    } catch (err: any) {
      if (err?.code === 'P2002' || err?.code === 'P2034' || err instanceof ConflictException || err?.status === 409) {
        throw new ConflictException(`One or more of the selected slots "${combinedTimeSlot}" on ${date} were just booked by another user. Please choose available slots.`);
      }
      throw err;
    }

    if (!opts.hold) {
      await this.recalculateDashboardMetrics(verifiedAdminId);
    }
    return booking;
  }

  /** Creates the public open-match challenge for a confirmed booking (once per booking). */
  private async createChallengeForBooking(tx: any, booking: any, turf: any) {
    const existing = await tx.openChallenge.findFirst({ where: { bookingId: booking.id } });
    if (existing) return existing;
    const teamName = booking.teamName || booking.customerName || 'My Team';
    const initials = teamName.length >= 2 ? teamName.substring(0, 2).toUpperCase() : 'TC';
    return tx.openChallenge.create({
      data: {
        id: `ch_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
        bookingId: booking.id,
        turfId: turf.id,
        turfName: turf.venueName,
        location: turf.neighborhoodArea || 'Madurai',
        date: booking.date,
        time: booking.timeSlot,
        sport: booking.sport || 'Football',
        challengerName: teamName,
        challengerTeamInitials: initials,
        challengerColor: '4292149248',
        creatorPhone: booking.customerPhone,
        teamSize: booking.teamSize || '7v7',
        isJoined: false,
        status: 'OPEN',
        joinRequests: [],
      },
    });
  }

  /**
   * Turns a paid payment hold into a confirmed booking. If the hold already expired, it tries to
   * re-reserve the same slots; returns null when they were taken in the meantime (caller refunds).
   */
  async confirmPaymentHold(bookingId: number, paymentLabel: string): Promise<any | null> {
    const booking = await this.prisma.turfBooking.findUnique({
      where: { id: bookingId },
      include: { verifiedAdmin: true },
    });
    if (!booking) return null;

    if (booking.status === 'Confirmed' || booking.status === 'Checked In') {
      return booking;
    }

    let confirmed: any = null;
    if (booking.status === PENDING_PAYMENT_STATUS) {
      confirmed = await this.prisma.turfBooking.update({
        where: { id: bookingId },
        data: { status: 'Confirmed', paymentMethod: paymentLabel },
      });
    } else if (booking.status === 'Cancelled') {
      // Hold expired before payment completed: re-check availability and restore it if free.
      try {
        confirmed = await this.prisma.$transaction(
          async (tx) => {
            for (const s of booking.timeSlot.split(',').map((x) => x.trim()).filter(Boolean)) {
              const clash = await tx.turfBooking.findFirst({
                where: {
                  verifiedAdminId: booking.verifiedAdminId,
                  date: booking.date,
                  timeSlot: { contains: s },
                  status: { not: 'Cancelled' },
                  id: { not: booking.id },
                },
              });
              if (clash) return null;
            }
            return tx.turfBooking.update({
              where: { id: bookingId },
              data: { status: 'Confirmed', paymentMethod: paymentLabel },
            });
          },
          { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
        );
      } catch {
        confirmed = null;
      }
    }

    if (!confirmed) return null;

    if (confirmed.isOpenMatch) {
      await this.createChallengeForBooking(this.prisma, confirmed, booking.verifiedAdmin).catch((e) =>
        console.error('Error creating open challenge for paid booking:', e),
      );
    }
    await this.recalculateDashboardMetrics(confirmed.verifiedAdminId);
    return confirmed;
  }

  /** Releases an unpaid hold immediately (player closed checkout or payment failed). */
  async releasePaymentHold(bookingId: number) {
    await this.prisma.turfBooking.updateMany({
      where: { id: bookingId, status: PENDING_PAYMENT_STATUS },
      data: { status: 'Cancelled', paymentMethod: 'Payment not completed' },
    });
  }

  async toggleBlockSlot(id: number, body: any) {
    const { date, timeSlot, reason, action, callerPhone, ownerPhone } = body || {};

    if (!date || !timeSlot) {
      throw new BadRequestException('Date and timeSlot are required to block/unblock a slot');
    }

    const cleanDate = String(date || '').trim();
    const cleanTimeSlot = String(timeSlot || '').trim().replace(/\s*-\s*/, ' - ');
    const cleanReason = String(reason || 'Under Maintenance').trim().slice(0, 80);

    if (cleanDate.length > 25 || cleanTimeSlot.length > 50) {
      throw new BadRequestException('Invalid date or timeSlot payload format');
    }

    const turf = await this.findVerifiedAdmin(id, true, false);
    if (!turf) {
      throw new NotFoundException(`Turf with ID ${id} not found`);
    }

    if (turf.isBookingHold || turf.status !== 'VERIFIED') {
      throw new BadRequestException('Cannot modify slot: venue is currently on booking hold or unverified');
    }

    // Authorization verification: if owner/caller phone provided, ensure ownership match
    const providedPhone = String(callerPhone || ownerPhone || '').replace(/\D/g, '').slice(-10);
    const cleanOwner = String(turf.ownerPhone || '').replace(/\D/g, '').slice(-10);
    const cleanAlt = String(turf.alternativePhone || '').replace(/\D/g, '').slice(-10);
    if (providedPhone && providedPhone !== cleanOwner && providedPhone !== cleanAlt) {
      throw new BadRequestException('Unauthorized: Provided credentials do not match turf venue operator');
    }

    const verifiedAdminId = turf.id;

    const existing = await this.prisma.blockedSlot.findFirst({
      where: {
        verifiedAdminId,
        date: cleanDate,
        timeSlot: {
          equals: cleanTimeSlot,
          mode: 'insensitive',
        },
      },
    });

    let isBlocked = false;

    if (action === 'unblock') {
      if (existing) {
        await this.prisma.blockedSlot.deleteMany({
          where: {
            verifiedAdminId,
            date: cleanDate,
            timeSlot: existing.timeSlot,
          },
        });
      }
      isBlocked = false;
    } else if (action === 'block') {
      // Cannot block a slot that is already booked by a customer
      const booked = await this.prisma.turfBooking.findFirst({
        where: {
          verifiedAdminId,
          date: cleanDate,
          timeSlot: {
            equals: cleanTimeSlot,
            mode: 'insensitive',
          },
          status: { not: 'Cancelled' },
        },
      });

      if (booked) {
        throw new BadRequestException(
          `Cannot block slot "${cleanTimeSlot}" because it is already booked by customer ${booked.customerName}.`,
        );
      }

      await this.prisma.blockedSlot.upsert({
        where: {
          verifiedAdminId_date_timeSlot: {
            verifiedAdminId,
            date: cleanDate,
            timeSlot: cleanTimeSlot,
          },
        },
        create: {
          verifiedAdminId,
          date: cleanDate,
          timeSlot: cleanTimeSlot,
          reason: cleanReason,
        },
        update: {
          reason: cleanReason,
        },
      });
      isBlocked = true;
    } else {
      // Default toggle behavior
      if (existing) {
        await this.prisma.blockedSlot.deleteMany({
          where: {
            verifiedAdminId,
            date: cleanDate,
            timeSlot: existing.timeSlot,
          },
        });
        isBlocked = false;
      } else {
        const booked = await this.prisma.turfBooking.findFirst({
          where: {
            verifiedAdminId,
            date: cleanDate,
            timeSlot: {
              equals: cleanTimeSlot,
              mode: 'insensitive',
            },
            status: { not: 'Cancelled' },
          },
        });

        if (booked) {
          throw new BadRequestException(
            `Cannot block slot "${cleanTimeSlot}" because it is already booked by customer ${booked.customerName}.`,
          );
        }

        await this.prisma.blockedSlot.upsert({
          where: {
            verifiedAdminId_date_timeSlot: {
              verifiedAdminId,
              date: cleanDate,
              timeSlot: cleanTimeSlot,
            },
          },
          create: {
            verifiedAdminId,
            date: cleanDate,
            timeSlot: cleanTimeSlot,
            reason: cleanReason,
          },
          update: {
            reason: cleanReason,
          },
        });
        isBlocked = true;
      }
    }

    const blockedCount = await this.prisma.blockedSlot.count({
      where: { verifiedAdminId, date: cleanDate },
    });

    await this.prisma.adminDashboard.upsert({
      where: { verifiedAdminId },
      create: {
        verifiedAdminId,
        blockedSlotsCount: blockedCount,
      },
      update: {
        blockedSlotsCount: blockedCount,
      },
    });

    return {
      success: true,
      isBlocked,
      message: isBlocked ? `Slot ${cleanTimeSlot} blocked for maintenance` : `Slot ${cleanTimeSlot} unblocked and now available`,
      blockedCount,
    };
  }

  async setSlotOffer(id: number, body: any) {
    const { date, timeSlot, offerString, offerType, discountPercent, originalPrice, offerPrice, tagLabel, remove, callerPhone, ownerPhone, adminPhone } = body || {};

    if (!date || !timeSlot) {
      throw new BadRequestException('Date and timeSlot are required to set slot offer');
    }

    const cleanDate = date.trim();
    const cleanTimeSlot = timeSlot.trim();

    const turf = await this.findVerifiedAdmin(id, false, false);
    if (!turf) {
      throw new NotFoundException(`Turf #${id} not found`);
    }

    const callerRaw = callerPhone || ownerPhone || adminPhone;
    if (callerRaw) {
      const cleanCaller = String(callerRaw).replace(/\D/g, '').slice(-10);
      const cleanOwner = String(turf.ownerPhone || '').replace(/\D/g, '').slice(-10);
      const cleanAlt = String(turf.alternativePhone || '').replace(/\D/g, '').slice(-10);
      if (cleanCaller !== cleanOwner && cleanCaller !== cleanAlt) {
        throw new BadRequestException('Security Alert: You do not have permission to modify slot offers for this turf.');
      }
    }

    const verifiedAdminId = turf.id;

    // Check if user wants to remove the offer
    if (remove === true || offerString === '' || (offerType === undefined && offerString === undefined && discountPercent === undefined && offerPrice === undefined)) {
      await this.prisma.slotOffer.deleteMany({
        where: {
          verifiedAdminId,
          date: cleanDate,
          timeSlot: cleanTimeSlot,
        },
      });
      return {
        success: true,
        message: `Offer removed from slot ${cleanTimeSlot}`,
        offer: null,
      };
    }

    let finalOfferType = 'PERCENT';
    let finalDiscountPercent: number = 20;
    let finalOriginalPrice: number = turf.dayRate || 1000;
    let finalOfferPrice: number = Math.round(finalOriginalPrice * 0.8);
    let finalTagLabel: string | null = null;
    let rawOfferString = offerString || '';

    if (offerString && typeof offerString === 'string' && offerString.includes('|')) {
      const parts = offerString.split('|');
      if (parts[0].toUpperCase() === 'PERCENT') {
        finalOfferType = 'PERCENT';
        finalDiscountPercent = parseFloat(parts[1]) || 20;
        finalTagLabel = parts.length > 2 && parts[2].trim() ? parts[2].trim() : 'Happy Hour';
        finalOriginalPrice = turf.dayRate || 1000;
        finalOfferPrice = Math.round(finalOriginalPrice * (1 - finalDiscountPercent / 100));
      } else if (parts[0].toUpperCase() === 'PRICE') {
        finalOfferType = 'PRICE';
        finalOriginalPrice = parseFloat(parts[1]) || (turf.dayRate || 1000);
        finalOfferPrice = parseFloat(parts[2]) || Math.round(finalOriginalPrice * 0.8);
        finalTagLabel = parts.length > 3 && parts[3].trim() ? parts[3].trim() : 'Special Price';
        finalDiscountPercent = finalOriginalPrice > 0 ? Math.round(((finalOriginalPrice - finalOfferPrice) / finalOriginalPrice) * 100) : 0;
      }
    } else {
      finalOfferType = (offerType || 'PERCENT').toUpperCase();
      if (finalOfferType === 'PERCENT') {
        finalDiscountPercent = Number(discountPercent) || 20;
        finalTagLabel = tagLabel || 'Happy Hour';
        finalOriginalPrice = Number(originalPrice) || turf.dayRate || 1000;
        finalOfferPrice = Math.round(finalOriginalPrice * (1 - finalDiscountPercent / 100));
        rawOfferString = `PERCENT|${finalDiscountPercent}|${finalTagLabel}`;
      } else {
        finalOfferType = 'PRICE';
        finalOriginalPrice = Number(originalPrice) || turf.dayRate || 1000;
        finalOfferPrice = Number(offerPrice) || Math.round(finalOriginalPrice * 0.8);
        finalTagLabel = tagLabel || 'Special Price';
        finalDiscountPercent = finalOriginalPrice > 0 ? Math.round(((finalOriginalPrice - finalOfferPrice) / finalOriginalPrice) * 100) : 0;
        rawOfferString = `PRICE|${finalOriginalPrice}|${finalOfferPrice}`;
      }
    }

    const offer = await this.prisma.slotOffer.upsert({
      where: {
        verifiedAdminId_date_timeSlot: {
          verifiedAdminId,
          date: cleanDate,
          timeSlot: cleanTimeSlot,
        },
      },
      create: {
        verifiedAdminId,
        date: cleanDate,
        timeSlot: cleanTimeSlot,
        offerType: finalOfferType,
        discountPercent: finalDiscountPercent,
        originalPrice: finalOriginalPrice,
        offerPrice: finalOfferPrice,
        tagLabel: finalTagLabel,
        rawOfferString,
      },
      update: {
        offerType: finalOfferType,
        discountPercent: finalDiscountPercent,
        originalPrice: finalOriginalPrice,
        offerPrice: finalOfferPrice,
        tagLabel: finalTagLabel,
        rawOfferString,
      },
    });

    return {
      success: true,
      message: `Offer applied to slot ${cleanTimeSlot}`,
      offer,
    };
  }

  async getUserBookings(phone?: string, name?: string) {
    const orConditions: any[] = [];
    const challengeOrConditions: any[] = [];

    // Bookings are matched by the player's phone number only. Matching by name leaked bookings
    // between different players who share a name, so `name` is intentionally ignored.
    void name;
    const cleanDigits = String(phone || '').replace(/\D/g, '');
    if (cleanDigits.length < 10) {
      return [];
    }
    const last10 = cleanDigits.slice(-10);
    const phoneVariants = Array.from(new Set([last10, `91${last10}`, `+91${last10}`, `+91 ${last10}`, String(phone).trim()]));
    orConditions.push({ customerPhone: { in: phoneVariants } });
    orConditions.push({ opponentPhone: { in: phoneVariants } });
    challengeOrConditions.push({ creatorPhone: { in: phoneVariants } });
    challengeOrConditions.push({ opponentContact: { in: phoneVariants } });

    const bookings = await this.prisma.turfBooking.findMany({
      where: {
        OR: orConditions,
        // Unpaid holds are not bookings yet; they expire or get confirmed by the payment flow.
        status: { not: PENDING_PAYMENT_STATUS },
      },
      include: {
        verifiedAdmin: {
          select: {
            id: true,
            venueName: true,
            neighborhoodArea: true,
            streetAddress: true,
            photoUrls: true,
          },
        },
      },
      orderBy: [
        { date: 'desc' },
        { createdAt: 'desc' },
      ],
    });

    // Check for matched open challenges for this user/opponent that might not yet be in bookings
    let acceptedChallenges: any[] = [];
    if (challengeOrConditions.length > 0) {
      acceptedChallenges = await this.prisma.openChallenge.findMany({
        where: {
          status: 'ACCEPTED',
          OR: challengeOrConditions,
        },
        orderBy: { createdAt: 'desc' },
      });
    }

    const { todayStr, currentMinutes } = getISTDateAndMinutes();

    const existingBookingIds = new Set<string>();

    const mappedBookings = bookings.map((b) => {
      const photos = normalizePhotoList(b.verifiedAdmin?.photoUrls);

      let isActive = false;
      const statusLower = (b.status || '').toLowerCase();
      if (statusLower !== 'cancelled' && statusLower !== 'completed' && statusLower !== 'not visited') {
        if (b.date > todayStr) {
          isActive = true;
        } else if (b.date === todayStr) {
          const endMin = parseSlotEndMinutes(b.timeSlot);
          if (endMin === -1) {
            isActive = true;
          } else {
            // Once current time reaches or passes slot end time, slot is completed
            isActive = currentMinutes < endMin;
          }
        }
      }

      const formalCode = b.bookingCode || `G24-BK-${b.id.toString().padStart(4, '0')}`;
      existingBookingIds.add(b.id.toString());
      existingBookingIds.add(formalCode);

      return {
        id: b.id,
        bookingId: formalCode,
        bookingCode: formalCode,
        verifiedAdminId: b.verifiedAdminId,
        turfId: b.verifiedAdminId,
        turfName: b.verifiedAdmin?.venueName || b.courtName || 'Turf Arena',
        courtName: b.courtName,
        sport: b.sport,
        date: b.date,
        timeSlot: b.timeSlot,
        amount: b.amount,
        paymentMethod: b.paymentMethod,
        status: b.status,
        customerName: b.customerName,
        customerPhone: b.customerPhone,
        isOpenMatch: b.isOpenMatch,
        openMatchStatus: b.openMatchStatus,
        teamName: b.teamName,
        teamSize: b.teamSize,
        opponentName: b.opponentName,
        opponentPhone: b.opponentPhone,
        isActive,
        location: b.verifiedAdmin
          ? `${b.verifiedAdmin.neighborhoodArea} • ${b.verifiedAdmin.streetAddress}`
          : (b.courtName || 'Main Arena'),
        imageUrl: photos[0] || '',
        photoUrls: photos,
        createdAt: b.createdAt,
        updatedAt: b.updatedAt,
      };
    });

    // Append any accepted challenges not already represented by a TurfBooking
    for (const c of acceptedChallenges) {
      if (c.bookingId && existingBookingIds.has(c.bookingId.toString())) {
        continue;
      }
      if (existingBookingIds.has(c.id)) {
        continue;
      }

      let isActive = false;
      if (c.status !== 'CANCELLED' && c.status !== 'COMPLETED') {
        if (c.date > todayStr) {
          isActive = true;
        } else if (c.date === todayStr) {
          const endMin = parseSlotEndMinutes(c.time);
          if (endMin === -1) {
            isActive = true;
          } else {
            isActive = currentMinutes < endMin;
          }
        }
      }

      mappedBookings.push({
        id: c.bookingId || c.id,
        bookingId: `G24-CH-${c.id}`,
        bookingCode: `G24-CH-${c.id}`,
        verifiedAdminId: c.turfId ?? null,
        turfId: c.turfId ?? null,
        turfName: c.turfName,
        courtName: 'Main Arena',
        sport: c.sport,
        date: c.date,
        timeSlot: c.time,
        amount: 0,
        paymentMethod: 'UPI',
        status: c.status === 'COMPLETED' ? 'Completed' : 'Confirmed',
        customerName: c.challengerName,
        customerPhone: c.creatorPhone,
        isOpenMatch: true,
        openMatchStatus: 'OPPONENT_JOINED',
        teamName: c.challengerName,
        teamSize: c.teamSize,
        opponentName: c.opponentName,
        opponentPhone: c.opponentContact,
        isActive,
        location: c.location || 'Madurai',
        imageUrl: '',
        photoUrls: [],
        createdAt: c.createdAt,
        updatedAt: c.createdAt,
      });
    }

    return mappedBookings;
  }

  async recalculateDashboardMetrics(verifiedAdminId: number) {
    try {
      const { todayStr, currentMinutes } = getISTDateAndMinutes();
      const now = new Date();
      const monthPrefix = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

      const allBookings = await this.prisma.turfBooking.findMany({
        where: { verifiedAdminId },
      });

      // Automatically transition un-checked past bookings to 'Not Visited' in database
      const unvisitedPast = allBookings.filter((b) => {
        const s = (b.status || '').toLowerCase();
        if (s === 'cancelled' || s === 'completed' || s === 'not visited' || s === 'checked in') return false;
        if (s === PENDING_PAYMENT_STATUS.toLowerCase()) return false;
        return isBookingSlotEnded(b.date, b.timeSlot, todayStr, currentMinutes);
      });

      if (unvisitedPast.length > 0) {
        await this.prisma.turfBooking.updateMany({
          where: { id: { in: unvisitedPast.map((b) => b.id) } },
          data: { status: 'Not Visited' },
        }).catch((err) => console.error('Error updating unvisited bookings:', err));
        for (const b of unvisitedPast) {
          b.status = 'Not Visited';
        }
      }

      // Automatically transition checked-in past bookings to 'Completed' in database
      const checkedInPast = allBookings.filter((b) => {
        const s = (b.status || '').toLowerCase();
        if (s !== 'checked in') return false;
        return isBookingSlotEnded(b.date, b.timeSlot, todayStr, currentMinutes);
      });

      if (checkedInPast.length > 0) {
        await this.prisma.turfBooking.updateMany({
          where: { id: { in: checkedInPast.map((b) => b.id) } },
          data: { status: 'Completed' },
        }).catch((err) => console.error('Error updating completed bookings:', err));
        for (const b of checkedInPast) {
          b.status = 'Completed';
        }
      }

      const activeBookings = allBookings.filter((b) => isRevenueBooking(b));
      const cancelledBookings = allBookings.filter(
        (b) => b.status === 'Cancelled' && b.paymentMethod !== 'Payment not completed',
      );
      const todayBookings = activeBookings.filter((b) => b.date === todayStr);
      const monthBookings = activeBookings.filter((b) => b.date && b.date.startsWith(monthPrefix));

      const countBookingSlots = (timeSlot?: string): number => {
        if (!timeSlot) return 1;
        const parts = timeSlot.split(',').map((s) => s.trim()).filter(Boolean);
        return parts.length > 0 ? parts.length : 1;
      };

      const todayCount = todayBookings.length;
      const todayPaid = todayBookings.filter((b) => !b.paymentMethod?.toLowerCase().includes('cash')).length;
      const todayCash = todayCount - todayPaid;
      const monthTotal = monthBookings.length;
      const monthRev = monthBookings.reduce((sum, b) => sum + (Number(b.amount) || 0), 0);
      const bookedSlots = todayBookings.reduce((acc, b) => acc + countBookingSlots(b.timeSlot), 0);

      const blockedCount = await this.prisma.blockedSlot.count({
        where: { verifiedAdminId, date: todayStr },
      });

      const dash = await this.prisma.adminDashboard.findUnique({
        where: { verifiedAdminId },
      });

      const openingTime = dash?.openingTime || '05:00 AM';
      const closingTime = dash?.closingTime || '11:00 PM';
      const allSlots = generateTimeSlots(openingTime, closingTime);
      const totalSlots = allSlots.length || 18;

      const passedSlots = allSlots.filter((slot) => {
        const startMin = parseSlotStartMinutes(slot);
        return startMin !== -1 && currentMinutes >= startMin;
      });

      const upcomingBookedSlots = todayBookings.filter((b: any) => {
        const startMin = parseSlotStartMinutes(b.timeSlot);
        return startMin === -1 || currentMinutes < startMin;
      });
      const upcomingBookedSlotsCount = upcomingBookedSlots.reduce(
        (acc: number, b: any) => acc + countBookingSlots(b.timeSlot),
        0
      );

      const freeSlots = Math.max(
        0,
        totalSlots - passedSlots.length - upcomingBookedSlotsCount - blockedCount
      );
      const occPercent = totalSlots > 0 ? Math.round((bookedSlots / totalSlots) * 100) : 0;
      const slotsBadge = `${occPercent}% Full`;

      const realCancelledCount = cancelledBookings.length;
      const shiftedCount = dash?.shiftedCount || 0;
      const cancelledTotal = realCancelledCount + shiftedCount;

      await this.prisma.adminDashboard.upsert({
        where: { verifiedAdminId },
        create: {
          verifiedAdminId,
          todayBookingsCount: todayCount,
          todayPaidBookings: todayPaid,
          todayCashBookings: todayCash,
          todayBookingsGrowth: todayCount > 0 ? `+${todayCount} Today` : '0% Today',
          monthRevenue: monthRev,
          monthTotalBookings: monthTotal,
          revenueBadge: `₹${monthRev.toLocaleString('en-IN')} GMV`,
          freeSlotsCount: freeSlots,
          bookedSlotsCount: bookedSlots,
          blockedSlotsCount: blockedCount,
          slotsBadge,
          cancelledCount: realCancelledCount,
          shiftedCount,
          cancelledTotal,
          cancelledBadge: `${cancelledTotal} Tracked`,
        },
        update: {
          todayBookingsCount: todayCount,
          todayPaidBookings: todayPaid,
          todayCashBookings: todayCash,
          todayBookingsGrowth: todayCount > 0 ? `+${todayCount} Today` : '0% Today',
          monthRevenue: monthRev,
          monthTotalBookings: monthTotal,
          revenueBadge: `₹${monthRev.toLocaleString('en-IN')} GMV`,
          freeSlotsCount: freeSlots,
          bookedSlotsCount: bookedSlots,
          blockedSlotsCount: blockedCount,
          slotsBadge,
          cancelledCount: realCancelledCount,
          shiftedCount,
          cancelledTotal,
          cancelledBadge: `${cancelledTotal} Tracked`,
        },
      });
    } catch (e) {
      console.error('Error recalculating admin dashboard:', e);
    }
  }

  async cancelBooking(bookingId: number, body?: any, adminKey?: string) {
    const booking = await this.prisma.turfBooking.findUnique({
      where: { id: bookingId },
      include: {
        verifiedAdmin: true,
      },
    });
    if (!booking) {
      throw new NotFoundException(`Booking #${bookingId} not found`);
    }

    // Security check: Super Admin OR Customer who booked OR Turf Owner
    const isSuperAdmin = adminKey === (process.env.SUPER_ADMIN_KEY || 'superadmin-secret-key-games24');
    if (!isSuperAdmin) {
      const callerPhone = String(body?.callerPhone || body?.phone || body?.customerPhone || body?.ownerPhone || '').replace(/\D/g, '').slice(-10);
      if (!callerPhone) {
        throw new BadRequestException('Security Alert: Caller phone number is required to cancel this booking.');
      }

      const bookingCustomerPhone = String(booking.customerPhone || '').replace(/\D/g, '').slice(-10);
      const ownerPhone = String(booking.verifiedAdmin?.ownerPhone || '').replace(/\D/g, '').slice(-10);
      const altPhone = String(booking.verifiedAdmin?.alternativePhone || '').replace(/\D/g, '').slice(-10);

      const isCustomer = Boolean(bookingCustomerPhone && callerPhone === bookingCustomerPhone);
      const isOwner = Boolean((ownerPhone && callerPhone === ownerPhone) || (altPhone && callerPhone === altPhone));

      if (!isCustomer && !isOwner) {
        throw new BadRequestException('Security Alert: You do not have permission to cancel this booking.');
      }
    }

    // 3-hour cancellation rule:
    const { todayStr, currentMinutes } = getISTDateAndMinutes();
    if (booking.date < todayStr) {
      throw new BadRequestException('Past bookings cannot be cancelled.');
    }
    if (booking.date === todayStr) {
      const startMin = parseSlotStartMinutes(booking.timeSlot);
      if (startMin !== -1) {
        // Must be at least 180 minutes (3 hours) prior to slot start time
        if (currentMinutes > startMin - 180) {
          throw new BadRequestException('Bookings can only be cancelled at least 3 hours prior to the slot start time.');
        }
      }
    }

    const updated = await this.prisma.turfBooking.update({
      where: { id: bookingId },
      data: { status: 'Cancelled' },
    });

    await this.recalculateDashboardMetrics(booking.verifiedAdminId);

    return {
      success: true,
      message: 'Booking cancelled successfully',
      booking: updated,
    };
  }

  private parseBookingWindow(dateStr: string, timeSlot: string) {
    try {
      if (!dateStr || !timeSlot) return null;

      // Extract Year, Month, Day (handles "2026-11-20", "2026/11/20", "10-11-2026", or standard dates)
      let year = 0;
      let month = 0;
      let day = 0;

      const trimmedDate = dateStr.trim();
      const isoParts = trimmedDate.split(/[-/]/).map((p) => parseInt(p, 10));
      if (isoParts.length >= 3) {
        if (isoParts[0] > 1000) {
          // YYYY-MM-DD
          year = isoParts[0];
          month = isoParts[1];
          day = isoParts[2];
        } else if (isoParts[2] > 1000) {
          // DD-MM-YYYY
          day = isoParts[0];
          month = isoParts[1];
          year = isoParts[2];
        }
      }

      if (!year || !month || !day) {
        const parsed = new Date(trimmedDate);
        if (!isNaN(parsed.getTime())) {
          // If server operates in UTC, adjust by Indian Standard Time (+05:30) to preserve local day
          const istDate = new Date(parsed.getTime() + (5 * 60 + 30) * 60 * 1000);
          year = istDate.getUTCFullYear();
          month = istDate.getUTCMonth() + 1;
          day = istDate.getUTCDate();
        }
      }

      if (!year || !month || !day) return null;

      // Support multiple comma-separated slots e.g. "05:00 PM - 06:00 PM, 06:00 PM - 07:00 PM"
      const subSlots = timeSlot.split(',').map((s) => s.trim()).filter(Boolean);
      const firstSlot = subSlots[0] || timeSlot;
      const lastSlot = subSlots[subSlots.length - 1] || timeSlot;

      // Split slot range by '-' or '–' or 'to'
      const splitSlotRange = (s: string) => {
        return s.split(/\s*[-–]\s*|\s+to\s+/i).map((p) => p.trim()).filter(Boolean);
      };

      const startParts = splitSlotRange(firstSlot);
      const endParts = splitSlotRange(lastSlot);

      const rawStartStr = startParts[0] || firstSlot;
      const rawEndStr =
        endParts.length > 1
          ? endParts[endParts.length - 1]
          : startParts.length > 1
          ? startParts[startParts.length - 1]
          : null;

      const hasPm = (s: string) => /pm/i.test(s);
      const hasAm = (s: string) => /am/i.test(s);

      const endHasPm = rawEndStr ? hasPm(rawEndStr) : false;
      const startHasExplicitAmPm = hasPm(rawStartStr) || hasAm(rawStartStr);

      // If end time is PM and start time did not specify AM/PM, inherit PM when start <= end
      let inheritPmForStart = false;
      if (endHasPm && !startHasExplicitAmPm) {
        const startRawDigit = parseInt(rawStartStr.replace(/[^\d:]/g, '').split(':')[0], 10);
        const endRawDigit = parseInt((rawEndStr || '').replace(/[^\d:]/g, '').split(':')[0], 10);
        if (!isNaN(startRawDigit) && !isNaN(endRawDigit)) {
          if (startRawDigit <= endRawDigit || endRawDigit === 12) {
            inheritPmForStart = true;
          }
        }
      }

      const parseTime = (tStr: string, inheritPm: boolean = false) => {
        if (!tStr) return null;
        let isPM = hasPm(tStr);
        let isAM = hasAm(tStr);
        if (!isPM && !isAM && inheritPm) {
          isPM = true;
        }

        const digitsOnly = tStr.replace(/[^\d:]/g, '');
        const parts = digitsOnly.split(':');
        const hRaw = parseInt(parts[0], 10);
        if (isNaN(hRaw)) return null;
        const mRaw = parts.length > 1 ? parseInt(parts[1], 10) : 0;
        let hours = hRaw;
        const minutes = !isNaN(mRaw) ? mRaw : 0;

        // In turf operations context, unspecified hour between 1 and 7 is PM (afternoon/evening)
        if (!isPM && !isAM) {
          if (hours >= 1 && hours <= 7) {
            hours += 12;
          }
        } else {
          if (isPM && hours < 12) hours += 12;
          if (isAM && hours === 12) hours = 0;
        }

        return { hours, minutes };
      };

      const start = parseTime(rawStartStr, inheritPmForStart);
      if (!start) return null;

      const end = rawEndStr ? parseTime(rawEndStr, false) : null;
      const endHours = end ? end.hours : (start.hours + 1) % 24;
      const endMinutes = end ? end.minutes : start.minutes;

      // Construct accurate UTC timestamps based on Indian Standard Time (IST, UTC+05:30)
      // This prevents server UTC timezone offset mismatches (which previously caused "you have more time" error)
      const istOffsetMs = (5 * 60 + 30) * 60 * 1000;

      const startUtcMs = Date.UTC(year, month - 1, day, start.hours, start.minutes, 0, 0) - istOffsetMs;
      const startDateTime = new Date(startUtcMs);

      let endUtcMs = Date.UTC(year, month - 1, day, endHours, endMinutes, 0, 0) - istOffsetMs;
      if (endUtcMs <= startUtcMs) {
        // Crosses midnight or wrapped around
        endUtcMs += 24 * 60 * 60 * 1000;
      }
      const endDateTime = new Date(endUtcMs);

      // Check-in opens 20 minutes before slot start
      const checkInOpensAt = new Date(startDateTime.getTime() - 20 * 60 * 1000);
      // Check-in closes 30 minutes after slot end (allows check-in for ongoing match up to 30 mins after end)
      const checkInClosesAt = new Date(endDateTime.getTime() + 30 * 60 * 1000);

      const formatTimeIST = (d: Date) => {
        try {
          return new Intl.DateTimeFormat('en-IN', {
            timeZone: 'Asia/Kolkata',
            hour: '2-digit',
            minute: '2-digit',
            hour12: true,
          }).format(d);
        } catch {
          const ist = new Date(d.getTime() + (5 * 60 + 30) * 60 * 1000);
          let h = ist.getUTCHours();
          const m = ist.getUTCMinutes();
          const ampm = h >= 12 ? 'PM' : 'AM';
          h = h % 12;
          if (h === 0) h = 12;
          const hh = h.toString().padStart(2, '0');
          const mm = m.toString().padStart(2, '0');
          return `${hh}:${mm} ${ampm}`;
        }
      };

      return {
        startDateTime,
        endDateTime,
        checkInOpensAt,
        checkInClosesAt,
        opensAtStr: formatTimeIST(checkInOpensAt),
        startStr: formatTimeIST(startDateTime),
        endStr: formatTimeIST(endDateTime),
      };
    } catch {
      return null;
    }
  }

  async checkInBooking(verifiedAdminId?: number, body?: any) {
    // 1. Robust body parsing (handles string, JSON, or pre-parsed object)
    let parsedBody: any = body;
    if (typeof body === 'string') {
      try {
        parsedBody = JSON.parse(body);
      } catch {
        parsedBody = { searchId: body.trim() };
      }
    } else if (body && typeof body === 'object' && typeof body.body === 'string') {
      try {
        parsedBody = { ...body, ...JSON.parse(body.body) };
      } catch {}
    }

    const b = parsedBody || {};

    // 2. Extract potential identifiers from any key
    let candidate =
      b.bookingId ||
      b.bookingCode ||
      b.ticketToken ||
      b.rawCode ||
      b.qrPayload ||
      b.qrData ||
      b.code ||
      b.id ||
      b.numericId ||
      b.payload ||
      b.searchId ||
      b.data ||
      b.text ||
      b.token;

    // If candidate itself is a JSON string from QR code pass:
    if (typeof candidate === 'string' && candidate.trim().startsWith('{')) {
      try {
        const innerJson = JSON.parse(candidate.trim());
        if (innerJson && typeof innerJson === 'object') {
          candidate =
            innerJson.bookingCode ||
            innerJson.bookingId ||
            innerJson.numericId ||
            innerJson.id ||
            candidate;

          if (!verifiedAdminId && (innerJson.turfId || innerJson.verifiedAdminId)) {
            verifiedAdminId = Number(innerJson.turfId || innerJson.verifiedAdminId);
          }
        }
      } catch {}
    }

    if (!verifiedAdminId && (b.turfId || b.verifiedAdminId)) {
      verifiedAdminId = Number(b.turfId || b.verifiedAdminId);
    }

    if (!candidate || String(candidate).trim().length === 0) {
      throw new BadRequestException('Booking ID or QR payload is required for check-in');
    }

    const cleanSearchId = String(candidate).trim();

    // 3. Extract numeric ID from the LAST group of digits (e.g. G24-BK-0013 -> 13)
    let numericId: number | undefined;
    if (typeof candidate === 'number' && Number.isInteger(candidate)) {
      numericId = candidate;
    } else {
      const lastDigitsMatch = cleanSearchId.match(/(\d+)(?!.*\d)/);
      if (lastDigitsMatch) {
        numericId = parseInt(lastDigitsMatch[1], 10);
      }
    }

    // 4. Find booking in database globally across venues
    const booking = await this.prisma.turfBooking.findFirst({
      where: {
        OR: [
          ...(numericId ? [{ id: numericId }] : []),
          { bookingCode: { equals: cleanSearchId, mode: 'insensitive' } },
        ],
      },
      include: { verifiedAdmin: true },
    });

    if (!booking) {
      return {
        success: false,
        valid: false,
        message: `Booking ticket "${cleanSearchId}" not found in database!`,
      };
    }

    // 5. Cross-Branch & Master Account Verification:
    // If the scanning owner has multiple branches under the same master phone or parent turf,
    // allow cross-branch check-in for ANY venue belonging to that owner's turf group!
    const scannerOwnerPhone = b.ownerPhone || b.masterPhone;
    const scannerTurfId = verifiedAdminId || b.scannerAdminId || b.turfId;

        let allowedVenueNames: string[] = [];

    if (scannerOwnerPhone || (scannerTurfId && !isNaN(Number(scannerTurfId)))) {
      const cleanPhone = String(scannerOwnerPhone || '').trim().replace(/\D/g, '');
      const last10 = cleanPhone.length >= 10 ? cleanPhone.slice(-10) : cleanPhone;
      const parsedScannerId = Number(scannerTurfId);

      // Find all turfs belonging to this owner / master phone
      const matchedTurfs = await this.prisma.verifiedAdmin.findMany({
        where: {
          OR: [
            ...(last10 ? [
              { ownerPhone: cleanPhone },
              { ownerPhone: last10 },
              { ownerPhone: { contains: last10 } },
            ] : []),
            ...(!isNaN(parsedScannerId) ? [
              { id: parsedScannerId },
              { parentTurfId: parsedScannerId },
            ] : []),
          ],
        },
        select: { id: true, venueName: true, parentTurfId: true, ownerPhone: true },
      });

      const allowedIds = new Set<number>();
      for (const t of matchedTurfs) {
        allowedIds.add(t.id);
        if (t.parentTurfId) allowedIds.add(t.parentTurfId);
        allowedVenueNames.push(t.venueName);
      }

      // Also include any child branches whose parentTurfId is one of these
      if (allowedIds.size > 0) {
        const childBranches = await this.prisma.verifiedAdmin.findMany({
          where: { parentTurfId: { in: Array.from(allowedIds) } },
          select: { id: true, venueName: true },
        });
        for (const cb of childBranches) {
          allowedIds.add(cb.id);
          allowedVenueNames.push(cb.venueName);
        }
      }

      // Check if the booked venue is part of this owner's branch network
      if (allowedIds.has(booking.verifiedAdminId)) {
              } else {
        // Pass was booked for a completely different turf owner
        const bookedVenue = booking.verifiedAdmin?.venueName || 'another venue';
        return {
          success: false,
          valid: false,
          message: `Invalid Pass! This booking was booked for a different turf ("${bookedVenue}") and does not belong to your turf account.`,
        };
      }
    } else {
      // If no scanner context provided, ensure it matches requested verifiedAdminId
      if (verifiedAdminId && !isNaN(verifiedAdminId) && booking.verifiedAdminId !== verifiedAdminId) {
        const bookedVenue = booking.verifiedAdmin?.venueName || 'another venue';
        return {
          success: false,
          valid: false,
          message: `Invalid Pass! This booking is for "${bookedVenue}" and not recognized under this venue.`,
        };
      }
          }

    verifiedAdminId = booking.verifiedAdminId;

    const formalCode = booking.bookingCode || `G24-BK-${booking.id.toString().padStart(4, '0')}`;
    const venueName = booking.verifiedAdmin?.venueName || booking.courtName || 'Turf Arena';
    const window = this.parseBookingWindow(booking.date, booking.timeSlot);

    if (booking.status?.toLowerCase() === 'cancelled') {
      return {
        success: false,
        valid: false,
        booking: {
          ...booking,
          bookingCode: formalCode,
          bookingId: formalCode,
          turfName: venueName,
          courtName: venueName,
          startTime: window?.startStr || '',
          endTime: window?.endStr || '',
          slotTime: booking.timeSlot,
        },
        message: `Entry Denied! Booking ${formalCode} (${booking.customerName}) was cancelled.`,
      };
    }

    const formatTimestamp = (d: Date) => {
      try {
        return new Intl.DateTimeFormat('en-IN', {
          timeZone: 'Asia/Kolkata',
          day: 'numeric',
          month: 'short',
          hour: '2-digit',
          minute: '2-digit',
          hour12: true,
        }).format(d);
      } catch {
        const ist = new Date(d.getTime() + (5 * 60 + 30) * 60 * 1000);
        let h = ist.getUTCHours();
        const m = ist.getUTCMinutes();
        const ampm = h >= 12 ? 'PM' : 'AM';
        h = h % 12;
        if (h === 0) h = 12;
        const mm = m.toString().padStart(2, '0');
        const hh = h.toString().padStart(2, '0');
        const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        return `${ist.getUTCDate()} ${months[ist.getUTCMonth()]}, ${hh}:${mm} ${ampm}`;
      }
    };

    // 1. Single-Use Verification & Multi-Slot Split Session Re-Entry Check
    const now = new Date();
    const subSlots = (booking.timeSlot || '')
      .split(',')
      .map((s: string) => s.trim())
      .filter(Boolean);

    const alreadyChecked = booking.status?.toLowerCase() === 'checked in';
    if (alreadyChecked) {
      // Check if this is a multi-slot booking where a later slot is currently active for re-entry
      if (subSlots.length > 1) {
        let activeReEntryIndex = -1;
        let activeReEntryWindow: any = null;

        for (let i = 1; i < subSlots.length; i++) {
          const sw = this.parseBookingWindow(booking.date, subSlots[i]);
          if (sw && now >= sw.checkInOpensAt && now <= sw.checkInClosesAt) {
            const lastUpdated = booking.updatedAt ? new Date(booking.updatedAt) : new Date(0);
            if (lastUpdated < sw.checkInOpensAt) {
              activeReEntryIndex = i;
              activeReEntryWindow = sw;
              break;
            }
          }
        }

        if (activeReEntryIndex > 0 && activeReEntryWindow) {
          const updated = await this.prisma.turfBooking.update({
            where: { id: booking.id },
            data: {
              updatedAt: new Date(),
              bookingCode: formalCode,
            },
          });

          const verifiedAtStr = formatTimestamp(new Date());

          return {
            success: true,
            valid: true,
            isReEntry: true,
            slotIndex: activeReEntryIndex + 1,
            totalSlots: subSlots.length,
            reEntrySlot: subSlots[activeReEntryIndex],
            alreadyCheckedIn: false,
            notYetOpen: false,
            checkedInAt: verifiedAtStr,
            startTime: activeReEntryWindow.startStr,
            endTime: activeReEntryWindow.endStr,
            slotTime: subSlots[activeReEntryIndex],
            date: booking.date,
            booking: {
              ...updated,
              bookingCode: formalCode,
              bookingId: formalCode,
              turfName: venueName,
              courtName: venueName,
              checkedInAt: verifiedAtStr,
              startTime: activeReEntryWindow.startStr,
              endTime: activeReEntryWindow.endStr,
              slotTime: booking.timeSlot,
              date: booking.date,
              isReEntry: true,
              slotIndex: activeReEntryIndex + 1,
              totalSlots: subSlots.length,
            },
            message: `Re-entry verified for Slot ${activeReEntryIndex + 1} (${subSlots[activeReEntryIndex]})! Welcome back 🎉`,
          };
        }
      }

      const checkedInTimeStr = booking.updatedAt
        ? formatTimestamp(new Date(booking.updatedAt))
        : 'Earlier today';

      return {
        success: false,
        valid: true,
        alreadyCheckedIn: true,
        notYetOpen: false,
        checkedInAt: checkedInTimeStr,
        startTime: window?.startStr || '',
        endTime: window?.endStr || '',
        slotTime: booking.timeSlot,
        date: booking.date,
        booking: {
          ...booking,
          bookingCode: formalCode,
          bookingId: formalCode,
          turfName: venueName,
          courtName: venueName,
          checkedInAt: checkedInTimeStr,
          startTime: window?.startStr || '',
          endTime: window?.endStr || '',
          slotTime: booking.timeSlot,
          date: booking.date,
        },
        message: `Pass Already Verified ⚠️! Gate check-in was previously recorded at ${checkedInTimeStr}. Single-use entry pass.`,
      };
    }

    // 2. Timing Window Check: QR scan ONLY verifies 10-20 minutes before slot start

    if (window) {
      if (now < window.checkInOpensAt) {
        // Scanned before the 10-20 min window: Do NOT verify! Show time details only
        const diffMs = window.checkInOpensAt.getTime() - now.getTime();
        const minsLeft = Math.max(1, Math.ceil(diffMs / (60 * 1000)));
        const hoursLeft = Math.floor(minsLeft / 60);
        const remMins = minsLeft % 60;
        const countdownStr = hoursLeft > 0 ? `${hoursLeft}h ${remMins}m` : `${minsLeft} mins`;

        return {
          success: false,
          valid: true,
          notYetOpen: true,
          alreadyCheckedIn: false,
          opensAt: window.opensAtStr,
          startTime: window.startStr,
          endTime: window.endStr,
          slotTime: booking.timeSlot,
          bookingDate: booking.date,
          minsUntilOpen: minsLeft,
          countdownStr,
          booking: {
            ...booking,
            bookingCode: formalCode,
            bookingId: formalCode,
            turfName: venueName,
            courtName: venueName,
            opensAt: window.opensAtStr,
            startTime: window.startStr,
            endTime: window.endStr,
            slotTime: booking.timeSlot,
            date: booking.date,
          },
          message: `Check-in window not open yet ⏳. QR scan unlocks 15-20 mins before slot start at ${window.opensAtStr} (in ${countdownStr}).`,
        };
      }

      if (now > window.checkInClosesAt) {
        // Past slot end time
        return {
          success: false,
          valid: false,
          expired: true,
          alreadyCheckedIn: false,
          notYetOpen: false,
          startTime: window.startStr,
          endTime: window.endStr,
          booking: {
            ...booking,
            bookingCode: formalCode,
            bookingId: formalCode,
            turfName: venueName,
            courtName: venueName,
            startTime: window.startStr,
            endTime: window.endStr,
            slotTime: booking.timeSlot,
            date: booking.date,
          },
          message: `Booking Pass Expired ❌! Slot (${booking.timeSlot} on ${booking.date}) has already ended.`,
        };
      }
    }

    // 3. Valid Check-in during the 10-20m window (First time entry)
    const updated = await this.prisma.turfBooking.update({
      where: { id: booking.id },
      data: {
        status: 'Checked In',
        bookingCode: formalCode,
      },
    });

    if (verifiedAdminId) {
      await this.recalculateDashboardMetrics(verifiedAdminId);
    }

    const verifiedAtStr = formatTimestamp(new Date());

    return {
      success: true,
      valid: true,
      alreadyCheckedIn: false,
      notYetOpen: false,
      checkedInAt: verifiedAtStr,
      startTime: window?.startStr || '',
      endTime: window?.endStr || '',
      slotTime: booking.timeSlot,
      date: booking.date,
      booking: {
        ...updated,
        bookingCode: formalCode,
        bookingId: formalCode,
        turfName: venueName,
        courtName: venueName,
        checkedInAt: verifiedAtStr,
        startTime: window?.startStr || '',
        endTime: window?.endStr || '',
        slotTime: booking.timeSlot,
        date: booking.date,
      },
      message: `Gate check-in confirmed for ${booking.customerName}! (${formalCode}) 🎉`,
    };
  }

  async getTurfSubscription(id: number) {
    const turf = await this.findVerifiedAdmin(id, true);
    if (!turf) {
      throw new NotFoundException(`Turf with ID ${id} not found`);
    }

    const isSubscribed = !turf.isBookingHold && turf.status === 'VERIFIED';
    const now = new Date();

    // Dynamically calculate the monthly billing cycle based on verification/registration day
    const baseDate = turf.verifiedAt ? new Date(turf.verifiedAt) : new Date(turf.createdAt);
    const billingDay = Math.min(Math.max(1, baseDate.getDate()), 28);

    let nextRenew = new Date(now.getFullYear(), now.getMonth(), billingDay, 23, 59, 59);
    if (nextRenew.getTime() <= now.getTime()) {
      nextRenew = new Date(now.getFullYear(), now.getMonth() + 1, billingDay, 23, 59, 59);
    }

    const diffTime = nextRenew.getTime() - now.getTime();
    const calculatedDays = Math.max(1, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));
    const daysRemaining = isSubscribed ? calculatedDays : 0;
    const isEndingSoon = isSubscribed && daysRemaining <= 3 && daysRemaining > 0;
    const isBlocked = !isSubscribed || daysRemaining <= 0;

    const renewDateStr = nextRenew.toLocaleDateString('en-GB', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });

    const prevMonth1 = new Date(nextRenew.getFullYear(), nextRenew.getMonth() - 1, billingDay);
    const prevMonth2 = new Date(nextRenew.getFullYear(), nextRenew.getMonth() - 2, billingDay);

    const fmt = (d: Date) =>
      d.toLocaleDateString('en-GB', { day: '2-digit', month: 'short', year: 'numeric' });
    const fmtId = (d: Date) =>
      `SUB-${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;

    const history = [
      {
        id: fmtId(prevMonth1),
        date: `${fmt(prevMonth1)}, 10:15 AM`,
        baseAmount: 1000.0,
        gstAmount: 180.0,
        totalAmount: 1180.0,
        paymentMethod: 'UPI (GPay / PhonePe)',
        status: isSubscribed ? 'Paid & Active' : 'Expired',
        validPeriod: `${fmt(prevMonth1)} - ${fmt(nextRenew)}`,
        receiptNumber: `RCP-${turf.id}-${fmtId(prevMonth1)}`,
      },
      {
        id: fmtId(prevMonth2),
        date: `${fmt(prevMonth2)}, 11:30 AM`,
        baseAmount: 1000.0,
        gstAmount: 180.0,
        totalAmount: 1180.0,
        paymentMethod: 'UPI (Auto-Pay)',
        status: 'Completed',
        validPeriod: `${fmt(prevMonth2)} - ${fmt(prevMonth1)}`,
        receiptNumber: `RCP-${turf.id}-${fmtId(prevMonth2)}`,
      },
    ];

    return {
      turfId: turf.id,
      venueName: turf.venueName,
      ownerName: turf.ownerName,
      ownerPhone: turf.ownerPhone,
      planName: 'Monthly Turf Partner Subscription',
      baseFee: 1000.0,
      gstRate: 18,
      gstAmount: 180.0,
      totalAmount: 1180.0,
      isSubscriptionActive: isSubscribed,
      status: isSubscribed ? 'ACTIVE' : 'EXPIRED',
      isLiveOnPlayerApp: isSubscribed,
      daysRemaining,
      isEndingSoon,
      isBlocked,
      billingCycle: 'Monthly',
      nextBillingDate: renewDateStr,
      history,
      description: 'Platform listing fee for turf discovery and slot bookings on Games24 Player App.',
    };
  }

  async payTurfSubscription(id: number, body: any) {
    const turf = await this.findVerifiedAdmin(id, true);
    if (!turf) {
      throw new NotFoundException(`Turf with ID ${id} not found`);
    }

    // Activate subscription and unhold turf so it is visible to players
    const updated = await this.prisma.verifiedAdmin.update({
      where: { id: turf.id },
      data: {
        isBookingHold: false,
        status: 'VERIFIED',
      },
      include: { dashboard: true },
    });

    const now = new Date();
    const nextRenew = new Date(now.getFullYear(), now.getMonth() + 1, now.getDate());
    const renewDateStr = nextRenew.toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });

    const newPayment = {
      id: `SUB-${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`,
      date: now.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }),
      baseAmount: 1000.0,
      gstAmount: 180.0,
      totalAmount: 1180.0,
      paymentMethod: body?.paymentMethod || 'UPI (GPay)',
      status: 'Paid & Active',
      validPeriod: `${now.toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' })} - ${renewDateStr}`,
      receiptNumber: `RCP-SUB-${now.getTime() % 100000}`,
    };

    return {
      success: true,
      message: 'Monthly subscription of ₹1,180 (₹1,000 + 18% GST) paid successfully. Your turf is now LIVE on Games24 Player App and owner access is unlocked!',
      subscription: {
        turfId: updated.id,
        venueName: updated.venueName,
        baseFee: 1000.0,
        gstRate: 18,
        gstAmount: 180.0,
        totalAmount: 1180.0,
        isSubscriptionActive: true,
        status: 'ACTIVE',
        isLiveOnPlayerApp: true,
        daysRemaining: 30,
        isEndingSoon: false,
        isBlocked: false,
        paidAt: now.toISOString(),
        paymentMethod: body?.paymentMethod || 'UPI',
        utr: body?.utr || `UPI${Date.now()}`,
        nextBillingDate: renewDateStr,
        newPayment,
      },
    };
  }

  async toggleTurfSubscription(id: number) {
    const turf = await this.findVerifiedAdmin(id, true);
    if (!turf) {
      throw new NotFoundException(`Turf with ID ${id} not found`);
    }

    const currentHold = turf.isBookingHold || turf.status !== 'VERIFIED';
    const newHold = !currentHold;

    const updated = await this.prisma.verifiedAdmin.update({
      where: { id: turf.id },
      data: {
        isBookingHold: newHold,
        status: newHold ? 'HOLD' : 'VERIFIED',
      },
      include: { dashboard: true },
    });

    const isSubscribed = !updated.isBookingHold && updated.status === 'VERIFIED';

    return {
      success: true,
      message: isSubscribed
        ? 'Subscription marked ACTIVE. Turf is now visible on Player App.'
        : 'Subscription marked EXPIRED/HOLD. Turf is now HIDDEN on Player App.',
      isSubscriptionActive: isSubscribed,
      status: isSubscribed ? 'ACTIVE' : 'EXPIRED',
      isLiveOnPlayerApp: isSubscribed,
    };
  }

  // =========================================================================
  // REAL-TIME OPEN MATCHES / OPEN CHALLENGES (SHARED ACROSS ALL PLAYERS & SYNCED)
  // =========================================================================
  async getOpenMatches(location?: string, sport?: string) {
    const where: any = {
      status: { notIn: ['CANCELLED', 'COMPLETED'] },
    };

    if (sport && sport.toLowerCase() !== 'all') {
      where.sport = { equals: sport, mode: 'insensitive' };
    }

    if (location && location.toLowerCase() !== 'all' && location.toLowerCase() !== 'all madurai') {
      where.OR = [
        { location: { contains: location, mode: 'insensitive' } },
        { turfName: { contains: location, mode: 'insensitive' } },
      ];
    }

    const matches = await this.prisma.openChallenge.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: 100,
    });

    return {
      success: true,
      count: matches.length,
      matches,
    };
  }

  async createOpenMatch(body: any) {
    const turfId = body.turfId != null ? Number(body.turfId) : null;
    const bookingId = body.bookingId != null ? Number(body.bookingId) : null;

    // One challenge per booking: paid open-match bookings already create theirs server-side.
    if (bookingId) {
      const existingForBooking = await this.prisma.openChallenge.findFirst({ where: { bookingId } });
      if (existingForBooking) {
        return {
          success: true,
          message: 'Open match already posted for this booking.',
          challenge: existingForBooking,
        };
      }
    }

    // A client-supplied id may only update a challenge created by the same phone number.
    let id = body.id || `ch_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    if (body.id) {
      const existing = await this.prisma.openChallenge.findUnique({ where: { id: body.id } });
      const callerLast10 = String(body.creatorPhone || '').replace(/\D/g, '').slice(-10);
      const ownerLast10 = String(existing?.creatorPhone || '').replace(/\D/g, '').slice(-10);
      if (existing && (!callerLast10 || callerLast10 !== ownerLast10)) {
        id = `ch_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
      }
    }

    const challenge = await this.prisma.openChallenge.upsert({
      where: { id },
      create: {
        id,
        turfId,
        bookingId,
        turfName: body.turfName || 'Turf Arena',
        location: body.location || 'Madurai',
        date: body.date || 'Today',
        time: body.time || '06:00 PM - 07:00 PM',
        sport: body.sport || 'Football',
        challengerName: body.challengerName || 'Player Team',
        challengerTeamInitials: body.challengerTeamInitials || 'TC',
        challengerColor: String(body.challengerColor ?? '4280148788'),
        creatorPhone: body.creatorPhone || '',
        teamSize: body.teamSize || '7v7',
        isJoined: false,
        status: 'OPEN',
        joinRequests: [],
      },
      update: {
        turfId: turfId ?? undefined,
        bookingId: bookingId ?? undefined,
        turfName: body.turfName,
        location: body.location,
        date: body.date,
        time: body.time,
        sport: body.sport,
        teamSize: body.teamSize,
      },
    });

    return {
      success: true,
      message: 'Open match posted successfully and visible to all players!',
      challenge,
    };
  }

  async joinOpenMatch(challengeId: string, body: any) {
    const challenge = await this.prisma.openChallenge.findUnique({
      where: { id: challengeId },
    });

    if (!challenge) {
      throw new NotFoundException(`Open match with ID ${challengeId} not found`);
    }

    if (challenge.status !== 'OPEN' || challenge.isJoined) {
      throw new BadRequestException('This open match already has an opponent.');
    }

    const currentRequests: any[] = Array.isArray(challenge.joinRequests) ? (challenge.joinRequests as any[]) : [];
    const contactLast10 = String(body.contactDetails || '').replace(/\D/g, '').slice(-10);
    if (contactLast10) {
      if (String(challenge.creatorPhone || '').replace(/\D/g, '').slice(-10) === contactLast10) {
        throw new BadRequestException('You cannot request to join your own open match.');
      }
      const already = currentRequests.find(
        (r) => String(r?.contactDetails || '').replace(/\D/g, '').slice(-10) === contactLast10,
      );
      if (already) {
        return { success: true, message: 'You have already requested to join this match.', challenge };
      }
    }

    const newRequest = {
      id: body.id || `req_${Date.now()}`,
      teamName: body.teamName || 'Opponent Squad',
      teamSize: body.teamSize || '7v7',
      contactDetails: body.contactDetails || '',
      requestedAt: 'Just now',
    };

    const updatedRequests = [...currentRequests, newRequest];

    const updated = await this.prisma.openChallenge.update({
      where: { id: challengeId },
      data: {
        joinRequests: updatedRequests,
      },
    });

    return {
      success: true,
      message: 'Challenge request sent successfully to host!',
      challenge: updated,
    };
  }

  async acceptOpenMatch(challengeId: string, body: any) {
    const challenge = await this.prisma.openChallenge.findUnique({
      where: { id: challengeId },
    });

    if (!challenge) {
      throw new NotFoundException(`Open match with ID ${challengeId} not found`);
    }

    const opponentName = body.opponentName || body.teamName || 'Opponent Team';
    const opponentContact = body.opponentContact || body.contactDetails || '';
    const opponentTeamSize = body.opponentTeamSize || body.teamSize || '7v7';

    const updated = await this.prisma.openChallenge.update({
      where: { id: challengeId },
      data: {
        isJoined: true,
        status: 'ACCEPTED',
        opponentName,
        opponentContact,
        opponentTeamSize,
      },
    });

    let bookingId = challenge.bookingId;
    if (!bookingId && challenge.turfId) {
      // Legacy challenges without a bookingId: only look inside the same venue.
      const matchBooking = await this.prisma.turfBooking.findFirst({
        where: {
          verifiedAdminId: challenge.turfId,
          isOpenMatch: true,
          date: challenge.date,
          timeSlot: { contains: challenge.time },
          status: { not: 'Cancelled' },
        },
      });
      if (matchBooking) {
        bookingId = matchBooking.id;
        await this.prisma.openChallenge.update({
          where: { id: challengeId },
          data: { bookingId: matchBooking.id },
        }).catch(() => null);
      }
    }

    if (bookingId) {
      await this.prisma.turfBooking.update({
        where: { id: bookingId },
        data: {
          openMatchStatus: 'OPPONENT_JOINED',
          opponentName,
          opponentPhone: opponentContact,
        },
      }).catch(() => null);
    }

    return {
      success: true,
      message: 'Opponent accepted! Match is now locked and confirmed.',
      challenge: updated,
    };
  }

  /** Host declines one join request; it is removed for everyone, not just on the host's phone. */
  async rejectOpenMatchRequest(challengeId: string, body: any) {
    const challenge = await this.prisma.openChallenge.findUnique({ where: { id: challengeId } });
    if (!challenge) {
      throw new NotFoundException(`Open match with ID ${challengeId} not found`);
    }
    const callerLast10 = String(body?.callerPhone || '').replace(/\D/g, '').slice(-10);
    const ownerLast10 = String(challenge.creatorPhone || '').replace(/\D/g, '').slice(-10);
    if (!callerLast10 || callerLast10 !== ownerLast10) {
      throw new BadRequestException('Only the host of this open match can decline requests.');
    }
    const requestId = String(body?.requestId || '');
    const current: any[] = Array.isArray(challenge.joinRequests) ? (challenge.joinRequests as any[]) : [];
    const remaining = current.filter((r) => String(r?.id) !== requestId);
    const updated = await this.prisma.openChallenge.update({
      where: { id: challengeId },
      data: { joinRequests: remaining },
    });
    return { success: true, message: 'Join request declined.', challenge: updated };
  }

  async completeBooking(bookingId: number) {
    const booking = await this.prisma.turfBooking.findUnique({
      where: { id: bookingId },
    });
    if (!booking) {
      throw new NotFoundException(`Booking with ID ${bookingId} not found`);
    }
    const statusLower = (booking.status || '').toLowerCase();
    if (statusLower === 'cancelled' || statusLower === PENDING_PAYMENT_STATUS.toLowerCase()) {
      throw new BadRequestException('Only confirmed bookings can be marked as completed.');
    }
    const { todayStr, currentMinutes } = getISTDateAndMinutes();
    if (!isBookingSlotEnded(booking.date, booking.timeSlot, todayStr, currentMinutes)) {
      // The court is still running: keep the booking active (player may play another match).
      return { success: false, message: 'Booking slot has not ended yet.', booking };
    }
    const updated = await this.prisma.turfBooking.update({
      where: { id: bookingId },
      data: {
        status: 'Completed',
        openMatchStatus: booking.isOpenMatch ? 'COMPLETED' : null,
      },
    });

    await this.prisma.openChallenge.updateMany({
      where: { bookingId },
      data: { status: 'COMPLETED' },
    }).catch(() => null);

    return {
      success: true,
      message: 'Booking completed successfully',
      booking: updated,
    };
  }

  async setManualOpponent(bookingId: number, body: any) {
    const booking = await this.prisma.turfBooking.findFirst({
      where: {
        OR: [
          { id: bookingId },
          { bookingCode: String(bookingId) },
        ],
      },
    });

    if (!booking) {
      throw new NotFoundException(`Booking #${bookingId} not found`);
    }

    const opponentName = (body.opponentName || body.teamName || 'Opponent Team').trim();
    const opponentPhone = (body.opponentPhone || body.opponentContact || '').trim();

    const updated = await this.prisma.turfBooking.update({
      where: { id: booking.id },
      data: {
        openMatchStatus: 'OPPONENT_JOINED',
        opponentName,
        opponentPhone,
      },
    });

    // Also update any corresponding openChallenge so other users don't see it as open
    // Only the challenge linked to THIS booking (date/time matching touched other venues).
    await this.prisma.openChallenge.updateMany({
      where: { bookingId: booking.id },
      data: {
        isJoined: true,
        status: 'ACCEPTED',
        opponentName,
        opponentContact: opponentPhone,
      },
    }).catch(() => null);

    return {
      success: true,
      message: `Opponent team set to ${opponentName}! Match is ready to play.`,
      booking: updated,
    };
  }

  async convertBookingToPrivate(bookingId: number) {
    const booking = await this.prisma.turfBooking.findFirst({
      where: {
        OR: [
          { id: bookingId },
          { bookingCode: String(bookingId) },
        ],
      },
    });

    if (!booking) {
      throw new NotFoundException(`Booking #${bookingId} not found`);
    }

    const updated = await this.prisma.turfBooking.update({
      where: { id: booking.id },
      data: {
        isOpenMatch: false,
        openMatchStatus: null,
      },
    });

    // Cancel the open challenge so it is removed from public open challenge list
    // Only the challenge linked to THIS booking (date/time matching touched other venues).
    await this.prisma.openChallenge.updateMany({
      where: { bookingId: booking.id },
      data: {
        status: 'CANCELLED',
      },
    }).catch(() => null);

    return {
      success: true,
      message: 'Booking converted to private match! Both teams can now be managed manually.',
      booking: updated,
    };
  }

  async getAllTournaments(
    sport?: string,
    turfId?: string,
    phone?: string,
    venue?: string,
    ownerOnly?: string,
    viewer?: string,
  ) {
    const where: any = {
      status: { notIn: ['ON_HOLD', 'DELETED'] },
      isHold: false,
    };
    const callerLast10 = String(phone || viewer || '').replace(/\D/g, '').slice(-10);
    // Private tournaments are never listed publicly; organizers still see their own.
    if (callerLast10.length === 10) {
      where.AND = [
        { OR: [{ isPrivate: false }, { organizerPhone: { contains: callerLast10 } }] },
      ];
    } else {
      where.isPrivate = false;
    }
    if (sport && sport !== 'All Sports') {
      where.sport = { contains: sport, mode: 'insensitive' };
    }

    const isOwnerFilter = ownerOnly === 'true' || Boolean(turfId || phone || venue);
    if (isOwnerFilter) {
      const ownerConditions: any[] = [];
      if (turfId && !isNaN(Number(turfId)) && Number(turfId) > 0) {
        ownerConditions.push({ verifiedAdminId: Number(turfId) });
      }
      if (phone && phone.trim()) {
        const cleanPhone = phone.trim().replace(/[^0-9]/g, '');
        const last10 = cleanPhone.length >= 10 ? cleanPhone.slice(-10) : cleanPhone;
        if (last10.length > 0) {
          ownerConditions.push({ organizerPhone: { contains: last10 } });
        }
      }
      if (venue && venue.trim()) {
        ownerConditions.push({ venueName: { equals: venue.trim(), mode: 'insensitive' } });
      }
      if (ownerConditions.length > 0) {
        where.OR = ownerConditions;
      } else if (ownerOnly === 'true') {
        return [];
      }
    }

    const tournaments = await this.prisma.tournament.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: { verifiedAdmin: true },
    });

    // Exclude tournaments if tournament itself is held, or if the host turf is held or inactive
    const activeTournaments = tournaments.filter((t) => {
      if (t.isHold || t.status === 'ON_HOLD' || t.status === 'DELETED') return false;
      if (t.verifiedAdmin) {
        if (t.verifiedAdmin.isBookingHold || t.verifiedAdmin.status !== 'VERIFIED') {
          return false;
        }
      }
      return true;
    });

    return activeTournaments.map((t) => this.toPublicTournament(t, callerLast10));
  }

  private toPublicTournament(t: any, callerLast10 = '') {
    const isOrganizer =
      callerLast10.length === 10 && String(t.organizerPhone || '').replace(/\D/g, '').endsWith(callerLast10);
    return {
      id: t.id.toString(),
      isPrivate: t.isPrivate === true,
      // The PIN is only returned to the organizer; everyone else must already know it.
      accessCode: isOrganizer ? t.accessCode : null,
      createdByRole: t.createdByRole,
      isOwnerCreated: t.isOwnerCreated,
      title: t.title,
      sport: t.sport,
      format: t.format,
      status: t.status.toLowerCase(),
      date: t.date,
      time: t.time || '09:00 AM',
      venue: t.venueName,
      venueName: t.venueName,
      location: t.location || t.verifiedAdmin?.neighborhoodArea || 'Madurai',
      entryFee: `₹${t.entryFee.toFixed(0)}`,
      prizePool: t.prizePool || '₹15,000',
      grandPrize: t.prizePool || '₹15,000',
      maxTeams: t.maxTeams,
      registeredTeams: t.registeredTeams,
      imageUrl: t.bannerUrl || 'https://picsum.photos/seed/tournament/800/400',
      reportingTime: '30 mins before match',
      matchDay: 'Day 1',
      tournamentProgress: t.status === 'LIVE' ? 'Ongoing' : (t.status === 'CANCELLED' ? 'Cancelled' : 'Upcoming'),
      registeredUsers: Array.isArray(t.registeredUsers) ? t.registeredUsers : [],
      organizerName: t.organizerName,
      organizerPhone: t.organizerPhone,
      verifiedAdminId: t.verifiedAdminId,
    };
  }

  /** Looks up a private tournament by its access PIN (the only way to see one). */
  async getTournamentByAccessCode(code: string) {
    const clean = String(code || '').trim().toUpperCase();
    if (clean.length < 4) {
      throw new BadRequestException('Enter a valid tournament access PIN');
    }
    const t = await this.prisma.tournament.findFirst({
      where: {
        isPrivate: true,
        accessCode: { equals: clean, mode: 'insensitive' },
        isHold: false,
        status: { notIn: ['ON_HOLD', 'DELETED', 'CANCELLED'] },
      },
      include: { verifiedAdmin: true },
    });
    if (!t) {
      throw new NotFoundException('No private tournament found for this PIN');
    }
    return { success: true, tournament: this.toPublicTournament(t) };
  }

  async createTournament(body: any) {
    const title = (body?.title || '').toString().trim();
    const venueName = (body?.venueName || body?.venue || 'Games24 Arena').toString().trim();
    const todayStr = new Date().toISOString().split('T')[0];
    const date = (body?.date || todayStr).toString().trim();

    if (!title) {
      throw new BadRequestException('Tournament title is required for creating a tournament');
    }

    const sport = (body?.sport || body?.sportType || 'Football').toString().trim();
    const format = (body?.format || body?.tournamentType || 'Knockout').toString().trim();
    const time = (body?.time || body?.matchStartTime || '09:00 AM').toString().trim();
    const location = (body?.location || 'Madurai').toString().trim();
    const entryFee = Number(body?.entryFee ?? body?.teamEntryFee ?? 1500) || 0;
    const prizePool = (body?.prizePool || body?.championPrize || '₹15,000').toString().trim();
    const maxTeams = Number(body?.maxTeams) || 16;
    const organizerName = (body?.organizerName || 'Games24 Community').toString().trim();
    const organizerPhone = (body?.organizerPhone || body?.phone || '9876543210').toString().trim();
    const bannerUrl = (body?.bannerUrl || body?.imageUrl || 'https://images.unsplash.com/photo-1540747913346-19e32dc3e97e?auto=format&fit=crop&w=800&q=80').toString().trim();

    const createdByRole = String(body?.createdByRole || 'OWNER').toUpperCase() === 'PLAYER' ? 'PLAYER' : 'OWNER';
    const isPlayerCreated = createdByRole === 'PLAYER';

    // Player tournaments are never silently attached to a venue by name match: that put them on
    // the venue owner's dashboard (who could delete them) without the venue agreeing to host.
    let verifiedAdminId = body?.verifiedAdminId ? Number(body.verifiedAdminId) : null;
    if (!verifiedAdminId && !isPlayerCreated && venueName && !venueName.toLowerCase().includes('tba')) {
      const match = await this.prisma.verifiedAdmin.findFirst({
        where: { venueName: { equals: venueName, mode: 'insensitive' } },
      });
      if (match) verifiedAdminId = match.id;
    }

    const isPrivate = body?.isPrivate === true;
    let accessCode: string | null = null;
    if (isPrivate) {
      accessCode = String(body?.accessCode || '').trim().toUpperCase();
      if (!/^[A-Z0-9]{4,10}$/.test(accessCode)) {
        accessCode = Math.random().toString(36).slice(2, 8).toUpperCase();
      }
      // PINs must be unique so a PIN identifies exactly one tournament.
      for (let i = 0; i < 5; i++) {
        const clash = await this.prisma.tournament.findFirst({ where: { accessCode } });
        if (!clash) break;
        accessCode = Math.random().toString(36).slice(2, 8).toUpperCase();
      }
    }

    const created = await this.prisma.tournament.create({
      data: {
        title,
        sport,
        format,
        date,
        time,
        venueName,
        location,
        entryFee,
        prizePool,
        maxTeams,
        registeredTeams: 0,
        registeredUsers: [],
        organizerName,
        organizerPhone,
        bannerUrl,
        status: 'UPCOMING',
        isHold: false,
        verifiedAdminId,
        createdByRole,
        isOwnerCreated: !isPlayerCreated,
        isPrivate,
        accessCode,
      },
    });

    return {
      success: true,
      message: 'Tournament created successfully!',
      tournament: created,
    };
  }

  async registerTournament(id: number, body: any) {
    const teamName = String(body?.teamName || '').trim();
    if (!teamName) {
      throw new BadRequestException('Team name is required to register.');
    }
    const captainPhone = String(body?.captainPhone || body?.contact || body?.phone || body?.contactPhone || '').replace(/\D/g, '').slice(-10);

    // Only keep known registration fields (the raw body used to be stored as-is).
    const entry = {
      id: `reg_srv_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
      teamName: teamName.slice(0, 60),
      captainName: String(body?.captainName || body?.name || '').trim().slice(0, 60),
      captainPhone,
      contact: captainPhone,
      playersCount: Number(body?.playersCount || body?.players?.length || 0) || null,
      players: Array.isArray(body?.players) ? body.players.slice(0, 30).map((p: any) => String(p?.name ?? p).slice(0, 60)) : [],
      registeredAt: new Date().toISOString(),
    };

    try {
      return await this.prisma.$transaction(
        async (tx) => {
          const tournament = await tx.tournament.findUnique({
            where: { id },
            include: { verifiedAdmin: true },
          });
          if (!tournament) {
            throw new NotFoundException('Tournament not found');
          }
          if (tournament.isPrivate) {
            const code = String(body?.accessCode || '').trim().toUpperCase();
            if (!code || code !== String(tournament.accessCode || '').toUpperCase()) {
              throw new BadRequestException('This is a private tournament. Enter the correct access PIN to register.');
            }
          }
          if (tournament.isHold || tournament.status === 'ON_HOLD' || tournament.status === 'CANCELLED') {
            throw new BadRequestException('This tournament is currently placed on hold by platform administrator and cannot accept registrations.');
          }
          if (tournament.verifiedAdmin && (tournament.verifiedAdmin.isBookingHold || tournament.verifiedAdmin.status !== 'VERIFIED')) {
            throw new BadRequestException('The venue for this tournament is currently on hold by platform administrator.');
          }

          const currentUsers = Array.isArray(tournament.registeredUsers)
            ? (tournament.registeredUsers as any[])
            : [];
          if (currentUsers.length >= tournament.maxTeams || tournament.registeredTeams >= tournament.maxTeams) {
            throw new BadRequestException('Tournament registration is full!');
          }
          if (currentUsers.some((u) => String(u?.teamName || '').toLowerCase() === teamName.toLowerCase())) {
            throw new BadRequestException(`Team "${teamName}" is already registered for this tournament!`);
          }
          if (captainPhone && currentUsers.some((u) => String(u?.captainPhone || '').replace(/\D/g, '').slice(-10) === captainPhone)) {
            throw new BadRequestException('You have already registered a team for this tournament.');
          }

          const updated = await tx.tournament.update({
            where: { id },
            data: {
              registeredTeams: currentUsers.length + 1,
              registeredUsers: [...currentUsers, entry],
            },
          });

          return {
            success: true,
            message: `Team "${teamName}" registered successfully for "${tournament.title}"!`,
            tournament: this.toPublicTournament(updated),
            registration: entry,
          };
        },
        { isolationLevel: Prisma.TransactionIsolationLevel.Serializable },
      );
    } catch (err: any) {
      if (err?.code === 'P2034') {
        throw new ConflictException('Another team registered at the same moment. Please try again.');
      }
      throw err;
    }
  }

  async cancelTournament(id: number) {
    if (!id || isNaN(id)) {
      throw new BadRequestException('Valid tournament ID is required');
    }
    const tournament = await this.prisma.tournament.findUnique({
      where: { id },
    });
    if (!tournament) {
      throw new NotFoundException(`Tournament #${id} not found`);
    }
    const updated = await this.prisma.tournament.update({
      where: { id },
      data: { status: 'CANCELLED' },
    });
    return {
      success: true,
      message: `Tournament "${tournament.title}" has been cancelled.`,
      tournament: updated,
    };
  }

  async deleteTournament(id: number) {
    if (!id || isNaN(id)) {
      throw new BadRequestException('Valid tournament ID is required');
    }
    const tournament = await this.prisma.tournament.findUnique({
      where: { id },
    });
    if (!tournament) {
      return {
        success: true,
        message: 'Tournament not found or already deleted',
      };
    }
    await this.prisma.tournament.delete({
      where: { id },
    });
    return {
      success: true,
      message: `Tournament "${tournament.title}" deleted permanently.`,
    };
  }

  async getTurfCourts(id: number) {
    const turf = await this.findVerifiedAdmin(id, false, false);
    if (!turf) {
      throw new NotFoundException(`Turf #${id} not found`);
    }
    const sports = this.getSportsForTurf(id);
    return getCourtsForTurf(id, turf.venueName, sports, turf.courts);
  }

  async saveTurfCourts(id: number, courts: any[], callerPhone?: string) {
    const turf = await this.findVerifiedAdmin(id, false, false);
    if (!turf) {
      throw new NotFoundException(`Turf #${id} not found`);
    }

    if (callerPhone) {
      const cleanCaller = String(callerPhone).replace(/\D/g, '').slice(-10);
      const cleanOwner = String(turf.ownerPhone || '').replace(/\D/g, '').slice(-10);
      const cleanAlt = String(turf.alternativePhone || '').replace(/\D/g, '').slice(-10);
      if (cleanCaller !== cleanOwner && cleanCaller !== cleanAlt) {
        throw new BadRequestException('Security Alert: You do not have permission to modify courts for this turf.');
      }
    }

    const updated = await this.prisma.verifiedAdmin.update({
      where: { id: turf.id },
      data: { courts: Array.isArray(courts) ? courts : [] },
    });
    return {
      success: true,
      message: 'Turf courts saved successfully in database',
      courts: updated.courts,
    };
  }

  // =========================================================================
  // CELEBRATION & EVENT ENQUIRIES & BOOKINGS
  // =========================================================================
  async createCelebrationBooking(body: any) {
    const bookingCode = `G24-CEL-${Math.floor(1000 + Math.random() * 9000)}`;
    const cleanPhone = (body.customerPhone || '').replace(/\D/g, '').slice(-10);

    const celebration = await (this.prisma as any).celebrationBooking.create({
      data: {
        bookingCode,
        packageId: body.packageId || 'c1',
        packageTitle: body.packageTitle || 'Turf Sports Celebration',
        turfId: body.turfId ? Number(body.turfId) : null,
        turfName: body.turfName || 'Madurai Turf Arena',
        customerName: body.customerName || 'Player',
        customerPhone: cleanPhone,
        eventDate: body.eventDate || 'Upcoming Weekend',
        eventTimeSlot: body.eventTimeSlot || '04:00 PM - 07:00 PM',
        guestCount: body.guestCount ? Number(body.guestCount) : 30,
        totalAmount: body.totalAmount ? Number(body.totalAmount) : 4999.0,
        notes: body.notes || 'Celebration booking submitted via Gamez24',
        status: 'PENDING',
      },
    });

    // Create a real notification for the player
    if (cleanPhone) {
      await (this.prisma as any).playerNotification.create({
        data: {
          userPhone: cleanPhone,
          title: 'Celebration Enquiry Received 🎂',
          message: `Your booking for "${celebration.packageTitle}" at ${celebration.turfName} (${celebration.eventDate}) has been logged. Our event manager will call you within 15 minutes!`,
          type: 'celebration',
          metadata: { bookingCode, celebrationId: celebration.id },
        },
      }).catch(() => null);
    }

    return {
      success: true,
      bookingCode,
      message: 'Celebration booking created successfully!',
      celebration,
    };
  }

  async getCelebrations(phone?: string) {
    const where: any = {};
    if (phone && phone.trim()) {
      const cleanPhone = phone.trim().replace(/\D/g, '').slice(-10);
      where.customerPhone = cleanPhone;
    }

    const list = await (this.prisma as any).celebrationBooking.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      take: 50,
    });

    return {
      success: true,
      count: list.length,
      celebrations: list,
    };
  }

  // =========================================================================
  // REALTIME PLAYER NOTIFICATIONS
  // =========================================================================
  async getUserNotifications(phone: string) {
    const cleanPhone = (phone || '').replace(/\D/g, '').slice(-10);
    if (!cleanPhone) {
      return { success: true, count: 0, notifications: [] };
    }

    let notifications = await (this.prisma as any).playerNotification.findMany({
      where: { userPhone: cleanPhone },
      orderBy: { createdAt: 'desc' },
      take: 30,
    });

    // If new user with 0 notifications, seed starter notifications in DB
    if (notifications.length === 0) {
      const starterItems = [
        {
          userPhone: cleanPhone,
          title: 'Welcome to Games24 ⚽',
          message: 'Explore verified local turfs, host open matches, build your squad, and book slots seamlessly.',
          type: 'general',
          isRead: false,
        },
        {
          userPhone: cleanPhone,
          title: 'Open Match Challenge Available 🔥',
          message: 'Teams in Madurai are looking for football and cricket match opponents. Check out the Community section!',
          type: 'challenge',
          isRead: false,
        },
        {
          userPhone: cleanPhone,
          title: 'Cashfree Fast Payments Active 💳',
          message: 'Instant UPI, Cards & Netbanking now supported for hassle-free venue slot booking.',
          type: 'general',
          isRead: true,
        },
      ];

      for (const item of starterItems) {
        await (this.prisma as any).playerNotification.create({ data: item }).catch(() => null);
      }

      notifications = await (this.prisma as any).playerNotification.findMany({
        where: { userPhone: cleanPhone },
        orderBy: { createdAt: 'desc' },
      });
    }

    return {
      success: true,
      count: notifications.length,
      notifications,
    };
  }

  async markNotificationRead(id: number) {
    const updated = await (this.prisma as any).playerNotification.update({
      where: { id },
      data: { isRead: true },
    }).catch(() => null);

    return {
      success: true,
      notification: updated,
    };
  }

  async createNotification(body: { userPhone: string; title: string; message: string; type?: string; metadata?: any }) {
    const cleanPhone = (body.userPhone || '').replace(/\D/g, '').slice(-10);
    const created = await (this.prisma as any).playerNotification.create({
      data: {
        userPhone: cleanPhone,
        title: body.title,
        message: body.message,
        type: body.type || 'general',
        metadata: body.metadata || null,
        isRead: false,
      },
    });

    return {
      success: true,
      notification: created,
    };
  }
}
