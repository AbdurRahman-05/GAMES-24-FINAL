
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
  return hour * 60 + (isNaN(minutes) ? 0 : minutes);
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
  } catch (e) {
    const now = new Date();
    const istMs = now.getTime() + (330 + now.getTimezoneOffset()) * 60000;
    const ist = new Date(istMs);
    const todayStr = `${ist.getFullYear()}-${String(ist.getMonth() + 1).padStart(2, '0')}-${String(ist.getDate()).padStart(2, '0')}`;
    const currentMinutes = ist.getHours() * 60 + ist.getMinutes();
    return { todayStr, currentMinutes };
  }
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

    // 3. Fallback to the first available verifiedAdmin if any
    if (!turf) {
      turf = await this.prisma.verifiedAdmin.findFirst({
        orderBy: { id: 'asc' },
        ...(Object.keys(include).length > 0 ? { include } : {}),
      });
    }

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

    return verified.map((t: any) => {
      const photos = normalizePhotoList(t.photoUrls);
      
      const amenities = Array.isArray(t.amenities) && t.amenities.length > 0
        ? t.amenities
        : ['Drinking Water', 'Parking', 'Floodlights', 'Restroom'];

      // Live dynamic rate based on current day and time
      const now = new Date();
      const currentDay = now.getDay();
      const isWeekendNow = (currentDay === 0 || currentDay === 6);
      const currentHour = now.getHours();
      const isNightNow = (currentHour >= 18 || currentHour < 6);

      let currentPrice = t.dayRate || 1000;
      if (isWeekendNow) {
        if (isNightNow) currentPrice = (t.weekendRate || 1600) + Math.max(0, (t.nightRate || 1400) - (t.dayRate || 1000));
        else currentPrice = t.weekendRate || 1600;
      } else {
        if (isNightNow) currentPrice = t.nightRate || 1400;
        else currentPrice = t.dayRate || t.weekdayRate || 1000;
      }

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
        rating: '4.9',
        reviews: '128',
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
      rating: '4.9',
      reviews: '128',
      sports: sportsItems.map(s => s.name),
      sportsList: sportsItems,
      courts: courtsList,
      dashboard: turf.dashboard,
      bookings: turf.bookings,
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

    const [year, month, d] = targetDate.split('-').map(Number);
    const dateObj = new Date(year, month - 1, d);
    const dayOfWeek = dateObj.getDay(); // 0 is Sunday, 6 is Saturday
    const isWeekend = (dayOfWeek === 0 || dayOfWeek === 6);

    const sportsItems = this.getSportsForTurf(verifiedAdminId);
    let matchedSport: TurfSportConfig | undefined;
    if (sport) {
      matchedSport = sportsItems.find(s => s.name.toLowerCase() === sport.toLowerCase());
      if (!matchedSport) {
        matchedSport = sportsItems.find(s =>
          s.name.toLowerCase().includes(sport.toLowerCase()) ||
          sport.toLowerCase().includes(s.name.toLowerCase())
        );
      }
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

      // Parse starting hour to check if Night slot (06:00 PM to 06:00 AM)
      const startPart = slot.split('-')[0].trim();
      const [timePart, period] = startPart.split(' ');
      let hour = parseInt(timePart.split(':')[0], 10);
      if (period?.toUpperCase() === 'PM' && hour !== 12) hour += 12;
      if (period?.toUpperCase() === 'AM' && hour === 12) hour = 0;
      const isNight = (hour >= 18 || hour < 6);

      let price: number;
      let rateType: string;

      if (isWeekend) {
        if (isNight) {
          const nightDiff = Math.max(0, nightRate - dayRate);
          price = weekendRate + nightDiff;
          rateType = 'Weekend Night Rate';
        } else {
          price = weekendRate;
          rateType = 'Weekend Day Rate';
        }
      } else {
        if (isNight) {
          price = nightRate;
          rateType = 'Weekday Night Rate';
        } else {
          price = dayRate;
          rateType = 'Weekday Day Rate';
        }
      }

      const offerRecord = offerMap.get(slot);
      let offer: any = null;
      let finalPrice = price;

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

      return {
        slot,
        time: slot,
        status,
        reason: isBlocked ? (blockedReasonMap.get(slot) || 'Under Maintenance') : null,
        blockReason: isBlocked ? (blockedReasonMap.get(slot) || 'Under Maintenance') : null,
        isPast,
        originalPrice: price,
        price: finalPrice,
        rateType,
        isNight,
        isWeekend,
        booking: isBooked ? bookedSlotMap.get(slot) : null,
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

  async bookSlot(id: number, body: any) {
    const { customerName, customerPhone, sport, courtName, date, timeSlot, amount, paymentMethod } = body || {};

    const rawSlots: string[] = Array.isArray(body?.timeSlots) && body.timeSlots.length > 0
      ? body.timeSlots
      : String(timeSlot || '').split(',').map((s: string) => s.trim()).filter(Boolean);

    if (!date || rawSlots.length === 0) {
      throw new BadRequestException('Date and at least one timeSlot are required for booking');
    }

    // Sort slots by start time
    rawSlots.sort((a, b) => parseSlotStartMinutes(a) - parseSlotStartMinutes(b));
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

    const turf = await this.findVerifiedAdmin(id, true, false);
    if (!turf) {
      throw new NotFoundException(`Turf #${id} not found`);
    }

    if (turf.isBookingHold || turf.status !== 'VERIFIED') {
      throw new BadRequestException(`Bookings for "${turf.venueName}" are currently on hold by platform administrator and cannot accept new reservations.`);
    }

    const verifiedAdminId = turf.id;

    // Security hardening: Calculate authentic server-side price based on owner's court/sport rates and active slot offers.
    // Hackers cannot tamper with amount in the client request.
    let expectedTotalAmount = 0;
    const sportConfig = this.getSportsForTurf(verifiedAdminId).find(s => s.name.toLowerCase() === (sport || 'Football').toLowerCase());
    const baseSlotRate = sportConfig?.hourlyRate || turf.dayRate || 1000.0;

    for (const s of rawSlots) {
      const slotOffer = await this.prisma.slotOffer.findUnique({
        where: {
          verifiedAdminId_date_timeSlot: {
            verifiedAdminId,
            date,
            timeSlot: s,
          },
        },
      });
      if (slotOffer?.offerPrice && slotOffer.offerPrice > 0) {
        expectedTotalAmount += slotOffer.offerPrice;
      } else {
        expectedTotalAmount += baseSlotRate;
      }
    }

    // Enforce authentic server-verified amount
    const bookingAmount = expectedTotalAmount > 0 ? expectedTotalAmount : (Number(amount) || 1000.0);

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
          const teamName = body?.teamName?.trim() || customerName?.trim() || 'My Team';
          const teamSize = body?.teamSize?.trim() || '7v7';

          const createdBooking = await tx.turfBooking.create({
            data: {
              verifiedAdminId,
              customerName: customerName?.trim() || 'Player Customer',
              customerPhone: customerPhone?.trim() || '9876543210',
              sport: sport || 'Football',
              courtName: courtName || `${turf.venueName} Main Arena`,
              date,
              timeSlot: combinedTimeSlot,
              amount: bookingAmount,
              paymentMethod: paymentMethod || 'UPI (GPay)',
              status: 'Confirmed',
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

          if (isOpenMatch) {
            const initials = teamName.length >= 2 ? teamName.substring(0, 2).toUpperCase() : 'TC';
            await tx.openChallenge.create({
              data: {
                id: `ch_${Date.now()}_${Math.floor(Math.random() * 1000)}`,
                bookingId: createdBooking.id,
                turfId: verifiedAdminId,
                turfName: turf.venueName,
                location: turf.neighborhoodArea || 'Madurai',
                date,
                time: combinedTimeSlot,
                sport: sport || 'Football',
                challengerName: teamName,
                challengerTeamInitials: initials,
                challengerColor: String(body?.challengerColor ?? '4280148788'),
                creatorPhone: customerPhone?.trim() || '9876543210',
                teamSize,
                isJoined: false,
                status: 'OPEN',
                joinRequests: [],
              },
            });
          }

          return {
            ...updatedWithCode,
            bookingId: formalBookingCode,
            bookingCode: formalBookingCode,
            turfId: verifiedAdminId,
            turfName: turf.venueName,
            courtName: courtName || `${turf.venueName} Main Arena`,
            location: turf.neighborhoodArea || 'Madurai',
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

    // Automatically update AdminDashboard metrics based on actual database bookings
    const monthPrefix = todayStr.substring(0, 7);

    const allBookings = await this.prisma.turfBooking.findMany({
      where: { verifiedAdminId, status: { not: 'Cancelled' } },
    });

    const todayBookings = allBookings.filter((b) => b.date === todayStr);
    const monthBookings = allBookings.filter((b) => b.date.startsWith(monthPrefix));

    const todayCount = todayBookings.length;
    const todayPaid = todayBookings.filter((b) => !b.paymentMethod?.toLowerCase().includes('cash')).length;
    const todayCash = todayBookings.filter((b) => b.paymentMethod?.toLowerCase().includes('cash')).length;
    const todayRev = todayBookings.reduce((sum, b) => sum + (Number(b.amount) || 0), 0);
    const monthTotal = monthBookings.length;
    const monthRev = monthBookings.reduce((sum, b) => sum + (Number(b.amount) || 0), 0);

    const blockedCount = await this.prisma.blockedSlot.count({
      where: { verifiedAdminId, date: todayStr },
    });

    const openingTime = turf.dashboard?.openingTime || '06:00 AM';
    const closingTime = turf.dashboard?.closingTime || '10:00 PM';
    const totalSlots = generateTimeSlots(openingTime, closingTime).length;
    const freeSlots = Math.max(0, totalSlots - todayCount - blockedCount);
    const slotsPercent = totalSlots > 0 ? Math.round((todayCount / totalSlots) * 100) : 0;

    await this.prisma.adminDashboard.upsert({
      where: { verifiedAdminId },
      create: {
        verifiedAdminId,
        todayBookingsCount: todayCount,
        todayPaidBookings: todayPaid,
        todayCashBookings: todayCash,
        todayRevenue: todayRev,
        todayBookingsGrowth: todayCount > 0 ? `+${todayCount} Today` : '0% Today',
        monthRevenue: monthRev,
        monthTotalBookings: monthTotal,
        revenueBadge: `₹${monthRev.toLocaleString('en-IN')} GMV`,
        freeSlotsCount: freeSlots,
        bookedSlotsCount: todayCount,
        blockedSlotsCount: blockedCount,
        slotsBadge: `${slotsPercent}% Full`,
      },
      update: {
        todayBookingsCount: todayCount,
        todayPaidBookings: todayPaid,
        todayCashBookings: todayCash,
        todayRevenue: todayRev,
        todayBookingsGrowth: todayCount > 0 ? `+${todayCount} Today` : '0% Today',
        monthRevenue: monthRev,
        monthTotalBookings: monthTotal,
        revenueBadge: `₹${monthRev.toLocaleString('en-IN')} GMV`,
        freeSlotsCount: freeSlots,
        bookedSlotsCount: todayCount,
        blockedSlotsCount: blockedCount,
        slotsBadge: `${slotsPercent}% Full`,
      },
    });

    return {
      success: true,
      message: 'Booking confirmed successfully in realtime!',
      ...booking,
      booking,
    };
  }

  async toggleBlockSlot(id: number, body: any) {
    const { date, timeSlot, reason, action } = body || {};

    if (!date || !timeSlot) {
      throw new BadRequestException('Date and timeSlot are required to block/unblock a slot');
    }

    const cleanDate = String(date || '').trim();
    const cleanTimeSlot = String(timeSlot || '').trim().replace(/\s*-\s*/, ' - ');

    const turf = await this.findVerifiedAdmin(id, true, false);
    if (!turf) {
      throw new NotFoundException(`Turf with ID ${id} not found`);
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
          reason: reason || 'Under Maintenance',
        },
        update: {
          reason: reason || 'Under Maintenance',
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
            reason: reason || 'Under Maintenance',
          },
          update: {
            reason: reason || 'Under Maintenance',
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
    const { date, timeSlot, offerString, offerType, discountPercent, originalPrice, offerPrice, tagLabel, remove } = body || {};

    if (!date || !timeSlot) {
      throw new BadRequestException('Date and timeSlot are required to set slot offer');
    }

    const cleanDate = date.trim();
    const cleanTimeSlot = timeSlot.trim();

    const turf = await this.findVerifiedAdmin(id, false, false);
    if (!turf) {
      throw new NotFoundException(`Turf #${id} not found`);
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

    if (phone && phone.trim()) {
      const trimmedPhone = phone.trim();
      const cleanDigits = trimmedPhone.replace(/\D/g, '');
      const last10 = cleanDigits.length >= 10 ? cleanDigits.slice(-10) : cleanDigits;

      if (last10.length >= 7) {
        orConditions.push({ customerPhone: { contains: last10 } });
        orConditions.push({ opponentPhone: { contains: last10 } });
        challengeOrConditions.push({ creatorPhone: { contains: last10 } });
        challengeOrConditions.push({ opponentContact: { contains: last10 } });
      }
      orConditions.push({ customerPhone: trimmedPhone });
      orConditions.push({ opponentPhone: trimmedPhone });
      challengeOrConditions.push({ creatorPhone: trimmedPhone });
      challengeOrConditions.push({ opponentContact: trimmedPhone });
    }

    if (name && name.trim()) {
      orConditions.push({ customerName: { equals: name.trim(), mode: 'insensitive' } });
      orConditions.push({ opponentName: { equals: name.trim(), mode: 'insensitive' } });
      challengeOrConditions.push({ challengerName: { equals: name.trim(), mode: 'insensitive' } });
      challengeOrConditions.push({ opponentName: { equals: name.trim(), mode: 'insensitive' } });
    }

    if (orConditions.length === 0 && challengeOrConditions.length === 0) {
      return [];
    }

    const bookings = await this.prisma.turfBooking.findMany({
      where: {
        OR: orConditions,
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
      if (statusLower !== 'cancelled' && statusLower !== 'completed') {
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
        verifiedAdminId: c.turfId || 1,
        turfId: c.turfId || 1,
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

      const activeBookings = allBookings.filter((b) => b.status !== 'Cancelled');
      const cancelledBookings = allBookings.filter((b) => b.status === 'Cancelled');
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

  async cancelBooking(bookingId: number) {
    const booking = await this.prisma.turfBooking.findUnique({
      where: { id: bookingId },
    });
    if (!booking) {
      throw new NotFoundException(`Booking #${bookingId} not found`);
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

    // 4. Find booking in database
    let booking: any = null;

    if (verifiedAdminId && !isNaN(verifiedAdminId)) {
      booking = await this.prisma.turfBooking.findFirst({
        where: {
          verifiedAdminId,
          OR: [
            ...(numericId ? [{ id: numericId }] : []),
            { bookingCode: { equals: cleanSearchId, mode: 'insensitive' } },
          ],
        },
        include: { verifiedAdmin: true },
      });
    }

    // Global lookup if not found under specific verifiedAdminId
    if (!booking) {
      const globalBooking = await this.prisma.turfBooking.findFirst({
        where: {
          OR: [
            ...(numericId ? [{ id: numericId }] : []),
            { bookingCode: { equals: cleanSearchId, mode: 'insensitive' } },
          ],
        },
        include: { verifiedAdmin: true },
      });

      if (!globalBooking) {
        return {
          success: false,
          valid: false,
          message: `Booking ticket "${cleanSearchId}" not found in database!`,
        };
      }

      // Security check: if scanning owner provided their turf ID and the pass belongs elsewhere
      if (verifiedAdminId && !isNaN(verifiedAdminId) && globalBooking.verifiedAdminId !== verifiedAdminId) {
        const bookedVenue = globalBooking.verifiedAdmin?.venueName || 'another venue';
        return {
          success: false,
          valid: false,
          message: `Cross-venue check-in denied: This pass is for "${bookedVenue}", not this venue!`,
        };
      }

      booking = globalBooking;
      verifiedAdminId = globalBooking.verifiedAdminId;
    }

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
    // Subscription runs on monthly cycle (renews 07 Dec 2026)
    const nextRenew = new Date(2026, 11, 7);
    const renewDateStr = '07 Dec 2026';
    const diffTime = nextRenew.getTime() - now.getTime();
    const calculatedDays = Math.max(0, Math.ceil(diffTime / (1000 * 60 * 60 * 24)));
    const daysRemaining = isSubscribed ? calculatedDays : 0;
    const isEndingSoon = isSubscribed && daysRemaining <= 3 && daysRemaining > 0;
    const isBlocked = !isSubscribed || daysRemaining <= 0;

    const history = [
      {
        id: 'SUB-2026-11',
        date: '07 Nov 2026, 10:15 AM',
        baseAmount: 1000.0,
        gstAmount: 180.0,
        totalAmount: 1180.0,
        paymentMethod: 'UPI (GPay)',
        status: isSubscribed ? 'Paid & Active' : 'Expired',
        validPeriod: '07 Nov 2026 - 07 Dec 2026',
        receiptNumber: 'RCP-SUB-84920',
      },
      {
        id: 'SUB-2026-10',
        date: '07 Oct 2026, 11:30 AM',
        baseAmount: 1000.0,
        gstAmount: 180.0,
        totalAmount: 1180.0,
        paymentMethod: 'UPI (PhonePe)',
        status: 'Completed',
        validPeriod: '07 Oct 2026 - 07 Nov 2026',
        receiptNumber: 'RCP-SUB-72109',
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
      status: { not: 'CANCELLED' },
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
    const id = body.id || `ch_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    const challenge = await this.prisma.openChallenge.upsert({
      where: { id },
      create: {
        id,
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

    const currentRequests: any[] = Array.isArray(challenge.joinRequests) ? (challenge.joinRequests as any[]) : [];
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
    if (!bookingId) {
      const matchBooking = await this.prisma.turfBooking.findFirst({
        where: {
          isOpenMatch: true,
          date: challenge.date,
          timeSlot: { contains: challenge.time },
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

  async completeBooking(bookingId: number) {
    const booking = await this.prisma.turfBooking.findUnique({
      where: { id: bookingId },
    });
    if (!booking) {
      throw new NotFoundException(`Booking with ID ${bookingId} not found`);
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
    await this.prisma.openChallenge.updateMany({
      where: {
        OR: [
          { bookingId: booking.id },
          {
            date: booking.date,
            time: { contains: booking.timeSlot },
          },
        ],
      },
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
    await this.prisma.openChallenge.updateMany({
      where: {
        OR: [
          { bookingId: booking.id },
          {
            date: booking.date,
            time: { contains: booking.timeSlot },
          },
        ],
      },
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
  ) {
    const where: any = {
      status: { notIn: ['CANCELLED', 'ON_HOLD', 'DELETED'] },
      isHold: false,
    };
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
      if (t.isHold || t.status === 'ON_HOLD' || t.status === 'CANCELLED') return false;
      if (t.verifiedAdmin) {
        if (t.verifiedAdmin.isBookingHold || t.verifiedAdmin.status !== 'VERIFIED') {
          return false;
        }
      }
      return true;
    });

    return activeTournaments.map((t) => ({
      id: t.id.toString(),
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
      tournamentProgress: t.status === 'LIVE' ? 'Ongoing' : 'Upcoming',
      registeredUsers: Array.isArray(t.registeredUsers) ? t.registeredUsers : [],
      organizerName: t.organizerName,
      organizerPhone: t.organizerPhone,
      verifiedAdminId: t.verifiedAdminId,
    }));
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

    let verifiedAdminId = body?.verifiedAdminId ? Number(body.verifiedAdminId) : null;
    if (!verifiedAdminId && venueName && !venueName.toLowerCase().includes('tba')) {
      const match = await this.prisma.verifiedAdmin.findFirst({
        where: { venueName: { equals: venueName, mode: 'insensitive' } },
      });
      if (match) verifiedAdminId = match.id;
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
      },
    });

    return {
      success: true,
      message: 'Tournament created successfully!',
      tournament: created,
    };
  }

  async registerTournament(id: number, body: any) {
    const tournament = await this.prisma.tournament.findUnique({
      where: { id },
      include: { verifiedAdmin: true },
    });
    if (!tournament) {
      throw new NotFoundException('Tournament not found');
    }
    if (tournament.isHold || tournament.status === 'ON_HOLD' || tournament.status === 'CANCELLED') {
      throw new BadRequestException('This tournament is currently placed on hold by platform administrator and cannot accept registrations.');
    }
    if (tournament.verifiedAdmin && (tournament.verifiedAdmin.isBookingHold || tournament.verifiedAdmin.status !== 'VERIFIED')) {
      throw new BadRequestException('The venue for this tournament is currently on hold by platform administrator.');
    }
    if (tournament.registeredTeams >= tournament.maxTeams) {
      throw new BadRequestException('Tournament registration is full!');
    }

    const currentUsers = Array.isArray(tournament.registeredUsers)
      ? (tournament.registeredUsers as any[])
      : [];

    const teamName = body?.teamName || 'New Team';
    const alreadyRegistered = currentUsers.some(
      (u) => (u.teamName || '').toLowerCase() === teamName.toLowerCase(),
    );
    if (alreadyRegistered) {
      throw new BadRequestException(`Team "${teamName}" is already registered for this tournament!`);
    }

    const updatedUsers = [...currentUsers, { ...body, registeredAt: new Date().toISOString() }];

    const updated = await this.prisma.tournament.update({
      where: { id },
      data: {
        registeredTeams: { increment: 1 },
        registeredUsers: updatedUsers,
      },
    });

    return {
      success: true,
      message: `Team "${teamName}" registered successfully for "${tournament.title}"!`,
      tournament: updated,
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

  async saveTurfCourts(id: number, courts: any[]) {
    const turf = await this.findVerifiedAdmin(id, false, false);
    if (!turf) {
      throw new NotFoundException(`Turf #${id} not found`);
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
}
