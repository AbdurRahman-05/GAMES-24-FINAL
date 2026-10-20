import {
  Controller,
  Post,
  UploadedFile,
  UseInterceptors,
  BadRequestException,
  Req,
} from '@nestjs/common';
import { FileInterceptor } from '@nestjs/platform-express';
import { diskStorage } from 'multer';
import { extname, join } from 'path';
import { existsSync, mkdirSync } from 'fs';
import type { Request } from 'express';

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

@Controller('upload')
export class UploadController {
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

          // Reject executables or scripts
          const dangerousExtensions = ['.exe', '.bat', '.sh', '.cmd', '.js', '.ts', '.html', '.htm', '.php'];
          if (dangerousExtensions.includes(ext)) {
            return cb(new BadRequestException('Executable or script files are not allowed.'), false);
          }

          // Allow any image mimetype or extension or octet-stream/binary
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
  uploadPhoto(@UploadedFile() file: Express.Multer.File, @Req() req: Request) {
    if (!file) {
      throw new BadRequestException('No photo file received. Please choose an image.');
    }
    const host = req.get('host') || 'localhost:3000';
    const protocol = req.protocol || 'http';
    const fileUrl = `${protocol}://${host}/uploads/photos/${file.filename}`;
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
  uploadDocument(@UploadedFile() file: Express.Multer.File, @Req() req: Request) {
    if (!file) {
      throw new BadRequestException('No PDF document file received.');
    }
    const host = req.get('host') || 'localhost:3000';
    const protocol = req.protocol || 'http';
    const fileUrl = `${protocol}://${host}/uploads/documents/${file.filename}`;
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
