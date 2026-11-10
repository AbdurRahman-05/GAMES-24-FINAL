import {
  Controller,
  Get,
  Post,
  Patch,
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

  @Get('open-matches')
  async getOpenMatches(
    @Query('location') location?: string,
    @Query('sport') sport?: string,
  ) {
    return this.turfService.getOpenMatches(location, sport);
  }

  @Post('open-matches')
  async createOpenMatch(@Body() body: any) {
    return this.turfService.createOpenMatch(body);
  }

  @Post('open-matches/:id/join')
  async joinOpenMatch(
    @Param('id') id: string,
    @Body() body: any,
  ) {
    return this.turfService.joinOpenMatch(id, body);
  }

  @Post('open-matches/:id/accept')
  async acceptOpenMatch(
    @Param('id') id: string,
    @Body() body: any,
  ) {
    return this.turfService.acceptOpenMatch(id, body);
  }

  @Post('bookings/:bookingId/cancel')
  async cancelBooking(
    @Param('bookingId', ParseIntPipe) bookingId: number,
  ) {
    return this.turfService.cancelBooking(bookingId);
  }

  @Post('check-in')
  async checkInGlobal(
    @Body() body: any,
    @Query('adminId') adminIdQuery?: string,
  ) {
    const adminId = adminIdQuery ? parseInt(adminIdQuery, 10) : undefined;
    return this.turfService.checkInBooking(isNaN(adminId as any) ? undefined : adminId, body);
  }

  @Post(':id/check-in')
  async checkInBooking(
    @Param('id') id: string,
    @Body() body: any,
  ) {
    const adminId = parseInt(id, 10);
    return this.turfService.checkInBooking(isNaN(adminId) ? undefined : adminId, body);
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
    @Query('sport') sport?: string,
  ) {
    return this.turfService.getTurfSlots(id, date, role, sport);
  }

  @Get(':id/sports')
  async getTurfSports(@Param('id', ParseIntPipe) id: number) {
    return this.turfService.getTurfSports(id);
  }

  @Post(':id/sports')
  async saveTurfSportsPost(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: any,
  ) {
    return this.turfService.saveTurfSports(id, body);
  }

  @Patch(':id/sports')
  async saveTurfSportsPatch(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: any,
  ) {
    return this.turfService.saveTurfSports(id, body);
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
