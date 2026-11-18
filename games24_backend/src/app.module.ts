import { Module } from '@nestjs/common';
import { AppController } from './app.controller.js';
import { AppService } from './app.service.js';
import { AuthController } from './auth.controller.js';
import { AuthService } from './auth.service.js';
import { UploadController, UploadsServeController } from './upload.controller.js';
import { PrismaService } from './prisma.service.js';

import { SuperAdminController } from './super-admin.controller.js';
import { SuperAdminService } from './super-admin.service.js';
import { TurfController } from './turf.controller.js';
import { TurfService } from './turf.service.js';
import { CashfreeController } from './cashfree.controller.js';
import { CashfreeService } from './cashfree.service.js';

@Module({
  imports: [],
  controllers: [
    AppController,
    AuthController,
    UploadController,
    UploadsServeController,
    SuperAdminController,
    TurfController,
    CashfreeController,
  ],
  providers: [
    AppService,
    AuthService,
    PrismaService,
    SuperAdminService,
    TurfService,
    CashfreeService,
  ],
})
export class AppModule {}

