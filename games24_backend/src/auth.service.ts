import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from './prisma.service.js';
import * as bcrypt from 'bcrypt';
import fs from 'fs';
import path from 'path';
import { DEFAULT_TURF_SPORTS, generateTimeSlots } from './turf.service.js';

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

    // Check ONLY the VerifiedAdmin table!
    const verifiedAdmin = await this.prisma.verifiedAdmin.findFirst({
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
    });

    if (!verifiedAdmin) {
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
    const monthTotalBookings = monthBookings.length;
    const monthRevenue = monthBookings.reduce((sum: number, b: any) => sum + (Number(b.amount) || 0), 0);
    const bookedSlotsCount = todayBookings.reduce((acc: number, b: any) => acc + countBookingSlots(b.timeSlot), 0);
    const openingTime = dashboard.openingTime || '05:00 AM';
    const closingTime = dashboard.closingTime || '11:00 PM';
    const totalSlots = generateTimeSlots(openingTime, closingTime).length || 18;
    const freeSlotsCount = Math.max(0, totalSlots - bookedSlotsCount - (dashboard.blockedSlotsCount || 0));
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
        sports: getAdminSports(verifiedAdmin.id).map((s: any) => s.name),
        sportsList: getAdminSports(verifiedAdmin.id),
      },
    };
  }

  async getVerifiedAdminByPhone(phone: string) {
    const clean = phone.trim().replace(/[^0-9]/g, '');
    const admin = await this.prisma.verifiedAdmin.findFirst({
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
    });

    if (!admin) {
      throw new BadRequestException('No verified admin found for this mobile number');
    }

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
    const monthTotalBookings = monthBookings.length;
    const monthRevenue = monthBookings.reduce((sum: number, b: any) => sum + (Number(b.amount) || 0), 0);
    const bookedSlotsCount = todayBookings.reduce((acc: number, b: any) => acc + countBookingSlots(b.timeSlot), 0);
    const openingTime = dashboard.openingTime || '05:00 AM';
    const closingTime = dashboard.closingTime || '11:00 PM';
    const totalSlots = generateTimeSlots(openingTime, closingTime).length || 18;
    const freeSlotsCount = Math.max(0, totalSlots - bookedSlotsCount - (dashboard.blockedSlotsCount || 0));
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
        sports: getAdminSports(admin.id).map((s: any) => s.name),
        sportsList: getAdminSports(admin.id),
      },
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



