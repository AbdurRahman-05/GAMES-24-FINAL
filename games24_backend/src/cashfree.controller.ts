import { Controller, Post, Get, Body, Param, Headers, Req } from '@nestjs/common';
import type { RawBodyRequest } from '@nestjs/common';
import type { Request } from 'express';
import { CashfreeService } from './cashfree.service.js';

@Controller('cashfree')
export class CashfreeController {
  constructor(private readonly cashfreeService: CashfreeService) {}

  @Get('status')
  getStatus() {
    return this.cashfreeService.getGatewayStatus();
  }

  /**
   * Body: { turfId, date, timeSlots[], sport, courtName, customerName, customerPhone,
   *         isOpenMatch?, teamName?, teamSize? }
   * The amount is computed on the server; any client "orderAmount" is ignored.
   */
  @Post('create-order')
  createOrder(@Body() body: any) {
    return this.cashfreeService.createPaymentOrder(body);
  }

  @Post('verify-payment')
  verifyPayment(@Body() body: { orderId: string }) {
    return this.cashfreeService.verifyOrderPayment(body?.orderId);
  }

  @Post('cancel-order')
  cancelOrder(@Body() body: { orderId: string }) {
    return this.cashfreeService.cancelPaymentOrder(body?.orderId);
  }

  @Get('order/:orderId')
  getOrder(@Param('orderId') orderId: string) {
    return this.cashfreeService.getOrderStatus(orderId);
  }

  @Post('webhook')
  handleWebhook(
    @Req() req: RawBodyRequest<Request>,
    @Body() body: any,
    @Headers('x-webhook-signature') signature?: string,
    @Headers('x-webhook-timestamp') timestamp?: string,
  ) {
    return this.cashfreeService.handleWebhook(req.rawBody, body, signature, timestamp);
  }
}
