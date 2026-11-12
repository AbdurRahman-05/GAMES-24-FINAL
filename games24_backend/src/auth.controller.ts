import { Controller, Post, Get, Patch, Body, Param, Query, ParseIntPipe } from '@nestjs/common';
import { AuthService } from './auth.service.js';

@Controller('auth')
export class AuthController {
  constructor(private readonly authService: AuthService) {}

  @Get('user-profile')
  async getUserProfile(@Query('phone') phone: string) {
    return this.authService.getUserProfile(phone || '');
  }

  @Post('user/teams')
  async saveUserTeams(@Body() body: any) {
    return this.authService.saveUserTeams(body?.phone || '', body?.teams || []);
  }

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
  async getVerifiedAdmin(
    @Param('phone') phone: string,
    @Query('turfId') turfId?: string,
  ) {
    const numId = turfId ? parseInt(turfId, 10) : undefined;
    return this.authService.getVerifiedAdminByPhone(phone, isNaN(numId as any) ? undefined : numId);
  }

  @Post('verified-admin/add-branch')
  async addOwnerBranch(@Body() body: any) {
    return this.authService.addOwnerBranch(body);
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

  @Get('players/search')
  async searchPlayers(@Query('q') q: string) {
    return this.authService.searchPlayer(q || '');
  }

  @Post('team-invitations')
  async sendTeamInvitation(@Body() body: any) {
    return this.authService.sendTeamInvitation(body);
  }

  @Get('team-invitations')
  async getPlayerInvitations(@Query('identifier') identifier: string) {
    return this.authService.getPlayerInvitations(identifier || '');
  }

  @Post('team-invitations/:inviteId/respond')
  async respondTeamInvitation(
    @Param('inviteId') inviteId: string,
    @Body() body: { action: 'accept' | 'decline'; playerData?: any },
  ) {
    return this.authService.respondTeamInvitation(inviteId, body.action, body.playerData);
  }

  @Post('team-match/challenge')
  async createTeamMatchChallenge(@Body() body: any) {
    return this.authService.createTeamMatchChallenge(body);
  }
}

