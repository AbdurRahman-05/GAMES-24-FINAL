export const BACKEND_URL = process.env.NEXT_PUBLIC_BACKEND_URL || 'https://games-24-final.onrender.com';

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
  const res = await fetch(`${BACKEND_URL}/super-admin/stats`, { cache: 'no-store' });
  if (!res.ok) throw new Error('Failed to fetch stats');
  return res.json();
}

export async function getDashboardOverview(): Promise<DashboardOverview> {
  const res = await fetch(`${BACKEND_URL}/super-admin/overview`, { cache: 'no-store' });
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
    const errorData = await res.json().catch(() => ({}));
    throw new Error(errorData.message || 'Failed to verify registration');
  }
  return res.json();
}

export async function cancelRegistration(
  id: number,
  body?: { reason?: string }
): Promise<{ success: boolean; message: string }> {
  const res = await fetch(`${BACKEND_URL}/super-admin/registrations/${id}/cancel`, {
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

  const res = await fetch(`${BACKEND_URL}/super-admin/verified-admins?${query.toString()}`, {
    cache: 'no-store',
  });
  if (!res.ok) throw new Error('Failed to fetch verified admins');
  return res.json();
}

export async function toggleTurfBookingHold(
  turfId: number,
  hold?: boolean
): Promise<{ success: boolean; message: string; isBookingHold: boolean }> {
  const res = await fetch(`${BACKEND_URL}/super-admin/turfs/${turfId}/toggle-hold`, {
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

  const res = await fetch(`${BACKEND_URL}/super-admin/all-bookings?${query.toString()}`, {
    cache: 'no-store',
  });
  if (!res.ok) throw new Error('Failed to fetch bookings');
  return res.json();
}

export async function toggleBookingHold(
  bookingId: number,
  isHold?: boolean
): Promise<{ success: boolean; message: string; booking: BookingItem }> {
  const res = await fetch(`${BACKEND_URL}/super-admin/bookings/${bookingId}/hold`, {
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
  const res = await fetch(`${BACKEND_URL}/super-admin/bookings/${bookingId}/cancel`, {
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

  const res = await fetch(`${BACKEND_URL}/super-admin/all-tournaments?${query.toString()}`, {
    cache: 'no-store',
  });
  if (!res.ok) throw new Error('Failed to fetch tournaments');
  return res.json();
}

export async function toggleTournamentHold(
  tournamentId: number,
  isHold?: boolean
): Promise<{ success: boolean; message: string; tournament: TournamentItem }> {
  const res = await fetch(`${BACKEND_URL}/super-admin/tournaments/${tournamentId}/toggle-hold`, {
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
  let res = await fetch(`${BACKEND_URL}/super-admin/verified-admins/${turfId}`, {
    method: 'DELETE',
    headers: { 'Content-Type': 'application/json' },
  });
  if (!res.ok) {
    res = await fetch(`${BACKEND_URL}/super-admin/verified-admins/${turfId}/delete`, {
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
  let res = await fetch(`${BACKEND_URL}/super-admin/tournaments/${tournamentId}`, {
    method: 'DELETE',
    headers: { 'Content-Type': 'application/json' },
  });
  if (!res.ok) {
    res = await fetch(`${BACKEND_URL}/super-admin/tournaments/${tournamentId}/delete`, {
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
