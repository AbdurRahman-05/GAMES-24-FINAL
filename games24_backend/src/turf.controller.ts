import {
  Controller,
  Get,
  Post,
  Patch,
  Delete,
  Param,
  Query,
  Body,
  Headers,
  ParseIntPipe,
  UseGuards,
} from '@nestjs/common';
import { TurfService } from './turf.service.js';
import { CashfreeService } from './cashfree.service.js';
import { SuperAdminGuard } from './super-admin.guard.js';

@Controller('turfs')
export class TurfController {
  constructor(
    private readonly turfService: TurfService,
    private readonly cashfreeService: CashfreeService,
  ) {}

  @Get()
  async getAllTurfs() {
    return this.turfService.getAllTurfs();
  }

  @Get('tournaments')
  async getAllTournaments(
    @Query('sport') sport?: string,
    @Query('turfId') turfId?: string,
    @Query('phone') phone?: string,
    @Query('venue') venue?: string,
    @Query('ownerOnly') ownerOnly?: string,
    @Query('viewer') viewer?: string,
  ) {
    return this.turfService.getAllTournaments(sport, turfId, phone, venue, ownerOnly, viewer);
  }

  @Get('tournaments/private/:code')
  async getPrivateTournament(@Param('code') code: string) {
    return this.turfService.getTournamentByAccessCode(code);
  }

  @Post('tournaments')
  async createTournament(@Body() body: any) {
    return this.turfService.createTournament(body);
  }

  @Post('tournaments/:id/register')
  async registerTournament(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: any,
  ) {
    return this.turfService.registerTournament(id, body);
  }

  @Post('tournaments/:id/cancel')
  async cancelTournament(
    @Param('id') id: string,
  ) {
    const numericId = parseInt(id.replace(/\D/g, ''), 10) || parseInt(id, 10);
    return this.turfService.cancelTournament(numericId);
  }

  @Delete('tournaments/:id')
  async deleteTournament(
    @Param('id') id: string,
  ) {
    const numericId = parseInt(id.replace(/\D/g, ''), 10) || parseInt(id, 10);
    return this.turfService.deleteTournament(numericId);
  }

  @Post('tournaments/:id/delete')
  async deleteTournamentPost(
    @Param('id') id: string,
  ) {
    const numericId = parseInt(id.replace(/\D/g, ''), 10) || parseInt(id, 10);
    return this.turfService.deleteTournament(numericId);
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

  @Post('open-matches/:id/reject')
  async rejectOpenMatch(
    @Param('id') id: string,
    @Body() body: any,
  ) {
    return this.turfService.rejectOpenMatchRequest(id, body);
  }

  @Post('bookings/:bookingId/cancel')
  async cancelBooking(
    @Param('bookingId', ParseIntPipe) bookingId: number,
    @Body() body: any,
    @Headers('x-admin-key') adminKey?: string,
  ) {
    const result = await this.turfService.cancelBooking(bookingId, body, adminKey);
    // Cancellation is only allowed 3+ hours before the slot, which qualifies for a full refund.
    const refund = await this.cashfreeService.refundForBooking(bookingId, 'Booking cancelled by player');
    return { ...result, refund };
  }

  @Post('bookings/:bookingId/complete')
  async completeBooking(
    @Param('bookingId', ParseIntPipe) bookingId: number,
  ) {
    return this.turfService.completeBooking(bookingId);
  }

  @Post('bookings/:bookingId/set-opponent')
  async setOpponent(
    @Param('bookingId', ParseIntPipe) bookingId: number,
    @Body() body: any,
  ) {
    return this.turfService.setManualOpponent(bookingId, body);
  }

  @Post('bookings/:bookingId/convert-to-private')
  async convertToPrivate(
    @Param('bookingId', ParseIntPipe) bookingId: number,
  ) {
    return this.turfService.convertBookingToPrivate(bookingId);
  }

  @Post('check-in')
  async checkInGlobal(
    @Body() body: any,
    @Query('adminId') adminIdQuery?: string,
  ) {
    const adminId = adminIdQuery ? parseInt(adminIdQuery, 10) : undefined;
    return this.turfService.checkInBooking(isNaN(adminId as any) ? undefined : adminId, body);
  }

  // Celebrations & Event Bookings
  @Post('celebrations')
  async createCelebration(@Body() body: any) {
    return this.turfService.createCelebrationBooking(body);
  }

  @Get('celebrations')
  async getCelebrations(@Query('phone') phone?: string) {
    return this.turfService.getCelebrations(phone);
  }

  // Player Realtime Notifications
  @Get('notifications/:phone')
  async getUserNotifications(@Param('phone') phone: string) {
    return this.turfService.getUserNotifications(phone);
  }

  @Post('notifications/:id/read')
  async markNotificationRead(@Param('id', ParseIntPipe) id: number) {
    return this.turfService.markNotificationRead(id);
  }

  @Post('notifications')
  async createNotification(@Body() body: any) {
    return this.turfService.createNotification(body);
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

  // Direct confirmed booking without online payment: platform admin only (walk-in / manual).
  // Players book through POST /cashfree/create-order, which holds the slot until payment.
  @Post(':id/book')
  @UseGuards(SuperAdminGuard)
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

  @Get(':id/courts')
  async getTurfCourts(@Param('id', ParseIntPipe) id: number) {
    return this.turfService.getTurfCourts(id);
  }

  @Post(':id/courts')
  async saveTurfCourts(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: any,
  ) {
    const courts = Array.isArray(body) ? body : (body?.courts || []);
    const callerPhone = body?.callerPhone || body?.adminPhone || body?.ownerPhone;
    return this.turfService.saveTurfCourts(id, courts, callerPhone);
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
