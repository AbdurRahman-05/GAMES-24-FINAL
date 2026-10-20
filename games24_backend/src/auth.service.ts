import { Injectable, BadRequestException } from '@nestjs/common';
import { PrismaService } from './prisma.service.js';
import * as bcrypt from 'bcrypt';

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

    return {
      success: true,
      message: `Login successful! Welcome back, ${verifiedAdmin.venueName}.`,
      admin: verifiedAdmin,
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
    });

    if (!admin) {
      throw new BadRequestException('No verified admin found for this mobile number');
    }

    return {
      success: true,
      admin,
    };
  }
}



