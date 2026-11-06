import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from './prisma.service.js';

@Injectable()
export class SuperAdminService {
  constructor(private readonly prisma: PrismaService) {}

  async getStats() {
    const total = await this.prisma.adminUser.count();
    const waiting = await this.prisma.adminUser.count({
      where: { status: 'PENDING_APPROVAL' },
    });
    const verified = await this.prisma.adminUser.count({
      where: { status: 'VERIFIED' },
    });
    const cancelled = await this.prisma.adminUser.count({
      where: { status: 'CANCELLED' },
    });
    const totalVerifiedTable = await this.prisma.verifiedAdmin.count();

    return {
      total,
      waiting,
      verified,
      cancelled,
      totalVerifiedTable,
    };
  }

  async getRegistrations(query: {
    status?: string;
    search?: string;
    page?: string | number;
    limit?: string | number;
  }) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.max(1, Math.min(100, Number(query.limit) || 50));
    const skip = (page - 1) * limit;

    const where: any = {};

    if (query.status && query.status.toUpperCase() !== 'ALL') {
      where.status = query.status.toUpperCase();
    }

    if (query.search && query.search.trim() !== '') {
      const s = query.search.trim();
      where.OR = [
        { venueName: { contains: s, mode: 'insensitive' } },
        { ownerName: { contains: s, mode: 'insensitive' } },
        { ownerPhone: { contains: s, mode: 'insensitive' } },
        { ownerEmail: { contains: s, mode: 'insensitive' } },
        { trackingCode: { contains: s, mode: 'insensitive' } },
        { neighborhoodArea: { contains: s, mode: 'insensitive' } },
      ];
    }

    const [items, totalCount, stats] = await Promise.all([
      this.prisma.adminUser.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.adminUser.count({ where }),
      this.getStats(),
    ]);

    return {
      items,
      pagination: {
        page,
        limit,
        totalCount,
        totalPages: Math.ceil(totalCount / limit),
      },
      stats,
    };
  }

  async getRegistrationById(id: number) {
    const admin = await this.prisma.adminUser.findUnique({
      where: { id },
    });
    if (!admin) {
      throw new NotFoundException(`Admin registration #${id} not found`);
    }

    const verifiedRecord = await this.prisma.verifiedAdmin.findUnique({
      where: { adminUserId: id },
    });

    return {
      ...admin,
      verifiedRecord,
    };
  }

  async verifyRegistration(id: number, body?: { verifiedBy?: string }) {
    const admin = await this.prisma.adminUser.findUnique({
      where: { id },
    });
    if (!admin) {
      throw new NotFoundException(`Admin registration #${id} not found`);
    }

    // 1. Update AdminUser status
    const updatedAdmin = await this.prisma.adminUser.update({
      where: { id },
      data: {
        status: 'VERIFIED',
        cancelReason: null,
      },
    });

    // 2. Insert or update into VerifiedAdmin table
    const verifiedAdmin = await this.prisma.verifiedAdmin.upsert({
      where: { adminUserId: id },
      update: {
        trackingCode: admin.trackingCode,
        venueName: admin.venueName,
        ownerName: admin.ownerName,
        ownerPhone: admin.ownerPhone,
        ownerEmail: admin.ownerEmail,
        streetAddress: admin.streetAddress,
        neighborhoodArea: admin.neighborhoodArea,
        isMobileVerified: admin.isMobileVerified,
        isEmailVerified: admin.isEmailVerified,
        photosCount: admin.photosCount,
        photoUrls: admin.photoUrls,
        amenities: admin.amenities,
        gstin: admin.gstin,
        panNumber: admin.panNumber,
        aadhaarNumber: admin.aadhaarNumber,
        aadhaarDocUrl: admin.aadhaarDocUrl,
        panDocUrl: admin.panDocUrl,
        gstDocUrl: admin.gstDocUrl,
        bankAccount: admin.bankAccount,
        ifscCode: admin.ifscCode,
        upiId: admin.upiId,
        status: 'VERIFIED',
        verifiedAt: new Date(),
        verifiedBy: body?.verifiedBy || 'Super Admin',
      },
      create: {
        adminUserId: admin.id,
        trackingCode: admin.trackingCode,
        venueName: admin.venueName,
        ownerName: admin.ownerName,
        ownerPhone: admin.ownerPhone,
        ownerEmail: admin.ownerEmail,
        streetAddress: admin.streetAddress,
        neighborhoodArea: admin.neighborhoodArea,
        isMobileVerified: admin.isMobileVerified,
        isEmailVerified: admin.isEmailVerified,
        photosCount: admin.photosCount,
        photoUrls: admin.photoUrls,
        amenities: admin.amenities,
        gstin: admin.gstin,
        panNumber: admin.panNumber,
        aadhaarNumber: admin.aadhaarNumber,
        aadhaarDocUrl: admin.aadhaarDocUrl,
        panDocUrl: admin.panDocUrl,
        gstDocUrl: admin.gstDocUrl,
        bankAccount: admin.bankAccount,
        ifscCode: admin.ifscCode,
        upiId: admin.upiId,
        status: 'VERIFIED',
        verifiedAt: new Date(),
        verifiedBy: body?.verifiedBy || 'Super Admin',
      },
    });

    // 3. Ensure AdminDashboard record is created with initial 0s
    await this.prisma.adminDashboard.upsert({
      where: { verifiedAdminId: verifiedAdmin.id },
      create: { verifiedAdminId: verifiedAdmin.id },
      update: {},
    });

    return {
      success: true,
      message: 'Venue owner successfully verified and added to VerifiedAdmin',
      admin: updatedAdmin,
      verifiedAdmin,
    };
  }

  async cancelRegistration(id: number, body?: { reason?: string }) {
    const admin = await this.prisma.adminUser.findUnique({
      where: { id },
    });
    if (!admin) {
      throw new NotFoundException(`Admin registration #${id} not found`);
    }

    const cancelReason = body?.reason?.trim() || 'Application cancelled/rejected by Super Admin';

    // 1. Update AdminUser status
    const updatedAdmin = await this.prisma.adminUser.update({
      where: { id },
      data: {
        status: 'CANCELLED',
        cancelReason,
      },
    });

    // 2. Remove from VerifiedAdmin if present
    await this.prisma.verifiedAdmin.deleteMany({
      where: { adminUserId: id },
    });

    return {
      success: true,
      message: 'Application cancelled successfully',
      admin: updatedAdmin,
    };
  }

  async getVerifiedAdmins(query: {
    search?: string;
    page?: string | number;
    limit?: string | number;
  }) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.max(1, Math.min(100, Number(query.limit) || 50));
    const skip = (page - 1) * limit;

    const where: any = {};

    if (query.search && query.search.trim() !== '') {
      const s = query.search.trim();
      where.OR = [
        { venueName: { contains: s, mode: 'insensitive' } },
        { ownerName: { contains: s, mode: 'insensitive' } },
        { ownerPhone: { contains: s, mode: 'insensitive' } },
        { ownerEmail: { contains: s, mode: 'insensitive' } },
        { trackingCode: { contains: s, mode: 'insensitive' } },
        { neighborhoodArea: { contains: s, mode: 'insensitive' } },
      ];
    }

    const [items, totalCount] = await Promise.all([
      this.prisma.verifiedAdmin.findMany({
        where,
        include: { dashboard: true },
        orderBy: { verifiedAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.verifiedAdmin.count({ where }),
    ]);

    return {
      items,
      pagination: {
        page,
        limit,
        totalCount,
        totalPages: Math.ceil(totalCount / limit),
      },
    };
  }

  async getVerifiedAdminById(id: number) {
    let verifiedAdmin = await this.prisma.verifiedAdmin.findUnique({
      where: { id },
      include: { dashboard: true },
    });
    if (!verifiedAdmin) {
      verifiedAdmin = await this.prisma.verifiedAdmin.findFirst({
        where: { adminUserId: id },
        include: { dashboard: true },
      });
    }
    if (!verifiedAdmin) {
      throw new NotFoundException(`Verified admin #${id} not found`);
    }
    return verifiedAdmin;
  }

  async getAdminStatus(adminIdOrTracking: string) {
    const numId = Number(adminIdOrTracking);
    let admin: any = null;

    if (!isNaN(numId)) {
      admin = await this.prisma.adminUser.findUnique({
        where: { id: numId },
      });
    }

    if (!admin) {
      admin = await this.prisma.adminUser.findFirst({
        where: { trackingCode: adminIdOrTracking },
      });
    }

    if (!admin) {
      throw new NotFoundException('Admin application not found');
    }

    const isVerifiedTable = await this.prisma.verifiedAdmin.findUnique({
      where: { adminUserId: admin.id },
    });

    return {
      adminId: admin.id,
      trackingCode: admin.trackingCode,
      venueName: admin.venueName,
      ownerName: admin.ownerName,
      status: admin.status,
      cancelReason: admin.cancelReason,
      isVerifiedInTable: !!isVerifiedTable,
      updatedAt: admin.updatedAt,
    };
  }

  // ==========================================
  // SUPERCHARGED SUPER ADMIN ANALYTICS & CONTROLS
  // ==========================================

  async getDashboardOverview() {
    const now = new Date();
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;

    // Fresh database: only load tournaments created by turf owners

    // 1. Core KPIs
    const [
      totalUsers,
      totalOwners,
      verifiedOwners,
      pendingOwners,
      allBookings,
      allTurfs,
      allTournaments,
    ] = await Promise.all([
      this.prisma.user.count(),
      this.prisma.adminUser.count(),
      this.prisma.verifiedAdmin.count({ where: { status: 'VERIFIED' } }),
      this.prisma.adminUser.count({ where: { status: 'PENDING_APPROVAL' } }),
      this.prisma.turfBooking.findMany({
        include: {
          verifiedAdmin: {
            select: { id: true, venueName: true, neighborhoodArea: true },
          },
        },
        orderBy: { createdAt: 'desc' },
      }),
      this.prisma.verifiedAdmin.findMany({
        include: {
          bookings: true,
          dashboard: true,
        },
      }),
      this.prisma.tournament.findMany({
        orderBy: { createdAt: 'desc' },
      }),
    ]);

    // Aggregate booking metrics
    const nonCancelledBookings = allBookings.filter((b) => b.status !== 'Cancelled');
    const totalRevenue = nonCancelledBookings.reduce((sum, b) => sum + (Number(b.amount) || 0), 0);
    const totalBookingsCount = allBookings.length;

    const todayBookings = allBookings.filter((b) => b.date === todayStr);
    const todayConfirmed = todayBookings.filter((b) => b.status !== 'Cancelled');
    const todayCancelled = todayBookings.filter((b) => b.status === 'Cancelled');
    const todayRevenue = todayConfirmed.reduce((sum, b) => sum + (Number(b.amount) || 0), 0);

    const todayAdvancePaid = todayConfirmed
      .filter((b) => !b.paymentMethod?.toLowerCase().includes('cash'))
      .reduce((sum, b) => sum + (Number(b.amount) || 0), 0);

    const todayCashAmount = todayConfirmed
      .filter((b) => b.paymentMethod?.toLowerCase().includes('cash'))
      .reduce((sum, b) => sum + (Number(b.amount) || 0), 0);

    // 2. Tournaments Summary
    const tournamentsSummary = {
      total: allTournaments.length,
      live: allTournaments.filter((t) => (t.status === 'LIVE' || t.status === 'Ongoing') && !t.isHold).length,
      upcoming: allTournaments.filter((t) => t.status === 'UPCOMING' && !t.isHold).length,
      finished: allTournaments.filter((t) => t.status === 'FINISHED' || t.status === 'Completed').length,
      onHold: allTournaments.filter((t) => t.isHold || t.status === 'ON_HOLD').length,
    };

    // 3. Turf Revenue & Bookings Breakdown
    const turfRevenueBreakdown = allTurfs.map((t) => {
      const turfBookings = t.bookings || [];
      const validTurfBookings = turfBookings.filter((b) => b.status !== 'Cancelled');
      const turfTodayBookings = turfBookings.filter((b) => b.date === todayStr && b.status !== 'Cancelled');
      const turfTodayCancelled = turfBookings.filter((b) => b.date === todayStr && b.status === 'Cancelled');

      const turfTotalRev = validTurfBookings.reduce((sum, b) => sum + (Number(b.amount) || 0), 0);
      const turfTodayRev = turfTodayBookings.reduce((sum, b) => sum + (Number(b.amount) || 0), 0);

      return {
        turfId: t.id,
        venueName: t.venueName,
        ownerName: t.ownerName,
        ownerPhone: t.ownerPhone,
        neighborhoodArea: t.neighborhoodArea,
        status: t.status,
        isBookingHold: t.isBookingHold ?? false,
        todayBookingsCount: turfTodayBookings.length,
        todayRevenue: turfTodayRev,
        todayCancelled: turfTodayCancelled.length,
        totalBookingsCount: validTurfBookings.length,
        totalRevenue: turfTotalRev,
        activeRateWeekday: t.weekdayRate,
        activeRateWeekend: t.weekendRate,
      };
    });

    // 4. Player Analytics: how many times each player booked
    const playerBookingsMap = new Map<string, {
      customerName: string;
      customerPhone: string;
      totalBookings: number;
      totalSpent: number;
      lastBookingDate: string;
      favoriteSport: string;
      sportsMap: Record<string, number>;
    }>();

    allBookings.forEach((b) => {
      const phone = (b.customerPhone || 'Unknown').trim();
      const existing = playerBookingsMap.get(phone) || {
        customerName: b.customerName || 'Player',
        customerPhone: phone,
        totalBookings: 0,
        totalSpent: 0,
        lastBookingDate: b.date || '',
        favoriteSport: b.sport || 'Football',
        sportsMap: {},
      };

      existing.totalBookings += 1;
      if (b.status !== 'Cancelled') {
        existing.totalSpent += Number(b.amount) || 0;
      }
      if (!existing.lastBookingDate || b.date > existing.lastBookingDate) {
        existing.lastBookingDate = b.date;
      }
      existing.sportsMap[b.sport] = (existing.sportsMap[b.sport] || 0) + 1;
      playerBookingsMap.set(phone, existing);
    });

    const playerStats = Array.from(playerBookingsMap.values())
      .map((p) => {
        let bestSport = 'Football';
        let maxCount = 0;
        Object.entries(p.sportsMap).forEach(([sport, count]) => {
          if (count > maxCount) {
            maxCount = count;
            bestSport = sport;
          }
        });
        return {
          customerName: p.customerName,
          customerPhone: p.customerPhone,
          totalBookings: p.totalBookings,
          totalSpent: p.totalSpent,
          lastBookingDate: p.lastBookingDate,
          favoriteSport: bestSport,
        };
      })
      .sort((a, b) => b.totalBookings - a.totalBookings)
      .slice(0, 30);

    // 5. Recent Live Actions (Platform Activity Stream)
    const recentLiveActions: any[] = [];

    // Recent bookings (up to 15)
    allBookings.slice(0, 15).forEach((b) => {
      recentLiveActions.push({
        id: `bk_${b.id}`,
        type: b.status === 'Cancelled' ? 'CANCELLATION' : b.isHold ? 'HOLD' : 'BOOKING',
        title: b.status === 'Cancelled' ? 'Booking Cancelled' : b.isHold ? 'Booking Held' : 'New Slot Booking',
        description: `${b.customerName} (${b.customerPhone}) • ${b.courtName} • ${b.timeSlot}`,
        amount: b.amount,
        turfName: b.verifiedAdmin?.venueName || 'Venue',
        status: b.status,
        timestamp: b.createdAt,
      });
    });

    // Recent registrations (up to 5)
    const recentAdmins = await this.prisma.adminUser.findMany({
      take: 6,
      orderBy: { createdAt: 'desc' },
    });
    recentAdmins.forEach((a) => {
      recentLiveActions.push({
        id: `reg_${a.id}`,
        type: a.status === 'VERIFIED' ? 'VERIFICATION' : 'REGISTRATION',
        title: a.status === 'VERIFIED' ? 'Venue Partner Verified' : 'New Venue Application',
        description: `${a.ownerName} submitted ${a.venueName} in ${a.neighborhoodArea}`,
        turfName: a.venueName,
        status: a.status,
        timestamp: a.createdAt,
      });
    });

    // Recent tournaments
    allTournaments.slice(0, 5).forEach((t) => {
      recentLiveActions.push({
        id: `tourn_${t.id}`,
        type: 'TOURNAMENT',
        title: t.isHold ? 'Tournament Placed on Hold' : 'Tournament Hosted',
        description: `${t.title} (${t.sport}) • Prize: ${t.prizePool || 'Trophy'}`,
        turfName: t.venueName,
        status: t.status,
        timestamp: t.createdAt,
      });
    });

    recentLiveActions.sort(
      (a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime(),
    );

    return {
      kpis: {
        totalUsers,
        totalOwners,
        verifiedOwners,
        pendingOwners,
        totalRevenue,
        totalBookingsCount,
        todayBookingsCount: todayConfirmed.length,
        todayCancelledCount: todayCancelled.length,
        todayRevenue,
        todayAdvancePaid,
        todayCashAmount,
      },
      tournamentsSummary,
      turfRevenueBreakdown,
      playerStats,
      recentLiveActions: recentLiveActions.slice(0, 25),
    };
  }

  // HOLD / RESUME TURF BOOKINGS
  async toggleTurfBookingHold(turfId: number, body?: { hold?: boolean }) {
    const turf = await this.prisma.verifiedAdmin.findUnique({
      where: { id: turfId },
    });
    if (!turf) {
      throw new NotFoundException(`Turf #${turfId} not found`);
    }

    const currentHold = turf.isBookingHold ?? false;
    const newHold = body?.hold !== undefined ? body.hold : !currentHold;

    const updated = await this.prisma.verifiedAdmin.update({
      where: { id: turfId },
      data: {
        isBookingHold: newHold,
        status: newHold ? 'HOLD' : 'VERIFIED',
      },
    });

    return {
      success: true,
      turfId,
      venueName: updated.venueName,
      isBookingHold: updated.isBookingHold,
      status: updated.status,
      message: newHold
        ? `Bookings for "${updated.venueName}" are now ON HOLD.`
        : `Bookings for "${updated.venueName}" are now RESUMED and live.`,
    };
  }

  // ALL BOOKINGS WITH ADVANCED FILTERS
  async getAllBookings(query: {
    search?: string;
    turfId?: string | number;
    status?: string;
    date?: string;
    page?: string | number;
    limit?: string | number;
  }) {
    const page = Math.max(1, Number(query.page) || 1);
    const limit = Math.max(1, Math.min(100, Number(query.limit) || 50));
    const skip = (page - 1) * limit;

    const where: any = {};

    if (query.turfId) {
      where.verifiedAdminId = Number(query.turfId);
    }
    if (query.status && query.status.toUpperCase() !== 'ALL') {
      where.status = query.status;
    }
    if (query.date) {
      where.date = query.date;
    }
    if (query.search && query.search.trim()) {
      const s = query.search.trim();
      where.OR = [
        { customerName: { contains: s, mode: 'insensitive' } },
        { customerPhone: { contains: s, mode: 'insensitive' } },
        { courtName: { contains: s, mode: 'insensitive' } },
        { sport: { contains: s, mode: 'insensitive' } },
        { timeSlot: { contains: s, mode: 'insensitive' } },
        { verifiedAdmin: { venueName: { contains: s, mode: 'insensitive' } } },
      ];
    }

    const [items, totalCount] = await Promise.all([
      this.prisma.turfBooking.findMany({
        where,
        include: {
          verifiedAdmin: {
            select: { id: true, venueName: true, neighborhoodArea: true, ownerPhone: true },
          },
        },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.turfBooking.count({ where }),
    ]);

    return {
      items,
      pagination: {
        page,
        limit,
        totalCount,
        totalPages: Math.ceil(totalCount / limit),
      },
    };
  }

  // HOLD / UNHOLD SPECIFIC BOOKING
  async toggleBookingHold(bookingId: number, body?: { isHold?: boolean }) {
    const booking = await this.prisma.turfBooking.findUnique({
      where: { id: bookingId },
    });
    if (!booking) {
      throw new NotFoundException(`Booking #${bookingId} not found`);
    }

    const currentHold = booking.isHold ?? false;
    const newHold = body?.isHold !== undefined ? body.isHold : !currentHold;

    const updated = await this.prisma.turfBooking.update({
      where: { id: bookingId },
      data: {
        isHold: newHold,
        status: newHold ? 'On Hold' : 'Confirmed',
      },
    });

    return {
      success: true,
      booking: updated,
      message: newHold
        ? `Booking #${bookingId} for ${updated.customerName} has been put ON HOLD.`
        : `Booking #${bookingId} has been released and CONFIRMED.`,
    };
  }

  // CANCEL BOOKING FROM SUPER ADMIN
  async cancelBooking(bookingId: number, body?: { reason?: string }) {
    const booking = await this.prisma.turfBooking.findUnique({
      where: { id: bookingId },
    });
    if (!booking) {
      throw new NotFoundException(`Booking #${bookingId} not found`);
    }

    const updated = await this.prisma.turfBooking.update({
      where: { id: bookingId },
      data: {
        status: 'Cancelled',
        isHold: false,
      },
    });

    return {
      success: true,
      booking: updated,
      message: `Booking #${bookingId} cancelled by Super Admin. (Reason: ${body?.reason || 'Administrative action'})`,
    };
  }

  // TOURNAMENTS
  async getAllTournaments(query: { status?: string; search?: string }) {
    const where: any = {};
    if (query.status && query.status.toUpperCase() !== 'ALL') {
      if (query.status.toUpperCase() === 'ON_HOLD') {
        where.OR = [{ isHold: true }, { status: 'ON_HOLD' }];
      } else {
        where.status = { equals: query.status.toUpperCase(), mode: 'insensitive' };
      }
    }
    if (query.search && query.search.trim()) {
      const s = query.search.trim();
      where.OR = [
        { title: { contains: s, mode: 'insensitive' } },
        { sport: { contains: s, mode: 'insensitive' } },
        { venueName: { contains: s, mode: 'insensitive' } },
      ];
    }

    const items = await this.prisma.tournament.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: {
        verifiedAdmin: {
          select: { id: true, venueName: true, neighborhoodArea: true, ownerPhone: true },
        },
      },
    });

    return { items };
  }

  // HOLD / UNHOLD TOURNAMENT
  async toggleTournamentHold(tournamentId: number, body?: { isHold?: boolean }) {
    const tourn = await this.prisma.tournament.findUnique({
      where: { id: tournamentId },
    });
    if (!tourn) {
      throw new NotFoundException(`Tournament #${tournamentId} not found`);
    }

    const currentHold = tourn.isHold ?? false;
    const newHold = body?.isHold !== undefined ? body.isHold : !currentHold;

    const updated = await this.prisma.tournament.update({
      where: { id: tournamentId },
      data: {
        isHold: newHold,
        status: newHold ? 'ON_HOLD' : (tourn.status === 'ON_HOLD' ? 'LIVE' : tourn.status),
      },
    });

    return {
      success: true,
      tournament: updated,
      message: newHold
        ? `Tournament "${updated.title}" placed ON HOLD.`
        : `Tournament "${updated.title}" is now RESUMED & ACTIVE.`,
    };
  }

  // CREATE TOURNAMENT VIA SUPER ADMIN
  async createTournament(body: any) {
    const { title, sport, format, venueName, date, time, entryFee, prizePool, maxTeams, organizerName, verifiedAdminId } = body;
    if (!title || !venueName || !date) {
      throw new BadRequestException('Title, venueName, and date are required.');
    }

    const created = await this.prisma.tournament.create({
      data: {
        title,
        sport: sport || 'Football',
        format: format || 'Knockout',
        status: 'UPCOMING',
        isHold: false,
        venueName,
        date,
        time: time || '09:00 AM',
        entryFee: Number(entryFee) || 0,
        prizePool: prizePool || 'Trophy',
        maxTeams: Number(maxTeams) || 16,
        registeredTeams: 0,
        organizerName: organizerName || 'Games24 Platform',
        verifiedAdminId: verifiedAdminId ? Number(verifiedAdminId) : null,
      },
    });

    return {
      success: true,
      tournament: created,
    };
  }
}
