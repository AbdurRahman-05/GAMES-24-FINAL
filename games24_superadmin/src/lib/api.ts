export const DEFAULT_LIVE_BACKEND_URL = 'https://games-24-final.onrender.com';

export function getEffectiveBackendUrl(): string {
  if (typeof window !== 'undefined') {
    const override = localStorage.getItem('g24_superadmin_backend_url');
    if (override && override.trim()) return override.trim().replace(/\/+$/, '');
  }
  return (process.env.NEXT_PUBLIC_BACKEND_URL || DEFAULT_LIVE_BACKEND_URL).trim().replace(/\/+$/, '');
}

export function setEffectiveBackendUrl(url: string | null) {
  if (typeof window !== 'undefined') {
    if (url && url.trim()) {
      localStorage.setItem('g24_superadmin_backend_url', url.trim().replace(/\/+$/, ''));
    } else {
      localStorage.removeItem('g24_superadmin_backend_url');
    }
  }
}

export const BACKEND_URL = (process.env.NEXT_PUBLIC_BACKEND_URL || DEFAULT_LIVE_BACKEND_URL).trim().replace(/\/+$/, '');
export const ADMIN_SECRET = process.env.NEXT_PUBLIC_ADMIN_SECRET || 'g24_super_admin_secret_2026';
export const adminHeaders = (extra: Record<string, string> = {}) => ({
  'x-admin-key': ADMIN_SECRET,
  ...extra,
});

export async function safeAdminFetch(
  pathWithQuery: string,
  options: RequestInit = {},
  allowFallback = true
): Promise<Response> {
  const base = getEffectiveBackendUrl();
  const cleanPath = pathWithQuery.startsWith('/') ? pathWithQuery : `/${pathWithQuery}`;
  const primaryUrl = `${base}${cleanPath}`;

  // Configure timeout (25 seconds for Render cold-starts)
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 25000);

  const mergedHeaders: Record<string, string> = {
    'x-admin-key': ADMIN_SECRET,
    ...adminHeaders(),
    ...((options.headers as Record<string, string>) || {}),
  };

  try {
    const res = await fetch(primaryUrl, {
      ...options,
      headers: mergedHeaders,
      signal: controller.signal,
    });
    clearTimeout(timeoutId);

    // If server responded with 502/503 during cold-start or waking, retry once after short pause
    if ((res.status === 502 || res.status === 503) && allowFallback) {
      await new Promise((r) => setTimeout(r, 1200));
      return safeAdminFetch(pathWithQuery, options, false);
    }

    return res;
  } catch (err: any) {
    clearTimeout(timeoutId);

    // If localhost failed (not running / connection refused) and allowFallback is true,
    // automatically fallback to live Render cloud!
    if (allowFallback && base !== DEFAULT_LIVE_BACKEND_URL) {
      console.warn(`[SuperAdmin] Primary backend ${base} unreachable (${err?.message || err}). Auto-falling back to live Render cloud...`);
      const fallbackUrl = `${DEFAULT_LIVE_BACKEND_URL}${cleanPath}`;
      const fallbackController = new AbortController();
      const fbTimeoutId = setTimeout(() => fallbackController.abort(), 25000);

      try {
        const fbRes = await fetch(fallbackUrl, {
          ...options,
          headers: mergedHeaders,
          signal: fallbackController.signal,
        });
        clearTimeout(fbTimeoutId);
        return fbRes;
      } catch (fbErr: any) {
        clearTimeout(fbTimeoutId);
        throw new Error(`Failed to reach live backend (${DEFAULT_LIVE_BACKEND_URL}): ${fbErr?.message || fbErr}`);
      }
    }

    throw err;
  }
}

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
  sports?: string[];
  sportsList?: any[];
  gstin: string | null;
  panNumber: string | null;
  aadhaarNumber: string | null;
  aadhaarDocUrl: string | null;
  panDocUrl: string | null;
  gstDocUrl: string | null;
  bankAccount: string | null;
  ifscCode: string | null;
  upiId: string | null;
  isBranch?: boolean;
  parentTurfId?: number | null;
  alternativePhone?: string | null;
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
  sports?: string[];
  sportsList?: any[];
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
  isBookingHold?: boolean;
  weekdayRate?: number;
  weekendRate?: number;
  dayRate?: number;
  nightRate?: number;
  dashboard?: AdminDashboard | null;
  verifiedAt: string;
  verifiedBy: string;
  createdAt: string;
  updatedAt: string;
}

export interface AdminDashboard {
  id: number;
  verifiedAdminId: number;
  openingTime?: string;
  closingTime?: string;
  todayBookingsCount: number;
  todayPaidBookings: number;
  todayCashBookings: number;
  todayBookingsGrowth: string;
  monthRevenue: number;
  monthTotalBookings: number;
  revenueBadge: string;
  freeSlotsCount: number;
  bookedSlotsCount: number;
  blockedSlotsCount: number;
  slotsBadge: string;
  cancelledTotal: number;
  cancelledCount: number;
  shiftedCount: number;
  cancelledBadge: string;
  createdAt: string;
}

export interface SystemStats {
  total: number;
  waiting: number;
  verified: number;
  cancelled: number;
  totalVerifiedTable: number;
}

export interface DashboardOverview {
  kpis: {
    totalUsers: number;
    totalOwners: number;
    verifiedOwners: number;
    pendingOwners: number;
    totalRevenue: number;
    totalBookingsCount: number;
    todayBookingsCount: number;
    todayCancelledCount: number;
    todayRevenue: number;
    todayAdvancePaid: number;
    todayCashAmount: number;
  };
  tournamentsSummary: {
    total: number;
    live: number;
    upcoming: number;
    finished: number;
    onHold: number;
  };
  turfRevenueBreakdown: Array<{
    turfId: number;
    venueName: string;
    ownerName: string;
    ownerPhone: string;
    neighborhoodArea: string;
    status: string;
    isBookingHold: boolean;
    todayBookingsCount: number;
    todayRevenue: number;
    todayCancelled: number;
    totalBookingsCount: number;
    totalRevenue: number;
    activeRateWeekday?: number;
    activeRateWeekend?: number;
  }>;
  playerStats: Array<{
    customerName: string;
    customerPhone: string;
    totalBookings: number;
    totalSpent: number;
    lastBookingDate: string;
    favoriteSport: string;
  }>;
  recentLiveActions: Array<{
    id: string;
    type: 'BOOKING' | 'CANCELLATION' | 'HOLD' | 'REGISTRATION' | 'VERIFICATION' | 'TOURNAMENT';
    title: string;
    description: string;
    amount?: number;
    turfName?: string;
    status?: string;
    timestamp: string;
  }>;
}

export interface BookingItem {
  id: number;
  bookingCode?: string | null;
  bookingId?: string | null;
  verifiedAdminId: number;
  customerName: string;
  customerPhone: string;
  sport: string;
  courtName: string;
  date: string;
  timeSlot: string;
  amount: number;
  paymentMethod: string;
  status: string;
  isHold: boolean;
  isOpenMatch?: boolean;
  openMatchStatus?: string | null;
  teamName?: string | null;
  teamSize?: string | null;
  opponentName?: string | null;
  opponentPhone?: string | null;
  createdAt: string;
  verifiedAdmin?: {
    id: number;
    venueName: string;
    neighborhoodArea: string;
    ownerPhone: string;
  };
}

export interface TournamentItem {
  id: number;
  title: string;
  sport: string;
  format: string;
  status: 'LIVE' | 'UPCOMING' | 'FINISHED' | 'ON_HOLD' | 'CANCELLED' | string;
  isHold: boolean;
  date: string;
  time: string;
  venueName: string;
  location?: string;
  entryFee: number;
  prizePool: string;
  maxTeams: number;
  registeredTeams: number;
  organizerName: string;
  verifiedAdmin?: {
    venueName: string;
    neighborhoodArea: string;
  };
}

export async function getStats(): Promise<SystemStats> {
  const res = await safeAdminFetch('/super-admin/stats', { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch stats');
  return res.json();
}

export async function getDashboardOverview(): Promise<DashboardOverview> {
  const res = await safeAdminFetch('/super-admin/overview', { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch overview analytics');
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

  const res = await safeAdminFetch(`/super-admin/registrations?${query.toString()}`, {
    cache: 'no-store',
  });
  if (!res.ok) throw new Error('Failed to fetch registrations');
  return res.json();
}

export async function getRegistrationById(id: number): Promise<AdminRegistration> {
  const res = await safeAdminFetch(`/super-admin/registrations/${id}`, { cache: 'no-store' });
  if (!res.ok) throw new Error(`Failed to fetch registration #${id}`);
  return res.json();
}

export async function verifyRegistration(
  id: number,
  body?: { verifiedBy?: string }
): Promise<{ success: boolean; message: string; verifiedAdmin: VerifiedAdmin }> {
  const res = await safeAdminFetch(`/super-admin/registrations/${id}/verify`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body || {}),
  });
  if (!res.ok) {
    const errorData = await res.json().catch(() => ({}));
    throw new Error(errorData.message || 'Failed to verify registration');
  }
  return res.json();
}

export async function cancelRegistration(
  id: number,
  body?: { reason?: string }
): Promise<{ success: boolean; message: string }> {
  const res = await safeAdminFetch(`/super-admin/registrations/${id}/cancel`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body || {}),
  });
  if (!res.ok) {
    const errorData = await res.json().catch(() => ({}));
    throw new Error(errorData.message || 'Failed to cancel registration');
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

  const res = await safeAdminFetch(`/super-admin/verified-admins?${query.toString()}`, {
    cache: 'no-store',
  });
  if (!res.ok) throw new Error('Failed to fetch verified admins');
  return res.json();
}

export async function toggleTurfBookingHold(
  turfId: number,
  hold?: boolean
): Promise<{ success: boolean; message: string; isBookingHold: boolean }> {
  const res = await safeAdminFetch(`/super-admin/turfs/${turfId}/toggle-hold`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ hold }),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || 'Failed to toggle turf hold');
  }
  return res.json();
}

export async function getAllBookings(params: {
  search?: string;
  turfId?: string;
  status?: string;
  date?: string;
  page?: number;
  limit?: number;
}): Promise<{
  items: BookingItem[];
  pagination: { page: number; limit: number; totalCount: number; totalPages: number };
}> {
  const query = new URLSearchParams();
  if (params.search) query.append('search', params.search);
  if (params.turfId) query.append('turfId', params.turfId);
  if (params.status) query.append('status', params.status);
  if (params.date) query.append('date', params.date);
  if (params.page) query.append('page', String(params.page));
  if (params.limit) query.append('limit', String(params.limit));

  const res = await safeAdminFetch(`/super-admin/all-bookings?${query.toString()}`, {
    cache: 'no-store',
  });
  if (!res.ok) throw new Error('Failed to fetch bookings');
  return res.json();
}

export async function toggleBookingHold(
  bookingId: number,
  isHold?: boolean
): Promise<{ success: boolean; message: string; booking: BookingItem }> {
  const res = await safeAdminFetch(`/super-admin/bookings/${bookingId}/hold`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ isHold }),
  });
  if (!res.ok) throw new Error('Failed to update booking hold status');
  return res.json();
}

export async function cancelBookingByAdmin(
  bookingId: number,
  reason?: string
): Promise<{ success: boolean; message: string }> {
  const res = await safeAdminFetch(`/super-admin/bookings/${bookingId}/cancel`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ reason }),
  });
  if (!res.ok) throw new Error('Failed to cancel booking');
  return res.json();
}

export async function getAllTournaments(params: {
  status?: string;
  search?: string;
}): Promise<{ items: TournamentItem[] }> {
  const query = new URLSearchParams();
  if (params.status) query.append('status', params.status);
  if (params.search) query.append('search', params.search);

  const res = await safeAdminFetch(`/super-admin/all-tournaments?${query.toString()}`, {
    cache: 'no-store',
  });
  if (!res.ok) throw new Error('Failed to fetch tournaments');
  return res.json();
}

export async function toggleTournamentHold(
  tournamentId: number,
  isHold?: boolean
): Promise<{ success: boolean; message: string; tournament: TournamentItem }> {
  const res = await safeAdminFetch(`/super-admin/tournaments/${tournamentId}/toggle-hold`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ isHold }),
  });
  if (!res.ok) throw new Error('Failed to update tournament hold status');
  return res.json();
}

export async function deleteVerifiedAdmin(
  turfId: number
): Promise<{ success: boolean; message: string }> {
  let res = await safeAdminFetch(`/super-admin/verified-admins/${turfId}`, {
    method: 'DELETE',
    headers: { 'Content-Type': 'application/json' },
  });
  if (!res.ok) {
    res = await safeAdminFetch(`/super-admin/verified-admins/${turfId}/delete`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    });
  }
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || 'Failed to delete turf owner account');
  }
  return res.json();
}

export async function deleteTournament(
  tournamentId: number
): Promise<{ success: boolean; message: string }> {
  let res = await safeAdminFetch(`/super-admin/tournaments/${tournamentId}`, {
    method: 'DELETE',
    headers: { 'Content-Type': 'application/json' },
  });
  if (!res.ok) {
    res = await safeAdminFetch(`/super-admin/tournaments/${tournamentId}/delete`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
    });
  }
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || 'Failed to delete tournament');
  }
  return res.json();
}

export async function deploySuperAdminTournament(body: {
  title: string;
  sport: string;
  venueName: string;
  date: string;
  entryFee?: number;
  prizePool?: string;
  maxTeams?: number;
}): Promise<{ success: boolean; message: string; tournament: TournamentItem }> {
  const res = await safeAdminFetch('/super-admin/tournaments', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  if (!res.ok) {
    const err = await res.json().catch(() => ({}));
    throw new Error(err.message || 'Failed to deploy tournament');
  }
  return res.json();
}
