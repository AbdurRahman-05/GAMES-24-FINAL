import { Controller, Post, Get, Body, Param, Headers } from '@nestjs/common';
import { CashfreeService } from './cashfree.service.js';

@Controller('cashfree')
export class CashfreeController {
  constructor(private readonly cashfreeService: CashfreeService) {}

  @Get('status')
  getStatus() {
    return this.cashfreeService.getGatewayStatus();
  }

  @Post('create-order')
  createOrder(
    @Body()
    body: {
      orderAmount: number;
      customerPhone: string;
      customerName: string;
      customerEmail?: string;
      turfId?: number;
      bookingPayload?: any;
    },
  ) {
    return this.cashfreeService.createPaymentOrder(body);
  }

  @Post('verify-payment')
  verifyPayment(@Body() body: { orderId: string }) {
    return this.cashfreeService.verifyOrderPayment(body.orderId);
  }

  @Get('order/:orderId')
  getOrder(@Param('orderId') orderId: string) {
    return this.cashfreeService.getOrderStatus(orderId);
  }

  @Post('webhook')
  handleWebhook(
    @Body() body: any,
    @Headers('x-webhook-signature') signature?: string,
    @Headers('x-webhook-timestamp') timestamp?: string,
  ) {
    return this.cashfreeService.handleWebhook(body, signature, timestamp);
  }
}
