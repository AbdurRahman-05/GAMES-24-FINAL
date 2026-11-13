import { Controller, Get, Post, Delete, Param, Query, Body, ParseIntPipe, UseGuards } from '@nestjs/common';
import { SuperAdminService } from './super-admin.service.js';
import { SuperAdminGuard } from './super-admin.guard.js';

@Controller('super-admin')
@UseGuards(SuperAdminGuard)
export class SuperAdminController {
  constructor(private readonly superAdminService: SuperAdminService) {}

  @Get('stats')
  async getStats() {
    return this.superAdminService.getStats();
  }

  // REALTIME OVERVIEW: ALL KPIS, REVENUE BREAKDOWN, LIVE ACTIONS, PLAYER STATS
  @Get('overview')
  async getDashboardOverview() {
    return this.superAdminService.getDashboardOverview();
  }

  @Get('registrations')
  async getRegistrations(
    @Query('status') status?: string,
    @Query('search') search?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.superAdminService.getRegistrations({ status, search, page, limit });
  }

  @Get('registrations/:id')
  async getRegistrationById(@Param('id', ParseIntPipe) id: number) {
    return this.superAdminService.getRegistrationById(id);
  }

  @Post('registrations/:id/verify')
  async verifyRegistration(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { verifiedBy?: string },
  ) {
    return this.superAdminService.verifyRegistration(id, body);
  }

  @Post('registrations/:id/cancel')
  async cancelRegistration(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { reason?: string },
  ) {
    return this.superAdminService.cancelRegistration(id, body);
  }

  @Get('verified-admins')
  async getVerifiedAdmins(
    @Query('search') search?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.superAdminService.getVerifiedAdmins({ search, page, limit });
  }

  @Get('verified-admins/:id')
  async getVerifiedAdminById(@Param('id', ParseIntPipe) id: number) {
    return this.superAdminService.getVerifiedAdminById(id);
  }

  @Get('status/:identifier')
  async getAdminStatus(@Param('identifier') identifier: string) {
    return this.superAdminService.getAdminStatus(identifier);
  }

  // HOLD / RESUME TURF OWNER ACCOUNT & BOOKINGS
  @Post('turfs/:id/toggle-hold')
  async toggleTurfBookingHold(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { hold?: boolean },
  ) {
    return this.superAdminService.toggleTurfBookingHold(id, body);
  }

  @Post('verified-admins/:id/toggle-hold')
  async toggleVerifiedAdminHold(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { hold?: boolean },
  ) {
    return this.superAdminService.toggleTurfBookingHold(id, body);
  }

  // DELETE TURF OWNER PERMANENTLY (Cascades venue, bookings, challenges, tournaments)
  @Delete('verified-admins/:id')
  async deleteVerifiedAdminDelete(@Param('id', ParseIntPipe) id: number) {
    return this.superAdminService.deleteVerifiedAdmin(id);
  }

  @Post('verified-admins/:id/delete')
  async deleteVerifiedAdminPost(@Param('id', ParseIntPipe) id: number) {
    return this.superAdminService.deleteVerifiedAdmin(id);
  }

  // ALL BOOKINGS MANAGEMENT
  @Get('all-bookings')
  async getAllBookings(
    @Query('search') search?: string,
    @Query('turfId') turfId?: string,
    @Query('status') status?: string,
    @Query('date') date?: string,
    @Query('page') page?: string,
    @Query('limit') limit?: string,
  ) {
    return this.superAdminService.getAllBookings({ search, turfId, status, date, page, limit });
  }

  @Post('bookings/:id/hold')
  async toggleBookingHold(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { isHold?: boolean },
  ) {
    return this.superAdminService.toggleBookingHold(id, body);
  }

  @Post('bookings/:id/cancel')
  async cancelBooking(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { reason?: string },
  ) {
    return this.superAdminService.cancelBooking(id, body);
  }

  // TOURNAMENTS MANAGEMENT
  @Get('all-tournaments')
  async getAllTournaments(
    @Query('status') status?: string,
    @Query('search') search?: string,
  ) {
    return this.superAdminService.getAllTournaments({ status, search });
  }

  @Post('tournaments/:id/toggle-hold')
  async toggleTournamentHold(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: { isHold?: boolean },
  ) {
    return this.superAdminService.toggleTournamentHold(id, body);
  }

  // DELETE TOURNAMENT PERMANENTLY
  @Delete('tournaments/:id')
  async deleteTournamentDelete(@Param('id', ParseIntPipe) id: number) {
    return this.superAdminService.deleteTournament(id);
  }

  @Post('tournaments/:id/delete')
  async deleteTournamentPost(@Param('id', ParseIntPipe) id: number) {
    return this.superAdminService.deleteTournament(id);
  }

  @Post('tournaments')
  async createTournament(@Body() body: any) {
    return this.superAdminService.createTournament(body);
  }
}
