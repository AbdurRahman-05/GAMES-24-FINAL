import { CanActivate, ExecutionContext, Injectable, UnauthorizedException } from '@nestjs/common';

@Injectable()
export class SuperAdminGuard implements CanActivate {
  canActivate(context: ExecutionContext): boolean {
    const request = context.switchToHttp().getRequest();
    const adminKey = request.headers['x-admin-key'] || request.headers['authorization'];
    const expectedKey = process.env.ADMIN_SECRET || 'g24_super_admin_secret_2026';

    if (adminKey === expectedKey || adminKey === `Bearer ${expectedKey}`) {
      return true;
    }

    throw new UnauthorizedException('Access denied: Valid super admin credentials required.');
  }
}

