import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);

  constructor() {
    super({
      log: ['error', 'warn'],
    });

    this.$use(async (params, next) => {
      let attempts = 0;
      const maxAttempts = 3;

      while (attempts < maxAttempts) {
        try {
          return await next(params);
        } catch (error: any) {
          attempts++;
          const errorMessage = error?.message || '';
          const errorCode = error?.code || '';

          const isConnectionError =
            errorCode === 'P1001' ||
            errorCode === 'P1017' ||
            errorCode === 'P2024' ||
            errorMessage.includes("Can't reach database server") ||
            errorMessage.includes('Connection terminated') ||
            errorMessage.includes('closed unexpectedly') ||
            errorMessage.includes('Connection pool timeout') ||
            errorMessage.includes('connection refused') ||
            errorMessage.includes('timeout');

          if (isConnectionError && attempts < maxAttempts) {
            const delay = attempts * 1000;
            this.logger.warn(
              `Database connection drop or waking up (${errorCode || 'P1001'}). Retrying in ${delay}ms (attempt ${attempts}/${maxAttempts})...`,
            );
            await new Promise((res) => setTimeout(res, delay));
            try {
              await this.$connect();
            } catch (_) {}
            continue;
          }

          throw error;
        }
      }
    });
  }

  async onModuleInit() {
    try {
      await this.$connect();
      this.logger.log('Successfully connected to Neon database.');
      // Enforce unique active booking partial index in PostgreSQL to prevent double-booking
      await this.$executeRawUnsafe(`
        CREATE UNIQUE INDEX IF NOT EXISTS unique_active_turf_booking 
        ON "TurfBooking" ("verifiedAdminId", "date", "timeSlot") 
        WHERE "status" != 'Cancelled';
      `).catch((e) => this.logger.warn(`Could not verify unique booking index: ${e?.message || e}`));
    } catch (error: any) {
      this.logger.warn(`Initial database connection delayed: ${error?.message || error}. Will retry on queries.`);
    }
  }

  async onModuleDestroy() {
    await this.$disconnect();
  }
}
