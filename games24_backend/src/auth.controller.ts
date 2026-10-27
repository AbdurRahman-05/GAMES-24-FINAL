import { Controller, Post, Get, Patch, Body, Param, ParseIntPipe } from '@nestjs/common';
import { AuthService } from './auth.service.js';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Get('admin-status/:identifier')
  async getAdminStatus(@Param('identifier') identifier: string) {
    return this.authService.getAdminStatus(identifier);
  }

  @Post('send-otp')
  async sendOtp(@Body('mobileNumber') mobileNumber: string) {
    return this.authService.sendOtp(mobileNumber);
  }

  @Post('check-mobile')
  async checkMobile(@Body('mobileNumber') mobileNumber: string) {
    return this.authService.checkMobile(mobileNumber);
  }

  @Post('check-admin-contact')
  async checkAdminContact(@Body() body: any) {
    return this.authService.checkAdminContact(body);
  }

  @Post('verify-otp')
  async verifyOtp(@Body() body: any) {
    return this.authService.verifyOtp(body);
  }

  @Post('register')
  async register(@Body() body: any) {
    return this.authService.register(body);
  }

  @Post('register-admin')
  async registerAdmin(@Body() body: any) {
    return this.authService.registerAdmin(body);
  }

  @Post('send-admin-otp')
  async sendAdminOtps(@Body() body: any) {
    return this.authService.sendAdminOtps(body);
  }

  @Post('verify-admin-otp')
  async verifyAdminOtp(@Body() body: any) {
    return this.authService.verifyAdminOtp(body);
  }

  @Post('update-admin-kyc')
  async updateAdminKyc(@Body() body: any) {
    return this.authService.updateAdminKyc(body);
  }

  @Post('login')
  async login(@Body() body: any) {
    return this.authService.login(body);
  }

  @Post('reset-password')
  async resetPassword(@Body() body: any) {
    return this.authService.resetPassword(body);
  }

  @Post('verify-reset-otp')
  async verifyResetOtp(@Body() body: any) {
    return this.authService.verifyResetOtp(body);
  }

  @Post('admin-login')
  async adminLogin(@Body() body: any) {
    return this.authService.adminLogin(body);
  }

  @Get('verified-admin/:phone')
  async getVerifiedAdmin(@Param('phone') phone: string) {
    return this.authService.getVerifiedAdminByPhone(phone);
  }

  @Patch('verified-admin/:id/metrics')
  async updateVerifiedAdminMetrics(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: any,
  ) {
    return this.authService.updateVerifiedAdminMetrics(id, body);
  }

  @Patch('verified-admin/:id/profile')
  async updateVerifiedAdminProfilePatch(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: any,
  ) {
    return this.authService.updateVerifiedAdminProfile(id, body);
  }

  @Post('verified-admin/:id/profile')
  async updateVerifiedAdminProfilePost(
    @Param('id', ParseIntPipe) id: number,
    @Body() body: any,
  ) {
    return this.authService.updateVerifiedAdminProfile(id, body);
  }
}

