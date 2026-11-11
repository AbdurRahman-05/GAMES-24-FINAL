import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from './prisma.service.js';
import * as bcrypt from 'bcrypt';
import fs from 'fs';
import path from 'path';
import { DEFAULT_TURF_SPORTS, generateTimeSlots, getISTDateAndMinutes, parseSlotStartMinutes } from './turf.service.js';

function getAdminCourts(adminId: number, venueName: string, sportsList: any[], courtsJson?: any) {
  if (Array.isArray(courtsJson) && courtsJson.length > 0) {
    return courtsJson;
  }
  const courts: any[] = [];
  let courtIndex = 1;
  const sports = (sportsList && sportsList.length > 0) ? sportsList : DEFAULT_TURF_SPORTS;
  for (const s of sports) {
    const numCourts = s.courtsAvailable || 2;
    for (let i = 1; i <= numCourts; i++) {
      let surface = 'Artificial Grass';
      if (s.name.toLowerCase().includes('cricket')) surface = 'Astro Turf';
      else if (s.name.toLowerCase().includes('football')) surface = 'FIFA Pro Turf';
      else if (s.name.toLowerCase().includes('badminton')) surface = 'Synthetic Mat';
      else if (s.name.toLowerCase().includes('pickle')) surface = 'Hard Court';

      courts.push({
        id: `CRT-${adminId}-${courtIndex++}`,
        name: `${s.name} Court ${i}`,
        sport: s.name,
        surface,
        hourlyRate: s.hourlyRate || 1000.0,
        timings: '06:00 AM - 11:00 PM',
        description: `Premium ${s.name} playing court at ${venueName}. Equipped with floodlights and spectator seating.`,
        amenities: ['Floodlights', 'Changing Room', 'Locker', 'First Aid'],
        imageUrls: [],
      });
    }
  }
  return courts;
}

function getAdminSports(adminId: number) {
  try {
    const filePath = path.resolve(process.cwd(), 'turf_sports_data.json');
    if (fs.existsSync(filePath)) {
      const data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
      if (data[adminId] && data[adminId].length > 0) {
        return data[adminId];
      }
    }
  } catch (e) {}
  return DEFAULT_TURF_SPORTS;
}

function saveAdminSports(adminId: number, sports: any[]) {
  try {
    const filePath = path.resolve(process.cwd(), 'turf_sports_data.json');
    let data: Record<number, any> = {};
    if (fs.existsSync(filePath)) {
      data = JSON.parse(fs.readFileSync(filePath, 'utf8'));
    }
    data[adminId] = sports;
    fs.writeFileSync(filePath, JSON.stringify(data, null, 2), 'utf8');
  } catch (e) {}
}

@Injectable()
export class AuthService {
  constructor(private prisma: PrismaService) {}

  async checkMobile(mobileNumber: string) {
    if (!mobileNumber) {
      throw new BadRequestException('Mobile number is required');
    }
    const user = await this.prisma.user.findUnique({
      where: { mobileNumber },
    });
    return { exists: !!user };
  }


  async sendOtp(mobileNumber: string) {
    if (!mobileNumber) {
      throw new BadRequestException('Mobile number is required');
    }
    
    const otp = Math.floor(1000 + Math.random() * 9000).toString();
    const expiresAt = new Date(Date.now() + 5 * 60 * 1000);

    await this.prisma.otp.create({
      data: {
        mobileNumber,
        otp,
        expiresAt,
      },
    });

    console.log(`[DEV ONLY] OTP for ${mobileNumber} is ${otp}`);
    return { message: 'OTP sent successfully', otp };
  }

  async verifyOtp(body: any) {
    const { mobileNumber, otp } = body;
    if (!mobileNumber || !otp) {
      throw new BadRequestException('Missing required fields');
    }

    const otpRecord = await this.prisma.otp.findFirst({
      where: {
        mobileNumber,
        otp,
        expiresAt: {
          gt: new Date(),
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otpRecord) {
      throw new BadRequestException('Invalid or expired OTP');
    }

    await this.prisma.otp.deleteMany({
      where: { mobileNumber },
    });

    return { message: 'OTP verified successfully' };
  }

  async sendAdminOtps(body: any) {
    const { mobileNumber, email } = body;
    if (!mobileNumber && !email) {
      throw new BadRequestException('Mobile number or email is required');
    }

    const expiresAt = new Date(Date.now() + 10 * 60 * 1000);
    let mobileOtp: string | undefined;
    let emailOtp: string | undefined;

    if (mobileNumber) {
      mobileOtp = Math.floor(1000 + Math.random() * 9000).toString();
      const mobileKey = `mobile:${mobileNumber}`;
      await this.prisma.otp.deleteMany({ where: { mobileNumber: mobileKey } });
      await this.prisma.otp.create({
        data: {
          mobileNumber: mobileKey,
          otp: mobileOtp,
          expiresAt,
        },
      });
    }

    if (email) {
      emailOtp = Math.floor(1000 + Math.random() * 9000).toString();
      const emailKey = `email:${email}`;
      await this.prisma.otp.deleteMany({ where: { mobileNumber: emailKey } });
      await this.prisma.otp.create({
        data: {
          mobileNumber: emailKey,
          otp: emailOtp,
          expiresAt,
        },
      });
    }

    console.log('\n======================================================');
    console.log('🏟️   [TURF OWNER KYC OTP VERIFICATION]');
    if (mobileNumber && mobileOtp) {
      console.log(`📱  Mobile SMS OTP for +91 ${mobileNumber}: >>> ${mobileOtp} <<<`);
    }
    if (email && emailOtp) {
      console.log(`📧  Email OTP for ${email}:        >>> ${emailOtp} <<<`);
    }
    console.log('======================================================\n');

    return {
      message: 'OTPs generated and sent successfully',
      mobileOtp,
      emailOtp,
    };
  }

  async verifyAdminOtp(body: any) {
    const { type, identifier, otp } = body;
    if (!type || !identifier || !otp) {
      throw new BadRequestException('Type (mobile/email), identifier, and OTP are required');
    }

    const key = `${type}:${identifier}`;
    const otpRecord = await this.prisma.otp.findFirst({
      where: {
        mobileNumber: key,
        otp: String(otp).trim(),
        expiresAt: {
          gt: new Date(),
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otpRecord) {
      throw new BadRequestException(`Invalid or expired OTP for ${type}`);
    }

    await this.prisma.otp.deleteMany({
      where: { mobileNumber: key },
    });

    return {
      success: true,
      message: `${type.toUpperCase()} verified successfully`,
    };
  }

  async register(body: any) {
    const { fullName, mobileNumber, password, preferredSport } = body;

    if (!fullName || !mobileNumber || !password || !preferredSport) {
      throw new BadRequestException('Missing required fields');
    }

    const existingUser = await this.prisma.user.findUnique({
      where: { mobileNumber },
    });
    if (existingUser) {
      throw new BadRequestException('User with this mobile number already exists');
    }

    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await this.prisma.user.create({
      data: {
        fullName,
        mobileNumber,
        password: hashedPassword,
        preferredSport,
      },
    });

    return { 
      message: 'Account created successfully', 
      userId: newUser.id,
      fullName: newUser.fullName,
      mobileNumber: newUser.mobileNumber,
      preferredSport: newUser.preferredSport,
    };
  }

  async checkAdminContact(body: any) {
    const { ownerPhone, ownerEmail, mobileNumber, email } = body || {};
    const phone = (ownerPhone || mobileNumber || '').toString().trim();
    const mail = (ownerEmail || email || '').toString().trim().toLowerCase();

    let phoneExists = false;
    let emailExists = false;

    if (phone) {
      const existingPhone = await this.prisma.adminUser.findFirst({
        where: { ownerPhone: phone },
      });
      if (existingPhone) {
        phoneExists = true;
      }
    }

    if (mail) {
      const allAdmins = await this.prisma.adminUser.findMany({
        select: { ownerEmail: true },
      });
      emailExists = allAdmins.some(
        (a) => a.ownerEmail && a.ownerEmail.trim().toLowerCase() === mail,
      );
    }

    return {
      phoneExists,
      emailExists,
      exists: phoneExists || emailExists,
      message:
        phoneExists && emailExists
          ? 'Both mobile number and email address are already registered.'
          : phoneExists
            ? 'This mobile number is already registered. Please use another number.'
            : emailExists
              ? 'This email address is already registered. Please use another email.'
              : 'Available',
    };
  }

  async registerAdmin(body: any) {
    const { venueName, ownerName, ownerPhone, ownerEmail, streetAddress, neighborhoodArea } = body;

    if (!venueName || !ownerName || !ownerPhone || !ownerEmail || !streetAddress || !neighborhoodArea) {
      throw new BadRequestException('Missing required fields');
    }

    const cleanPhone = String(ownerPhone).trim();
    const cleanEmail = String(ownerEmail).trim().toLowerCase();

    const existingPhone = await this.prisma.adminUser.findFirst({
      where: { ownerPhone: cleanPhone },
    });
    if (existingPhone) {
      throw new BadRequestException('This mobile number is already registered. Please use another mobile number.');
    }

    const allAdmins = await this.prisma.adminUser.findMany({
      select: { ownerEmail: true },
    });
    const existingEmail = allAdmins.some(
      (a) => a.ownerEmail && a.ownerEmail.trim().toLowerCase() === cleanEmail,
    );
    if (existingEmail) {
      throw new BadRequestException('This email address is already registered. Please use another email address.');
    }

    const newAdmin = await this.prisma.adminUser.create({
      data: {
        venueName: venueName.trim(),
        ownerName: ownerName.trim(),
        ownerPhone: cleanPhone,
        ownerEmail: cleanEmail,
        streetAddress: streetAddress.trim(),
        neighborhoodArea: neighborhoodArea.trim(),
      },
    });

    const trackingCode = `REG-MAD-${(1000 + newAdmin.id).toString()}`;
    await this.prisma.adminUser.update({
      where: { id: newAdmin.id },
      data: { trackingCode },
    });

    return { 
      message: 'Admin account created successfully', 
      adminId: newAdmin.id,
      trackingCode,
      venueName: newAdmin.venueName,
      ownerName: newAdmin.ownerName,
    };
  }

  async updateAdminKyc(body: any) {
    const { 
      adminId, 
      isMobileVerified, 
      isEmailVerified, 
      photosCount, 
      photoUrls,
      amenities, 
      gstin, 
      panNumber, 
      aadhaarNumber, 
      aadhaarDocUrl,
      panDocUrl,
      gstDocUrl,
      bankAccount, 
      ifscCode, 
      upiId 
    } = body;

    if (!adminId) {
      throw new BadRequestException('adminId is required');
    }

    const admin = await this.prisma.adminUser.findUnique({
      where: { id: Number(adminId) },
    });

    const trackingCode = admin?.trackingCode || `REG-MAD-${(1000 + Number(adminId)).toString()}`;

    const updatedAdmin = await this.prisma.adminUser.update({
      where: { id: Number(adminId) },
      data: {
        trackingCode,
        isMobileVerified: isMobileVerified !== undefined ? Boolean(isMobileVerified) : true,
        isEmailVerified: isEmailVerified !== undefined ? Boolean(isEmailVerified) : true,
        photosCount: photosCount != null ? Number(photosCount) : 0,
        photoUrls: Array.isArray(photoUrls) ? photoUrls : (photoUrls ? [photoUrls] : []),
        amenities: Array.isArray(amenities) ? amenities : [],
        gstin: gstin || undefined,
        panNumber: panNumber || undefined,
        aadhaarNumber: aadhaarNumber || undefined,
        aadhaarDocUrl: aadhaarDocUrl || undefined,
        panDocUrl: panDocUrl || undefined,
        gstDocUrl: gstDocUrl || undefined,
        bankAccount: bankAccount || undefined,
        ifscCode: ifscCode || undefined,
        upiId: upiId || undefined,
        status: 'PENDING_APPROVAL',
      },
    });

    return { 
      message: 'Admin KYC and venue details submitted successfully', 
      adminId: updatedAdmin.id,
      trackingCode: updatedAdmin.trackingCode,
      venueName: updatedAdmin.venueName,
      ownerName: updatedAdmin.ownerName,
      photoUrls: updatedAdmin.photoUrls,
      aadhaarDocUrl: updatedAdmin.aadhaarDocUrl,
      panDocUrl: updatedAdmin.panDocUrl,
      gstDocUrl: updatedAdmin.gstDocUrl,
      status: updatedAdmin.status,
    };
  }

  async login(body: any) {
    const { mobileNumber, password } = body;

    if (!mobileNumber || !password) {
      throw new BadRequestException('Missing mobile number or password');
    }

    const user = await this.prisma.user.findUnique({
      where: { mobileNumber },
    });

    if (!user) {
      throw new BadRequestException('Invalid credentials');
    }

    const isPasswordValid = await bcrypt.compare(password, user.password);

    if (!isPasswordValid) {
      throw new BadRequestException('Invalid credentials');
    }

    return { 
      message: 'Login successful', 
      userId: user.id,
      fullName: user.fullName,
      mobileNumber: user.mobileNumber,
      preferredSport: user.preferredSport,
    };
  }

  async resetPassword(body: any) {
    const { mobileNumber, otp, newPassword } = body;
    if (!mobileNumber || !otp || !newPassword) {
      throw new BadRequestException('Missing required fields');
    }

    // Verify OTP
    const otpRecord = await this.prisma.otp.findFirst({
      where: {
        mobileNumber,
        otp,
        expiresAt: {
          gt: new Date(),
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otpRecord) {
      throw new BadRequestException('Invalid or expired OTP');
    }

    // Ensure user exists
    const user = await this.prisma.user.findUnique({
      where: { mobileNumber },
    });

    if (!user) {
      throw new BadRequestException('User not found');
    }

    const hashedPassword = await bcrypt.hash(newPassword, 10);

    await this.prisma.user.update({
      where: { mobileNumber },
      data: { password: hashedPassword },
    });

    await this.prisma.otp.deleteMany({
      where: { mobileNumber },
    });

    return { message: 'Password reset successfully' };
  }

  async verifyResetOtp(body: any) {
    const { mobileNumber, otp } = body;
    if (!mobileNumber || !otp) {
      throw new BadRequestException('Missing required fields');
    }

    const otpRecord = await this.prisma.otp.findFirst({
      where: {
        mobileNumber,
        otp,
        expiresAt: {
          gt: new Date(),
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    if (!otpRecord) {
      throw new BadRequestException('Invalid or expired OTP');
    }

    // Do NOT delete the OTP here, let resetPassword delete it.
    return { message: 'OTP is valid' };
  }

  async getAdminStatus(identifier: string) {
    const numId = Number(identifier);
    let admin: any = null;

    if (!isNaN(numId)) {
      admin = await this.prisma.adminUser.findUnique({
        where: { id: numId },
      });
    }

    if (!admin) {
      admin = await this.prisma.adminUser.findFirst({
        where: { trackingCode: identifier },
      });
    }

    if (!admin) {
      throw new BadRequestException('Admin application not found');
    }

    return {
      adminId: admin.id,
      trackingCode: admin.trackingCode,
      venueName: admin.venueName,
      ownerName: admin.ownerName,
      ownerPhone: admin.ownerPhone,
      ownerEmail: admin.ownerEmail,
      neighborhoodArea: admin.neighborhoodArea,
      status: admin.status,
      cancelReason: admin.cancelReason,
      updatedAt: admin.updatedAt,
    };
  }

  async adminLogin(body: any) {
    const { mobileNumber, otp } = body;

    if (!mobileNumber) {
      throw new BadRequestException('Please enter your registered mobile number.');
    }

    const cleanPhone = String(mobileNumber).trim().replace(/\D/g, '');
    if (cleanPhone.length < 10) {
      throw new BadRequestException('Please enter a valid 10-digit mobile number.');
    }

    const cleanOtp = String(otp || '').trim();
    if (!cleanOtp) {
      throw new BadRequestException('Please enter the 4-digit OTP (Mock: 1234).');
    }

    if (cleanOtp !== '1234') {
      throw new BadRequestException('Invalid OTP entered. Please use mock OTP: 1234.');
    }

    // Fetch ALL verified turfs/branches owned by this mobile number!
    const allAdmins = await this.prisma.verifiedAdmin.findMany({
      where: {
        OR: [
          { ownerPhone: cleanPhone },
          { ownerPhone: { contains: cleanPhone } },
        ],
      },
      include: {
        dashboard: true,
        bookings: {
          orderBy: { createdAt: 'desc' },
        },
      },
      orderBy: { id: 'asc' },
    });

    if (!allAdmins || allAdmins.length === 0) {
      // Check if it exists in AdminUser to provide helpful context/warning
      const pendingAdmin = await this.prisma.adminUser.findFirst({
        where: {
          OR: [
            { ownerPhone: cleanPhone },
            { ownerPhone: { contains: cleanPhone } },
          ],
        },
      });

      if (pendingAdmin) {
        if (pendingAdmin.status === 'PENDING_APPROVAL') {
          throw new BadRequestException(
            'Your turf registration is still WAITING for Super Admin verification. You can only log in once verified.'
          );
        }
        if (pendingAdmin.status === 'CANCELLED') {
          throw new BadRequestException(
            `Your registration was rejected by Super Admin. Reason: ${pendingAdmin.cancelReason || 'Application rejected'}`
          );
        }
      }

      throw new BadRequestException(
        'Access Denied: This mobile number is not in the Verified Admin table. Only verified turf owners can log in.'
      );
    }

    // Active turf defaults to requested turfId or the first registered branch
    const requestedTurfId = body?.turfId ? Number(body.turfId) : undefined;
    const verifiedAdmin = (requestedTurfId ? allAdmins.find((a: any) => a.id === requestedTurfId) : null) || allAdmins[0];

    let dashboard = verifiedAdmin.dashboard;
    if (!dashboard) {
      dashboard = await this.prisma.adminDashboard.create({
        data: { verifiedAdminId: verifiedAdmin.id },
      });
    }

    const now = new Date();
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    const monthPrefix = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

    const activeBookings = (verifiedAdmin.bookings || []).filter((b: any) => b.status !== 'Cancelled');
    const cancelledBookings = (verifiedAdmin.bookings || []).filter((b: any) => b.status === 'Cancelled');
    const todayBookings = activeBookings.filter((b: any) => b.date === todayStr);
    const monthBookings = activeBookings.filter((b: any) => b.date?.startsWith(monthPrefix));

    const countBookingSlots = (timeSlot?: string): number => {
      if (!timeSlot) return 1;
      const parts = timeSlot.split(',').map((s: string) => s.trim()).filter(Boolean);
      return parts.length > 0 ? parts.length : 1;
    };

    const todayBookingsCount = todayBookings.length;
    const todayPaidBookings = todayBookings.filter((b: any) => !b.paymentMethod?.toLowerCase().includes('cash')).length;
    const todayCashBookings = todayBookings.filter((b: any) => b.paymentMethod?.toLowerCase().includes('cash')).length;
    const todayRevenue = todayBookings.reduce((sum: number, b: any) => sum + (Number(b.amount) || 0), 0);
    const monthTotalBookings = monthBookings.length;
    const monthRevenue = monthBookings.reduce((sum: number, b: any) => sum + (Number(b.amount) || 0), 0);
    const { currentMinutes } = getISTDateAndMinutes();
    const bookedSlotsCount = todayBookings.reduce((acc: number, b: any) => acc + countBookingSlots(b.timeSlot), 0);
    const openingTime = dashboard.openingTime || '05:00 AM';
    const closingTime = dashboard.closingTime || '11:00 PM';
    const allSlots = generateTimeSlots(openingTime, closingTime);
    const totalSlots = allSlots.length || 18;

    const passedSlots = allSlots.filter((slot: string) => {
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

    const freeSlotsCount = Math.max(
      0,
      totalSlots - passedSlots.length - upcomingBookedSlotsCount - (dashboard.blockedSlotsCount || 0)
    );
    const occupancyPercent = totalSlots > 0 ? Math.round((bookedSlotsCount / totalSlots) * 100) : 0;
    const slotsBadge = `${occupancyPercent}% Full`;
    const realCancelledCount = Math.max(cancelledBookings.length, dashboard.cancelledCount || 0);
    const shiftedCount = dashboard.shiftedCount || 0;
    const cancelledTotal = realCancelledCount + shiftedCount;
    const cancelledBadge = `${cancelledTotal} Tracked`;
    const growthBadge = todayBookingsCount > 0 ? `+${todayBookingsCount} Today` : '0% Today';
    const revBadge = `₹${monthRevenue.toLocaleString('en-IN')} GMV`;

    dashboard = {
      ...dashboard,
      todayBookingsCount,
      todayPaidBookings,
      todayCashBookings,
      todayRevenue,
      monthTotalBookings,
      monthRevenue,
      bookedSlotsCount,
      freeSlotsCount,
      slotsBadge,
      cancelledCount: realCancelledCount,
      cancelledTotal,
      cancelledBadge,
      todayBookingsGrowth: growthBadge,
      revenueBadge: revBadge,
    };

    await this.prisma.adminDashboard.update({
      where: { verifiedAdminId: verifiedAdmin.id },
      data: {
        todayBookingsCount,
        todayPaidBookings,
        todayCashBookings,
        todayRevenue,
        monthTotalBookings,
        monthRevenue,
        bookedSlotsCount,
        freeSlotsCount,
        slotsBadge,
        cancelledCount: realCancelledCount,
        shiftedCount,
        cancelledTotal,
        cancelledBadge,
        todayBookingsGrowth: growthBadge,
        revenueBadge: revBadge,
      },
    }).catch(() => {});

    // Compute all branches summary for multi-branch switching
    const branches = allAdmins.map((va: any) => {
      const bks = (va.bookings || []).filter((b: any) => b.status !== 'Cancelled');
      const tdBks = bks.filter((b: any) => b.date === todayStr);
      const mBks = bks.filter((b: any) => b.date?.startsWith(monthPrefix));
      const tdRev = tdBks.reduce((sum: number, b: any) => sum + (Number(b.amount) || 0), 0);
      const mRev = mBks.reduce((sum: number, b: any) => sum + (Number(b.amount) || 0), 0);
      return {
        id: va.id,
        venueName: va.venueName,
        neighborhoodArea: va.neighborhoodArea || 'Main Branch',
        streetAddress: va.streetAddress,
        ownerPhone: va.ownerPhone,
        status: va.status,
        todayBookingsCount: tdBks.length,
        todayRevenue: tdRev,
        monthRevenue: mRev,
        monthTotalBookings: mBks.length,
        isActive: va.id === verifiedAdmin.id,
      };
    });

    const sportsList = getAdminSports(verifiedAdmin.id);
    const courtsList = getAdminCourts(verifiedAdmin.id, verifiedAdmin.venueName, sportsList, verifiedAdmin.courts);

    return {
      success: true,
      message: `Login successful! Welcome back, ${verifiedAdmin.venueName}.`,
      admin: {
        ...verifiedAdmin,
        bookings: verifiedAdmin.bookings || [],
        dashboard,
        openingTime: dashboard.openingTime,
        closingTime: dashboard.closingTime,
        todayBookingsCount,
        todayPaidBookings,
        todayCashBookings,
        todayRevenue,
        todayBookingsGrowth: growthBadge,
        monthRevenue,
        monthTotalBookings,
        revenueBadge: revBadge,
        freeSlotsCount,
        bookedSlotsCount,
        blockedSlotsCount: dashboard.blockedSlotsCount,
        slotsBadge,
        cancelledTotal,
        cancelledCount: realCancelledCount,
        shiftedCount,
        cancelledBadge,
        sports: sportsList.map((s: any) => s.name),
        sportsList,
        courts: courtsList,
      },
      branches,
    };
  }

  async getVerifiedAdminByPhone(phone: string, queryTurfId?: number) {
    const clean = phone.trim().replace(/[^0-9]/g, '');
    const allAdmins = await this.prisma.verifiedAdmin.findMany({
      where: {
        OR: [
          { ownerPhone: clean },
          { ownerPhone: { contains: clean } },
        ],
      },
      include: {
        dashboard: true,
        bookings: {
          orderBy: { createdAt: 'desc' },
        },
      },
      orderBy: { id: 'asc' },
    });

    if (!allAdmins || allAdmins.length === 0) {
      throw new BadRequestException('No verified admin found for this mobile number');
    }

    const admin = (queryTurfId ? allAdmins.find((a: any) => a.id === queryTurfId) : null) || allAdmins[0];

    let dashboard = admin.dashboard;
    if (!dashboard) {
      dashboard = await this.prisma.adminDashboard.create({
        data: { verifiedAdminId: admin.id },
      });
    }

    const now = new Date();
    const todayStr = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}-${String(now.getDate()).padStart(2, '0')}`;
    const monthPrefix = `${now.getFullYear()}-${String(now.getMonth() + 1).padStart(2, '0')}`;

    const activeBookings = (admin.bookings || []).filter((b: any) => b.status !== 'Cancelled');
    const cancelledBookings = (admin.bookings || []).filter((b: any) => b.status === 'Cancelled');
    const todayBookings = activeBookings.filter((b: any) => b.date === todayStr);
    const monthBookings = activeBookings.filter((b: any) => b.date?.startsWith(monthPrefix));

    const countBookingSlots = (timeSlot?: string): number => {
      if (!timeSlot) return 1;
      const parts = timeSlot.split(',').map((s: string) => s.trim()).filter(Boolean);
      return parts.length > 0 ? parts.length : 1;
    };

    const todayBookingsCount = todayBookings.length;
    const todayPaidBookings = todayBookings.filter((b: any) => !b.paymentMethod?.toLowerCase().includes('cash')).length;
    const todayCashBookings = todayBookings.filter((b: any) => b.paymentMethod?.toLowerCase().includes('cash')).length;
    const todayRevenue = todayBookings.reduce((sum: number, b: any) => sum + (Number(b.amount) || 0), 0);
    const monthTotalBookings = monthBookings.length;
    const monthRevenue = monthBookings.reduce((sum: number, b: any) => sum + (Number(b.amount) || 0), 0);
    const { currentMinutes } = getISTDateAndMinutes();
    const bookedSlotsCount = todayBookings.reduce((acc: number, b: any) => acc + countBookingSlots(b.timeSlot), 0);
    const openingTime = dashboard.openingTime || '05:00 AM';
    const closingTime = dashboard.closingTime || '11:00 PM';
    const allSlots = generateTimeSlots(openingTime, closingTime);
    const totalSlots = allSlots.length || 18;

    const passedSlots = allSlots.filter((slot: string) => {
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

    const freeSlotsCount = Math.max(
      0,
      totalSlots - passedSlots.length - upcomingBookedSlotsCount - (dashboard.blockedSlotsCount || 0)
    );
    const occupancyPercent = totalSlots > 0 ? Math.round((bookedSlotsCount / totalSlots) * 100) : 0;
    const slotsBadge = `${occupancyPercent}% Full`;
    const realCancelledCount = Math.max(cancelledBookings.length, dashboard.cancelledCount || 0);
    const shiftedCount = dashboard.shiftedCount || 0;
    const cancelledTotal = realCancelledCount + shiftedCount;
    const cancelledBadge = `${cancelledTotal} Tracked`;
    const growthBadge = todayBookingsCount > 0 ? `+${todayBookingsCount} Today` : '0% Today';
    const revBadge = `₹${monthRevenue.toLocaleString('en-IN')} GMV`;

    dashboard = {
      ...dashboard,
      todayBookingsCount,
      todayPaidBookings,
      todayCashBookings,
      todayRevenue,
      monthTotalBookings,
      monthRevenue,
      bookedSlotsCount,
      freeSlotsCount,
      slotsBadge,
      cancelledCount: realCancelledCount,
      cancelledTotal,
      cancelledBadge,
      todayBookingsGrowth: growthBadge,
      revenueBadge: revBadge,
    };

    await this.prisma.adminDashboard.update({
      where: { verifiedAdminId: admin.id },
      data: {
        todayBookingsCount,
        todayPaidBookings,
        todayCashBookings,
        todayRevenue,
        monthTotalBookings,
        monthRevenue,
        bookedSlotsCount,
        freeSlotsCount,
        slotsBadge,
        cancelledCount: realCancelledCount,
        shiftedCount,
        cancelledTotal,
        cancelledBadge,
        todayBookingsGrowth: growthBadge,
        revenueBadge: revBadge,
      },
    }).catch(() => {});

    // Compute all branches summary for multi-branch switching
    const branches = allAdmins.map((va: any) => {
      const bks = (va.bookings || []).filter((b: any) => b.status !== 'Cancelled');
      const tdBks = bks.filter((b: any) => b.date === todayStr);
      const mBks = bks.filter((b: any) => b.date?.startsWith(monthPrefix));
      const tdRev = tdBks.reduce((sum: number, b: any) => sum + (Number(b.amount) || 0), 0);
      const mRev = mBks.reduce((sum: number, b: any) => sum + (Number(b.amount) || 0), 0);
      return {
        id: va.id,
        venueName: va.venueName,
        neighborhoodArea: va.neighborhoodArea || 'Main Branch',
        streetAddress: va.streetAddress,
        ownerPhone: va.ownerPhone,
        status: va.status,
        todayBookingsCount: tdBks.length,
        todayRevenue: tdRev,
        monthRevenue: mRev,
        monthTotalBookings: mBks.length,
        isActive: va.id === admin.id,
      };
    });

    const sportsList = getAdminSports(admin.id);
    const courtsList = getAdminCourts(admin.id, admin.venueName, sportsList, admin.courts);

    return {
      success: true,
      admin: {
        ...admin,
        bookings: admin.bookings || [],
        dashboard,
        openingTime: dashboard.openingTime,
        closingTime: dashboard.closingTime,
        todayBookingsCount,
        todayPaidBookings,
        todayCashBookings,
        todayRevenue,
        todayBookingsGrowth: growthBadge,
        monthRevenue,
        monthTotalBookings,
        revenueBadge: revBadge,
        freeSlotsCount,
        bookedSlotsCount,
        blockedSlotsCount: dashboard.blockedSlotsCount,
        slotsBadge,
        cancelledTotal,
        cancelledCount: realCancelledCount,
        shiftedCount,
        cancelledBadge,
        sports: sportsList.map((s: any) => s.name),
        sportsList,
        courts: courtsList,
      },
      branches,
    };
  }

  async addOwnerBranch(body: any) {
    const {
      ownerPhone,
      venueName,
      neighborhoodArea,
      streetAddress,
      dayRate,
      nightRate,
      weekdayRate,
      weekendRate,
    } = body;

    if (!ownerPhone || !venueName) {
      throw new BadRequestException('Owner phone and venue name are required');
    }

    const cleanPhone = String(ownerPhone).trim().replace(/\D/g, '');
    const existingAdmin = await this.prisma.verifiedAdmin.findFirst({
      where: {
        OR: [{ ownerPhone: cleanPhone }, { ownerPhone: { contains: cleanPhone } }],
      },
    });

    if (!existingAdmin) {
      throw new BadRequestException('Primary owner profile not found. Please register first.');
    }

    const trackingCode = `TRK-BR-${Date.now().toString().slice(-6)}`;
    const newAdminUser = await this.prisma.adminUser.create({
      data: {
        trackingCode,
        venueName,
        ownerName: existingAdmin.ownerName,
        ownerPhone: cleanPhone,
        ownerEmail: existingAdmin.ownerEmail,
        streetAddress: streetAddress || existingAdmin.streetAddress,
        neighborhoodArea: neighborhoodArea || existingAdmin.neighborhoodArea,
        isMobileVerified: true,
        isEmailVerified: true,
        status: 'APPROVED',
      },
    });

    const newBranch = await this.prisma.verifiedAdmin.create({
      data: {
        adminUserId: newAdminUser.id,
        trackingCode,
        venueName,
        ownerName: existingAdmin.ownerName,
        ownerPhone: cleanPhone,
        ownerEmail: existingAdmin.ownerEmail,
        streetAddress: streetAddress || existingAdmin.streetAddress,
        neighborhoodArea: neighborhoodArea || existingAdmin.neighborhoodArea,
        dayRate: Number(dayRate) || existingAdmin.dayRate || 1000.0,
        nightRate: Number(nightRate) || existingAdmin.nightRate || 1400.0,
        weekdayRate: Number(weekdayRate) || existingAdmin.weekdayRate || 1200.0,
        weekendRate: Number(weekendRate) || existingAdmin.weekendRate || 1600.0,
        status: 'VERIFIED',
      },
    });

    await this.prisma.adminDashboard.create({
      data: { verifiedAdminId: newBranch.id },
    });

    return {
      success: true,
      message: `New branch "${venueName}" created successfully!`,
      branch: newBranch,
    };
  }

  async getUserProfile(phone: string) {
    const clean = phone.trim().replace(/\D/g, '');
    const last10 = clean.length >= 10 ? clean.slice(-10) : clean;

    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { mobileNumber: clean },
          { mobileNumber: { contains: last10 } },
        ],
      },
    });

    const bookings = await this.prisma.turfBooking.findMany({
      where: {
        OR: [
          { customerPhone: { contains: last10 } },
          { opponentPhone: { contains: last10 } },
        ],
      },
      orderBy: { createdAt: 'desc' },
    });

    const completedCount = bookings.filter((b) => b.status === 'Completed' || (b.date < new Date().toISOString().slice(0, 10) && b.status !== 'Cancelled')).length;
    const activeCount = bookings.filter((b) => b.status === 'Confirmed').length;

    return {
      id: user?.id || 0,
      fullName: user?.fullName || 'Active Player',
      mobileNumber: user?.mobileNumber || phone,
      preferredSport: user?.preferredSport || 'Football',
      totalBookings: bookings.length,
      completedMatches: completedCount,
      activeBookings: activeCount,
      teams: Array.isArray(user?.teamsJson) ? user?.teamsJson : [],
    };
  }

  async saveUserTeams(phone: string, teams: any) {
    const clean = phone.trim().replace(/\D/g, '');
    const last10 = clean.length >= 10 ? clean.slice(-10) : clean;

    const user = await this.prisma.user.findFirst({
      where: {
        OR: [
          { mobileNumber: clean },
          { mobileNumber: { contains: last10 } },
        ],
      },
    });

    if (user) {
      await this.prisma.user.update({
        where: { id: user.id },
        data: { teamsJson: Array.isArray(teams) ? teams : [] },
      });
    }

    return { success: true, message: 'Teams synced to database successfully' };
  }

  async updateVerifiedAdminMetrics(id: number, metrics: any) {
    let admin = await this.prisma.verifiedAdmin.findUnique({
      where: { id },
      include: { dashboard: true },
    });
    if (!admin) {
      admin = await this.prisma.verifiedAdmin.findFirst({
        where: { adminUserId: id },
        include: { dashboard: true },
      });
    }
    if (!admin) {
      admin = await this.prisma.verifiedAdmin.findFirst({
        orderBy: { id: 'asc' },
        include: { dashboard: true },
      });
    }
    if (!admin) {
      throw new BadRequestException(`Verified admin with ID ${id} not found`);
    }

    const verifiedAdminId = admin.id;

    const dataToUpdate: any = {};
    if (metrics.openingTime !== undefined) dataToUpdate.openingTime = String(metrics.openingTime);
    if (metrics.closingTime !== undefined) dataToUpdate.closingTime = String(metrics.closingTime);
    if (metrics.todayBookingsCount !== undefined) dataToUpdate.todayBookingsCount = Number(metrics.todayBookingsCount);
    if (metrics.todayPaidBookings !== undefined) dataToUpdate.todayPaidBookings = Number(metrics.todayPaidBookings);
    if (metrics.todayCashBookings !== undefined) dataToUpdate.todayCashBookings = Number(metrics.todayCashBookings);
    if (metrics.todayBookingsGrowth !== undefined) dataToUpdate.todayBookingsGrowth = String(metrics.todayBookingsGrowth);
    if (metrics.monthRevenue !== undefined) dataToUpdate.monthRevenue = Number(metrics.monthRevenue);
    if (metrics.monthTotalBookings !== undefined) dataToUpdate.monthTotalBookings = Number(metrics.monthTotalBookings);
    if (metrics.revenueBadge !== undefined) dataToUpdate.revenueBadge = String(metrics.revenueBadge);
    if (metrics.freeSlotsCount !== undefined) dataToUpdate.freeSlotsCount = Number(metrics.freeSlotsCount);
    if (metrics.bookedSlotsCount !== undefined) dataToUpdate.bookedSlotsCount = Number(metrics.bookedSlotsCount);
    if (metrics.blockedSlotsCount !== undefined) dataToUpdate.blockedSlotsCount = Number(metrics.blockedSlotsCount);
    if (metrics.slotsBadge !== undefined) dataToUpdate.slotsBadge = String(metrics.slotsBadge);
    if (metrics.cancelledTotal !== undefined) dataToUpdate.cancelledTotal = Number(metrics.cancelledTotal);
    if (metrics.cancelledCount !== undefined) dataToUpdate.cancelledCount = Number(metrics.cancelledCount);
    if (metrics.shiftedCount !== undefined) dataToUpdate.shiftedCount = Number(metrics.shiftedCount);
    if (metrics.cancelledBadge !== undefined) dataToUpdate.cancelledBadge = String(metrics.cancelledBadge);

    const dashboard = await this.prisma.adminDashboard.upsert({
      where: { verifiedAdminId },
      create: {
        verifiedAdminId,
        ...dataToUpdate,
      },
      update: dataToUpdate,
    });

    const updatedAdmin = await this.prisma.verifiedAdmin.findUnique({
      where: { id: verifiedAdminId },
      include: { dashboard: true },
    });

    return {
      success: true,
      message: 'Venue performance metrics updated successfully in AdminDashboard table',
      dashboard,
      admin: {
        ...updatedAdmin,
        dashboard,
        openingTime: dashboard.openingTime,
        closingTime: dashboard.closingTime,
        todayBookingsCount: dashboard.todayBookingsCount,
        todayPaidBookings: dashboard.todayPaidBookings,
        todayCashBookings: dashboard.todayCashBookings,
        todayBookingsGrowth: dashboard.todayBookingsGrowth,
        monthRevenue: dashboard.monthRevenue,
        monthTotalBookings: dashboard.monthTotalBookings,
        revenueBadge: dashboard.revenueBadge,
        freeSlotsCount: dashboard.freeSlotsCount,
        bookedSlotsCount: dashboard.bookedSlotsCount,
        blockedSlotsCount: dashboard.blockedSlotsCount,
        slotsBadge: dashboard.slotsBadge,
        cancelledTotal: dashboard.cancelledTotal,
        cancelledCount: dashboard.cancelledCount,
        shiftedCount: dashboard.shiftedCount,
        cancelledBadge: dashboard.cancelledBadge,
      },
    };
  }

  async updateVerifiedAdminProfile(id: number, profileData: any) {
    let admin = await this.prisma.verifiedAdmin.findUnique({
      where: { id },
    });
    if (!admin) {
      admin = await this.prisma.verifiedAdmin.findFirst({
        where: { adminUserId: id },
      });
    }
    if (!admin) {
      admin = await this.prisma.verifiedAdmin.findFirst({
        orderBy: { id: 'asc' },
      });
    }
    if (!admin) {
      throw new BadRequestException(`Verified admin with ID ${id} not found`);
    }

    const verifiedAdminId = admin.id;

    const dataToUpdate: any = {};
    if (profileData.venueName !== undefined) dataToUpdate.venueName = String(profileData.venueName);
    if (profileData.ownerName !== undefined) dataToUpdate.ownerName = String(profileData.ownerName);
    if (profileData.ownerPhone !== undefined) dataToUpdate.ownerPhone = String(profileData.ownerPhone);
    if (profileData.ownerEmail !== undefined) dataToUpdate.ownerEmail = String(profileData.ownerEmail);
    if (profileData.streetAddress !== undefined) dataToUpdate.streetAddress = String(profileData.streetAddress);
    if (profileData.neighborhoodArea !== undefined) dataToUpdate.neighborhoodArea = String(profileData.neighborhoodArea);
    if (profileData.dayRate !== undefined) dataToUpdate.dayRate = Number(profileData.dayRate);
    if (profileData.nightRate !== undefined) dataToUpdate.nightRate = Number(profileData.nightRate);
    if (profileData.weekdayRate !== undefined) dataToUpdate.weekdayRate = Number(profileData.weekdayRate);
    if (profileData.weekendRate !== undefined) dataToUpdate.weekendRate = Number(profileData.weekendRate);

    if (profileData.sports || profileData.sportsList) {
      saveAdminSports(verifiedAdminId, profileData.sportsList || profileData.sports);
    }

    const updated = await this.prisma.verifiedAdmin.update({
      where: { id: verifiedAdminId },
      data: dataToUpdate,
      include: { dashboard: true },
    });

    const sportsList = getAdminSports(verifiedAdminId);

    return {
      success: true,
      message: 'Turf Profile and Hourly Rates updated successfully in database',
      admin: {
        ...updated,
        dashboard: updated.dashboard,
        openingTime: updated.dashboard?.openingTime,
        closingTime: updated.dashboard?.closingTime,
        sports: sportsList.map((s: any) => s.name),
        sportsList,
      },
    };
  }
}



