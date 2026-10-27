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

function generateTimeSlots(openingTime: string, closingTime: string): string[] {
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
    const verified = await this.prisma.verifiedAdmin.findMany({
      include: {
        dashboard: true,
      },
      orderBy: { id: 'desc' },
    });

    return verified.map((t: any) => {
      const photos = Array.isArray(t.photoUrls) && t.photoUrls.length > 0
        ? t.photoUrls
        : ['https://picsum.photos/seed/turf1/800/400'];
      
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
        sports: ['Football', 'Box Cricket', 'Badminton'],
      };
    });
  }

  async getTurfById(id: number) {
    const turf = await this.findVerifiedAdmin(id, true, true);

    if (!turf) {
      throw new NotFoundException(`Turf with ID ${id} not found`);
    }

    const photos = Array.isArray(turf.photoUrls) && turf.photoUrls.length > 0
      ? turf.photoUrls
      : ['https://picsum.photos/seed/turf1/800/400'];
    
    const amenities = Array.isArray(turf.amenities) && turf.amenities.length > 0
      ? turf.amenities
      : ['Drinking Water', 'Parking', 'Floodlights', 'Restroom'];

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
      sports: ['Football', 'Box Cricket', 'Badminton'],
      dashboard: turf.dashboard,
      bookings: turf.bookings,
      blockedSlots: turf.blockedSlots,
    };
  }

  async getTurfSlots(id: number, date?: string, role?: string) {
    const turf = await this.findVerifiedAdmin(id, true, false);

    if (!turf) {
      throw new NotFoundException(`Turf with ID ${id} not found`);
    }

    const verifiedAdminId = turf.id;

    const now = new Date();
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    const targetDate = date || todayStr;

    const [year, month, d] = targetDate.split('-').map(Number);
    const dateObj = new Date(year, month - 1, d);
    const dayOfWeek = dateObj.getDay(); // 0 is Sunday, 6 is Saturday
    const isWeekend = (dayOfWeek === 0 || dayOfWeek === 6);

    const dayRate = turf.dayRate || 1000.0;
    const nightRate = turf.nightRate || 1400.0;
    const weekdayRate = turf.weekdayRate || 1200.0;
    const weekendRate = turf.weekendRate || 1600.0;

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
      bookedSlotMap.set(b.timeSlot, b);
    }

    const blockedSlotSet = new Set<string>();
    for (const bl of blocked) {
      blockedSlotSet.add(bl.timeSlot);
    }

    const currentMinutes = now.getHours() * 60 + now.getMinutes();
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

      let status = 'available';
      if (isBooked) status = 'booked';
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

      return {
        slot,
        time: slot,
        status,
        price,
        rateType,
        isNight,
        isWeekend,
        booking: isBooked ? bookedSlotMap.get(slot) : null,
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

    if (!date || !timeSlot) {
      throw new BadRequestException('Date and timeSlot are required for booking');
    }

    // Validate that slot is not in the past or within 5-minute cutoff
    const now = new Date();
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    if (date < todayStr) {
      throw new BadRequestException('Cannot book slots for a past date');
    }
    if (date === todayStr) {
      const currentMinutes = now.getHours() * 60 + now.getMinutes();
      const startMin = parseSlotStartMinutes(timeSlot);
      if (startMin !== -1 && currentMinutes >= startMin - 5) {
        throw new BadRequestException('This slot is no longer available for booking (booking closes 5 minutes before slot start time)');
      }
    }

    const turf = await this.findVerifiedAdmin(id, true, false);
    if (!turf) {
      throw new NotFoundException(`Turf #${id} not found`);
    }

    const verifiedAdminId = turf.id;

    const bookingAmount = Number(amount) || 1200.0;

    let booking: any;
    try {
      booking = await this.prisma.$transaction(
        async (tx) => {
          // 1. Atomically check if slot is already booked inside transaction
          const existing = await tx.turfBooking.findFirst({
            where: {
              verifiedAdminId,
              date,
              timeSlot,
              status: { not: 'Cancelled' },
            },
          });
          if (existing) {
            throw new ConflictException(`Slot "${timeSlot}" on ${date} is already booked!`);
          }

          // 2. Atomically check if slot is blocked by owner inside transaction
          const blocked = await tx.blockedSlot.findFirst({
            where: {
              verifiedAdminId,
              date,
              timeSlot,
            },
          });
          if (blocked) {
            throw new BadRequestException(`Slot "${timeSlot}" on ${date} is blocked for maintenance by the owner.`);
          }

          // 3. Atomically create the booking (protected by unique index & serializable lock)
          return await tx.turfBooking.create({
            data: {
              verifiedAdminId,
              customerName: customerName?.trim() || 'Player Customer',
              customerPhone: customerPhone?.trim() || '9876543210',
              sport: sport || 'Football',
              courtName: courtName || `${turf.venueName} Main Arena`,
              date,
              timeSlot,
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
        throw new ConflictException(`Slot "${timeSlot}" on ${date} was just booked by another user. Please choose another available slot.`);
      }
      throw err;
    }

    // Automatically update AdminDashboard metrics based on actual database bookings
    const monthPrefix = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

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

    const now = new Date();
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

    return bookings.map((b) => {
      const photos = Array.isArray(b.verifiedAdmin?.photoUrls) && b.verifiedAdmin.photoUrls.length > 0
        ? b.verifiedAdmin.photoUrls
        : ['https://picsum.photos/seed/booking/250/250'];

      const isActive = b.status !== 'Cancelled' && b.date >= todayStr;

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

  async cancelBooking(bookingId: number) {
    const booking = await this.prisma.turfBooking.findUnique({
      where: { id: bookingId },
    });
    if (!booking) {
      throw new NotFoundException(`Booking #${bookingId} not found`);
    }

    const updated = await this.prisma.turfBooking.update({
      where: { id: bookingId },
      data: { status: 'Cancelled' },
    });

    return {
      success: true,
      message: 'Booking cancelled successfully',
      booking: updated,
    };
  }
}
