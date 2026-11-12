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

    const playerId = user?.id
      ? `PLY-${user.id.toString().padStart(4, '0')}`
      : (last10.length >= 4 ? `PLY-${last10.slice(-4)}` : 'PLY-1001');

    return {
      id: user?.id || 0,
      playerId,
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

  private getInvitationsFilePath(): string {
    const dir = path.join(process.cwd(), 'data');
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    return path.join(dir, 'team_invitations.json');
  }

  private readInvitations(): any[] {
    try {
      const file = this.getInvitationsFilePath();
      if (fs.existsSync(file)) {
        return JSON.parse(fs.readFileSync(file, 'utf8'));
      }
    } catch {
      // ignore
    }
    return [];
  }

  private writeInvitations(invites: any[]) {
    try {
      const file = this.getInvitationsFilePath();
      fs.writeFileSync(file, JSON.stringify(invites, null, 2), 'utf8');
    } catch (e) {
      console.error('Failed to write invitations', e);
    }
  }

  async searchPlayer(query: string) {
    if (!query || !query.trim()) return [];
    const q = query.trim();
    const cleanDigits = q.replace(/\D/g, '');
    const isPlayerId = q.toUpperCase().startsWith('PLY-');
    const numericPart = isPlayerId ? parseInt(q.replace(/\D/g, ''), 10) : (cleanDigits ? parseInt(cleanDigits, 10) : null);

    const conditions: any[] = [];
    if (numericPart && !isNaN(numericPart)) {
      conditions.push({ id: numericPart });
    }
    if (cleanDigits.length >= 4) {
      conditions.push({ mobileNumber: { contains: cleanDigits.slice(-10) } });
    }
    if (q.length >= 2) {
      conditions.push({ fullName: { contains: q, mode: 'insensitive' } });
    }

    if (conditions.length === 0) return [];

    const users = await this.prisma.user.findMany({
      where: { OR: conditions },
      take: 10,
    });

    return users.map((u) => {
      const pId = `PLY-${u.id.toString().padStart(4, '0')}`;
      return {
        id: u.id,
        playerId: pId,
        fullName: u.fullName || 'Active Player',
        mobileNumber: u.mobileNumber,
        preferredSport: u.preferredSport || 'Football',
      };
    });
  }

  async sendTeamInvitation(body: {
    senderPhone: string;
    senderPlayerId?: string;
    senderName?: string;
    senderTeamId: string;
    senderTeamCode?: string;
    senderTeamName: string;
    senderTeamSport: string;
    targetPlayerId: string;
    targetPhone?: string;
    targetName?: string;
    role?: string;
  }) {
    const invites = this.readInvitations();

    const existing = invites.find(
      (inv) =>
        inv.senderTeamId === body.senderTeamId &&
        inv.targetPlayerId.toUpperCase() === body.targetPlayerId.toUpperCase() &&
        inv.status === 'pending'
    );
    if (existing) {
      return { success: true, message: 'Invitation already sent and pending', invitation: existing };
    }

    const newInvite = {
      id: `INV-${Date.now()}-${Math.floor(Math.random() * 1000)}`,
      senderPhone: body.senderPhone,
      senderPlayerId: body.senderPlayerId || 'PLY-0001',
      senderName: body.senderName || 'Team Captain',
      senderTeamId: body.senderTeamId,
      senderTeamCode: body.senderTeamCode || body.senderTeamId,
      senderTeamName: body.senderTeamName,
      senderTeamSport: body.senderTeamSport,
      targetPlayerId: body.targetPlayerId.toUpperCase(),
      targetPhone: body.targetPhone || '',
      targetName: body.targetName || 'Player',
      role: body.role || 'Player',
      status: 'pending',
      createdAt: new Date().toISOString(),
    };

    invites.unshift(newInvite);
    this.writeInvitations(invites);

    return { success: true, message: 'Squad invitation sent successfully!', invitation: newInvite };
  }

  async getPlayerInvitations(identifier: string) {
    if (!identifier) return [];
    const clean = identifier.trim().toUpperCase();
    const cleanDigits = identifier.replace(/\D/g, '');
    const last10 = cleanDigits.length >= 10 ? cleanDigits.slice(-10) : cleanDigits;

    const invites = this.readInvitations();
    return invites.filter((inv) => {
      const matchId = inv.targetPlayerId.toUpperCase() === clean;
      const matchPhone = last10 && inv.targetPhone && inv.targetPhone.replace(/\D/g, '').includes(last10);
      return (matchId || matchPhone) && inv.status === 'pending';
    });
  }

  async respondTeamInvitation(inviteId: string, action: 'accept' | 'decline', playerData?: any) {
    const invites = this.readInvitations();
    const index = invites.findIndex((inv) => inv.id === inviteId);
    if (index === -1) {
      throw new BadRequestException('Invitation not found');
    }

    const invite = invites[index];
    if (action === 'accept') {
      invite.status = 'accepted';
      invite.resolvedAt = new Date().toISOString();

      if (invite.senderPhone) {
        const senderClean = invite.senderPhone.trim().replace(/\D/g, '');
        const senderUser = await this.prisma.user.findFirst({
          where: {
            OR: [
              { mobileNumber: senderClean },
              { mobileNumber: { contains: senderClean.slice(-10) } },
            ],
          },
        });
        if (senderUser && Array.isArray(senderUser.teamsJson)) {
          const updatedTeams = (senderUser.teamsJson as any[]).map((t: any) => {
            if (t.id === invite.senderTeamId) {
              const members = Array.isArray(t.members) ? [...t.members] : [];
              const alreadyMember = members.some(
                (m: any) =>
                  (m.playerId && m.playerId.toUpperCase() === invite.targetPlayerId.toUpperCase()) ||
                  (playerData?.phone && m.phone === playerData.phone)
              );
              if (!alreadyMember) {
                members.push({
                  id: `MBR-${Date.now()}`,
                  playerId: invite.targetPlayerId,
                  name: playerData?.name || invite.targetName || 'Teammate',
                  phone: playerData?.phone || invite.targetPhone || '',
                  role: invite.role || 'Player',
                });
              }
              return { ...t, members };
            }
            return t;
          });

          await this.prisma.user.update({
            where: { id: senderUser.id },
            data: { teamsJson: updatedTeams },
          });
        }
      }

      this.writeInvitations(invites);
      return { success: true, message: `Joined ${invite.senderTeamName} successfully!`, team: invite };
    } else {
      invite.status = 'declined';
      invite.resolvedAt = new Date().toISOString();
      this.writeInvitations(invites);
      return { success: true, message: 'Invitation declined' };
    }
  }

  async createTeamMatchChallenge(body: any) {
    const dir = path.join(process.cwd(), 'data');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    const file = path.join(dir, 'team_challenges.json');
    let challenges: any[] = [];
    try {
      if (fs.existsSync(file)) challenges = JSON.parse(fs.readFileSync(file, 'utf8'));
    } catch {}

    const newChallenge = {
      id: `CHAL-${Date.now()}`,
      challengerTeamId: body.challengerTeamId,
      challengerTeamName: body.challengerTeamName,
      opponentTeamId: body.opponentTeamId,
      opponentTeamName: body.opponentTeamName,
      sport: body.sport || 'Football',
      venueName: body.venueName || 'Downtown Sports Arena',
      courtName: body.courtName || 'Court A',
      date: body.date || new Date().toISOString().slice(0, 10),
      timeSlot: body.timeSlot || '07:00 PM - 08:00 PM',
      status: 'scheduled',
      createdAt: new Date().toISOString(),
    };

    challenges.unshift(newChallenge);
    fs.writeFileSync(file, JSON.stringify(challenges, null, 2), 'utf8');

    return { success: true, message: 'Team match scheduled successfully!', challenge: newChallenge };
  }

  // ==========================================
  // FRIENDS & LEADERBOARD SYSTEM
  // ==========================================

  private getFriendsFilePath(): string {
    const dir = path.join(process.cwd(), 'data');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    return path.join(dir, 'friends.json');
  }

  private readFriendRequests(): any[] {
    try {
      const file = this.getFriendsFilePath();
      if (fs.existsSync(file)) {
        return JSON.parse(fs.readFileSync(file, 'utf8'));
      }
    } catch {
      // ignore
    }
    // Seed initial friendships: Abdur & mafaz are friends, Vignesh has pending request to Abdur
    const seed = [
      {
        id: 'FR-SEED-1',
        fromPlayerId: 'PLY-0002',
        fromName: 'mafaz',
        fromPhone: '+918124817806',
        toPlayerId: 'PLY-0001',
        toName: 'Abdur',
        toPhone: '+919087786231',
        status: 'accepted',
        createdAt: new Date(Date.now() - 86400000 * 3).toISOString(),
        resolvedAt: new Date(Date.now() - 86400000 * 2).toISOString(),
      },
      {
        id: 'FR-SEED-2',
        fromPlayerId: 'PLY-0003',
        fromName: 'Vignesh',
        fromPhone: '+917010396731',
        toPlayerId: 'PLY-0001',
        toName: 'Abdur',
        toPhone: '+919087786231',
        status: 'pending',
        createdAt: new Date(Date.now() - 3600000 * 4).toISOString(),
      },
    ];
    this.writeFriendRequests(seed);
    return seed;
  }

  private writeFriendRequests(requests: any[]) {
    try {
      const file = this.getFriendsFilePath();
      fs.writeFileSync(file, JSON.stringify(requests, null, 2), 'utf8');
    } catch (e) {
      console.error('Failed to write friends', e);
    }
  }

  private getProfilesFilePath(): string {
    const dir = path.join(process.cwd(), 'data');
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    return path.join(dir, 'player_profiles.json');
  }

  private readPlayerProfiles(): any[] {
    try {
      const file = this.getProfilesFilePath();
      if (fs.existsSync(file)) {
        return JSON.parse(fs.readFileSync(file, 'utf8'));
      }
    } catch {
      // ignore
    }
    const seed = this.getDefaultPlayerProfiles();
    this.writePlayerProfiles(seed);
    return seed;
  }

  private writePlayerProfiles(profiles: any[]) {
    try {
      const file = this.getProfilesFilePath();
      fs.writeFileSync(file, JSON.stringify(profiles, null, 2), 'utf8');
    } catch (e) {
      console.error('Failed to write player profiles', e);
    }
  }

  private getDefaultPlayerProfiles(): any[] {
    return [
      {
        playerId: 'PLY-0001',
        phone: '+919087786231',
        fullName: 'Abdur',
        avatarUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        city: 'Chennai',
        state: 'Tamil Nadu',
        sport: 'Cricket',
        role: 'All-Rounder',
        matchesPlayed: 18,
        wins: 15,
        losses: 3,
        runs: 460,
        wickets: 18,
        battingAvg: 46.0,
        strikeRate: 158.4,
        bowlingEcon: 6.8,
        fifties: 3,
        hundreds: 0,
        goals: 8,
        assists: 5,
        cleanSheets: 2,
        mvpCount: 6,
        fairPlayRating: 5.0,
        points: 3580,
        badge: 'Universal Elite',
        form: '96%',
        isVerified: true,
      },
      {
        playerId: 'PLY-0002',
        phone: '+918124817806',
        fullName: 'mafaz',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        city: 'Chennai',
        state: 'Tamil Nadu',
        sport: 'Cricket',
        role: 'Batter',
        matchesPlayed: 15,
        wins: 11,
        losses: 4,
        runs: 490,
        wickets: 2,
        battingAvg: 49.0,
        strikeRate: 165.2,
        bowlingEcon: 8.5,
        fifties: 4,
        hundreds: 1,
        goals: 4,
        assists: 2,
        cleanSheets: 0,
        mvpCount: 4,
        fairPlayRating: 4.9,
        points: 3240,
        badge: 'Turf Master',
        form: '88%',
        isVerified: true,
      },
      {
        playerId: 'PLY-0003',
        phone: '+917010396731',
        fullName: 'Vignesh',
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        city: 'Chennai',
        state: 'Tamil Nadu',
        sport: 'Cricket',
        role: 'Bowler',
        matchesPlayed: 14,
        wins: 10,
        losses: 4,
        runs: 95,
        wickets: 26,
        battingAvg: 15.8,
        strikeRate: 110.0,
        bowlingEcon: 5.9,
        fifties: 0,
        hundreds: 0,
        goals: 0,
        assists: 1,
        cleanSheets: 0,
        mvpCount: 3,
        fairPlayRating: 4.9,
        points: 3110,
        badge: 'Wicket Machine',
        form: '85%',
        isVerified: true,
      },
      {
        playerId: 'PLY-1014',
        phone: '+919876543201',
        fullName: 'Karthik Raman',
        avatarUrl: 'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
        city: 'Chennai',
        state: 'Tamil Nadu',
        sport: 'Cricket',
        role: 'Bowler',
        matchesPlayed: 16,
        wins: 12,
        losses: 4,
        runs: 80,
        wickets: 28,
        battingAvg: 13.3,
        strikeRate: 105.0,
        bowlingEcon: 5.4,
        fifties: 0,
        hundreds: 0,
        goals: 0,
        assists: 0,
        cleanSheets: 0,
        mvpCount: 4,
        fairPlayRating: 4.8,
        points: 3150,
        badge: 'Death Overs Ace',
        form: '86%',
        isVerified: true,
      },
      {
        playerId: 'PLY-1022',
        phone: '+919876543202',
        fullName: 'Sanjay Verma',
        avatarUrl: 'https://images.unsplash.com/photo-1519085360753-af0119f7cbe7?w=150',
        city: 'Chennai',
        state: 'Tamil Nadu',
        sport: 'Football',
        role: 'Midfielder',
        matchesPlayed: 14,
        wins: 10,
        losses: 4,
        runs: 0,
        wickets: 0,
        goals: 9,
        assists: 14,
        cleanSheets: 3,
        mvpCount: 3,
        fairPlayRating: 4.9,
        points: 2850,
        badge: 'Playmaker',
        form: '82%',
        isVerified: false,
      },
      {
        playerId: 'PLY-1031',
        phone: '+919876543203',
        fullName: 'Praveen Kumar',
        avatarUrl: 'https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150',
        city: 'Coimbatore',
        state: 'Tamil Nadu',
        sport: 'Cricket',
        role: 'All-Rounder',
        matchesPlayed: 13,
        wins: 9,
        losses: 4,
        runs: 280,
        wickets: 15,
        battingAvg: 35.0,
        strikeRate: 142.0,
        bowlingEcon: 6.9,
        fifties: 2,
        hundreds: 0,
        goals: 2,
        assists: 1,
        cleanSheets: 0,
        mvpCount: 2,
        fairPlayRating: 4.8,
        points: 2680,
        badge: 'Clutch Striker',
        form: '78%',
        isVerified: false,
      },
      {
        playerId: 'PLY-1045',
        phone: '+919876543204',
        fullName: 'Rohan Sharma',
        avatarUrl: 'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
        city: 'Bangalore',
        state: 'Karnataka',
        sport: 'Cricket',
        role: 'Batter',
        matchesPlayed: 17,
        wins: 14,
        losses: 3,
        runs: 560,
        wickets: 1,
        battingAvg: 56.0,
        strikeRate: 172.5,
        bowlingEcon: 9.0,
        fifties: 5,
        hundreds: 1,
        goals: 0,
        assists: 0,
        cleanSheets: 0,
        mvpCount: 5,
        fairPlayRating: 4.9,
        points: 3450,
        badge: 'Century King',
        form: '92%',
        isVerified: true,
      },
      {
        playerId: 'PLY-1052',
        phone: '+919876543205',
        fullName: 'Deepak Gowda',
        avatarUrl: 'https://images.unsplash.com/photo-1539571696357-5a69c17a67c6?w=150',
        city: 'Bangalore',
        state: 'Karnataka',
        sport: 'Football',
        role: 'Forward / Striker',
        matchesPlayed: 16,
        wins: 12,
        losses: 4,
        goals: 21,
        assists: 6,
        cleanSheets: 1,
        mvpCount: 4,
        fairPlayRating: 4.7,
        points: 3120,
        badge: 'Golden Boot',
        form: '84%',
        isVerified: true,
      },
      {
        playerId: 'PLY-1067',
        phone: '+919876543206',
        fullName: 'Ananya Deshmukh',
        avatarUrl: 'https://images.unsplash.com/photo-1517841905240-472988babdf9?w=150',
        city: 'Mumbai',
        state: 'Maharashtra',
        sport: 'Badminton',
        role: 'Singles Specialist',
        matchesPlayed: 18,
        wins: 16,
        losses: 2,
        runs: 0,
        wickets: 0,
        goals: 0,
        assists: 0,
        cleanSheets: 0,
        mvpCount: 6,
        fairPlayRating: 5.0,
        points: 3310,
        badge: 'Court Queen',
        form: '94%',
        isVerified: true,
      },
      {
        playerId: 'PLY-1078',
        phone: '+919876543207',
        fullName: 'Vikram Sethi',
        avatarUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150',
        city: 'Delhi NCR',
        state: 'Delhi',
        sport: 'Football',
        role: 'Forward / Striker',
        matchesPlayed: 18,
        wins: 15,
        losses: 3,
        goals: 24,
        assists: 8,
        cleanSheets: 0,
        mvpCount: 6,
        fairPlayRating: 4.9,
        points: 3420,
        badge: 'Apex Predator',
        form: '94%',
        isVerified: true,
      },
      {
        playerId: 'PLY-1089',
        phone: '+919876543208',
        fullName: 'Sameer Khan',
        avatarUrl: 'https://images.unsplash.com/photo-1501196354995-cbb51c65aaea?w=150',
        city: 'Delhi NCR',
        state: 'Delhi',
        sport: 'Cricket',
        role: 'All-Rounder',
        matchesPlayed: 15,
        wins: 11,
        losses: 4,
        runs: 340,
        wickets: 16,
        battingAvg: 37.7,
        strikeRate: 148.0,
        bowlingEcon: 6.7,
        fifties: 2,
        hundreds: 0,
        goals: 1,
        assists: 2,
        cleanSheets: 0,
        mvpCount: 3,
        fairPlayRating: 4.8,
        points: 2980,
        badge: 'Impact Player',
        form: '82%',
        isVerified: false,
      },
      {
        playerId: 'PLY-1095',
        phone: '+919876543209',
        fullName: 'Rahul Dravid S.',
        avatarUrl: 'https://images.unsplash.com/photo-1463453091185-61582044d556?w=150',
        city: 'Hyderabad',
        state: 'Telangana',
        sport: 'Cricket',
        role: 'Wicket-Keeper',
        matchesPlayed: 14,
        wins: 10,
        losses: 4,
        runs: 380,
        wickets: 0,
        battingAvg: 42.2,
        strikeRate: 135.0,
        catches: 18,
        stumpings: 6,
        fifties: 3,
        hundreds: 0,
        goals: 0,
        assists: 0,
        cleanSheets: 0,
        mvpCount: 3,
        fairPlayRating: 5.0,
        points: 2840,
        badge: 'Safe Hands',
        form: '80%',
        isVerified: true,
      },
      {
        playerId: 'PLY-1102',
        phone: '+919876543210',
        fullName: 'Syed Ibrahim',
        avatarUrl: 'https://images.unsplash.com/photo-1508214751196-bcfd4ca60f91?w=150',
        city: 'Hyderabad',
        state: 'Telangana',
        sport: 'Football',
        role: 'Goalkeeper',
        matchesPlayed: 14,
        wins: 9,
        losses: 5,
        goals: 0,
        assists: 1,
        cleanSheets: 7,
        saves: 45,
        mvpCount: 3,
        fairPlayRating: 4.9,
        points: 2640,
        badge: 'The Wall',
        form: '76%',
        isVerified: false,
      },
      {
        playerId: 'PLY-1115',
        phone: '+919876543211',
        fullName: 'Gautam Menon',
        avatarUrl: 'https://images.unsplash.com/photo-1521119989659-a83eee488004?w=150',
        city: 'Chennai',
        state: 'Tamil Nadu',
        sport: 'Cricket',
        role: 'Wicket-Keeper',
        matchesPlayed: 12,
        wins: 8,
        losses: 4,
        runs: 270,
        wickets: 0,
        battingAvg: 33.7,
        strikeRate: 128.0,
        catches: 14,
        stumpings: 4,
        fifties: 2,
        hundreds: 0,
        goals: 0,
        assists: 0,
        cleanSheets: 0,
        mvpCount: 2,
        fairPlayRating: 4.8,
        points: 2520,
        badge: 'Gloveman',
        form: '74%',
        isVerified: false,
      },
      {
        playerId: 'PLY-1123',
        phone: '+919876543212',
        fullName: 'Aditya Rao',
        avatarUrl: 'https://images.unsplash.com/photo-1496345875659-11f7dd282d1d?w=150',
        city: 'Bangalore',
        state: 'Karnataka',
        sport: 'Badminton',
        role: 'Doubles Specialist',
        matchesPlayed: 15,
        wins: 11,
        losses: 4,
        runs: 0,
        wickets: 0,
        goals: 0,
        assists: 0,
        cleanSheets: 0,
        mvpCount: 3,
        fairPlayRating: 4.8,
        points: 2740,
        badge: 'Smash Specialist',
        form: '81%',
        isVerified: false,
      },
      {
        playerId: 'PLY-1134',
        phone: '+919876543213',
        fullName: 'Kishore Raj',
        avatarUrl: 'https://images.unsplash.com/photo-1531891437562-4301cf35b7e4?w=150',
        city: 'Chennai',
        state: 'Tamil Nadu',
        sport: 'Football',
        role: 'Defender',
        matchesPlayed: 13,
        wins: 9,
        losses: 4,
        goals: 2,
        assists: 4,
        cleanSheets: 6,
        mvpCount: 2,
        fairPlayRating: 4.9,
        points: 2610,
        badge: 'Stopper',
        form: '75%',
        isVerified: false,
      },
      {
        playerId: 'PLY-1145',
        phone: '+919876543214',
        fullName: 'Naveen Balaji',
        avatarUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        city: 'Madurai',
        state: 'Tamil Nadu',
        sport: 'Cricket',
        role: 'Bowler',
        matchesPlayed: 12,
        wins: 8,
        losses: 4,
        runs: 60,
        wickets: 21,
        battingAvg: 12.0,
        strikeRate: 98.0,
        bowlingEcon: 6.2,
        fifties: 0,
        hundreds: 0,
        goals: 0,
        assists: 0,
        cleanSheets: 0,
        mvpCount: 2,
        fairPlayRating: 4.7,
        points: 2430,
        badge: 'Spinner',
        form: '72%',
        isVerified: false,
      },
      {
        playerId: 'PLY-1156',
        phone: '+919876543215',
        fullName: 'Ashwin Nathan',
        avatarUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        city: 'Chennai',
        state: 'Tamil Nadu',
        sport: 'Cricket',
        role: 'All-Rounder',
        matchesPlayed: 15,
        wins: 11,
        losses: 4,
        runs: 320,
        wickets: 15,
        battingAvg: 35.5,
        strikeRate: 152.0,
        bowlingEcon: 6.5,
        fifties: 2,
        hundreds: 0,
        goals: 2,
        assists: 3,
        cleanSheets: 0,
        mvpCount: 3,
        fairPlayRating: 4.9,
        points: 2940,
        badge: 'Dual Threat',
        form: '83%',
        isVerified: true,
      },
    ];
  }

  private normalizePhone(phone?: string): string {
    if (!phone) return '';
    const clean = phone.replace(/\D/g, '');
    return clean.length >= 10 ? clean.slice(-10) : clean;
  }

  private areFriends(
    caller: { phone?: string; playerId?: string },
    target: { phone?: string; playerId?: string },
    requests: any[]
  ): boolean {
    const cPhone = this.normalizePhone(caller.phone);
    const cId = caller.playerId?.toUpperCase();
    const tPhone = this.normalizePhone(target.phone);
    const tId = target.playerId?.toUpperCase();

    return requests.some((req) => {
      if (req.status !== 'accepted') return false;
      const fPhone = this.normalizePhone(req.fromPhone);
      const toPhone = this.normalizePhone(req.toPhone);
      const fId = req.fromPlayerId?.toUpperCase();
      const toId = req.toPlayerId?.toUpperCase();

      const fromMatchesCaller = (cId && fId === cId) || (cPhone && fPhone === cPhone);
      const toMatchesTarget = (tId && toId === tId) || (tPhone && toPhone === tPhone);
      if (fromMatchesCaller && toMatchesTarget) return true;

      const fromMatchesTarget = (tId && fId === tId) || (tPhone && fPhone === tPhone);
      const toMatchesCaller = (cId && toId === cId) || (cPhone && toPhone === cPhone);
      return fromMatchesTarget && toMatchesCaller;
    });
  }

  private getFriendshipDetails(
    caller: { phone?: string; playerId?: string },
    target: { phone?: string; playerId?: string },
    requests: any[]
  ): { status: 'none' | 'pending_sent' | 'pending_received' | 'accepted'; requestId?: string } {
    const cPhone = this.normalizePhone(caller.phone);
    const cId = caller.playerId?.toUpperCase();
    const tPhone = this.normalizePhone(target.phone);
    const tId = target.playerId?.toUpperCase();

    if ((cId && tId && cId === tId) || (cPhone && tPhone && cPhone === tPhone)) {
      return { status: 'none' };
    }

    for (const req of requests) {
      const fPhone = this.normalizePhone(req.fromPhone);
      const toPhone = this.normalizePhone(req.toPhone);
      const fId = req.fromPlayerId?.toUpperCase();
      const toId = req.toPlayerId?.toUpperCase();

      const callerIsFrom = (cId && fId === cId) || (cPhone && fPhone === cPhone);
      const targetIsTo = (tId && toId === tId) || (tPhone && toPhone === tPhone);
      if (callerIsFrom && targetIsTo) {
        if (req.status === 'accepted') return { status: 'accepted', requestId: req.id };
        if (req.status === 'pending') return { status: 'pending_sent', requestId: req.id };
      }

      const targetIsFrom = (tId && fId === tId) || (tPhone && fPhone === tPhone);
      const callerIsTo = (cId && toId === cId) || (cPhone && toPhone === cPhone);
      if (targetIsFrom && callerIsTo) {
        if (req.status === 'accepted') return { status: 'accepted', requestId: req.id };
        if (req.status === 'pending') return { status: 'pending_received', requestId: req.id };
      }
    }

    return { status: 'none' };
  }

  async getLeaderboard(params: {
    scope?: string;
    sport?: string;
    role?: string;
    city?: string;
    state?: string;
    phone?: string;
    playerId?: string;
  }) {
    const friendRequests = this.readFriendRequests();
    const allProfiles = this.readPlayerProfiles();

    // Reconcile Prisma users with profiles:
    const prismaUsers = await this.prisma.user.findMany();
    for (const u of prismaUsers) {
      const uPhoneLast10 = this.normalizePhone(u.mobileNumber);
      const uPlayerId = `PLY-${u.id.toString().padStart(4, '0')}`;
      const existing = allProfiles.find(
        (p) =>
          this.normalizePhone(p.phone) === uPhoneLast10 ||
          p.playerId.toUpperCase() === uPlayerId.toUpperCase()
      );
      if (!existing) {
        allProfiles.push({
          playerId: uPlayerId,
          phone: u.mobileNumber,
          fullName: u.fullName || 'Active Player',
          avatarUrl: `https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150`,
          city: 'Chennai',
          state: 'Tamil Nadu',
          sport: u.preferredSport || 'Cricket',
          role: u.preferredSport === 'Cricket' ? 'All-Rounder' : 'Forward / Striker',
          matchesPlayed: 10,
          wins: 7,
          losses: 3,
          runs: 210,
          wickets: 8,
          battingAvg: 30.0,
          strikeRate: 140.0,
          bowlingEcon: 7.2,
          fifties: 1,
          hundreds: 0,
          goals: 5,
          assists: 3,
          cleanSheets: 1,
          mvpCount: 2,
          fairPlayRating: 5.0,
          points: 2500,
          badge: 'Rising Star',
          form: '78%',
          isVerified: true,
        });
      }
    }

    // Determine current user
    const callerPhone = this.normalizePhone(params.phone);
    const callerPlayerId = params.playerId?.toUpperCase();
    const currentUserProfile = allProfiles.find(
      (p) =>
        (callerPlayerId && p.playerId.toUpperCase() === callerPlayerId) ||
        (callerPhone && this.normalizePhone(p.phone) === callerPhone)
    ) || allProfiles[0];

    const currentCity = params.city || currentUserProfile.city || 'Chennai';
    const currentState = params.state || currentUserProfile.state || 'Tamil Nadu';

    // Filter by Scope
    const scope = (params.scope || 'global').toLowerCase();
    let scopedList = allProfiles;

    if (scope === 'friends') {
      scopedList = allProfiles.filter((p) => {
        const isSelf =
          (callerPlayerId && p.playerId.toUpperCase() === callerPlayerId) ||
          (callerPhone && this.normalizePhone(p.phone) === callerPhone);
        if (isSelf) return true;
        return this.areFriends(
          { phone: callerPhone, playerId: callerPlayerId },
          { phone: p.phone, playerId: p.playerId },
          friendRequests
        );
      });
    } else if (scope === 'city') {
      scopedList = allProfiles.filter(
        (p) => p.city.toLowerCase() === currentCity.toLowerCase()
      );
    } else if (scope === 'state') {
      scopedList = allProfiles.filter(
        (p) => p.state.toLowerCase() === currentState.toLowerCase()
      );
    }

    // Filter by Sport
    const sportFilter = params.sport || 'All Sports';
    if (sportFilter && sportFilter !== 'All Sports' && sportFilter !== 'All') {
      scopedList = scopedList.filter(
        (p) => p.sport.toLowerCase() === sportFilter.toLowerCase()
      );
    }

    // Filter by Role
    const roleFilter = params.role || 'All Roles';
    if (roleFilter && roleFilter !== 'All Roles' && roleFilter !== 'All') {
      scopedList = scopedList.filter(
        (p) => p.role.toLowerCase() === roleFilter.toLowerCase()
      );
    }

    // Sort descending by points
    scopedList.sort((a, b) => (b.points || 0) - (a.points || 0));

    // Map into rich leaderboard items
    let userRankIndex = -1;
    const leaderboard = scopedList.map((player, idx) => {
      const rank = idx + 1;
      const isYou =
        (callerPlayerId && player.playerId.toUpperCase() === callerPlayerId) ||
        (callerPhone && this.normalizePhone(player.phone) === callerPhone);
      if (isYou) userRankIndex = idx;

      const friendship = this.getFriendshipDetails(
        { phone: callerPhone, playerId: callerPlayerId },
        { phone: player.phone, playerId: player.playerId },
        friendRequests
      );

      // Rank change heuristic for excitement
      let change = '-';
      let isNegative = false;
      if (rank === 1) {
        change = '-';
      } else if (rank % 3 === 0) {
        change = '+ 2';
      } else if (rank % 4 === 0) {
        change = '- 1';
        isNegative = true;
      } else if (rank % 2 === 0) {
        change = '+ 1';
      }

      const winRate =
        player.matchesPlayed > 0
          ? `${Math.round((player.wins / player.matchesPlayed) * 100)}% W`
          : '100% W';

      return {
        rank,
        change,
        isChangeNegative: isNegative,
        playerId: player.playerId,
        name: player.fullName,
        phone: player.phone,
        city: player.city,
        state: player.state,
        location: `${player.city}, ${player.state}`,
        sport: player.sport,
        role: player.role,
        points: player.points.toLocaleString(),
        pointsNumeric: player.points,
        wins: `${player.wins} Wins`,
        matchesPlayed: player.matchesPlayed,
        winRate,
        imageUrl: player.avatarUrl || 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        badge: player.badge,
        isVerified: player.isVerified,
        isYou,
        friendshipStatus: friendship.status, // 'none' | 'pending_sent' | 'pending_received' | 'accepted'
        friendRequestId: friendship.requestId,
        statsSummary:
          player.sport === 'Cricket'
            ? `${player.runs || 0} Runs • ${player.wickets || 0} Wkts`
            : player.sport === 'Football'
            ? `${player.goals || 0} Goals • ${player.assists || 0} Ast`
            : `${player.wins} W • ${player.form || '80%'} Form`,
      };
    });

    // Compute current user rank data
    const myPlayer = leaderboard.find((p) => p.isYou) || {
      rank: userRankIndex >= 0 ? userRankIndex + 1 : leaderboard.length + 1,
      pointsNumeric: currentUserProfile.points,
      points: currentUserProfile.points.toLocaleString(),
      name: currentUserProfile.fullName,
      role: currentUserProfile.role,
      location: `${currentCity}, ${currentState}`,
    };

    let pointsToNext = 0;
    let targetPlayerName = '';
    if (myPlayer.rank > 1 && myPlayer.rank - 2 < leaderboard.length) {
      const playerAhead = leaderboard[myPlayer.rank - 2];
      if (playerAhead) {
        pointsToNext = Math.max(0, playerAhead.pointsNumeric - myPlayer.pointsNumeric);
        targetPlayerName = playerAhead.name;
      }
    }

    return {
      success: true,
      season: {
        name: 'Season 4 Final Lap',
        daysLeft: 12,
        reward: 'Top 3 earn ₹25,000 Vouchers + Golden Jersey',
        universalPlayersCount: 4820,
      },
      activeFilters: {
        scope,
        currentCity,
        currentState,
        sport: sportFilter,
        role: roleFilter,
      },
      currentUserRank: {
        rank: myPlayer.rank,
        points: myPlayer.points,
        pointsNumeric: myPlayer.pointsNumeric,
        role: currentUserProfile.role,
        pointsToNext,
        targetPlayerName,
        totalContenders: leaderboard.length,
      },
      leaderboard,
    };
  }

  async sendFriendRequest(body: {
    fromPhone: string;
    fromPlayerId?: string;
    fromName?: string;
    toPlayerId: string;
    toPhone?: string;
    toName?: string;
  }) {
    if (!body.toPlayerId) {
      throw new BadRequestException('Target player ID is required');
    }

    const requests = this.readFriendRequests();
    const cPhone = this.normalizePhone(body.fromPhone);
    const cId = body.fromPlayerId?.toUpperCase();
    const tId = body.toPlayerId.toUpperCase();
    const tPhone = this.normalizePhone(body.toPhone);

    // Cannot friend yourself
    if (cId === tId || (cPhone && tPhone && cPhone === tPhone)) {
      throw new BadRequestException('You cannot send a friend request to yourself');
    }

    // Check existing
    const existing = requests.find((r) => {
      const fId = r.fromPlayerId?.toUpperCase();
      const toId = r.toPlayerId?.toUpperCase();
      const fPhone = this.normalizePhone(r.fromPhone);
      const toP = this.normalizePhone(r.toPhone);

      const forward = (fId === cId || (cPhone && fPhone === cPhone)) && (toId === tId || (tPhone && toP === tPhone));
      const reverse = (fId === tId || (tPhone && fPhone === tPhone)) && (toId === cId || (cPhone && toP === cPhone));
      return forward || reverse;
    });

    if (existing) {
      if (existing.status === 'accepted') {
        return { success: true, message: 'You are already friends!', request: existing };
      }
      if (existing.status === 'pending') {
        return { success: true, message: 'Friend request already pending', request: existing };
      }
    }

    const newRequest = {
      id: `FR-${Date.now()}`,
      fromPlayerId: body.fromPlayerId || 'PLY-0001',
      fromName: body.fromName || 'Active Player',
      fromPhone: body.fromPhone,
      toPlayerId: body.toPlayerId,
      toName: body.toName || 'Challenger',
      toPhone: body.toPhone || '',
      status: 'pending',
      createdAt: new Date().toISOString(),
    };

    requests.unshift(newRequest);
    this.writeFriendRequests(requests);

    return {
      success: true,
      message: `Friend request sent to ${newRequest.toName}!`,
      request: newRequest,
    };
  }

  async respondFriendRequest(body: {
    requestId: string;
    action: 'accept' | 'decline';
    responderPhone?: string;
    responderPlayerId?: string;
  }) {
    const requests = this.readFriendRequests();
    const index = requests.findIndex((r) => r.id === body.requestId);
    if (index === -1) {
      throw new BadRequestException('Friend request not found');
    }

    const req = requests[index];
    req.status = body.action === 'accept' ? 'accepted' : 'declined';
    req.resolvedAt = new Date().toISOString();

    this.writeFriendRequests(requests);

    return {
      success: true,
      message: body.action === 'accept' ? 'Friend request accepted! You are now friends.' : 'Friend request declined.',
      request: req,
    };
  }

  async getPlayerFriends(identifier: string) {
    if (!identifier) return { friends: [], incomingRequests: [], outgoingRequests: [] };

    const clean = this.normalizePhone(identifier);
    const idUpper = identifier.toUpperCase();
    const friendRequests = this.readFriendRequests();
    const allProfiles = this.readPlayerProfiles();

    const incoming: any[] = [];
    const outgoing: any[] = [];
    const friendSet = new Set<string>();

    for (const req of friendRequests) {
      const fPhone = this.normalizePhone(req.fromPhone);
      const toPhone = this.normalizePhone(req.toPhone);
      const fId = req.fromPlayerId?.toUpperCase();
      const toId = req.toPlayerId?.toUpperCase();

      const isSender = (fId && fId === idUpper) || (clean && fPhone === clean);
      const isReceiver = (toId && toId === idUpper) || (clean && toPhone === clean);

      if (req.status === 'accepted') {
        if (isSender) friendSet.add(req.toPlayerId);
        if (isReceiver) friendSet.add(req.fromPlayerId);
      } else if (req.status === 'pending') {
        if (isReceiver) incoming.push(req);
        if (isSender) outgoing.push(req);
      }
    }

    const friendsList = allProfiles.filter((p) => friendSet.has(p.playerId));

    return {
      success: true,
      friendsCount: friendsList.length,
      friends: friendsList,
      incomingRequests: incoming,
      outgoingRequests: outgoing,
    };
  }

  async getPlayerPublicProfile(targetIdentifier: string, callerIdentifier?: string) {
    const allProfiles = this.readPlayerProfiles();
    const targetClean = this.normalizePhone(targetIdentifier);
    const targetUpper = targetIdentifier.toUpperCase();

    const player = allProfiles.find(
      (p) =>
        p.playerId.toUpperCase() === targetUpper ||
        this.normalizePhone(p.phone) === targetClean
    );

    if (!player) {
      throw new BadRequestException('Player not found');
    }

    const friendRequests = this.readFriendRequests();
    const callerClean = callerIdentifier ? this.normalizePhone(callerIdentifier) : '';
    const callerUpper = callerIdentifier ? callerIdentifier.toUpperCase() : '';

    const friendship = this.getFriendshipDetails(
      { phone: callerClean, playerId: callerUpper },
      { phone: player.phone, playerId: player.playerId },
      friendRequests
    );

    // Caller's stats for head-to-head comparison
    const callerProfile = allProfiles.find(
      (p) =>
        (callerUpper && p.playerId.toUpperCase() === callerUpper) ||
        (callerClean && this.normalizePhone(p.phone) === callerClean)
    );

    return {
      success: true,
      player: {
        ...player,
        location: `${player.city}, ${player.state}`,
        winRate:
          player.matchesPlayed > 0
            ? `${Math.round((player.wins / player.matchesPlayed) * 100)}%`
            : '100%',
        friendshipStatus: friendship.status,
        friendRequestId: friendship.requestId,
      },
      headToHead: callerProfile
        ? {
            caller: {
              name: callerProfile.fullName,
              playerId: callerProfile.playerId,
              points: callerProfile.points,
              wins: callerProfile.wins,
              matches: callerProfile.matchesPlayed,
              sport: callerProfile.sport,
              role: callerProfile.role,
            },
            target: {
              name: player.fullName,
              playerId: player.playerId,
              points: player.points,
              wins: player.wins,
              matches: player.matchesPlayed,
              sport: player.sport,
              role: player.role,
            },
          }
        : null,
    };
  }

  async updatePlayerProfile(body: {
    phone?: string;
    playerId?: string;
    city?: string;
    state?: string;
    preferredSport?: string;
    role?: string;
  }) {
    const allProfiles = this.readPlayerProfiles();
    const clean = this.normalizePhone(body.phone);
    const idUpper = body.playerId?.toUpperCase();

    const index = allProfiles.findIndex(
      (p) =>
        (idUpper && p.playerId.toUpperCase() === idUpper) ||
        (clean && this.normalizePhone(p.phone) === clean)
    );

    if (index === -1) {
      throw new BadRequestException('Profile not found');
    }

    if (body.city) allProfiles[index].city = body.city;
    if (body.state) allProfiles[index].state = body.state;
    if (body.preferredSport) allProfiles[index].sport = body.preferredSport;
    if (body.role) allProfiles[index].role = body.role;

    this.writePlayerProfiles(allProfiles);

    return {
      success: true,
      message: 'Profile updated successfully',
      profile: allProfiles[index],
    };
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



