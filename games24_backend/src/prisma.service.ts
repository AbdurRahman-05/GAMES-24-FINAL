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
      return (
        msg.includes('kind: Closed') ||
        msg.includes('Closed, cause: None') ||
        msg.includes('Socket closed') ||
        msg.includes('10054') ||
        msg.includes('ConnectionReset') ||
        msg.includes('forcibly closed') ||
        msg.includes('kind: Io') ||
        msg.includes('ECONNRESET') ||
        msg.includes('Broken pipe') ||
        msg.includes("Can't reach database server") ||
        msg.includes('P1001') ||
        msg.includes('P1017') ||
        msg.includes('P2024') ||
        msg.includes('Connection pool timeout') ||
        msg.includes('Connection terminated') ||
        msg.includes('closed unexpectedly')
      );
    };

    // Intercept Prisma engine logs and filter out harmless idle socket closures / Neon serverless cold starts
    (this as any).$on('error', async (e: any) => {
      const msg = e?.message || (typeof e === 'string' ? e : JSON.stringify(e));
      if (isHarmlessIdleReset(msg)) {
        // Idle connection drop or serverless Neon waking up - cleanly re-establish pool in background
        try {
          await this.$disconnect().catch(() => {});
          await this.$connect().catch(() => {});
        } catch (_) {}
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
            errorMessage.includes('kind: Closed') ||
            errorMessage.includes('Closed') ||
            errorMessage.includes('timeout') ||
            errorMessage.includes('10054') ||
            errorMessage.includes('ConnectionReset') ||
            errorMessage.includes('forcibly closed') ||
            errorMessage.includes('kind: Io') ||
            errorMessage.includes('Broken pipe') ||
            errorMessage.includes('ECONNRESET');

          if (isConnectionError && attempts < maxAttempts) {
            // Neon serverless cold-start wake up typically takes ~1.5 seconds
            const delay = attempts === 1 ? 1200 : attempts * 1000;
            this.logger.warn(
              `Database waking up or reconnecting (${errorCode || 'Neon-ColdStart'}). Resuming in ${delay}ms (attempt ${attempts}/${maxAttempts})...`,
            );
            await new Promise((res) => setTimeout(res, delay));
            try {
              await this.$disconnect().catch(() => {});
              await this.$connect().catch(() => {});
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

      // Start keep-alive ping every 20 seconds to keep Neon compute & socket active
      this.keepAliveTimer = setInterval(async () => {
        try {
          await this.$queryRawUnsafe('SELECT 1');
        } catch (_) {
          try {
            await this.$disconnect().catch(() => {});
            await this.$connect().catch(() => {});
          } catch (_) {}
        }
      }, 20000);
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
