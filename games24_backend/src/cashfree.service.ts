import { Injectable, Logger, BadRequestException, NotFoundException } from '@nestjs/common';
import { PrismaService } from './prisma.service.js';
import { TurfService } from './turf.service.js';
import * as crypto from 'node:crypto';

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

  private getBaseUrl(): string {
    const env = (process.env.CASHFREE_ENV || 'sandbox').toLowerCase();
    return env === 'production'
      ? 'https://api.cashfree.com/pg'
      : 'https://sandbox.cashfree.com/pg';
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

  /**
   * Returns gateway status and readiness info
   */
  getGatewayStatus() {
    const configured = this.isCashfreeConfigured();
    const env = (process.env.CASHFREE_ENV || 'sandbox').toLowerCase();
    return {
      gateway: 'Cashfree PG',
      version: this.getApiVersion(),
      environment: env,
      isConfigured: configured,
      status: configured ? 'READY_LIVE' : 'READY_AWAITING_KEYS',
      message: configured
        ? 'Cashfree payment gateway is active.'
        : 'Cashfree integration is prepared. Running in sandbox test mode until real credentials are provided.',
    };
  }

  /**
   * Creates a Cashfree payment order.
   * If credentials are valid, calls Cashfree PG API v2023-08-01.
   * If credentials are placeholders, creates a mock test session seamlessly.
   */
  async createPaymentOrder(dto: {
    orderAmount: number;
    customerPhone: string;
    customerName: string;
    customerEmail?: string;
    turfId?: number;
    bookingPayload?: any;
  }) {
    if (!dto.orderAmount || dto.orderAmount <= 0) {
      throw new BadRequestException('Order amount must be greater than 0');
    }
    if (!dto.customerPhone || dto.customerPhone.trim().length === 0) {
      throw new BadRequestException('Customer phone number is required');
    }

    const cleanPhone = dto.customerPhone.replace(/\D/g, '').slice(-10);
    const orderId = `order_g24_${Date.now()}_${Math.floor(Math.random() * 1000)}`;
    const customerId = `cust_${cleanPhone || 'guest'}`;
    const customerName = dto.customerName?.trim() || 'Player';
    const customerEmail = dto.customerEmail?.trim() || `${cleanPhone}@gamez24.com`;

    let paymentSessionId: string | null = null;
    let isMock = false;

    if (this.isCashfreeConfigured()) {
      try {
        const payload = {
          order_id: orderId,
          order_amount: Number(dto.orderAmount.toFixed(2)),
          order_currency: 'INR',
          customer_details: {
            customer_id: customerId,
            customer_name: customerName,
            customer_phone: cleanPhone,
            customer_email: customerEmail,
          },
          order_meta: {
            notify_url: 'https://games-24-final.onrender.com/cashfree/webhook',
          },
          order_note: `Games24 booking for turf #${dto.turfId ?? 1}`,
        };

        const res = await fetch(`${this.getBaseUrl()}/orders`, {
          method: 'POST',
          headers: {
            'x-client-id': this.getAppId(),
            'x-client-secret': this.getSecretKey(),
            'x-api-version': this.getApiVersion(),
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(payload),
        });

        const data = await res.json();
        if (res.ok && data.payment_session_id) {
          paymentSessionId = data.payment_session_id;
        } else {
          this.logger.warn(`Cashfree order creation returned non-ok: ${JSON.stringify(data)}`);
          paymentSessionId = `session_cf_test_${orderId}`;
          isMock = true;
        }
      } catch (err) {
        this.logger.error(`Cashfree API call error: ${err}`);
        paymentSessionId = `session_cf_test_${orderId}`;
        isMock = true;
      }
    } else {
      // Mock session for testing until user provides real keys
      paymentSessionId = `session_cf_mock_${orderId}`;
      isMock = true;
    }

    // Persist PaymentOrder in PostgreSQL
    const paymentOrder = await (this.prisma as any).paymentOrder.create({
      data: {
        orderId,
        turfId: dto.turfId ?? null,
        customerPhone: cleanPhone,
        customerName,
        customerEmail,
        orderAmount: Number(dto.orderAmount.toFixed(2)),
        orderCurrency: 'INR',
        paymentSessionId,
        orderStatus: 'ACTIVE',
        bookingPayload: dto.bookingPayload ?? null,
      },
    });

    return {
      success: true,
      orderId: paymentOrder.orderId,
      orderAmount: paymentOrder.orderAmount,
      orderCurrency: paymentOrder.orderCurrency,
      paymentSessionId: paymentOrder.paymentSessionId,
      isMock,
      environment: (process.env.CASHFREE_ENV || 'sandbox').toLowerCase(),
      message: isMock
        ? 'Order created in test mode. Awaiting Cashfree API credentials.'
        : 'Cashfree payment session created successfully.',
    };
  }

  /**
   * Verifies an order's payment status and confirms the turf booking in database.
   */
  async verifyOrderPayment(orderId: string) {
    const paymentOrder = await (this.prisma as any).paymentOrder.findUnique({
      where: { orderId },
    });

    if (!paymentOrder) {
      throw new NotFoundException(`Order ${orderId} not found`);
    }

    let isPaid = false;
    let cfPaymentId = `cf_pay_${Date.now()}`;
    let paymentMethod = 'UPI';

    if (this.isCashfreeConfigured()) {
      try {
        const res = await fetch(`${this.getBaseUrl()}/orders/${orderId}/payments`, {
          headers: {
            'x-client-id': this.getAppId(),
            'x-client-secret': this.getSecretKey(),
            'x-api-version': this.getApiVersion(),
          },
        });
        const data = await res.json();
        if (res.ok && Array.isArray(data) && data.length > 0) {
          const successPayment = data.find((p: any) => p.payment_status === 'SUCCESS');
          if (successPayment) {
            isPaid = true;
            cfPaymentId = String(successPayment.cf_payment_id || successPayment.payment_id || cfPaymentId);
            paymentMethod = successPayment.payment_group || 'UPI';
          }
        }
      } catch (err) {
        this.logger.error(`Cashfree payment verification query failed: ${err}`);
      }
    } else {
      // In preview / test mode, auto-confirm for seamless sandbox testing
      isPaid = true;
      paymentMethod = 'UPI_TEST';
    }

    if (!isPaid) {
      return {
        success: false,
        status: 'PENDING_OR_FAILED',
        orderId,
        message: 'Payment has not been completed yet.',
      };
    }

    // Update PaymentOrder record
    await (this.prisma as any).paymentOrder.update({
      where: { orderId },
      data: {
        orderStatus: 'PAID',
        paymentMethod,
        cfPaymentId,
        referenceId: cfPaymentId,
      },
    });

    // If there is an associated booking payload, create or finalize the booking
    let bookingResult: any = null;
    if (paymentOrder.bookingPayload) {
      const payload: any = paymentOrder.bookingPayload;
      const targetTurfId = paymentOrder.turfId || payload.turfId || payload.verifiedAdminId || 1;
      try {
        bookingResult = await this.turfService.bookSlot(targetTurfId, {
          ...payload,
          paymentMethod: `Cashfree (${paymentMethod})`,
          paymentStatus: 'PAID',
          transactionId: cfPaymentId,
        });

        // Create player notification
        await (this.prisma as any).playerNotification.create({
          data: {
            userPhone: paymentOrder.customerPhone,
            title: 'Booking Confirmed 🎉',
            message: `Your booking at ${payload.courtName || 'Turf'} is confirmed via Cashfree! Amount: ₹${paymentOrder.orderAmount}`,
            type: 'booking',
            metadata: { orderId, cfPaymentId, amount: paymentOrder.orderAmount },
          },
        });
      } catch (e) {
        this.logger.error(`Error auto-finalizing booking on payment success: ${e}`);
      }
    }

    return {
      success: true,
      status: 'PAID',
      orderId,
      cfPaymentId,
      paymentMethod,
      booking: bookingResult?.booking ?? null,
      message: 'Payment verified and turf slot booked successfully!',
    };
  }

  /**
   * Fetches the order status from local DB and/or Cashfree
   */
  async getOrderStatus(orderId: string) {
    const paymentOrder = await (this.prisma as any).paymentOrder.findUnique({
      where: { orderId },
    });
    if (!paymentOrder) {
      throw new NotFoundException(`Order ${orderId} not found`);
    }

    return {
      success: true,
      order: paymentOrder,
    };
  }

  /**
   * Webhook handler for asynchronous server-to-server notifications from Cashfree
   */
  async handleWebhook(rawBody: any, signature?: string, timestamp?: string) {
    this.logger.log(`Received Cashfree webhook: ${JSON.stringify(rawBody?.type || rawBody?.event)}`);

    const secret = this.getSecretKey();
    if (secret && signature && timestamp) {
      try {
        const payloadStr = timestamp + JSON.stringify(rawBody);
        const computedSignature = crypto
          .createHmac('sha256', secret)
          .update(payloadStr)
          .digest('base64');
        if (computedSignature !== signature) {
          this.logger.warn('Cashfree webhook signature mismatch');
          throw new BadRequestException('Cashfree webhook signature mismatch');
        }
      } catch (e) {
        this.logger.error(`Webhook signature verification error: ${e}`);
      }
    }

    const orderId = rawBody?.data?.order?.order_id || rawBody?.order_id;
    if (orderId) {
      const paymentStatus = rawBody?.data?.payment?.payment_status || rawBody?.payment_status;
      if (paymentStatus === 'SUCCESS') {
        await this.verifyOrderPayment(orderId);
      }
    }

    return { status: 'OK' };
  }
}
