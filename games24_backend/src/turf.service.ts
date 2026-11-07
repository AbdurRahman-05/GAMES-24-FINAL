
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
  { name: 'Cricket', hourlyRate: 1000.0, weekdayRate: 1000.0, weekendRate: 1200.0, nightRate: 1200.0, courtsAvailable: 2 },
  { name: 'Football', hourlyRate: 1400.0, weekdayRate: 1400.0, weekendRate: 1600.0, nightRate: 1600.0, courtsAvailable: 2 },
  { name: 'Pickle ball', hourlyRate: 800.0, weekdayRate: 800.0, weekendRate: 1000.0, nightRate: 1000.0, courtsAvailable: 2 },
  { name: 'Badminton', hourlyRate: 450.0, weekdayRate: 450.0, weekendRate: 550.0, nightRate: 500.0, courtsAvailable: 4 },
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
    for (const bl of blocked) {
      blockedSlotSet.add(bl.timeSlot);
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
      throw new BadRequestException('This turf is currently inactive due to expired platform subscription and cannot accept bookings.');
    }

    const verifiedAdminId = turf.id;

    // Check if slot has an active offer to calculate accurate offer price
    const activeOffer = await this.prisma.slotOffer.findUnique({
      where: {
        verifiedAdminId_date_timeSlot: {
          verifiedAdminId,
          date,
          timeSlot: rawSlots[0],
        },
      },
    });

    let bookingAmount = Number(amount);
    if (!bookingAmount || isNaN(bookingAmount)) {
      if (activeOffer?.offerPrice) {
        bookingAmount = activeOffer.offerPrice * rawSlots.length;
      } else {
        const sportConfig = this.getSportsForTurf(verifiedAdminId).find(s => s.name.toLowerCase() === (sport || 'Football').toLowerCase());
        const ratePerSlot = sportConfig?.hourlyRate || turf.dayRate || 1000.0;
        bookingAmount = ratePerSlot * rawSlots.length;
      }
    }

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
          return await tx.turfBooking.create({
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
            },
          });
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
      booking,
    };
  }

  async toggleBlockSlot(id: number, body: any) {
    const { date, timeSlot, reason } = body || {};

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
          reason: reason || 'Blocked by Turf Owner',
        },
        update: {
          reason: reason || 'Blocked by Turf Owner',
        },
      });
      isBlocked = true;
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

    if (phone && phone.trim()) {
      const trimmedPhone = phone.trim();
      const cleanDigits = trimmedPhone.replace(/\D/g, '');
      const last10 = cleanDigits.length >= 10 ? cleanDigits.slice(-10) : cleanDigits;

      if (last10.length >= 7) {
        orConditions.push({ customerPhone: { contains: last10 } });
      }
      orConditions.push({ customerPhone: trimmedPhone });
    }

    if (name && name.trim()) {
      orConditions.push({ customerName: { equals: name.trim(), mode: 'insensitive' } });
    }

    if (orConditions.length === 0) {
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

    const { todayStr, currentMinutes } = getISTDateAndMinutes();

    return bookings.map((b) => {
      const photos = normalizePhotoList(b.verifiedAdmin?.photoUrls);

      let isActive = false;
      if (b.status !== 'Cancelled') {
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

      return {
        id: b.id,
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
        isActive,
        location: b.verifiedAdmin
          ? `${b.verifiedAdmin.neighborhoodArea} • ${b.verifiedAdmin.streetAddress}`
          : (b.courtName || 'Main Arena'),
        imageUrl: photos[0],
        photoUrls: photos,
        createdAt: b.createdAt,
        updatedAt: b.updatedAt,
      };
    });
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

  async getTurfSubscription(id: number) {
    const turf = await this.findVerifiedAdmin(id, true);
    if (!turf) {
      throw new NotFoundException(`Turf with ID ${id} not found`);
    }

    const isSubscribed = !turf.isBookingHold && turf.status === 'VERIFIED';
    const now = new Date();
    const nextRenew = new Date(now.getFullYear(), now.getMonth() + 1, now.getDate());
    const renewDateStr = nextRenew.toLocaleDateString('en-IN', {
      day: '2-digit',
      month: 'short',
      year: 'numeric',
    });
    const daysRemaining = isSubscribed ? 30 : 0;
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
}
