import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from './prisma.service.js';
import { getAdminSports, saveAdminSports } from './auth.service.js';

@Injectable()
export class SuperAdminService {
  constructor(private readonly prisma: PrismaService) {}

  async getStats() {
    const total = await this.prisma.adminUser.count({
      where: { status: { not: 'DRAFT' } },
    });
    const waiting = await this.prisma.adminUser.count({
      where: { status: 'PENDING_APPROVAL' },
    });
    const verified = await this.prisma.adminUser.count({
      where: { status: { in: ['VERIFIED', 'APPROVED'] } },
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
    } else {
      where.status = { not: 'DRAFT' };
    }

    // Safety constraint: Never return DRAFT registrations to Super Admin
    where.AND = [
      ...(where.AND || []),
      { status: { not: 'DRAFT' } },
    ];

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

    const [rawItems, totalCount, stats] = await Promise.all([
      this.prisma.adminUser.findMany({
        where,
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
      }),
      this.prisma.adminUser.count({ where }),
      this.getStats(),
    ]);

    const items = await Promise.all(
      rawItems.map(async (item) => {
        const sportsList = getAdminSports(item.id);
        let parentTurf: any = null;
        if (item.isBranch && item.parentTurfId) {
          parentTurf = await this.prisma.verifiedAdmin.findUnique({
            where: { id: item.parentTurfId },
            select: {
              id: true,
              venueName: true,
              ownerName: true,
              ownerPhone: true,
              neighborhoodArea: true,
              streetAddress: true,
            },
          });
          if (!parentTurf) {
            parentTurf = await this.prisma.adminUser.findUnique({
              where: { id: item.parentTurfId },
              select: {
                id: true,
                venueName: true,
                ownerName: true,
                ownerPhone: true,
                neighborhoodArea: true,
                streetAddress: true,
              },
            });
          }
        }
        return {
          ...item,
          sports: sportsList.map((s: any) => s.name),
          sportsList,
          parentTurf,
          parentTurfName: parentTurf?.venueName || null,
          parentTurfPhone: parentTurf?.ownerPhone || item.ownerPhone,
          parentTurfArea: parentTurf?.neighborhoodArea || null,
        };
      }),
    );

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
    if (!admin || admin.status === 'DRAFT') {
      throw new NotFoundException(`Admin registration #${id} not found or incomplete draft`);
    }

    const verifiedRecord = await this.prisma.verifiedAdmin.findUnique({
      where: { adminUserId: id },
    });

    const sportsList = getAdminSports(admin.id);

    let parentTurf: any = null;
    if (admin.isBranch && admin.parentTurfId) {
      parentTurf = await this.prisma.verifiedAdmin.findUnique({
        where: { id: admin.parentTurfId },
        select: {
          id: true,
          venueName: true,
          ownerName: true,
          ownerPhone: true,
          neighborhoodArea: true,
          streetAddress: true,
        },
      });
      if (!parentTurf) {
        parentTurf = await this.prisma.adminUser.findUnique({
          where: { id: admin.parentTurfId },
          select: {
            id: true,
            venueName: true,
            ownerName: true,
            ownerPhone: true,
            neighborhoodArea: true,
            streetAddress: true,
          },
        });
      }
    }

    return {
      ...admin,
      sports: sportsList.map((s: any) => s.name),
      sportsList,
      verifiedRecord,
      parentTurf,
      parentTurfName: parentTurf?.venueName || null,
      parentTurfPhone: parentTurf?.ownerPhone || admin.ownerPhone,
      parentTurfArea: parentTurf?.neighborhoodArea || null,
    };
  }

  async verifyRegistration(id: number, body?: { verifiedBy?: string }) {
    const admin = await this.prisma.adminUser.findUnique({
      where: { id },
    });
    if (!admin) {
      throw new NotFoundException(`Admin registration #${id} not found`);
    }

    if (admin.status === 'DRAFT') {
      throw new BadRequestException('Cannot verify incomplete draft registration. The turf owner has not completed all steps and submitted the application.');
    }

    if (!admin.isBranch) {
      if (!admin.isMobileVerified || !admin.isEmailVerified) {
        throw new BadRequestException('Cannot verify registration: Mobile or Email OTP verification is incomplete.');
      }
      if (admin.photosCount === 0 && (!admin.photoUrls || admin.photoUrls.length === 0)) {
        throw new BadRequestException('Cannot verify registration: Venue photos must be uploaded.');
      }
      if (!admin.aadhaarNumber || !admin.panNumber || !admin.bankAccount) {
        throw new BadRequestException('Cannot verify registration: Complete KYC and Bank details are required.');
      }
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
        latitude: admin.latitude,
        longitude: admin.longitude,
        googleMapsUrl: admin.googleMapsUrl,
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
        isBranch: admin.isBranch ?? false,
        parentTurfId: admin.parentTurfId,
        alternativePhone: admin.alternativePhone,
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
        latitude: admin.latitude,
        longitude: admin.longitude,
        googleMapsUrl: admin.googleMapsUrl,
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
        isBranch: admin.isBranch ?? false,
        parentTurfId: admin.parentTurfId,
        alternativePhone: admin.alternativePhone,
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

    // 4. Synchronize sports configuration from registration to verifiedAdmin
    try {
      const registeredSports = getAdminSports(admin.id);
      saveAdminSports(verifiedAdmin.id, registeredSports);
    } catch (e) {
      console.error('Error syncing sports to verified admin:', e);
    }

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

    const cleanPhone = (verifiedAdmin.ownerPhone || '').trim().replace(/\D/g, '');
    const approvedBranches = await this.prisma.verifiedAdmin.findMany({
      where: {
        id: { not: verifiedAdmin.id },
        OR: [
          { parentTurfId: verifiedAdmin.id },
          { ownerPhone: cleanPhone, isBranch: true },
        ],
      },
      include: { dashboard: true },
    });

    const pendingBranchApplications = await this.prisma.adminUser.findMany({
      where: {
        status: 'PENDING_APPROVAL',
        OR: [
          { parentTurfId: verifiedAdmin.id },
          { ownerPhone: cleanPhone, isBranch: true },
        ],
      },
      orderBy: { createdAt: 'desc' },
    });

    return {
      ...verifiedAdmin,
      approvedBranches,
      pendingBranchApplications,
    };
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

  // HOLD / RESUME TURF OWNER ACCOUNT & BOOKINGS
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

    // If placed on hold, hold all active tournaments hosted at this turf
    if (newHold) {
      await this.prisma.tournament.updateMany({
        where: { verifiedAdminId: turfId, status: { in: ['LIVE', 'UPCOMING'] } },
        data: { isHold: true, status: 'ON_HOLD' },
      }).catch(() => {});
    }

    return {
      success: true,
      turfId,
      venueName: updated.venueName,
      isBookingHold: updated.isBookingHold,
      status: updated.status,
      message: newHold
        ? `Account & bookings for "${updated.venueName}" are now ON HOLD.`
        : `Account & bookings for "${updated.venueName}" are now RESUMED and live.`,
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
      if (query.status.toUpperCase() === 'OPEN_MATCH') {
        where.isOpenMatch = true;
      } else if (query.status.toUpperCase() === 'REGULAR') {
        where.isOpenMatch = false;
      } else {
        where.status = query.status;
      }
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
      items: items.map((b) => {
        const formalCode = b.bookingCode || `G24-BK-${b.id.toString().padStart(4, '0')}`;
        return {
          ...b,
          bookingCode: formalCode,
          bookingId: formalCode,
        };
      }),
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

  // DELETE VERIFIED TURF OWNER ACCOUNT AND CASCADE REMOVAL
  async deleteVerifiedAdmin(turfId: number) {
    const turf = await this.prisma.verifiedAdmin.findUnique({
      where: { id: turfId },
    });
    if (!turf) {
      throw new NotFoundException(`Turf owner #${turfId} not found`);
    }

    const adminUserId = turf.adminUserId;
    const turfName = turf.venueName;

    // 1. Delete all tournaments created at this turf
    await this.prisma.tournament.deleteMany({
      where: { verifiedAdminId: turfId },
    }).catch(() => {});

    // 2. Delete open challenges associated with this turf
    await this.prisma.openChallenge.deleteMany({
      where: {
        OR: [
          { turfId: turfId },
          { turfName: { equals: turfName, mode: 'insensitive' } },
        ],
      },
    }).catch(() => {});

    // 3. Delete VerifiedAdmin (Prisma schema cascades bookings, blockedSlots, offers, dashboard)
    await this.prisma.verifiedAdmin.delete({
      where: { id: turfId },
    });

    // 4. Delete the original AdminUser record so it completely disappears from all admin lists
    if (adminUserId) {
      try {
        await this.prisma.adminUser.delete({
          where: { id: adminUserId },
        });
      } catch {// Ignored if already deleted
      }
    }

    return {
      success: true,
      turfId,
      message: `Turf owner account "${turfName}" and all associated data have been permanently removed.`,
    };
  }

  // DELETE TOURNAMENT PERMANENTLY
  async deleteTournament(tournamentId: number) {
    const tourn = await this.prisma.tournament.findUnique({
      where: { id: tournamentId },
    });
    if (!tourn) {
      throw new NotFoundException(`Tournament #${tournamentId} not found`);
    }

    await this.prisma.tournament.delete({
      where: { id: tournamentId },
    });

    return {
      success: true,
      tournamentId,
      message: `Tournament "${tourn.title}" has been permanently deleted.`,
    };
  }

  // --- IST Date & Match Validity Helpers ---
  private getIstNow(): { todayStr: string; currentHour: number; currentMinute: number } {
    const istOffsetMs = 5.5 * 60 * 60 * 1000;
    const istNow = new Date(Date.now() + istOffsetMs);
    const todayStr = istNow.toISOString().slice(0, 10);
    const currentHour = istNow.getUTCHours();
    const currentMinute = istNow.getUTCMinutes();
    return { todayStr, currentHour, currentMinute };
  }

  private isMatchUpcoming(matchDate?: string | null, timeSlot?: string | null): boolean {
    if (!matchDate) return false;
    const d = matchDate.trim().toLowerCase();
    const { todayStr, currentHour, currentMinute } = this.getIstNow();

    if (d === 'tomorrow') return true;
    if (d === 'today') {
      return this.isSlotUpcomingToday(timeSlot, currentHour, currentMinute);
    }

    const dateOnly = d.slice(0, 10);
    if (dateOnly > todayStr) return true;
    if (dateOnly < todayStr) return false;

    // Date is today - check if slot end time has passed
    return this.isSlotUpcomingToday(timeSlot, currentHour, currentMinute);
  }

  private isSlotUpcomingToday(timeSlot?: string | null, currentHour?: number, currentMinute?: number): boolean {
    if (!timeSlot) return true;
    try {
      const parts = timeSlot.split('-').map((s) => s.trim());
      const endPart = parts[parts.length - 1] || parts[0];
      const match = endPart.match(/(\d{1,2}):(\d{2})\s*(AM|PM)?/i);
      if (match) {
        let h = parseInt(match[1], 10);
        const m = parseInt(match[2], 10);
        const ampm = (match[3] || '').toUpperCase();
        if (ampm === 'PM' && h < 12) h += 12;
        if (ampm === 'AM' && h === 12) h = 0;
        if (
          currentHour != null &&
          currentMinute != null &&
          (h < currentHour || (h === currentHour && m <= currentMinute))
        ) {
          return false;
        }
      }
    } catch (_) {}
    return true;
  }

  private isMatchForToday(matchDate?: string | null): boolean {
    if (!matchDate) return false;
    const d = matchDate.trim().toLowerCase();
    const { todayStr } = this.getIstNow();
    return d === 'today' || d.slice(0, 10) === todayStr;
  }

  // RADAR: SURROUNDING PLAYERS BY RADIUS (KM) FOR A TURF OR GIVEN COORDINATES
  async getNearbyPlayers(params: {
    turfId?: number;
    lat?: number;
    lng?: number;
    radiusKm?: number;
  }) {
    // 0. Fetch all turfs for plotting across the map
    const [allVerifiedTurfs, allAdminTurfs, allChallenges] = await Promise.all([
      this.prisma.verifiedAdmin.findMany({
        where: {
          latitude: { not: null },
          longitude: { not: null },
        },
        select: {
          id: true,
          venueName: true,
          ownerName: true,
          ownerPhone: true,
          streetAddress: true,
          neighborhoodArea: true,
          latitude: true,
          longitude: true,
          googleMapsUrl: true,
          status: true,
        },
        orderBy: { id: 'asc' },
      }),
      this.prisma.adminUser.findMany({
        where: {
          latitude: { not: null },
          longitude: { not: null },
          status: 'PENDING_APPROVAL',
        },
        select: {
          id: true,
          venueName: true,
          ownerName: true,
          ownerPhone: true,
          streetAddress: true,
          neighborhoodArea: true,
          latitude: true,
          longitude: true,
          googleMapsUrl: true,
          status: true,
        },
        orderBy: { id: 'asc' },
      }),
      this.prisma.openChallenge.findMany({
        where: {
          status: { notIn: ['CANCELLED', 'COMPLETED'] },
        },
        select: {
          id: true,
          turfId: true,
          turfName: true,
          status: true,
          opponentName: true,
          date: true,
          time: true,
          challengerName: true,
          sport: true,
        },
      }),
    ]);

    const turfListSummary: Array<{
      id: number;
      venueName: string;
      ownerName: string;
      ownerPhone?: string;
      streetAddress: string;
      neighborhoodArea: string;
      latitude: number;
      longitude: number;
      googleMapsUrl: string;
      openMatchesCount: number;
      waitingChallengesCount: number;
      isVerified: boolean;
    }> = [];

    for (const t of allVerifiedTurfs) {
      if (t.latitude == null || t.longitude == null) continue;
      const upcomingChallenges = allChallenges.filter(
        (c) =>
          (c.turfId === t.id ||
            (c.turfName && t.venueName && c.turfName.toLowerCase().includes(t.venueName.toLowerCase()))) &&
          this.isMatchUpcoming(c.date, c.time)
      );

      // Deduplicate challenges by challengerName + date + time + sport
      const seen = new Set<string>();
      const turfChallenges = [];
      for (const c of upcomingChallenges) {
        const key = `${c.challengerName}_${c.date}_${c.time}_${c.sport}`.toLowerCase();
        if (!seen.has(key)) {
          seen.add(key);
          turfChallenges.push(c);
        }
      }

      const waitingCount = turfChallenges.filter(
        (c) => c.status !== 'ACCEPTED' && !c.opponentName
      ).length;

      turfListSummary.push({
        id: t.id,
        venueName: t.venueName,
        ownerName: t.ownerName,
        ownerPhone: t.ownerPhone || undefined,
        streetAddress: t.streetAddress || 'Madurai, Tamil Nadu',
        neighborhoodArea: t.neighborhoodArea || 'Madurai',
        latitude: t.latitude,
        longitude: t.longitude,
        googleMapsUrl: t.googleMapsUrl || `https://www.google.com/maps?q=${t.latitude},${t.longitude}`,
        openMatchesCount: turfChallenges.length,
        waitingChallengesCount: waitingCount,
        isVerified: true,
      });
    }

    for (const a of allAdminTurfs) {
      if (a.latitude == null || a.longitude == null) continue;
      if (!turfListSummary.some((t) => t.id === a.id)) {
        const upcomingChallenges = allChallenges.filter(
          (c) =>
            (c.turfId === a.id ||
              (c.turfName && a.venueName && c.turfName.toLowerCase().includes(a.venueName.toLowerCase()))) &&
            this.isMatchUpcoming(c.date, c.time)
        );

        // Deduplicate challenges
        const seen = new Set<string>();
        const turfChallenges = [];
        for (const c of upcomingChallenges) {
          const key = `${c.challengerName}_${c.date}_${c.time}_${c.sport}`.toLowerCase();
          if (!seen.has(key)) {
            seen.add(key);
            turfChallenges.push(c);
          }
        }

        const waitingCount = turfChallenges.filter(
          (c) => c.status !== 'ACCEPTED' && !c.opponentName
        ).length;

        turfListSummary.push({
          id: a.id,
          venueName: a.venueName,
          ownerName: a.ownerName,
          ownerPhone: a.ownerPhone || undefined,
          streetAddress: a.streetAddress || 'Madurai, Tamil Nadu',
          neighborhoodArea: a.neighborhoodArea || 'Madurai',
          latitude: a.latitude,
          longitude: a.longitude,
          googleMapsUrl: a.googleMapsUrl || `https://www.google.com/maps?q=${a.latitude},${a.longitude}`,
          openMatchesCount: turfChallenges.length,
          waitingChallengesCount: waitingCount,
          isVerified: false,
        });
      }
    }

    // Determine the targeted/selected turf
    let targetTurf = params.turfId
      ? turfListSummary.find((t) => t.id === params.turfId)
      : turfListSummary[0];

    // If still not found by id, try direct DB lookup
    if (!targetTurf && params.turfId) {
      const v = await this.prisma.verifiedAdmin.findUnique({ where: { id: params.turfId } });
      if (v && v.latitude != null && v.longitude != null) {
        targetTurf = {
          id: v.id,
          venueName: v.venueName,
          ownerName: v.ownerName,
          ownerPhone: v.ownerPhone || undefined,
          streetAddress: v.streetAddress || 'Madurai, Tamil Nadu',
          neighborhoodArea: v.neighborhoodArea || 'Madurai',
          latitude: v.latitude,
          longitude: v.longitude,
          googleMapsUrl: v.googleMapsUrl || `https://www.google.com/maps?q=${v.latitude},${v.longitude}`,
          openMatchesCount: 0,
          waitingChallengesCount: 0,
          isVerified: true,
        };
      }
    }

    let turfLat: number = targetTurf?.latitude ?? (params.lat ?? 9.9252);
    let turfLng: number = targetTurf?.longitude ?? (params.lng ?? 78.1198);

    let turfInfo: any = targetTurf
      ? { ...targetTurf }
      : {
          id: params.turfId || 0,
          venueName: 'Madurai Arena',
          ownerName: 'Turf Owner',
          streetAddress: 'Madurai, Tamil Nadu',
          neighborhoodArea: 'Madurai',
          latitude: turfLat,
          longitude: turfLng,
          googleMapsUrl: `https://www.google.com/maps?q=${turfLat},${turfLng}`,
          isVerified: true,
        };

    const radius = Math.max(1, params.radiusKm || 10);

    // Fetch players from database
    const dbUsers = await this.prisma.user.findMany({
      select: {
        id: true,
        fullName: true,
        mobileNumber: true,
        preferredSport: true,
        latitude: true,
        longitude: true,
        city: true,
        rank: true,
        matchesPlayed: true,
      },
    });

    // Haversine formula calculation
    const calculateDistance = (lat1: number, lon1: number, lat2: number, lon2: number): number => {
      const R = 6371; // Earth's radius in km
      const dLat = (lat2 - lat1) * (Math.PI / 180);
      const dLon = (lon2 - lon1) * (Math.PI / 180);
      const a =
        Math.sin(dLat / 2) * Math.sin(dLat / 2) +
        Math.cos(lat1 * (Math.PI / 180)) *
          Math.cos(lat2 * (Math.PI / 180)) *
          Math.sin(dLon / 2) *
          Math.sin(dLon / 2);
      const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
      return Math.round(R * c * 10) / 10;
    };

    const playersList: any[] = [];

    // 1. Process ONLY real registered players from our player app (no mock/fake players)
    for (const u of dbUsers) {
      if (u.latitude == null || u.longitude == null) continue;
      const dist = calculateDistance(turfLat, turfLng, u.latitude, u.longitude);
      playersList.push({
        id: u.id,
        fullName: u.fullName,
        mobileNumber: u.mobileNumber,
        preferredSport: u.preferredSport || 'Football',
        rank: u.rank || 'Striker',
        matchesPlayed: u.matchesPlayed || 0,
        city: u.city || turfInfo.neighborhoodArea || 'Madurai',
        latitude: Math.round(u.latitude * 10000) / 10000,
        longitude: Math.round(u.longitude * 10000) / 10000,
        distanceKm: dist,
        isRegisteredUser: true,
      });
    }

    // Filter by radius and sort by distance
    const filteredPlayers = playersList
      .filter((p) => p.distanceKm <= radius)
      .sort((a, b) => a.distanceKm - b.distanceKm);

    // 2. Query Real Open Challenges & Matches for this Turf
    const rawChallenges = await this.prisma.openChallenge.findMany({
      where: {
        OR: [
          ...(turfInfo.id ? [{ turfId: turfInfo.id }] : []),
          { turfName: { contains: turfInfo.venueName, mode: 'insensitive' as const } },
        ],
        status: { notIn: ['CANCELLED', 'COMPLETED'] },
      },
      orderBy: { createdAt: 'desc' },
      take: 40,
    });

    // Keep only real upcoming matches and deduplicate
    const seenMatchKeys = new Set<string>();
    const upcomingChallenges = [];
    for (const c of rawChallenges) {
      if (!this.isMatchUpcoming(c.date, c.time)) continue;
      const key = `${c.challengerName}_${c.date}_${c.time}_${c.sport}`.toLowerCase();
      if (!seenMatchKeys.has(key)) {
        seenMatchKeys.add(key);
        upcomingChallenges.push(c);
      }
    }

    // Sort upcoming challenges by date ascending
    upcomingChallenges.sort((a, b) => {
      const dateA = a.date || '';
      const dateB = b.date || '';
      return dateA.localeCompare(dateB);
    });

    const formattedOpenMatches = upcomingChallenges.map((c) => {
      const isOpponentFound = c.status === 'ACCEPTED' || !!c.opponentName;
      const isToday = this.isMatchForToday(c.date);
      return {
        id: c.id,
        turfId: c.turfId,
        turfName: c.turfName,
        date: c.date,
        time: c.time,
        sport: c.sport,
        challengerName: c.challengerName,
        challengerTeamInitials:
          c.challengerTeamInitials ||
          (c.challengerName ? c.challengerName.substring(0, 2).toUpperCase() : 'TC'),
        challengerColor: c.challengerColor || '4280148788',
        creatorPhone: c.creatorPhone,
        teamSize: c.teamSize || '7v7',
        status: isOpponentFound ? 'OPPONENT_FOUND' : 'WAITING_FOR_OPPONENT',
        statusLabel: isOpponentFound ? 'Opponent Got' : 'Waiting for Opponent',
        opponentName: c.opponentName || 'Open Slot',
        opponentTeamSize: c.opponentTeamSize || c.teamSize || '7v7',
        opponentContact: c.opponentContact || null,
        isToday,
      };
    });

    // 3. Query Real Bookings for TODAY for this Turf
    const { todayStr } = this.getIstNow();
    const bookings = turfInfo.id
      ? await this.prisma.turfBooking.findMany({
          where: {
            verifiedAdminId: turfInfo.id,
            status: { not: 'Cancelled' },
            date: todayStr,
          },
          orderBy: { timeSlot: 'asc' },
        })
      : [];

    // Standard hourly operating schedule
    const standardSlotTimes = [
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
    ];

    const slotsList = standardSlotTimes.map((slotTime) => {
      // Check if this slot has an open challenge SPECIFICALLY FOR TODAY
      const match = formattedOpenMatches.find((m) =>
        m.isToday && (
          m.time.toLowerCase().includes(slotTime.toLowerCase()) ||
          slotTime.toLowerCase().includes(m.time.split(' - ')[0]?.trim().toLowerCase() || '')
        )
      );
      if (match) {
        return {
          timeSlot: slotTime,
          status: 'OPEN_MATCH',
          sport: match.sport,
          rate: 1200,
          challenge: match,
        };
      }

      // Check if slot has a regular booking
      const booking = bookings.find((b) => b.timeSlot === slotTime);
      if (booking) {
        return {
          timeSlot: slotTime,
          status: 'BOOKED',
          sport: booking.sport,
          rate: booking.amount,
          customerName: booking.customerName,
          customerPhone: booking.customerPhone,
        };
      }

      return {
        timeSlot: slotTime,
        status: 'AVAILABLE',
        sport: 'Football',
        rate: 1200,
      };
    });

    const availableCount = slotsList.filter((s) => s.status === 'AVAILABLE').length;
    const bookedCount = slotsList.filter((s) => s.status === 'BOOKED').length;
    const openMatchesCount = slotsList.filter((s) => s.status === 'OPEN_MATCH').length;
    const waitingOpponentCount = formattedOpenMatches.filter((m) => m.status === 'WAITING_FOR_OPPONENT').length;
    const opponentGotCount = formattedOpenMatches.filter((m) => m.status === 'OPPONENT_FOUND').length;

    return {
      turf: turfInfo,
      allTurfs: turfListSummary,
      radiusKm: radius,
      totalPlayersFound: filteredPlayers.length,
      players: filteredPlayers,
      slotsOverview: {
        totalSlots: standardSlotTimes.length,
        availableCount,
        bookedCount,
        openMatchesCount,
        waitingOpponentCount,
        opponentGotCount,
        slots: slotsList,
      },
      openMatches: formattedOpenMatches,
    };
  }

  // UPDATE TURF COORDINATES (SUPER ADMIN OVERRIDE)
  async updateTurfLocation(
    turfId: number,
    body: { latitude: number; longitude: number; googleMapsUrl?: string },
  ) {
    const { latitude, longitude, googleMapsUrl } = body;
    if (latitude == null || longitude == null) {
      throw new BadRequestException('latitude and longitude are required');
    }

    const lat = Number(latitude);
    const lng = Number(longitude);
    const mapUrl = googleMapsUrl || `https://www.google.com/maps?q=${lat},${lng}`;

    // Update VerifiedAdmin if exists
    try {
      await this.prisma.verifiedAdmin.update({
        where: { id: turfId },
        data: {
          latitude: lat,
          longitude: lng,
          googleMapsUrl: mapUrl,
        },
      });
    } catch (_) {}

    // Update AdminUser if exists
    try {
      await this.prisma.adminUser.update({
        where: { id: turfId },
        data: {
          latitude: lat,
          longitude: lng,
          googleMapsUrl: mapUrl,
        },
      });
    } catch (_) {}

    return {
      success: true,
      turfId,
      latitude: lat,
      longitude: lng,
      googleMapsUrl: mapUrl,
      message: 'Turf map location updated successfully',
    };
  }
}
