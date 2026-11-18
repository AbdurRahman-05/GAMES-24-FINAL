import {
  Controller,
  Post,
  Get,
  Param,
  Res,
  UploadedFile,
  UseInterceptors,
  BadRequestException,
  Req,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'fs';
import type { Request, Response } from 'express';
import { PrismaService } from './prisma.service.js';
import { v2 as cloudinary } from 'cloudinary';

const uploadsBaseDir = join(process.cwd(), 'uploads');
const photosDir = join(uploadsBaseDir, 'photos');
const documentsDir = join(uploadsBaseDir, 'documents');

if (!existsSync(photosDir)) {
  mkdirSync(photosDir, { recursive: true });
}
if (!existsSync(documentsDir)) {
  mkdirSync(documentsDir, { recursive: true });
}

const IMAGE_EXTENSIONS = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp', '.heic', '.jfif'];

// Setup Cloudinary from environment variables if present
const hasCloudinary = Boolean(
  process.env.CLOUDINARY_URL ||
    (process.env.CLOUDINARY_CLOUD_NAME &&
      process.env.CLOUDINARY_API_KEY &&
      process.env.CLOUDINARY_API_SECRET),
);

if (process.env.CLOUDINARY_URL) {
  cloudinary.config();
  console.log('[CLOUDINARY] ☁️ Cloudinary initialized via CLOUDINARY_URL');
} else if (
  process.env.CLOUDINARY_CLOUD_NAME &&
  process.env.CLOUDINARY_API_KEY &&
  process.env.CLOUDINARY_API_SECRET
) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key: process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
    secure: true,
  });
  console.log(`[CLOUDINARY] ☁️ Cloudinary initialized for cloud: ${process.env.CLOUDINARY_CLOUD_NAME}`);
}

async function uploadToCloudinary(
  buffer: Buffer,
  folder: string,
  resourceType: 'image' | 'raw' | 'auto',
  publicId?: string,
): Promise<string> {
  return new Promise((resolve, reject) => {
    const uploadStream = cloudinary.uploader.upload_stream(
      {
        folder,
        resource_type: resourceType,
        public_id: publicId,
      },
      (error, result) => {
        if (error) return reject(error);
        if (!result?.secure_url) return reject(new Error('Cloudinary upload failed: no secure_url returned'));
        resolve(result.secure_url);
      },
    );
    uploadStream.end(buffer);
  });
}

@Controller('upload')
export class UploadController {
  constructor(private readonly prisma: PrismaService) {}

  @Post('photo')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: (_req, _file, cb) => {
          cb(null, photosDir);
        },
        filename: (_req, file, cb) => {
          const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
          const originalName = file.originalname || '';
          let ext = extname(originalName).toLowerCase();
          if (!ext || ext === '.bin' || !IMAGE_EXTENSIONS.includes(ext)) {
            const mime = (file.mimetype || '').toLowerCase();
            if (mime.includes('png')) {
              ext = '.png';
            } else if (mime.includes('webp')) {
              ext = '.webp';
            } else {
              ext = '.jpg';
            }
          }
          cb(null, `venue-${uniqueSuffix}${ext}`);
        },
      }),
      fileFilter: (_req, file, cb) => {
        try {
          const originalName = file.originalname || '';
          const ext = extname(originalName).toLowerCase();
          const mime = (file.mimetype || '').toLowerCase();

          const dangerousExtensions = [
            '.exe', '.bat', '.sh', '.cmd', '.js', '.ts', '.html', '.htm', '.php', '.svg', '.dll', '.vbs', '.py',
          ];
          if (dangerousExtensions.includes(ext) || mime === 'image/svg+xml') {
            return cb(new BadRequestException('Executable, script, or SVG files are not allowed.'), false);
          }

          const isImageExt = IMAGE_EXTENSIONS.includes(ext);
          const isImageMime = mime.startsWith('image/');
          const isOctet = mime === 'application/octet-stream' || mime === 'binary/octet-stream' || mime === '';

          if (isImageExt || isImageMime || isOctet || !ext) {
            return cb(null, true);
          }

          return cb(
            new BadRequestException('Only image files (JPG, PNG, WEBP) are allowed for venue photos!'),
            false,
          );
        } catch (err: any) {
          return cb(new BadRequestException(err?.message || 'Invalid file format.'), false);
        }
      },
      limits: { fileSize: 25 * 1024 * 1024 }, // 25MB
    }),
  )
  async uploadPhoto(@UploadedFile() file: Express.Multer.File, @Req() req: Request) {
    if (!file) {
      throw new BadRequestException('No photo file received. Please choose an image.');
    }
    const host = req.get('host') || 'localhost:3000';
    const protoHeader = req.headers['x-forwarded-proto'];
    const protocol = protoHeader
      ? String(protoHeader).split(',')[0].trim()
      : host.includes('localhost')
        ? 'http'
        : 'https';

    let fileUrl = `${protocol}://${host}/uploads/photos/${file.filename}`;

    const filePath = file.path;
    let fileBuffer: Buffer | null = null;
    if (filePath && existsSync(filePath)) {
      try {
        fileBuffer = readFileSync(filePath);
      } catch (err) {
        console.error('[UPLOAD] Error reading saved photo file:', err);
      }
    }

    // 1. Upload to Cloudinary if available
    if (hasCloudinary && fileBuffer) {
      try {
        const cloudUrl = await uploadToCloudinary(fileBuffer, 'games24/photos', 'image');
        fileUrl = cloudUrl;
        console.log(`[UPLOAD] ☁️ Photo uploaded to Cloudinary: ${cloudUrl}`);
      } catch (cErr: any) {
        console.error('[UPLOAD] Cloudinary photo upload failed, falling back to database/local:', cErr?.message || cErr);
      }
    }

    // 2. Persist to Neon PostgreSQL Database
    if (fileBuffer) {
      try {
        await (this.prisma as any).uploadedFile.upsert({
          where: { filename: file.filename },
          update: {
            originalName: file.originalname || 'photo.jpg',
            mimetype: file.mimetype || 'image/jpeg',
            size: file.size,
            data: fileBuffer,
          },
          create: {
            filename: file.filename,
            originalName: file.originalname || 'photo.jpg',
            mimetype: file.mimetype || 'image/jpeg',
            size: file.size,
            data: fileBuffer,
          },
        });
        console.log(`[UPLOAD] 💾 Saved photo ${file.filename} to Neon DB persistent storage`);
      } catch (dbErr: any) {
        console.error('[UPLOAD] Failed to save photo to DB storage:', dbErr?.message || dbErr);
      }
    }

    console.log(`[UPLOAD] 📸 Venue photo saved: ${file.filename} (${file.size} bytes) -> ${fileUrl}`);
    return {
      success: true,
      url: fileUrl,
      filename: file.filename,
      originalName: file.originalname,
      size: file.size,
      mimetype: file.mimetype,
    };
  }

  @Post('document')
  @UseInterceptors(
    FileInterceptor('file', {
      storage: diskStorage({
        destination: (_req, _file, cb) => {
          cb(null, documentsDir);
        },
        filename: (_req, file, cb) => {
          const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
          cb(null, `kyc-${uniqueSuffix}.pdf`);
        },
      }),
      fileFilter: (_req, file, cb) => {
        try {
          const originalName = file.originalname || '';
          const ext = extname(originalName).toLowerCase();
          const mime = (file.mimetype || '').toLowerCase();

          const isPdfExt = ext === '.pdf';
          const isPdfMime = mime === 'application/pdf';
          const isOctet = mime === 'application/octet-stream' || !mime;

          if (isPdfExt || isPdfMime || (isOctet && isPdfExt)) {
            return cb(null, true);
          }

          return cb(
            new BadRequestException('Only PDF files are allowed for KYC documents!'),
            false,
          );
        } catch (err: any) {
          return cb(new BadRequestException(err?.message || 'Invalid document format.'), false);
        }
      },
      limits: { fileSize: 35 * 1024 * 1024 }, // 35MB
    }),
  )
  async uploadDocument(@UploadedFile() file: Express.Multer.File, @Req() req: Request) {
    if (!file) {
      throw new BadRequestException('No PDF document file received.');
    }
    const host = req.get('host') || 'localhost:3000';
    const protoHeader = req.headers['x-forwarded-proto'];
    const protocol = protoHeader
      ? String(protoHeader).split(',')[0].trim()
      : host.includes('localhost')
        ? 'http'
        : 'https';

    let fileUrl = `${protocol}://${host}/uploads/documents/${file.filename}`;

    const filePath = file.path;
    let fileBuffer: Buffer | null = null;
    if (filePath && existsSync(filePath)) {
      try {
        fileBuffer = readFileSync(filePath);
      } catch (err) {
        console.error('[UPLOAD] Error reading saved document file:', err);
      }
    }

    // 1. Upload to Cloudinary if available
    if (hasCloudinary && fileBuffer) {
      try {
        const cloudUrl = await uploadToCloudinary(fileBuffer, 'games24/documents', 'raw');
        fileUrl = cloudUrl;
        console.log(`[UPLOAD] ☁️ PDF document uploaded to Cloudinary: ${cloudUrl}`);
      } catch (cErr: any) {
        console.error('[UPLOAD] Cloudinary document upload failed, falling back to database/local:', cErr?.message || cErr);
      }
    }

    // 2. Persist to Neon PostgreSQL Database
    if (fileBuffer) {
      try {
        await (this.prisma as any).uploadedFile.upsert({
          where: { filename: file.filename },
          update: {
            originalName: file.originalname || 'kyc.pdf',
            mimetype: 'application/pdf',
            size: file.size,
            data: fileBuffer,
          },
          create: {
            filename: file.filename,
            originalName: file.originalname || 'kyc.pdf',
            mimetype: 'application/pdf',
            size: file.size,
            data: fileBuffer,
          },
        });
        console.log(`[UPLOAD] 💾 Saved document ${file.filename} to Neon DB persistent storage`);
      } catch (dbErr: any) {
        console.error('[UPLOAD] Failed to save document to DB storage:', dbErr?.message || dbErr);
      }
    }

    console.log(`[UPLOAD] 📄 KYC document saved: ${file.filename} (${file.size} bytes) -> ${fileUrl}`);
    return {
      success: true,
      url: fileUrl,
      filename: file.filename,
      originalName: file.originalname,
      size: file.size,
      mimetype: file.mimetype,
    };
  }
}

@Controller('uploads')
export class UploadsServeController {
  constructor(private readonly prisma: PrismaService) {}

  @Get('photos/:filename')
  async getPhoto(@Param('filename') filename: string, @Res() res: Response) {
    return this.serveUploadedFile('photos', filename, res);
  }

  @Get('documents/:filename')
  async getDocument(@Param('filename') filename: string, @Res() res: Response) {
    return this.serveUploadedFile('documents', filename, res);
  }

  @Get(':folder/:filename')
  async getGeneric(
    @Param('folder') folder: string,
    @Param('filename') filename: string,
    @Res() res: Response,
  ) {
    return this.serveUploadedFile(folder, filename, res);
  }

  private async serveUploadedFile(folder: string, filename: string, res: Response) {
    const safeFilename = filename.replace(/(\.\.[\/\\])/g, '');
    const localPath = join(uploadsBaseDir, folder, safeFilename);

    if (existsSync(localPath)) {
      return res.sendFile(localPath);
    }

    // If not found on local disk (e.g. Render restarted / redeployed), fetch from Neon PostgreSQL DB!
    try {
      const record = await (this.prisma as any).uploadedFile.findUnique({
        where: { filename: safeFilename },
      });

      if (record && record.data) {
        // Cache back to local disk
        try {
          const targetDir = join(uploadsBaseDir, folder);
          if (!existsSync(targetDir)) mkdirSync(targetDir, { recursive: true });
          writeFileSync(localPath, record.data);
        } catch (_) {}

        const mime = record.mimetype || (folder === 'photos' ? 'image/jpeg' : 'application/pdf');
        res.setHeader('Content-Type', mime);
        res.setHeader('Content-Disposition', `inline; filename="${record.originalName || safeFilename}"`);
        res.setHeader('Cache-Control', 'public, max-age=86400');
        return res.send(record.data);
      }
    } catch (dbErr) {
      console.error(`[UPLOADS SERVE] Error fetching ${safeFilename} from DB:`, dbErr);
    }

    return res.status(404).json({
      statusCode: 404,
      message: `File ${safeFilename} not found.`,
    });
  }
}
