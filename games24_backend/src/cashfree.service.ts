import {
  Injectable,
  Logger,
  BadRequestException,
  NotFoundException,
  ServiceUnavailableException,
  UnauthorizedException,
} from '@nestjs/common';
import { PrismaService } from './prisma.service.js';
import { TurfService, HOLD_MINUTES } from './turf.service.js';
import * as crypto from 'node:crypto';

/**
 * Payment flow for player bookings:
 *   1. create-order  -> slots are HELD (status "Pending Payment") and priced on the server
 *   2. player pays in the Cashfree checkout (SDK) using the returned payment_session_id
 *   3. verify-payment / webhook -> Cashfree is queried; only a PAID order for the exact amount
 *      confirms the held booking. If the slot was lost meanwhile, the payment is refunded.
 *   4. cancel-order  -> player closed the checkout: the hold is released immediately.
 */
@Injectable()
export class CashfreeService {
  private readonly logger = new Logger(CashfreeService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly turfService: TurfService,
  ) {}

  private getAppId(): string {
    return process.env.CASHFREE_APP_ID || '';
  }

  private getSecretKey(): string {
    return process.env.CASHFREE_SECRET_KEY || '';
  }

  private getApiVersion(): string {
    return process.env.CASHFREE_API_VERSION || '2023-08-01';
  }

  private getEnv(): 'production' | 'sandbox' {
    return (process.env.CASHFREE_ENV || 'sandbox').toLowerCase() === 'production' ? 'production' : 'sandbox';
  }

  private getBaseUrl(): string {
    return this.getEnv() === 'production' ? 'https://api.cashfree.com/pg' : 'https://sandbox.cashfree.com/pg';
  }

  private getNotifyUrl(): string {
    const base = (process.env.PUBLIC_BASE_URL || process.env.BASE_URL || 'https://games-24-final.onrender.com').replace(/\/+$/, '');
    return `${base}/cashfree/webhook`;
  }

  private headers(json = false): Record<string, string> {
    return {
      'x-client-id': this.getAppId(),
      'x-client-secret': this.getSecretKey(),
      'x-api-version': this.getApiVersion(),
      ...(json ? { 'Content-Type': 'application/json' } : {}),
    };
  }

  public isCashfreeConfigured(): boolean {
    const appId = this.getAppId().trim();
    const secret = this.getSecretKey().trim();
    return (
      appId.length > 5 &&
      secret.length > 5 &&
      !appId.includes('your_cashfree_') &&
      !secret.includes('your_cashfree_')
    );
  }

  /** Test-mode payments (no real money) are only allowed outside production. */
  private isMockAllowed(): boolean {
    return process.env.NODE_ENV !== 'production' || process.env.CASHFREE_ALLOW_MOCK === 'true';
  }

  private isMockOrder(order: { paymentSessionId?: string | null }): boolean {
    return String(order?.paymentSessionId || '').startsWith('session_cf_mock_');
  }

  getGatewayStatus() {
    const configured = this.isCashfreeConfigured();
    return {
      gateway: 'Cashfree PG',
      version: this.getApiVersion(),
      environment: this.getEnv(),
      isConfigured: configured,
      testModeAllowed: !configured && this.isMockAllowed(),
      holdMinutes: HOLD_MINUTES,
      status: configured ? 'READY_LIVE' : this.isMockAllowed() ? 'TEST_MODE' : 'UNAVAILABLE',
      message: configured
        ? 'Cashfree payment gateway is active.'
        : this.isMockAllowed()
          ? 'Cashfree keys are not configured: running in TEST MODE (no real money is charged).'
          : 'Online payments are not configured.',
    };
  }

  private formatBooking(b: any, turfName?: string) {
    if (!b) return null;
    const code = b.bookingCode || `G24-BK-${String(b.id).padStart(4, '0')}`;
    return {
      ...b,
      bookingId: code,
      bookingCode: code,
      turfId: b.verifiedAdminId,
      turfName: turfName || b.verifiedAdmin?.venueName || b.courtName,
    };
  }

  /**
   * Holds the requested slots and creates a Cashfree order for the SERVER-computed amount.
   * Any client-sent amount is ignored.
   */
  async createPaymentOrder(dto: any) {
    const payload = dto?.bookingPayload && typeof dto.bookingPayload === 'object' ? dto.bookingPayload : {};
    const turfId = Number(dto?.turfId ?? payload.turfId ?? payload.verifiedAdminId);
    if (!turfId || isNaN(turfId)) {
      throw new BadRequestException('turfId is required to create a payment order');
    }

    const configured = this.isCashfreeConfigured();
    if (!configured && !this.isMockAllowed()) {
      throw new ServiceUnavailableException('Online payments are not available right now. Please try again later.');
    }

    const bookingRequest = {
      ...payload,
      date: dto?.date ?? payload.date,
      timeSlots: dto?.timeSlots ?? payload.timeSlots,
      timeSlot: dto?.timeSlot ?? payload.timeSlot,
      sport: dto?.sport ?? payload.sport,
      courtName: dto?.courtName ?? payload.courtName,
      customerName: dto?.customerName ?? payload.customerName,
      customerPhone: dto?.customerPhone ?? payload.customerPhone,
      isOpenMatch: (dto?.isOpenMatch ?? payload.isOpenMatch) === true,
      teamName: dto?.teamName ?? payload.teamName,
      teamSize: dto?.teamSize ?? payload.teamSize,
    };

    // 1. Hold the slots (throws 409 if taken) and get the authoritative price.
    const hold = await this.turfService.createPaymentHold(turfId, bookingRequest);
    const amount = Number(Number(hold.amount).toFixed(2));
    if (!(amount > 0)) {
      await this.turfService.releasePaymentHold(hold.id);
      throw new BadRequestException('Could not price this booking. Please contact the venue.');
    }

    const cleanPhone = String(bookingRequest.customerPhone || '').replace(/\D/g, '').slice(-10);
    const orderId = `order_g24_${hold.id}_${Date.now()}`;
    const customerName = String(bookingRequest.customerName || '').trim() || 'Player';
    const customerEmail = String(dto?.customerEmail || '').trim() || `${cleanPhone}@gamez24.com`;

    let paymentSessionId: string;
    let isMock = false;

    if (configured) {
      try {
        // Order expires shortly after the slot hold, so a stale checkout cannot be paid much later.
        const expiry = new Date(Date.now() + (HOLD_MINUTES + 15) * 60 * 1000).toISOString();
        const res = await fetch(`${this.getBaseUrl()}/orders`, {
          method: 'POST',
          headers: this.headers(true),
          body: JSON.stringify({
            order_id: orderId,
            order_amount: amount,
            order_currency: 'INR',
            customer_details: {
              customer_id: `cust_${cleanPhone}`,
              customer_name: customerName,
              customer_phone: cleanPhone,
              customer_email: customerEmail,
            },
            order_meta: { notify_url: this.getNotifyUrl() },
            order_expiry_time: expiry,
            order_note: `Games24 booking ${hold.bookingCode} at turf #${turfId}`,
          }),
        });
        const data: any = await res.json().catch(() => ({}));
        if (!res.ok || !data?.payment_session_id) {
          throw new Error(`Cashfree order creation failed: ${JSON.stringify(data)}`);
        }
        paymentSessionId = data.payment_session_id;
      } catch (err) {
        this.logger.error(String(err));
        await this.turfService.releasePaymentHold(hold.id);
        throw new ServiceUnavailableException('Could not start the payment. Please try again.');
      }
    } else {
      paymentSessionId = `session_cf_mock_${orderId}`;
      isMock = true;
    }

    await this.prisma.paymentOrder.create({
      data: {
        orderId,
        turfId,
        bookingId: hold.id,
        customerPhone: cleanPhone,
        customerName,
        customerEmail,
        orderAmount: amount,
        orderCurrency: 'INR',
        paymentSessionId,
        orderStatus: 'ACTIVE',
        bookingPayload: {
          date: bookingRequest.date,
          timeSlot: hold.timeSlot,
          sport: bookingRequest.sport,
          courtName: hold.courtName,
          isOpenMatch: bookingRequest.isOpenMatch,
        },
      },
    });

    return {
      success: true,
      orderId,
      orderAmount: amount,
      orderCurrency: 'INR',
      paymentSessionId,
      isMock,
      environment: this.getEnv(),
      bookingId: hold.id,
      bookingCode: hold.bookingCode,
      holdExpiresAt: hold.holdExpiresAt,
      priceBreakdown: hold.priceBreakdown,
      message: isMock
        ? 'TEST MODE: no real money will be charged.'
        : 'Cashfree payment session created successfully.',
    };
  }

  /** Asks Cashfree whether the order is paid for the exact amount we expect. */
  private async fetchCashfreePaymentState(order: any): Promise<{
    paid: boolean;
    terminal: boolean;
    cfPaymentId?: string;
    method?: string;
  }> {
    const res = await fetch(`${this.getBaseUrl()}/orders/${encodeURIComponent(order.orderId)}`, {
      headers: this.headers(),
    });
    const data: any = await res.json().catch(() => ({}));
    if (!res.ok) {
      this.logger.warn(`Cashfree order lookup failed for ${order.orderId}: ${JSON.stringify(data)}`);
      return { paid: false, terminal: false };
    }
    const status = String(data?.order_status || '').toUpperCase();
    const amountMatches = Math.abs(Number(data?.order_amount) - Number(order.orderAmount)) < 0.01;
    if (status !== 'PAID') {
      return { paid: false, terminal: status === 'EXPIRED' || status === 'TERMINATED' };
    }
    if (!amountMatches || String(data?.order_currency || 'INR') !== 'INR') {
      this.logger.error(`Amount mismatch for ${order.orderId}: cashfree=${data?.order_amount} expected=${order.orderAmount}`);
      return { paid: false, terminal: false };
    }

    let cfPaymentId: string | undefined;
    let method: string | undefined;
    try {
      const pr = await fetch(`${this.getBaseUrl()}/orders/${encodeURIComponent(order.orderId)}/payments`, {
        headers: this.headers(),
      });
      const payments: any = await pr.json().catch(() => []);
      const ok = Array.isArray(payments) ? payments.find((p: any) => p.payment_status === 'SUCCESS') : null;
      if (ok) {
        cfPaymentId = String(ok.cf_payment_id || '');
        method = ok.payment_group || undefined;
      }
    } catch {
      // payment details are informational only
    }
    return { paid: true, terminal: false, cfPaymentId, method };
  }

  /**
   * Verifies payment and confirms the held booking. Safe to call repeatedly and concurrently
   * (app + webhook): only one caller can move the order from ACTIVE to PROCESSING.
   */
  async verifyOrderPayment(orderId: string) {
    if (!orderId) throw new BadRequestException('orderId is required');
    const order = await this.prisma.paymentOrder.findUnique({ where: { orderId } });
    if (!order) {
      throw new NotFoundException(`Order ${orderId} not found`);
    }

    const finished = await this.describeFinishedOrder(order);
    if (finished) return finished;

    let paid = false;
    let cfPaymentId = '';
    let method = 'UPI';

    if (this.isMockOrder(order)) {
      if (!this.isMockAllowed()) {
        return { success: false, status: 'FAILED', orderId, message: 'Test payments are disabled.' };
      }
      paid = true;
      cfPaymentId = `test_${Date.now()}`;
      method = 'TEST MODE';
    } else if (this.isCashfreeConfigured()) {
      const state = await this.fetchCashfreePaymentState(order);
      if (state.terminal) {
        await this.prisma.paymentOrder.updateMany({
          where: { orderId, orderStatus: 'ACTIVE' },
          data: { orderStatus: 'EXPIRED' },
        });
        if (order.bookingId) await this.turfService.releasePaymentHold(order.bookingId);
        return { success: false, status: 'EXPIRED', orderId, message: 'This payment session expired. Please book again.' };
      }
      paid = state.paid;
      cfPaymentId = state.cfPaymentId || '';
      method = state.method || 'UPI';
    }

    if (!paid) {
      return {
        success: false,
        status: 'PENDING',
        orderId,
        message: 'Payment has not been completed yet.',
      };
    }

    // Claim the order so the webhook and the app cannot both process it.
    const claim = await this.prisma.paymentOrder.updateMany({
      where: { orderId, orderStatus: 'ACTIVE' },
      data: { orderStatus: 'PROCESSING', paymentMethod: method, cfPaymentId, referenceId: cfPaymentId },
    });
    if (claim.count === 0) {
      const latest = await this.prisma.paymentOrder.findUnique({ where: { orderId } });
      return (
        (await this.describeFinishedOrder(latest)) || {
          success: false,
          status: latest?.orderStatus || 'PROCESSING',
          orderId,
          message: 'Your payment is being processed. Please check My Bookings in a moment.',
        }
      );
    }

    let bookingId = order.bookingId;
    if (!bookingId && order.bookingPayload && order.turfId) {
      // Orders created by older app versions carried only a payload; hold the slots now.
      try {
        const hold = await this.turfService.createPaymentHold(order.turfId, {
          ...(order.bookingPayload as any),
          customerPhone: order.customerPhone,
          customerName: order.customerName,
        });
        bookingId = hold.id;
      } catch (e) {
        this.logger.warn(`Legacy order ${orderId} could not reserve slots: ${String(e)}`);
      }
    }

    const confirmed = bookingId
      ? await this.turfService.confirmPaymentHold(bookingId, `Cashfree (${method})`)
      : null;

    if (!confirmed) {
      // Paid, but the slot is no longer available (hold expired and someone else booked it).
      await this.prisma.paymentOrder.update({
        where: { orderId },
        data: { orderStatus: 'PAID_UNFULFILLED', bookingId },
      });
      const refund = await this.refundOrder(orderId, 'Slot no longer available after payment');
      return {
        success: false,
        status: refund?.initiated ? 'REFUND_INITIATED' : 'PAID_UNFULFILLED',
        orderId,
        refund,
        message: refund?.initiated
          ? 'The slot was taken before your payment completed. A full refund has been initiated.'
          : 'The slot was taken before your payment completed. Our team will refund you shortly.',
      };
    }

    await this.prisma.paymentOrder.update({
      where: { orderId },
      data: { orderStatus: 'PAID', bookingId: confirmed.id },
    });

    await this.prisma.playerNotification
      .create({
        data: {
          userPhone: order.customerPhone,
          title: 'Booking Confirmed 🎉',
          message: `Your booking ${confirmed.bookingCode || ''} on ${confirmed.date} (${confirmed.timeSlot}) is confirmed. Amount paid: ₹${order.orderAmount}`,
          type: 'booking',
          metadata: { orderId, cfPaymentId, amount: order.orderAmount, bookingId: confirmed.id },
        },
      })
      .catch(() => null);

    const full = await this.prisma.turfBooking.findUnique({
      where: { id: confirmed.id },
      include: { verifiedAdmin: { select: { venueName: true, neighborhoodArea: true } } },
    });

    return {
      success: true,
      status: 'PAID',
      orderId,
      cfPaymentId,
      paymentMethod: method,
      isTestPayment: this.isMockOrder(order),
      booking: this.formatBooking(full),
      message: 'Payment verified and turf slot booked successfully!',
    };
  }

  /** Response for orders that already reached a final state (idempotent verify). */
  private async describeFinishedOrder(order: any) {
    if (!order) return null;
    const status = order.orderStatus;
    if (status === 'PAID') {
      const booking = order.bookingId
        ? await this.prisma.turfBooking.findUnique({
            where: { id: order.bookingId },
            include: { verifiedAdmin: { select: { venueName: true, neighborhoodArea: true } } },
          })
        : null;
      return {
        success: true,
        status: 'PAID',
        orderId: order.orderId,
        cfPaymentId: order.cfPaymentId,
        paymentMethod: order.paymentMethod,
        booking: this.formatBooking(booking),
        message: 'Order has already been verified and processed.',
      };
    }
    if (['REFUND_INITIATED', 'REFUNDED', 'PAID_UNFULFILLED'].includes(status)) {
      return {
        success: false,
        status,
        orderId: order.orderId,
        message: 'This payment could not be used for a booking and is being refunded.',
      };
    }
    if (['CANCELLED', 'EXPIRED', 'FAILED'].includes(status)) {
      return { success: false, status, orderId: order.orderId, message: 'This payment session is closed. Please book again.' };
    }
    return null;
  }

  /**
   * Player closed the checkout or the SDK reported an error: release the slot hold now instead
   * of waiting for it to expire. If Cashfree says it was actually paid, confirm instead.
   */
  async cancelPaymentOrder(orderId: string) {
    const order = await this.prisma.paymentOrder.findUnique({ where: { orderId } });
    if (!order) throw new NotFoundException(`Order ${orderId} not found`);
    if (order.orderStatus !== 'ACTIVE') {
      return { success: true, status: order.orderStatus };
    }
    if (!this.isMockOrder(order) && this.isCashfreeConfigured()) {
      const state = await this.fetchCashfreePaymentState(order);
      if (state.paid) {
        return this.verifyOrderPayment(orderId);
      }
    }
    const res = await this.prisma.paymentOrder.updateMany({
      where: { orderId, orderStatus: 'ACTIVE' },
      data: { orderStatus: 'CANCELLED' },
    });
    if (res.count > 0 && order.bookingId) {
      await this.turfService.releasePaymentHold(order.bookingId);
    }
    return { success: true, status: 'CANCELLED', message: 'Payment cancelled and slot released.' };
  }

  /** Full refund of an order (idempotent: Cashfree dedupes on refund_id). */
  async refundOrder(orderId: string, note: string) {
    const order = await this.prisma.paymentOrder.findUnique({ where: { orderId } });
    if (!order) return null;
    if (order.orderStatus === 'REFUND_INITIATED' || order.orderStatus === 'REFUNDED') {
      return { initiated: true, amount: order.orderAmount, refundId: `rf_${orderId}` };
    }

    if (this.isMockOrder(order)) {
      await this.prisma.paymentOrder.update({ where: { orderId }, data: { orderStatus: 'REFUNDED' } });
      return { initiated: true, amount: order.orderAmount, refundId: `rf_${orderId}`, testMode: true };
    }
    if (!this.isCashfreeConfigured()) {
      return { initiated: false, amount: order.orderAmount, message: 'Refund must be processed manually.' };
    }

    try {
      const res = await fetch(`${this.getBaseUrl()}/orders/${encodeURIComponent(orderId)}/refunds`, {
        method: 'POST',
        headers: this.headers(true),
        body: JSON.stringify({
          refund_amount: order.orderAmount,
          refund_id: `rf_${orderId}`.slice(0, 40),
          refund_note: note.slice(0, 100),
        }),
      });
      const data: any = await res.json().catch(() => ({}));
      if (!res.ok) {
        this.logger.error(`Refund failed for ${orderId}: ${JSON.stringify(data)}`);
        return { initiated: false, amount: order.orderAmount, message: 'Refund could not be started automatically. Our team will process it.' };
      }
      await this.prisma.paymentOrder.update({ where: { orderId }, data: { orderStatus: 'REFUND_INITIATED' } });
      return { initiated: true, amount: order.orderAmount, refundId: data?.refund_id || `rf_${orderId}` };
    } catch (e) {
      this.logger.error(`Refund error for ${orderId}: ${String(e)}`);
      return { initiated: false, amount: order.orderAmount, message: 'Refund could not be started automatically. Our team will process it.' };
    }
  }

  /** Refund for a cancelled booking that was paid online (cash/venue bookings return null). */
  async refundForBooking(bookingId: number, note: string) {
    const order = await this.prisma.paymentOrder.findFirst({
      where: { bookingId, orderStatus: 'PAID' },
      orderBy: { createdAt: 'desc' },
    });
    if (!order) return null;
    return this.refundOrder(order.orderId, note);
  }

  async getOrderStatus(orderId: string) {
    const order = await this.prisma.paymentOrder.findUnique({ where: { orderId } });
    if (!order) {
      throw new NotFoundException(`Order ${orderId} not found`);
    }
    // Do not expose customer details; status is enough for the app.
    return {
      success: true,
      orderId,
      status: order.orderStatus,
      orderAmount: order.orderAmount,
      bookingId: order.bookingId,
    };
  }

  /**
   * Cashfree server-to-server notification. The signature is computed over the RAW request body
   * (timestamp + body), so it must be verified before trusting anything in it.
   */
  async handleWebhook(rawBody: Buffer | undefined, body: any, signature?: string, timestamp?: string) {
    if (this.isCashfreeConfigured()) {
      if (!rawBody || !signature || !timestamp) {
        throw new UnauthorizedException('Missing webhook signature');
      }
      const expected = crypto
        .createHmac('sha256', this.getSecretKey())
        .update(timestamp + rawBody.toString('utf8'))
        .digest('base64');
      const a = Buffer.from(expected);
      const b = Buffer.from(signature);
      if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) {
        this.logger.warn('Cashfree webhook signature mismatch');
        throw new UnauthorizedException('Invalid webhook signature');
      }
    } else if (!this.isMockAllowed()) {
      throw new UnauthorizedException('Webhooks are not enabled');
    }

    const orderId = body?.data?.order?.order_id || body?.order_id;
    const paymentStatus = body?.data?.payment?.payment_status || body?.payment_status;
    this.logger.log(`Cashfree webhook ${body?.type || ''} for ${orderId}: ${paymentStatus}`);
    if (orderId && paymentStatus === 'SUCCESS') {
      // verifyOrderPayment re-checks the order with Cashfree before confirming anything.
      await this.verifyOrderPayment(orderId).catch((e) => this.logger.error(`Webhook verify failed: ${String(e)}`));
    }
    return { status: 'OK' };
  }
}
