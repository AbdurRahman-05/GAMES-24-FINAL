export const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'http://localhost:3000';

export interface AdminRegistration {
  id: number;
  trackingCode: string | null;
  venueName: string;
  ownerName: string;
  ownerPhone: string;
  ownerEmail: string;
  streetAddress: string;
  neighborhoodArea: string;
  isMobileVerified: boolean;
  isEmailVerified: boolean;
  photosCount: number;
  photoUrls: string[];
  amenities: string[];
  gstin: string | null;
  panNumber: string | null;
  aadhaarNumber: string | null;
  aadhaarDocUrl: string | null;
  panDocUrl: string | null;
  gstDocUrl: string | null;
  bankAccount: string | null;
  ifscCode: string | null;
  upiId: string | null;
  status: 'PENDING_APPROVAL' | 'VERIFIED' | 'CANCELLED';
  cancelReason: string | null;
  createdAt: string;
  updatedAt: string;
  verifiedRecord?: VerifiedAdmin | null;
}

export interface VerifiedAdmin {
  id: number;
  adminUserId: number;
  trackingCode: string | null;
  venueName: string;
  ownerName: string;
  ownerPhone: string;
  ownerEmail: string;
  streetAddress: string;
  neighborhoodArea: string;
  isMobileVerified: boolean;
  isEmailVerified: boolean;
  photosCount: number;
  photoUrls: string[];
  amenities: string[];
  gstin: string | null;
  panNumber: string | null;
  aadhaarNumber: string | null;
  aadhaarDocUrl: string | null;
  panDocUrl: string | null;
  gstDocUrl: string | null;
  bankAccount: string | null;
  ifscCode: string | null;
  upiId: string | null;
  status: string;
  verifiedAt: string;
  verifiedBy: string;
  createdAt: string;
  updatedAt: string;
}

export interface SystemStats {
  total: number;
  waiting: number;
  verified: number;
  cancelled: number;
  totalVerifiedTable: number;
}

export async function getStats(): Promise<SystemStats> {
  const res = await fetch(`${BACKEND_URL}/super-admin/stats`, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch stats');
  return res.json();
}

export async function getRegistrations(params: {
  status?: string;
  search?: string;
  page?: number;
  limit?: number;
}): Promise<{
  items: AdminRegistration[];
  pagination: { page: number; limit: number; totalCount: number; totalPages: number };
  stats: SystemStats;
}> {
  const query = new URLSearchParams();
  if (params.status) query.append('status', params.status);
  if (params.search) query.append('search', params.search);
  if (params.page) query.append('page', String(params.page));
  if (params.limit) query.append('limit', String(params.limit));

  const res = await fetch(`${BACKEND_URL}/super-admin/registrations?${query.toString()}`, {
    cache: 'no-store',
  });
  if (!res.ok) throw new Error('Failed to fetch registrations');
  return res.json();
}

export async function getRegistrationById(id: number): Promise<AdminRegistration> {
  const res = await fetch(`${BACKEND_URL}/super-admin/registrations/${id}`, { cache: 'no-store' });
  if (!res.ok) throw new Error(`Failed to fetch registration #${id}`);
  return res.json();
}

export async function verifyRegistration(
  id: number,
  body?: { verifiedBy?: string }
): Promise<{ success: boolean; message: string; verifiedAdmin: VerifiedAdmin }> {
  const res = await fetch(`${BACKEND_URL}/super-admin/registrations/${id}/verify`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body || {}),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || 'Verification failed');
  }
  return res.json();
}

export async function cancelRegistration(
  id: number,
  body: { reason: string }
): Promise<{ success: boolean; message: string }> {
  const res = await fetch(`${BACKEND_URL}/super-admin/registrations/${id}/cancel`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || 'Cancellation failed');
  }
  return res.json();
}

export async function getVerifiedAdmins(params: {
  search?: string;
  page?: number;
  limit?: number;
}): Promise<{
  items: VerifiedAdmin[];
  pagination: { page: number; limit: number; totalCount: number; totalPages: number };
}> {
  const query = new URLSearchParams();
  if (params.search) query.append('search', params.search);
  if (params.page) query.append('page', String(params.page));
  if (params.limit) query.append('limit', String(params.limit));

  const res = await fetch(`${BACKEND_URL}/super-admin/verified-admins?${query.toString()}`, {
    cache: 'no-store',
  });
  if (!res.ok) throw new Error('Failed to fetch verified admins');
  return res.json();
}

export async function getVerifiedAdminById(id: number): Promise<VerifiedAdmin> {
  const res = await fetch(`${BACKEND_URL}/super-admin/verified-admins/${id}`, {
    cache: 'no-store',
  });
  if (!res.ok) throw new Error(`Failed to fetch verified admin #${id}`);
  return res.json();
}
