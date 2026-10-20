import { Controller, Get, Post, Param, Query, Body, ParseIntPipe } from '@nestjs/common';
import { SuperAdminService } from './super-admin.service.js';

@Controller('super-admin')
export class SuperAdminController {
  constructor(private readonly superAdminService: SuperAdminService) {}

  @Get('stats')
  async getStats() {
    return this.superAdminService.getStats();
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
}
