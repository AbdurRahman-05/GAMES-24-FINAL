import {
  Controller,
  Get,
  Post,
  Param,
  Query,
  Body,
  ParseIntPipe,
} from '@nestjs/common';
import { TurfService } from './turf.service.js';

@Controller('turfs')
export class TurfController {
  constructor(private readonly turfService: TurfService) {}

  @Get()
  async getAllTurfs() {
    return this.turfService.getAllTurfs();
  }

  @Get('user-bookings')
  async getUserBookings(
    @Query('phone') phone?: string,
    @Query('name') name?: string,
  ) {
    return this.turfService.getUserBookings(phone, name);
  }

  @Post('bookings/:bookingId/cancel')
  async cancelBooking(
    @Param('bookingId', ParseIntPipe) bookingId: number,
  ) {
    return this.turfService.cancelBooking(bookingId);
  }

  @Get(':id')
  async getTurfById(@Param('id', ParseIntPipe) id: number) {
    return this.turfService.getTurfById(id);
  }

  @Get(':id/slots')
  async getTurfSlots(
    @Param('id', ParseIntPipe) id: number,
    @Query('date') date?: string,
    @Query('role') role?: string,
  ) {
    return this.turfService.getTurfSlots(id, date, role);
  }

  @Post(':id/book')
  async bookSlot(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: any,
  ) {
    return this.turfService.bookSlot(id, body);
  }

  @Post(':id/toggle-block')
  async toggleBlockSlot(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: any,
  ) {
    return this.turfService.toggleBlockSlot(id, body);
  }

  @Post(':id/slot-offer')
  async setSlotOffer(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: any,
  ) {
    return this.turfService.setSlotOffer(id, body);
  }

  @Get(':id/subscription')
  async getTurfSubscription(@Param('id', ParseIntPipe) id: number) {
    return this.turfService.getTurfSubscription(id);
  }

  @Post(':id/pay-subscription')
  async payTurfSubscription(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: any,
  ) {
    return this.turfService.payTurfSubscription(id, body);
  }

  @Post(':id/toggle-subscription')
  async toggleTurfSubscription(@Param('id', ParseIntPipe) id: number) {
    return this.turfService.toggleTurfSubscription(id);
  }
}
