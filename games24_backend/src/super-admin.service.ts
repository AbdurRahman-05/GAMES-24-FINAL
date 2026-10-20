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
    const verifiedAdmin = await this.prisma.verifiedAdmin.findUnique({
      where: { id },
    });
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
}
