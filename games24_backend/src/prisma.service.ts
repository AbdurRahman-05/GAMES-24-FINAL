import { Injectable, OnModuleInit, OnModuleDestroy, Logger } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);
  private keepAliveTimer: NodeJS.Timeout | null = null;

  constructor() {
    super({
      log: [
        { emit: 'event', level: 'error' },
        { emit: 'event', level: 'warn' },
      ],
    });

    const isHarmlessIdleReset = (msg: string): boolean => {
      const lower = msg.toLowerCase();
      return (
        lower.includes('kind: closed') ||
        lower.includes('closed, cause: none') ||
        lower.includes('socket closed') ||
        lower.includes('10054') ||
        lower.includes('connectionreset') ||
        lower.includes('forcibly closed') ||
        lower.includes('kind: io') ||
        lower.includes('econnreset') ||
        lower.includes('broken pipe') ||
        lower.includes("can't reach database server") ||
        lower.includes('p1001') ||
        lower.includes('p1017') ||
        lower.includes('p2024') ||
        lower.includes('connection pool timeout') ||
        lower.includes('timed out fetching a new connection') ||
        lower.includes('connection terminated') ||
        lower.includes('closed unexpectedly')
      );
    };

    // Intercept Prisma engine logs and filter out harmless idle socket closures / Neon serverless cold starts
    (this as any).$on('error', (e: any) => {
      const msg = e?.message || (typeof e === 'string' ? e : JSON.stringify(e));
      if (isHarmlessIdleReset(msg)) {
        // Harmless idle socket reset or serverless Neon spin-up; safely ignored as retry middleware handles it
        return;
      }
      this.logger.error(`Prisma error: ${msg}`);
    });

    (this as any).$on('warn', (e: any) => {
      const msg = e?.message || (typeof e === 'string' ? e : JSON.stringify(e));
      if (isHarmlessIdleReset(msg)) {
        return;
      }
      this.logger.warn(`Prisma warn: ${msg}`);
    });

    this.$use(async (params, next) => {
      let attempts = 0;
      const maxAttempts = 4;

      while (attempts < maxAttempts) {
        try {
          return await next(params);
        } catch (error: any) {
          attempts++;
          const errorMessage = (error?.message || '').toLowerCase();
          const errorCode = error?.code || '';

          const isConnectionError =
            errorCode === 'P1001' ||
            errorCode === 'P1017' ||
            errorCode === 'P2024' ||
            errorMessage.includes("can't reach database server") ||
            errorMessage.includes('connection terminated') ||
            errorMessage.includes('closed unexpectedly') ||
            errorMessage.includes('connection pool timeout') ||
            errorMessage.includes('timed out fetching a new connection') ||
            errorMessage.includes('connection refused') ||
            errorMessage.includes('kind: closed') ||
            errorMessage.includes('closed') ||
            errorMessage.includes('timeout') ||
            errorMessage.includes('10054') ||
            errorMessage.includes('connectionreset') ||
            errorMessage.includes('forcibly closed') ||
            errorMessage.includes('kind: io') ||
            errorMessage.includes('broken pipe') ||
            errorMessage.includes('econnreset');

          if (isConnectionError && attempts < maxAttempts) {
            // Neon serverless wake-up delay with exponential backoff
            const delay = attempts === 1 ? 800 : attempts * 1000;
            this.logger.warn(
              `Database waking up or reconnecting (${errorCode || 'Neon-ColdStart'}). Resuming in ${delay}ms (attempt ${attempts}/${maxAttempts})...`,
            );
            await new Promise((res) => setTimeout(res, delay));
            // Do NOT call $disconnect() as it destroys the connection pool for all active concurrent queries!
            // Prisma will reuse or open healthy connections on the next attempt automatically.
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

      // Keep-alive ping every 30 seconds to maintain warm connection to Neon
      this.keepAliveTimer = setInterval(async () => {
        try {
          await this.$queryRawUnsafe('SELECT 1');
        } catch (e: any) {
          // If keep-alive ping encounters cold-start or temporary socket stall, log quietly without destroying pool
          this.logger.debug?.(`Keep-alive ping delayed: ${e?.message || e}`);
        }
      }, 30000);
      if (this.keepAliveTimer && typeof (this.keepAliveTimer as any).unref === 'function') {
        (this.keepAliveTimer as any).unref();
      }
    } catch (error: any) {
      this.logger.warn(`Initial database connection delayed: ${error?.message || error}. Will retry on queries.`);
    }
  }

  async onModuleDestroy() {
    if (this.keepAliveTimer) {
      clearInterval(this.keepAliveTimer);
      this.keepAliveTimer = null;
    }
    await this.$disconnect();
  }
}
