'use client';

import { useState, useEffect, useCallback } from 'react';
import Sidebar, { DashboardTab } from '@/components/Sidebar';
import Header from '@/components/Header';
import AnalyticsCharts from '@/components/AnalyticsCharts';
import RegistrationDetailModal from '@/components/RegistrationDetailModal';
import {
  AdminRegistration,
  BookingItem,
  DashboardOverview,
  TournamentItem,
  getDashboardOverview,
  getRegistrations,
  getAllBookings,
  getAllTournaments,
  verifyRegistration,
  cancelRegistration,
  toggleTurfBookingHold,
  toggleBookingHold,
  cancelBookingByAdmin,
  toggleTournamentHold,
  deleteVerifiedAdmin,
  deleteTournament,
  deploySuperAdminTournament,
  resolveFileUrl,
} from '@/lib/api';
import {
  CheckCircle2,
  AlertCircle,
  AlertTriangle,
  Trash2,
  Users,
  Trophy,
  DollarSign,
  MapPin,
  PauseCircle,
  PlayCircle,
  Plus,
  RefreshCw,
  Search,
  Check,
  X,
  FileCheck2,
  CalendarDays,
  Calendar,
  Clock,
  Swords,
  Image as ImageIcon,
  ChevronRight,
  Building2,
  Terminal,
  ShieldAlert,
  ArrowUpRight,
  TrendingUp,
  CreditCard,
  Phone,
  User,
  Filter,
} from 'lucide-react';
import Link from 'next/link';

export default function SuperAdminDashboard() {
  const [activeTab, setActiveTab] = useState<DashboardTab>('OVERVIEW');
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);

  // Overview data state
  const [overview, setOverview] = useState<DashboardOverview | null>(null);
  const [overviewLoading, setOverviewLoading] = useState(true);

  // Registrations state
  const [activeRegTab, setActiveRegTab] = useState<'WAITING' | 'VERIFIED' | 'CANCEL'>('WAITING');
  const [regItems, setRegItems] = useState<AdminRegistration[]>([]);
  const [regStats, setRegStats] = useState({ total: 0, waiting: 0, verified: 0, cancelled: 0 });
  const [regLoading, setRegLoading] = useState(false);
  const [regSearch, setRegSearch] = useState('');
  const [selectedReg, setSelectedReg] = useState<AdminRegistration | null>(null);
  const [quickVerifyingId, setQuickVerifyingId] = useState<number | null>(null);
  const [cancelModalItem, setCancelModalItem] = useState<AdminRegistration | null>(null);
  const [cancelReasonText, setCancelReasonText] = useState('');

  // Bookings Central state
  const [bookings, setBookings] = useState<BookingItem[]>([]);
  const [bookingsLoading, setBookingsLoading] = useState(false);
  const [bookingSearch, setBookingSearch] = useState('');
  const [bookingStatusFilter, setBookingStatusFilter] = useState('ALL');
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);

  // Tournaments state
  const [tournaments, setTournaments] = useState<TournamentItem[]>([]);
  const [tournLoading, setTournLoading] = useState(false);
  const [tournStatusFilter, setTournStatusFilter] = useState('ALL');
  const [showCreateTournModal, setShowCreateTournModal] = useState(false);
  const [newTournTitle, setNewTournTitle] = useState('');
  const [newTournSport, setNewTournSport] = useState('Football');
  const [newTournVenue, setNewTournVenue] = useState('');
  const [newTournDate, setNewTournDate] = useState('');
  const [newTournEntryFee, setNewTournEntryFee] = useState('1500');
  const [newTournPrize, setNewTournPrize] = useState('₹15,000 Cash');

  // Delete Confirmation Dialogs
  const [deleteConfirmTourn, setDeleteConfirmTourn] = useState<TournamentItem | null>(null);
  const [deleteConfirmTurf, setDeleteConfirmTurf] = useState<{ turfId: number; venueName: string; ownerName?: string } | null>(null);

  // Global search input state in Header
  const [globalSearch, setGlobalSearch] = useState('');

  // Toast state
  const [toastMessage, setToastMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const showToast = (text: string, type: 'success' | 'error' = 'success') => {
    setToastMessage({ text, type });
    setTimeout(() => setToastMessage(null), 4000);
  };

  const getFullFileUrl = (url: string | null) => {
    return resolveFileUrl(url);
  };

  // Load Overview Data
  const loadOverview = useCallback(async () => {
    setOverviewLoading(true);
    try {
      const data = await getDashboardOverview();
      setOverview(data);
    } catch (err: unknown) {
      showToast((err as Error).message || 'Error loading dashboard metrics', 'error');
    } finally {
      setOverviewLoading(false);
    }
  }, []);

  // Load Registrations Data
  const loadRegistrations = useCallback(async () => {
    setRegLoading(true);
    try {
      let statusQuery = 'PENDING_APPROVAL';
      if (activeRegTab === 'VERIFIED') statusQuery = 'VERIFIED';
      if (activeRegTab === 'CANCEL') statusQuery = 'CANCELLED';

      const data = await getRegistrations({
        status: statusQuery,
        search: regSearch || globalSearch,
        limit: 50,
      });

      setRegItems(data.items);
      setRegStats(data.stats);
    } catch (err: unknown) {
      showToast((err as Error).message || 'Error loading registrations', 'error');
    } finally {
      setRegLoading(false);
    }
  }, [activeRegTab, regSearch, globalSearch]);

  // Load Bookings
  const loadBookings = useCallback(async () => {
    setBookingsLoading(true);
    try {
      const data = await getAllBookings({
        search: bookingSearch || globalSearch,
        status: bookingStatusFilter === 'ALL' ? undefined : bookingStatusFilter,
        limit: 50,
      });
      setBookings(data.items);
    } catch (err: unknown) {
      showToast((err as Error).message || 'Error loading bookings', 'error');
    } finally {
      setBookingsLoading(false);
    }
  }, [bookingSearch, bookingStatusFilter, globalSearch]);

  // Load Tournaments
  const loadTournaments = useCallback(async () => {
    setTournLoading(true);
    try {
      const data = await getAllTournaments({
        status: tournStatusFilter === 'ALL' ? undefined : tournStatusFilter,
      });
      setTournaments(data.items);
    } catch (err: unknown) {
      showToast((err as Error).message || 'Error loading tournaments', 'error');
    } finally {
      setTournLoading(false);
    }
  }, [tournStatusFilter]);

  // Initial load
  useEffect(() => {
    loadOverview();
  }, [loadOverview]);

  useEffect(() => {
    if (activeTab === 'REGISTRATIONS') loadRegistrations();
    if (activeTab === 'BOOKINGS') loadBookings();
    if (activeTab === 'TOURNAMENTS') loadTournaments();
  }, [activeTab, loadRegistrations, loadBookings, loadTournaments]);

  // ACTION: Hold / Resume Turf Bookings
  const handleToggleTurfHold = async (turfId: number, currentHold: boolean) => {
    setActionLoadingId(`turf_${turfId}`);
    try {
      const res = await toggleTurfBookingHold(turfId, !currentHold);
      showToast(res.message);
      loadOverview();
    } catch (err: unknown) {
      showToast((err as Error).message || 'Failed to update turf booking hold status', 'error');
    } finally {
      setActionLoadingId(null);
    }
  };

  // ACTION: Hold / Release Specific Booking
  const handleToggleBookingHold = async (bookingId: number, currentHold: boolean) => {
    setActionLoadingId(`book_${bookingId}`);
    try {
      const res = await toggleBookingHold(bookingId, !currentHold);
      showToast(res.message);
      loadBookings();
      loadOverview();
    } catch (err: unknown) {
      showToast((err as Error).message || 'Failed to update booking hold status', 'error');
    } finally {
      setActionLoadingId(null);
    }
  };

  // ACTION: Cancel Booking
  const handleCancelBooking = async (bookingId: number) => {
    if (!confirm(`Are you sure you want to cancel booking #${bookingId}?`)) return;
    setActionLoadingId(`cancel_book_${bookingId}`);
    try {
      const res = await cancelBookingByAdmin(bookingId, 'Cancelled by Super Admin');
      showToast(res.message);
      loadBookings();
      loadOverview();
    } catch (err: unknown) {
      showToast((err as Error).message || 'Failed to cancel booking', 'error');
    } finally {
      setActionLoadingId(null);
    }
  };

  // ACTION: Hold / Resume Tournament
  const handleToggleTournHold = async (tournId: number, currentHold: boolean) => {
    setActionLoadingId(`tourn_${tournId}`);
    try {
      const res = await toggleTournamentHold(tournId, !currentHold);
      showToast(res.message);
      loadTournaments();
      loadOverview();
    } catch (err: unknown) {
      showToast((err as Error).message || 'Failed to update tournament hold', 'error');
    } finally {
      setActionLoadingId(null);
    }
  };

  // ACTION: Delete Tournament Permanently
  const handleDeleteTournament = async (tournId: number) => {
    setActionLoadingId(`del_tourn_${tournId}`);
    try {
      const res = await deleteTournament(tournId);
      showToast(res.message);
      setDeleteConfirmTourn(null);
      loadTournaments();
      loadOverview();
    } catch (err: unknown) {
      showToast((err as Error).message || 'Failed to delete tournament', 'error');
    } finally {
      setActionLoadingId(null);
    }
  };

  // ACTION: Delete Turf Owner Account Permanently
  const handleDeleteTurf = async (turfId: number) => {
    setActionLoadingId(`del_turf_${turfId}`);
    try {
      const res = await deleteVerifiedAdmin(turfId);
      showToast(res.message);
      setDeleteConfirmTurf(null);
      loadOverview();
    } catch (err: unknown) {
      showToast((err as Error).message || 'Failed to delete turf owner account', 'error');
    } finally {
      setActionLoadingId(null);
    }
  };

  const isRegComplete = (r: AdminRegistration) => {
    if (r.isBranch) return true;
    return Boolean(
      r.isMobileVerified &&
      r.isEmailVerified &&
      (r.photosCount > 0 || (r.photoUrls && r.photoUrls.length > 0)) &&
      r.aadhaarNumber &&
      r.bankAccount
    );
  };

  // ACTION: Quick Verify Registration
  const handleQuickVerify = async (reg: AdminRegistration) => {
    if (!isRegComplete(reg)) {
      showToast('Cannot verify incomplete registration. Owner has not submitted all required KYC.', 'error');
      return;
    }
    setQuickVerifyingId(reg.id);
    try {
      await verifyRegistration(reg.id, { verifiedBy: 'Super Admin' });
      showToast(`Venue "${reg.venueName}" successfully verified & activated!`);
      loadRegistrations();
      loadOverview();
    } catch (err: unknown) {
      showToast((err as Error).message || 'Failed to verify registration', 'error');
    } finally {
      setQuickVerifyingId(null);
    }
  };

  // ACTION: Quick Cancel Registration
  const handleQuickCancelConfirm = async () => {
    if (!cancelModalItem || !cancelReasonText.trim()) {
      showToast('Please provide a reason for cancellation', 'error');
      return;
    }
    try {
      await cancelRegistration(cancelModalItem.id, { reason: cancelReasonText.trim() });
      showToast(`Application for "${cancelModalItem.venueName}" rejected`);
      setCancelModalItem(null);
      setCancelReasonText('');
      loadRegistrations();
      loadOverview();
    } catch (err: unknown) {
      showToast((err as Error).message || 'Failed to cancel registration', 'error');
    }
  };

  // ACTION: Create Tournament Modal Submit
  const handleCreateTournament = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTournTitle.trim() || !newTournVenue.trim() || !newTournDate) {
      showToast('Please fill all required tournament fields', 'error');
      return;
    }
    try {
      await deploySuperAdminTournament({
        title: newTournTitle,
        sport: newTournSport,
        venueName: newTournVenue,
        date: newTournDate,
        entryFee: Number(newTournEntryFee) || 0,
        prizePool: newTournPrize,
        maxTeams: 16,
      });
      showToast(`Tournament "${newTournTitle}" deployed successfully!`);
      setShowCreateTournModal(false);
      setNewTournTitle('');
      setNewTournVenue('');
      loadTournaments();
      loadOverview();
    } catch (err: unknown) {
      showToast((err as Error).message || 'Error creating tournament', 'error');
    }
  };

  const kpis = overview?.kpis || {
    totalUsers: 0,
    totalOwners: 0,
    verifiedOwners: 0,
    pendingOwners: 0,
    totalRevenue: 0,
    totalBookingsCount: 0,
    todayBookingsCount: 0,
    todayCancelledCount: 0,
    todayRevenue: 0,
    todayAdvancePaid: 0,
    todayCashAmount: 0,
  };

  const tournSummary = overview?.tournamentsSummary || {
    total: 0,
    live: 0,
    upcoming: 0,
    finished: 0,
    onHold: 0,
  };

  const activeTabTitles: Record<DashboardTab, string> = {
    OVERVIEW: 'EXECUTIVE OVERVIEW',
    ANALYTICS: 'ANALYTICS & CHARTS',
    REGISTRATIONS: 'KYC AUTHORIZATIONS',
    BOOKINGS: 'RESERVATIONS & HOLDS',
    TOURNAMENTS: 'CHAMPIONSHIPS OVERSIGHT',
    TURFS: 'VENUE FLEET DIRECTORY',
  };

  return (
    <div className="min-h-screen bg-[#080B11] text-slate-100 font-sans selection:bg-[#D4FF00] selection:text-black">
      {/* Enterprise Sidebar */}
      <Sidebar
        activeTab={activeTab}
        onSelectTab={(tab) => setActiveTab(tab)}
        waitingKycCount={regStats.waiting || kpis.pendingOwners}
        isOpenMobile={isMobileSidebarOpen}
        onCloseMobile={() => setIsMobileSidebarOpen(false)}
      />

      {/* Main Content Area */}
      <div className="lg:pl-72 flex flex-col min-h-screen">
        {/* Top Header Bar */}
        <Header
          onToggleMobileSidebar={() => setIsMobileSidebarOpen(!isMobileSidebarOpen)}
          onSyncMetrics={() => {
            loadOverview();
            if (activeTab === 'BOOKINGS') loadBookings();
            if (activeTab === 'TOURNAMENTS') loadTournaments();
            if (activeTab === 'REGISTRATIONS') loadRegistrations();
          }}
          isSyncing={overviewLoading}
          onDeployTournament={() => setShowCreateTournModal(true)}
          pendingKycCount={regStats.waiting || kpis.pendingOwners}
          onOpenKyc={() => setActiveTab('REGISTRATIONS')}
          searchQuery={globalSearch}
          onSearchChange={(val) => {
            setGlobalSearch(val);
            if (activeTab === 'BOOKINGS') setBookingSearch(val);
            if (activeTab === 'REGISTRATIONS') setRegSearch(val);
          }}
          activeTabTitle={activeTabTitles[activeTab]}
        />

        {/* Floating Toast Notification */}
        {toastMessage && (
          <div className="fixed top-20 right-6 z-50 animate-in fade-in slide-in-from-top-4 duration-200">
            <div
              className={`flex items-center gap-2.5 px-4 py-3 rounded-xl shadow-2xl border text-xs font-semibold backdrop-blur-md ${
                toastMessage.type === 'success'
                  ? 'bg-[#0E1D19]/95 text-emerald-300 border-emerald-500/40 shadow-emerald-500/10'
                  : 'bg-[#220E14]/95 text-rose-300 border-rose-500/40 shadow-rose-500/10'
              }`}
            >
              {toastMessage.type === 'success' ? (
                <CheckCircle2 className="w-4 h-4 text-emerald-400 shrink-0" />
              ) : (
                <AlertCircle className="w-4 h-4 text-rose-400 shrink-0" />
              )}
              <span>{toastMessage.text}</span>
            </div>
          </div>
        )}

        <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-7">
          {/* Action-Required Banner if Pending KYC */}
          {kpis.pendingOwners > 0 && activeTab !== 'REGISTRATIONS' && (
            <div className="p-4 rounded-xl bg-amber-500/10 border border-amber-500/30 flex flex-col sm:flex-row sm:items-center justify-between gap-3 animate-in fade-in duration-150">
              <div className="flex items-center gap-3">
                <div className="w-8 h-8 rounded-lg bg-amber-500/20 text-amber-400 flex items-center justify-center shrink-0">
                  <ShieldAlert className="w-4 h-4" />
                </div>
                <div>
                  <h4 className="text-xs font-bold text-amber-200 font-mono">
                    {kpis.pendingOwners} Venue Registration{kpis.pendingOwners > 1 ? 's' : ''} Awaiting Super Admin KYC Approval
                  </h4>
                  <p className="text-[11px] text-amber-300/80 mt-0.5 font-mono">
                    Venues cannot receive player bookings until business credentials, PAN, and turf photos are approved.
                  </p>
                </div>
              </div>
              <button
                onClick={() => setActiveTab('REGISTRATIONS')}
                className="px-3.5 py-1.5 rounded-lg text-xs font-bold bg-amber-500 text-black hover:bg-amber-400 transition-all shrink-0 self-start sm:self-auto flex items-center gap-1.5 font-mono"
              >
                <span>Audit Dossiers ({kpis.pendingOwners})</span>
                <ChevronRight className="w-3.5 h-3.5" />
              </button>
            </div>
          )}

          {/* High-Precision Bento KPI Metric Cards (6 Cards) */}
          <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3 sm:gap-4">
            {/* Card 1: Total Platform GMV */}
            <div className="p-4 rounded-xl bg-[#0E131F] border border-[#1E273A] hover:border-slate-600 transition-all">
              <div className="flex items-center justify-between text-xs text-slate-400 mb-2">
                <span className="font-medium text-slate-400 font-mono">Total GMV</span>
                <div className="w-6 h-6 rounded-md bg-[#161D2E] text-[#D4FF00] flex items-center justify-center">
                  <DollarSign className="w-3.5 h-3.5" />
                </div>
              </div>
              <div className="font-mono text-xl sm:text-2xl font-extrabold text-white tracking-tight tabular-nums">
                ₹{kpis.totalRevenue.toLocaleString()}
              </div>
              <div className="mt-2 text-[11px] text-slate-400 flex items-center justify-between font-mono">
                <span className="text-slate-500">Volume</span>
                <span className="text-emerald-400 font-semibold">Live Audit</span>
              </div>
            </div>

            {/* Card 2: Today's Slots */}
            <div className="p-4 rounded-xl bg-[#0E131F] border border-[#1E273A] hover:border-slate-600 transition-all">
              <div className="flex items-center justify-between text-xs text-slate-400 mb-2">
                <span className="font-medium text-slate-400 font-mono">Today&apos;s Slots</span>
                <div className="w-6 h-6 rounded-md bg-emerald-500/10 text-emerald-400 flex items-center justify-center">
                  <CalendarDays className="w-3.5 h-3.5" />
                </div>
              </div>
              <div className="font-mono text-xl sm:text-2xl font-extrabold text-white tracking-tight flex items-baseline gap-1.5 tabular-nums">
                <span>{kpis.todayBookingsCount}</span>
                <span className="text-xs text-emerald-400 font-normal">booked</span>
              </div>
              <div className="mt-2 text-[11px] text-slate-400 flex items-center justify-between font-mono">
                <span className="text-slate-300">₹{kpis.todayRevenue.toLocaleString()}</span>
                {kpis.todayCancelledCount > 0 ? (
                  <span className="text-rose-400 font-semibold">{kpis.todayCancelledCount} cnl</span>
                ) : (
                  <span className="text-slate-500">0 cnl</span>
                )}
              </div>
            </div>

            {/* Card 3: Partner Turfs */}
            <div className="p-4 rounded-xl bg-[#0E131F] border border-[#1E273A] hover:border-slate-600 transition-all">
              <div className="flex items-center justify-between text-xs text-slate-400 mb-2">
                <span className="font-medium text-slate-400 font-mono">Partner Turfs</span>
                <div className="w-6 h-6 rounded-md bg-[#161D2E] text-slate-300 flex items-center justify-center">
                  <Building2 className="w-3.5 h-3.5" />
                </div>
              </div>
              <div className="font-mono text-xl sm:text-2xl font-extrabold text-white tracking-tight tabular-nums">
                {kpis.verifiedOwners}
              </div>
              <div className="mt-2 text-[11px] text-slate-400 flex items-center justify-between font-mono">
                <span className="text-emerald-400 font-medium">Active</span>
                <span className="text-slate-500">{kpis.totalOwners} total</span>
              </div>
            </div>

            {/* Card 4: Registered Athletes */}
            <div className="p-4 rounded-xl bg-[#0E131F] border border-[#1E273A] hover:border-slate-600 transition-all">
              <div className="flex items-center justify-between text-xs text-slate-400 mb-2">
                <span className="font-medium text-slate-400 font-mono">Athletes</span>
                <div className="w-6 h-6 rounded-md bg-[#161D2E] text-sky-400 flex items-center justify-center">
                  <Users className="w-3.5 h-3.5" />
                </div>
              </div>
              <div className="font-mono text-xl sm:text-2xl font-extrabold text-white tracking-tight tabular-nums">
                {kpis.totalUsers}
              </div>
              <div className="mt-2 text-[11px] text-slate-400 flex items-center justify-between font-mono">
                <span className="text-slate-500">OTP Verified</span>
                <span className="text-sky-400 font-semibold">100%</span>
              </div>
            </div>

            {/* Card 5: Tournaments */}
            <div className="p-4 rounded-xl bg-[#0E131F] border border-[#1E273A] hover:border-slate-600 transition-all">
              <div className="flex items-center justify-between text-xs text-slate-400 mb-2">
                <span className="font-medium text-slate-400 font-mono">Championships</span>
                <div className="w-6 h-6 rounded-md bg-[#D4FF00]/10 text-[#D4FF00] flex items-center justify-center">
                  <Trophy className="w-3.5 h-3.5" />
                </div>
              </div>
              <div className="font-mono text-xl sm:text-2xl font-extrabold text-white tracking-tight flex items-baseline gap-1.5 tabular-nums">
                <span>{tournSummary.live}</span>
                <span className="text-xs text-[#D4FF00] font-normal">live now</span>
              </div>
              <div className="mt-2 text-[11px] text-slate-400 flex items-center justify-between font-mono">
                <span className="text-slate-400">{tournSummary.upcoming} upc</span>
                <span className="text-slate-500">{tournSummary.total} total</span>
              </div>
            </div>

            {/* Card 6: Pending KYC Approvals */}
            <div
              onClick={() => setActiveTab('REGISTRATIONS')}
              className={`p-4 rounded-xl border transition-all cursor-pointer ${
                kpis.pendingOwners > 0
                  ? 'bg-amber-500/10 border-amber-500/40 hover:border-amber-400'
                  : 'bg-[#0E131F] border-[#1E273A] hover:border-slate-600'
              }`}
            >
              <div className="flex items-center justify-between text-xs text-slate-400 mb-2">
                <span className="font-medium text-slate-400 font-mono">Pending KYC</span>
                <div
                  className={`w-6 h-6 rounded-md flex items-center justify-center ${
                    kpis.pendingOwners > 0 ? 'bg-amber-500/20 text-amber-300' : 'bg-[#161D2E] text-slate-400'
                  }`}
                >
                  <FileCheck2 className="w-3.5 h-3.5" />
                </div>
              </div>
              <div
                className={`font-mono text-xl sm:text-2xl font-extrabold tracking-tight tabular-nums ${
                  kpis.pendingOwners > 0 ? 'text-amber-300' : 'text-white'
                }`}
              >
                {kpis.pendingOwners}
              </div>
              <div className="mt-2 text-[11px] flex items-center justify-between font-mono">
                {kpis.pendingOwners > 0 ? (
                  <span className="text-amber-400 font-semibold flex items-center gap-1">
                    <span>Audit Now</span>
                    <ChevronRight className="w-3 h-3" />
                  </span>
                ) : (
                  <span className="text-slate-500 flex items-center gap-1">
                    <Check className="w-3 h-3 text-emerald-400" />
                    Up to date
                  </span>
                )}
              </div>
            </div>
          </div>

          {/* ========================================================================= */}
          {/* TAB 1: OVERVIEW */}
          {/* ========================================================================= */}
          {activeTab === 'OVERVIEW' && (
            <div className="space-y-7 animate-in fade-in duration-200">
              {/* Interactive Analytics Charts */}
              <AnalyticsCharts overview={overview} />

              {/* Split row: Connected Turfs & Real-time Live Actions Stream */}
              <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
                {/* Left Column (7 cols): Connected Turfs */}
                <div className="lg:col-span-7 space-y-3.5">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Building2 className="w-4 h-4 text-[#D4FF00]" />
                      <h2 className="text-sm font-bold text-white tracking-tight uppercase font-mono">
                        Active Turf Services & Booking Controls
                      </h2>
                    </div>
                    <button
                      onClick={() => setActiveTab('TURFS')}
                      className="text-xs text-[#D4FF00] hover:underline font-semibold flex items-center gap-1 font-mono"
                    >
                      <span>View All Venues</span>
                      <ChevronRight className="w-3.5 h-3.5" />
                    </button>
                  </div>

                  <div className="space-y-2.5">
                    {overview?.turfRevenueBreakdown && overview.turfRevenueBreakdown.length > 0 ? (
                      overview.turfRevenueBreakdown.map((turf) => (
                        <div
                          key={turf.turfId}
                          className="p-4 rounded-xl bg-[#0E131F] border border-[#1E273A] hover:border-[#2E3C58] transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-4"
                        >
                          <div className="flex items-start gap-3">
                            <div className="mt-1">
                              {turf.isBookingHold ? (
                                <span className="relative flex h-2.5 w-2.5">
                                  <span className="inline-flex rounded-full h-2.5 w-2.5 bg-amber-400" />
                                </span>
                              ) : (
                                <span className="relative flex h-2.5 w-2.5">
                                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75" />
                                  <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500" />
                                </span>
                              )}
                            </div>
                            <div>
                              <div className="flex items-center gap-2 flex-wrap">
                                <h3 className="text-sm font-bold text-white">{turf.venueName}</h3>
                                <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-[#161D2E] text-slate-300 border border-[#28354F]">
                                  #{turf.turfId}
                                </span>
                                {turf.isBookingHold && (
                                  <span className="text-[10px] px-2 py-0.5 rounded bg-amber-500/15 text-amber-300 border border-amber-500/30 font-semibold font-mono">
                                    HOLD ACTIVE
                                  </span>
                                )}
                              </div>
                              <p className="text-xs text-slate-400 mt-0.5 flex items-center gap-2 font-mono">
                                <span>{turf.neighborhoodArea || 'Tamil Nadu'}</span>
                                <span className="text-slate-600">•</span>
                                <span className="text-slate-400">{turf.ownerPhone}</span>
                              </p>
                              <div className="flex items-center gap-3 mt-2 text-xs font-mono">
                                <span className="text-slate-400">
                                  Today: <strong className="text-white">{turf.todayBookingsCount} slots</strong> (₹{turf.todayRevenue.toLocaleString()})
                                </span>
                                <span className="text-slate-600">•</span>
                                <span className="text-slate-400">
                                  Total: <strong className="text-[#D4FF00]">₹{turf.totalRevenue.toLocaleString()}</strong>
                                </span>
                              </div>
                            </div>
                          </div>

                          {/* Hold / Resume Action */}
                          <div className="flex items-center gap-2 shrink-0">
                            <button
                              type="button"
                              disabled={actionLoadingId === `turf_${turf.turfId}`}
                              onClick={() => handleToggleTurfHold(turf.turfId, turf.isBookingHold)}
                              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-50 active:scale-[0.98] font-mono ${
                                turf.isBookingHold
                                  ? 'bg-emerald-600 hover:bg-emerald-500 text-white shadow-md shadow-emerald-600/20'
                                  : 'bg-[#161D2E] hover:bg-amber-500/20 text-amber-300 border border-amber-500/30'
                              }`}
                            >
                              {turf.isBookingHold ? (
                                <>
                                  <PlayCircle className="w-3.5 h-3.5" />
                                  <span>Resume</span>
                                </>
                              ) : (
                                <>
                                  <PauseCircle className="w-3.5 h-3.5" />
                                  <span>Hold Slots</span>
                                </>
                              )}
                            </button>
                          </div>
                        </div>
                      ))
                    ) : (
                      <div className="p-8 rounded-xl bg-[#0E131F] border border-[#1E273A] text-center text-xs text-slate-400 font-mono">
                        No active turf venues registered yet.
                      </div>
                    )}
                  </div>
                </div>

                {/* Right Column (5 cols): Live Telemetry Stream */}
                <div className="lg:col-span-5 space-y-3.5">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <Terminal className="w-4 h-4 text-emerald-400" />
                      <h2 className="text-sm font-bold text-white tracking-tight uppercase font-mono">
                        Live Operations Stream
                      </h2>
                    </div>
                    <span className="text-[10px] font-mono text-emerald-400 flex items-center gap-1">
                      <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping" />
                      SYNCED
                    </span>
                  </div>

                  <div className="p-3.5 rounded-xl bg-[#05080E] border border-[#1E273A] font-mono text-xs space-y-2.5 max-h-[410px] overflow-y-auto">
                    {overview?.recentLiveActions && overview.recentLiveActions.length > 0 ? (
                      overview.recentLiveActions.map((action, i) => (
                        <div
                          key={action.id || i}
                          className="p-3 rounded-lg bg-[#0E131F] border border-[#1A2234] hover:border-[#2C3B5C] transition-colors"
                        >
                          <div className="flex items-center justify-between text-[10px] text-slate-500 mb-1">
                            <span className="text-slate-400 font-semibold">{action.timestamp}</span>
                            <span
                              className={`px-1.5 py-0.5 rounded text-[9px] font-bold uppercase ${
                                action.type === 'BOOKING'
                                  ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30'
                                  : action.type === 'CANCELLATION'
                                  ? 'bg-rose-500/15 text-rose-400 border border-rose-500/30'
                                  : action.type === 'HOLD'
                                  ? 'bg-amber-500/15 text-amber-400 border border-amber-500/30'
                                  : 'bg-[#D4FF00]/15 text-[#D4FF00] border border-[#D4FF00]/30'
                              }`}
                            >
                              {action.type}
                            </span>
                          </div>
                          <p className="text-xs font-semibold text-slate-200">{action.title}</p>
                          <p className="text-[11px] text-slate-400 mt-0.5 leading-snug">{action.description}</p>
                          {Boolean(action.amount) && (
                            <div className="mt-1 text-[11px] text-[#D4FF00] font-bold">
                              Amount: ₹{action.amount}
                            </div>
                          )}
                        </div>
                      ))
                    ) : (
                      <div className="py-12 text-center text-slate-500 font-mono text-xs">
                        Waiting for platform activity...
                      </div>
                    )}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ========================================================================= */}
          {/* TAB 2: ANALYTICS & INSIGHTS */}
          {/* ========================================================================= */}
          {activeTab === 'ANALYTICS' && (
            <div className="space-y-7 animate-in fade-in duration-200">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3 p-4 rounded-xl bg-[#0E131F] border border-[#1E273A]">
                <div>
                  <h2 className="text-sm font-bold text-white tracking-tight uppercase font-mono">
                    Deep Performance & Revenue Analytics
                  </h2>
                  <p className="text-xs text-slate-400 mt-0.5 font-mono">
                    Granular platform GMV trajectory, advance vs cash settlements, and sport demand splits.
                  </p>
                </div>
              </div>

              {/* Full Chart Suite */}
              <AnalyticsCharts overview={overview} />

              {/* Athlete Leaderboard */}
              <div className="space-y-3.5">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Users className="w-4 h-4 text-sky-400" />
                    <h2 className="text-sm font-bold text-white tracking-tight uppercase font-mono">
                      Athlete Activity & Booking Leaderboard
                    </h2>
                  </div>
                  <span className="text-xs font-mono text-slate-400">
                    {overview?.playerStats?.length || 0} Registered athletes
                  </span>
                </div>

                <div className="rounded-xl bg-[#0E131F] border border-[#1E273A] overflow-hidden">
                  <div className="overflow-x-auto">
                    <table className="w-full text-left border-collapse text-xs">
                      <thead>
                        <tr className="border-b border-[#1E273A] bg-[#0A0E18] text-slate-400 font-mono">
                          <th className="py-3.5 px-4 font-semibold">Player</th>
                          <th className="py-3.5 px-4 font-semibold">Contact</th>
                          <th className="py-3.5 px-4 font-semibold">Total Bookings</th>
                          <th className="py-3.5 px-4 font-semibold">Total Spent</th>
                          <th className="py-3.5 px-4 font-semibold">Favorite Sport</th>
                          <th className="py-3.5 px-4 font-semibold">Last Active</th>
                        </tr>
                      </thead>
                      <tbody className="divide-y divide-[#1A2234] font-mono">
                        {overview?.playerStats && overview.playerStats.length > 0 ? (
                          overview.playerStats.map((p, idx) => (
                            <tr key={idx} className="hover:bg-[#141B2B] transition-colors">
                              <td className="py-3.5 px-4 font-semibold text-white">{p.customerName}</td>
                              <td className="py-3.5 px-4 text-slate-400">{p.customerPhone}</td>
                              <td className="py-3.5 px-4 text-slate-200">
                                <span className="px-2 py-0.5 rounded bg-[#161D2E] text-slate-200 font-bold border border-[#28354F]">
                                  {p.totalBookings} slots
                                </span>
                              </td>
                              <td className="py-3.5 px-4 text-emerald-400 font-bold">
                                ₹{p.totalSpent.toLocaleString()}
                              </td>
                              <td className="py-3.5 px-4">
                                <span className="px-2 py-0.5 rounded text-[10px] bg-[#D4FF00]/10 text-[#D4FF00] border border-[#D4FF00]/20 font-bold uppercase">
                                  {p.favoriteSport || 'Football'}
                                </span>
                              </td>
                              <td className="py-3.5 px-4 text-slate-400">{p.lastBookingDate || 'Recent'}</td>
                            </tr>
                          ))
                        ) : (
                          <tr>
                            <td colSpan={6} className="py-8 text-center text-slate-500 font-mono">
                              No player bookings recorded yet.
                            </td>
                          </tr>
                        )}
                      </tbody>
                    </table>
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* ========================================================================= */}
          {/* TAB 3: REGISTRATIONS & KYC */}
          {/* ========================================================================= */}
          {activeTab === 'REGISTRATIONS' && (
            <div className="space-y-5 animate-in fade-in duration-200">
              {/* Filter Tabs & Search Bar */}
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-4 rounded-xl bg-[#0E131F] border border-[#1E273A]">
                <div className="flex items-center gap-2">
                  <button
                    type="button"
                    onClick={() => setActiveRegTab('WAITING')}
                    className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold font-mono transition-all flex items-center gap-1.5 ${
                      activeRegTab === 'WAITING'
                        ? 'bg-amber-500 text-black font-bold shadow-md shadow-amber-500/20'
                        : 'text-slate-400 hover:text-white hover:bg-[#161D2E]'
                    }`}
                  >
                    <span>Pending Review</span>
                    <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeRegTab === 'WAITING' ? 'bg-black text-amber-300' : 'bg-[#161D2E] text-slate-300'}`}>
                      {regStats.waiting}
                    </span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setActiveRegTab('VERIFIED')}
                    className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold font-mono transition-all flex items-center gap-1.5 ${
                      activeRegTab === 'VERIFIED'
                        ? 'bg-emerald-600 text-white font-bold shadow-md shadow-emerald-600/20'
                        : 'text-slate-400 hover:text-white hover:bg-[#161D2E]'
                    }`}
                  >
                    <span>Verified Venues</span>
                    <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeRegTab === 'VERIFIED' ? 'bg-black/30 text-emerald-200' : 'bg-[#161D2E] text-slate-300'}`}>
                      {regStats.verified}
                    </span>
                  </button>
                  <button
                    type="button"
                    onClick={() => setActiveRegTab('CANCEL')}
                    className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold font-mono transition-all flex items-center gap-1.5 ${
                      activeRegTab === 'CANCEL'
                        ? 'bg-rose-600 text-white font-bold shadow-md shadow-rose-600/20'
                        : 'text-slate-400 hover:text-white hover:bg-[#161D2E]'
                    }`}
                  >
                    <span>Declined</span>
                    <span className={`px-1.5 py-0.2 rounded-full text-[10px] ${activeRegTab === 'CANCEL' ? 'bg-black/30 text-rose-200' : 'bg-[#161D2E] text-slate-300'}`}>
                      {regStats.cancelled}
                    </span>
                  </button>
                </div>

                <div className="relative flex-1 max-w-xs">
                  <Search className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    placeholder="Filter by venue or manager..."
                    value={regSearch}
                    onChange={(e) => setRegSearch(e.target.value)}
                    className="w-full pl-9 pr-3 py-1.5 bg-[#05080E] border border-[#1E273A] rounded-lg text-xs text-white placeholder-slate-500 focus:outline-hidden focus:border-[#D4FF00] font-mono"
                  />
                </div>
              </div>

              {/* Registrations List */}
              {regLoading ? (
                <div className="py-20 flex flex-col items-center justify-center text-slate-400">
                  <RefreshCw className="w-8 h-8 animate-spin text-[#D4FF00] mb-3" />
                  <span className="text-xs font-mono">Fetching partner applications...</span>
                </div>
              ) : regItems.length === 0 ? (
                <div className="py-16 text-center rounded-xl bg-[#0E131F] border border-[#1E273A] p-8">
                  <FileCheck2 className="w-10 h-10 text-slate-600 mx-auto mb-2" />
                  <h3 className="text-sm font-bold text-slate-300">No applications in this category</h3>
                  <p className="text-xs text-slate-500 mt-1">All venue registrations are up to date.</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {regItems.map((reg) => (
                    <div
                      key={reg.id}
                      className="p-5 rounded-xl bg-[#0E131F] border border-[#1E273A] hover:border-[#2C3B5C] transition-all flex flex-col md:flex-row md:items-center justify-between gap-4"
                    >
                      <div>
                        <div className="flex items-center gap-2 flex-wrap">
                          <span className="font-mono text-[10px] px-2 py-0.5 rounded bg-[#161D2E] text-slate-300 border border-[#28354F]">
                            {reg.trackingCode || `#REG-${reg.id}`}
                          </span>
                          <h3 className="text-base font-bold text-white">{reg.venueName}</h3>
                          {reg.isBranch && (
                            <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-sky-500/15 text-sky-300 border border-sky-500/30 font-mono">
                              <Building2 className="w-3 h-3 text-sky-400" /> NEW BRANCH REQUEST
                            </span>
                          )}
                          {reg.status === 'PENDING_APPROVAL' && (
                            <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-500/15 text-amber-300 border border-amber-500/30 font-mono">
                              <span className="w-1.5 h-1.5 rounded-full bg-amber-400 animate-ping" />
                              REVIEW NEEDED
                            </span>
                          )}
                          {reg.status === 'VERIFIED' && (
                            <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-500/15 text-emerald-300 border border-emerald-500/30 font-mono">
                              VERIFIED ACTIVE
                            </span>
                          )}
                        </div>

                        {reg.isBranch && (
                          <div className="mt-2.5 p-2.5 rounded-lg bg-sky-950/30 border border-sky-800/50 flex flex-wrap items-center gap-x-4 gap-y-1.5 text-xs">
                            <div className="flex items-center gap-1.5">
                              <span className="text-sky-400 font-bold flex items-center gap-1 text-[11px] font-mono">
                                <Building2 className="w-3.5 h-3.5 text-sky-400" /> Parent Turf:
                              </span>
                              <span className="font-bold text-white bg-sky-900/40 px-2 py-0.5 rounded border border-sky-700/50">
                                {reg.parentTurfName || reg.parentTurf?.venueName || 'Primary Turf'}
                              </span>
                            </div>
                            <div className="flex items-center gap-1.5">
                              <span className="text-slate-400 text-[11px] font-mono">Owner Mobile:</span>
                              <span className="font-mono font-bold text-emerald-400 bg-emerald-950/40 px-2 py-0.5 rounded border border-emerald-800/40">
                                {reg.parentTurfPhone || reg.ownerPhone}
                              </span>
                            </div>
                            {reg.alternativePhone && (
                              <div className="flex items-center gap-1.5">
                                <span className="text-slate-400 text-[11px] font-mono">Branch Phone:</span>
                                <span className="font-mono text-sky-300 bg-[#161D2E] px-2 py-0.5 rounded border border-[#28354F]">
                                  {reg.alternativePhone}
                                </span>
                              </div>
                            )}
                          </div>
                        )}

                        <p className="text-xs text-slate-400 mt-1 flex items-center gap-2 flex-wrap">
                          <span>Owner: <strong className="text-slate-200">{reg.ownerName}</strong></span>
                          <span className="text-slate-600">•</span>
                          <span className="font-mono">{reg.ownerPhone}</span>
                          {reg.alternativePhone && (
                            <>
                              <span className="text-slate-600">•</span>
                              <span className="font-mono text-sky-400">Alt: {reg.alternativePhone}</span>
                            </>
                          )}
                          <span className="text-slate-600">•</span>
                          <span>{reg.neighborhoodArea}</span>
                        </p>

                        <div className="flex items-center gap-2.5 mt-2.5 text-[11px] font-mono text-slate-400 flex-wrap">
                          <span className="flex items-center gap-1">
                            Aadhaar: {reg.aadhaarNumber ? <strong className="text-emerald-400 flex items-center gap-1"><Check className="w-3 h-3" /> On File</strong> : <span className="text-slate-500">—</span>}
                          </span>
                          <span className="text-slate-600">•</span>
                          <span className="flex items-center gap-1">
                            PAN: {reg.panNumber ? <strong className="text-emerald-400 flex items-center gap-1"><Check className="w-3 h-3" /> On File</strong> : <span className="text-slate-500">—</span>}
                          </span>
                          <span className="text-slate-600">•</span>
                          <span className="flex items-center gap-1">
                            UPI: {reg.upiId ? <span className="text-slate-300">{reg.upiId}</span> : <span className="text-slate-500">—</span>}
                          </span>
                        </div>

                        {/* Venue Photos Preview Strip */}
                        {reg.photoUrls && reg.photoUrls.length > 0 && (
                          <div className="flex items-center gap-2 mt-3 overflow-x-auto py-1">
                            <span className="text-[10px] text-[#D4FF00] font-mono font-medium flex items-center gap-1 shrink-0">
                              <ImageIcon className="w-3 h-3" /> {reg.photoUrls.length} Photos:
                            </span>
                            <div className="flex items-center gap-1.5">
                              {reg.photoUrls.slice(0, 4).map((photoUrl, pIdx) => (
                                <button
                                  key={pIdx}
                                  type="button"
                                  onClick={() => setSelectedReg(reg)}
                                  className="w-14 h-10 rounded-md overflow-hidden border border-[#232C42] bg-[#161D2E] shrink-0 hover:border-[#D4FF00] transition-all group relative focus:outline-hidden"
                                  title={`View Photo ${pIdx + 1}`}
                                >
                                  {/* eslint-disable-next-line @next/next/no-img-element */}
                                  <img
                                    src={getFullFileUrl(photoUrl)}
                                    alt={`Venue photo ${pIdx + 1}`}
                                    className="w-full h-full object-cover group-hover:scale-110 transition-transform duration-200"
                                  />
                                  <div className="absolute inset-0 bg-black/20 group-hover:bg-transparent transition-colors" />
                                </button>
                              ))}
                              {reg.photoUrls.length > 4 && (
                                <span className="text-[10px] text-slate-500 font-mono">
                                  +{reg.photoUrls.length - 4}
                                </span>
                              )}
                            </div>
                          </div>
                        )}
                      </div>

                      <div className="flex items-center gap-2 shrink-0">
                        <button
                          onClick={() => setSelectedReg(reg)}
                          className="px-3.5 py-1.5 rounded-lg text-xs font-semibold bg-[#161D2E] hover:bg-[#20293F] text-slate-200 hover:text-white border border-[#28354F] transition-all font-mono"
                        >
                          Inspect Dossier
                        </button>

                        {reg.status === 'PENDING_APPROVAL' && (
                          <>
                            <button
                              disabled={quickVerifyingId === reg.id || !isRegComplete(reg)}
                              onClick={() => handleQuickVerify(reg)}
                              className="flex items-center gap-1.5 px-3.5 py-1.5 rounded-lg text-xs font-bold bg-[#D4FF00] hover:bg-[#b8dd00] text-black shadow-md shadow-[#D4FF00]/15 transition-all disabled:opacity-40 disabled:cursor-not-allowed active:scale-[0.98] font-mono"
                              title={!isRegComplete(reg) ? 'Incomplete application - cannot verify' : 'Approve and activate'}
                            >
                              <Check className="w-3.5 h-3.5 stroke-[2.5]" />
                              <span>{quickVerifyingId === reg.id ? 'Approving...' : 'Approve & Activate'}</span>
                            </button>
                            <button
                              onClick={() => {
                                setCancelModalItem(reg);
                                setCancelReasonText('');
                              }}
                              className="px-3 py-1.5 rounded-lg text-xs font-semibold text-rose-300 bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/30 transition-all font-mono"
                            >
                              Reject
                            </button>
                          </>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* ========================================================================= */}
          {/* TAB 4: BOOKINGS & HOLDS */}
          {/* ========================================================================= */}
          {activeTab === 'BOOKINGS' && (
            <div className="space-y-5 animate-in fade-in duration-200">
              {/* Filter Toolbar */}
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-4 rounded-xl bg-[#0E131F] border border-[#1E273A]">
                <div className="relative flex-1 max-w-md">
                  <Search className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    placeholder="Search by player phone, booking code, or turf..."
                    value={bookingSearch}
                    onChange={(e) => setBookingSearch(e.target.value)}
                    className="w-full pl-9 pr-3 py-2 bg-[#05080E] border border-[#1E273A] rounded-lg text-xs text-white placeholder-slate-500 focus:outline-hidden focus:border-[#D4FF00] font-mono"
                  />
                </div>

                <div className="flex items-center gap-2">
                  <select
                    value={bookingStatusFilter}
                    onChange={(e) => setBookingStatusFilter(e.target.value)}
                    className="px-3 py-2 bg-[#05080E] border border-[#1E273A] rounded-lg text-xs text-slate-200 focus:outline-hidden focus:border-[#D4FF00] font-mono"
                  >
                    <option value="ALL">All Statuses</option>
                    <option value="CONFIRMED">Confirmed Slots</option>
                    <option value="HOLD">Slots on Hold</option>
                    <option value="CANCELLED">Cancelled</option>
                  </select>
                </div>
              </div>

              {/* Bookings List */}
              {bookingsLoading ? (
                <div className="py-20 flex flex-col items-center justify-center text-slate-400">
                  <RefreshCw className="w-8 h-8 animate-spin text-[#D4FF00] mb-3" />
                  <span className="text-xs font-mono">Fetching reservation logs...</span>
                </div>
              ) : bookings.length === 0 ? (
                <div className="py-16 text-center rounded-xl bg-[#0E131F] border border-[#1E273A] p-8">
                  <CalendarDays className="w-10 h-10 text-slate-600 mx-auto mb-2" />
                  <h3 className="text-sm font-bold text-slate-300">No bookings match the filter</h3>
                  <p className="text-xs text-slate-500 mt-1">Try modifying your search or status query.</p>
                </div>
              ) : (
                <div className="space-y-3">
                  {bookings.map((booking) => (
                    <div
                      key={booking.id}
                      className="p-5 rounded-xl bg-[#0E131F] border border-[#1E273A] hover:border-[#2C3B5C] transition-all flex flex-col md:flex-row md:items-center justify-between gap-4"
                    >
                      <div>
                        <div className="flex items-center gap-2 flex-wrap">
                          <span className="font-mono text-xs px-2 py-0.5 rounded bg-[#161D2E] text-slate-200 font-bold border border-[#28354F]">
                            {booking.bookingCode || `#BK-${booking.id}`}
                          </span>
                          <span className="text-xs font-semibold px-2 py-0.5 rounded-full bg-[#D4FF00]/10 text-[#D4FF00] border border-[#D4FF00]/20 font-mono uppercase">
                            {booking.sport}
                          </span>
                          {booking.status === 'CONFIRMED' && (
                            <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-500/15 text-emerald-300 border border-emerald-500/30 font-mono">
                              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                              CONFIRMED
                            </span>
                          )}
                          {booking.isHold && (
                            <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-500/15 text-amber-300 border border-amber-500/30 font-mono">
                              SLOT HOLD ACTIVE
                            </span>
                          )}
                          {booking.status === 'CANCELLED' && (
                            <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-rose-500/15 text-rose-300 border border-rose-500/30 font-mono">
                              CANCELLED
                            </span>
                          )}
                          {booking.isOpenMatch && (
                            <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded bg-rose-950/60 text-rose-300 border border-rose-800/40 font-mono">
                              <Swords className="w-3 h-3 text-rose-400" /> OPEN CHALLENGE
                            </span>
                          )}
                        </div>

                        <div className="mt-1.5">
                          <h4 className="text-sm font-bold text-white">
                            {booking.verifiedAdmin?.venueName || 'Turf Venue'} • {booking.courtName}
                          </h4>
                          <p className="text-xs text-slate-400 mt-0.5 flex items-center gap-2 flex-wrap font-mono">
                            <span className="flex items-center gap-1">
                              <Calendar className="w-3.5 h-3.5 text-slate-400" />
                              {booking.date}
                            </span>
                            <span className="text-slate-600">•</span>
                            <span className="flex items-center gap-1">
                              <Clock className="w-3.5 h-3.5 text-slate-400" />
                              {booking.timeSlot}
                            </span>
                            <span className="text-slate-600">•</span>
                            <span className="flex items-center gap-1">
                              <User className="w-3.5 h-3.5 text-slate-400" />
                              <strong className="text-slate-200">{booking.customerName}</strong> ({booking.customerPhone})
                            </span>
                          </p>
                        </div>

                        <div className="mt-2 text-xs font-mono text-slate-400 flex items-center gap-3">
                          <span className="text-white font-bold">Total: ₹{booking.amount}</span>
                          <span className="text-slate-600">•</span>
                          <span>Mode: {booking.paymentMethod}</span>
                        </div>
                      </div>

                      <div className="flex items-center gap-2 shrink-0">
                        {booking.status !== 'CANCELLED' && (
                          <>
                            <button
                              type="button"
                              disabled={actionLoadingId === `book_${booking.id}`}
                              onClick={() => handleToggleBookingHold(booking.id, booking.isHold)}
                              className={`px-3.5 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-50 active:scale-[0.98] font-mono ${
                                booking.isHold
                                  ? 'bg-emerald-600 hover:bg-emerald-500 text-white'
                                  : 'bg-[#161D2E] hover:bg-amber-500/20 text-amber-300 border border-amber-500/30'
                              }`}
                            >
                              {booking.isHold ? 'Release Hold' : 'Hold Slot'}
                            </button>
                            <button
                              type="button"
                              disabled={actionLoadingId === `cancel_book_${booking.id}`}
                              onClick={() => handleCancelBooking(booking.id)}
                              className="px-3 py-1.5 rounded-lg text-xs font-semibold text-rose-300 bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/30 transition-all disabled:opacity-50 font-mono"
                            >
                              Cancel Slot
                            </button>
                          </>
                        )}
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* ========================================================================= */}
          {/* TAB 5: TOURNAMENTS */}
          {/* ========================================================================= */}
          {activeTab === 'TOURNAMENTS' && (
            <div className="space-y-5 animate-in fade-in duration-200">
              <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-4 rounded-xl bg-[#0E131F] border border-[#1E273A]">
                <div>
                  <h2 className="text-sm font-bold text-white tracking-tight uppercase font-mono">
                    Tournaments & Championship Management
                  </h2>
                  <p className="text-xs text-slate-400 mt-0.5 font-mono">
                    Squad registrations, cash prize pool audits, and active participation controls.
                  </p>
                </div>

                <div className="flex items-center gap-3">
                  <select
                    value={tournStatusFilter}
                    onChange={(e) => setTournStatusFilter(e.target.value)}
                    className="px-3 py-1.5 bg-[#05080E] border border-[#1E273A] rounded-lg text-xs text-slate-200 font-mono"
                  >
                    <option value="ALL">All Tournaments</option>
                    <option value="LIVE">Live Now</option>
                    <option value="UPCOMING">Upcoming</option>
                    <option value="ON_HOLD">On Hold</option>
                  </select>

                  <button
                    onClick={() => setShowCreateTournModal(true)}
                    className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold bg-[#D4FF00] hover:bg-[#b8dd00] text-black shadow-md shadow-[#D4FF00]/15 transition-all font-mono"
                  >
                    <Plus className="w-3.5 h-3.5 stroke-[2.5]" />
                    <span>Deploy New</span>
                  </button>
                </div>
              </div>

              {tournLoading ? (
                <div className="py-20 flex flex-col items-center justify-center text-slate-400">
                  <RefreshCw className="w-8 h-8 animate-spin text-[#D4FF00] mb-3" />
                  <span className="text-xs font-mono">Loading tournaments...</span>
                </div>
              ) : tournaments.length === 0 ? (
                <div className="py-16 text-center rounded-xl bg-[#0E131F] border border-[#1E273A] p-8">
                  <Trophy className="w-10 h-10 text-slate-600 mx-auto mb-2" />
                  <h3 className="text-sm font-bold text-slate-300">No tournaments registered</h3>
                  <p className="text-xs text-slate-500 mt-1">Deploy an official tournament to attract athletic squads.</p>
                </div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                  {tournaments.map((tourn) => (
                    <div
                      key={tourn.id}
                      className="p-5 rounded-xl bg-[#0E131F] border border-[#1E273A] hover:border-[#D4FF00]/40 transition-all flex flex-col justify-between"
                    >
                      <div>
                        <div className="flex items-center justify-between gap-2 mb-2">
                          <span className="text-xs font-semibold px-2 py-0.5 rounded-md bg-[#D4FF00]/10 text-[#D4FF00] border border-[#D4FF00]/20 font-mono uppercase">
                            {tourn.sport}
                          </span>
                          {tourn.status === 'LIVE' ? (
                            <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-500/15 text-emerald-300 border border-emerald-500/30 font-mono">
                              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping" />
                              LIVE CHAMPIONSHIP
                            </span>
                          ) : tourn.isHold ? (
                            <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-500/15 text-amber-300 border border-amber-500/30 font-mono">
                              ON HOLD
                            </span>
                          ) : (
                            <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-[#161D2E] text-slate-300 font-mono">
                              UPCOMING
                            </span>
                          )}
                        </div>

                        <h3 className="text-base font-bold text-white">{tourn.title}</h3>
                        <p className="text-xs text-slate-400 mt-1 flex items-center gap-1.5 font-mono">
                          <MapPin className="w-3.5 h-3.5 text-[#D4FF00] shrink-0" />
                          <span>{tourn.venueName}</span>
                        </p>

                        <div className="mt-4 pt-3 border-t border-[#1E273A] space-y-2 text-xs font-mono">
                          <div className="flex items-center justify-between text-slate-400">
                            <span>Prize Pool:</span>
                            <span className="text-[#D4FF00] font-bold text-sm">{tourn.prizePool}</span>
                          </div>
                          <div className="flex items-center justify-between text-slate-400">
                            <span>Entry Fee:</span>
                            <span className="text-white font-semibold">₹{tourn.entryFee} / squad</span>
                          </div>
                          <div>
                            <div className="flex items-center justify-between text-slate-400 mb-1">
                              <span>Squads:</span>
                              <span className="text-slate-200 font-bold">{tourn.registeredTeams || 0} / {tourn.maxTeams || 16}</span>
                            </div>
                            <div className="w-full h-1.5 rounded-full bg-[#161D2E] overflow-hidden">
                              <div
                                className="h-full bg-[#D4FF00] rounded-full transition-all"
                                style={{
                                  width: `${Math.min(100, Math.round(((tourn.registeredTeams || 0) / (tourn.maxTeams || 16)) * 100))}%`,
                                }}
                              />
                            </div>
                          </div>
                        </div>
                      </div>

                      <div className="mt-5 pt-3 border-t border-[#1E273A] flex items-center justify-between gap-2">
                        <span className="text-[11px] font-mono text-slate-400 flex items-center gap-1">
                          <Calendar className="w-3 h-3" />
                          {tourn.date}
                        </span>
                        <div className="flex items-center gap-1.5">
                          <button
                            type="button"
                            disabled={actionLoadingId === `tourn_${tourn.id}`}
                            onClick={() => handleToggleTournHold(tourn.id, tourn.isHold)}
                            className={`px-3 py-1 rounded-lg text-xs font-bold transition-all disabled:opacity-50 active:scale-[0.98] font-mono ${
                              tourn.isHold
                                ? 'bg-emerald-600 hover:bg-emerald-500 text-white'
                                : 'bg-[#161D2E] text-amber-300 border border-amber-500/30 hover:bg-amber-500/20'
                            }`}
                          >
                            {tourn.isHold ? 'Resume' : 'Hold'}
                          </button>
                          <button
                            type="button"
                            disabled={actionLoadingId === `del_tourn_${tourn.id}`}
                            onClick={() => setDeleteConfirmTourn(tourn)}
                            className="p-1.5 rounded-lg text-rose-400 hover:text-white hover:bg-rose-600/30 border border-rose-500/30 transition-all disabled:opacity-50"
                            title="Delete Tournament Permanently"
                          >
                            <Trash2 className="w-3.5 h-3.5" />
                          </button>
                        </div>
                      </div>
                    </div>
                  ))}
                </div>
              )}
            </div>
          )}

          {/* ========================================================================= */}
          {/* TAB 6: TURFS DIRECTORY */}
          {/* ========================================================================= */}
          {activeTab === 'TURFS' && (
            <div className="space-y-5 animate-in fade-in duration-200">
              <div className="p-4 rounded-xl bg-[#0E131F] border border-[#1E273A] flex flex-col sm:flex-row sm:items-center justify-between gap-3">
                <div>
                  <h2 className="text-sm font-bold text-white tracking-tight uppercase font-mono">
                    Venue Financials & Commission Auditing
                  </h2>
                  <p className="text-xs text-slate-400 mt-0.5 font-mono">
                    Detailed revenue reconciliation, active hourly rates, and booking hold switches.
                  </p>
                </div>
                <Link
                  href="/admins"
                  className="px-3.5 py-1.5 rounded-lg text-xs font-semibold bg-[#161D2E] hover:bg-[#20293F] text-slate-200 hover:text-white border border-[#28354F] transition-all font-mono self-start sm:self-auto flex items-center gap-1.5"
                >
                  <span>Full Directory</span>
                  <ChevronRight className="w-3.5 h-3.5" />
                </Link>
              </div>

              <div className="rounded-xl bg-[#0E131F] border border-[#1E273A] overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse text-xs">
                    <thead>
                      <tr className="border-b border-[#1E273A] bg-[#0A0E18] text-slate-400 font-mono">
                        <th className="py-3.5 px-4 font-semibold">Turf Venue</th>
                        <th className="py-3.5 px-4 font-semibold">Location</th>
                        <th className="py-3.5 px-4 font-semibold">Today&apos;s Revenue</th>
                        <th className="py-3.5 px-4 font-semibold">Today&apos;s Slots</th>
                        <th className="py-3.5 px-4 font-semibold">All-Time GMV</th>
                        <th className="py-3.5 px-4 font-semibold">Booking State</th>
                        <th className="py-3.5 px-4 font-semibold">Actions</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-[#1A2234] font-mono">
                      {overview?.turfRevenueBreakdown && overview.turfRevenueBreakdown.length > 0 ? (
                        overview.turfRevenueBreakdown.map((t) => (
                          <tr key={t.turfId} className="hover:bg-[#141B2B] transition-colors">
                            <td className="py-3.5 px-4 font-semibold text-white">
                              {t.venueName}
                              <span className="block text-[10px] text-slate-500 font-normal">
                                Mgr: {t.ownerName} ({t.ownerPhone})
                              </span>
                            </td>
                            <td className="py-3.5 px-4 text-slate-300">{t.neighborhoodArea}</td>
                            <td className="py-3.5 px-4 text-emerald-400 font-bold">
                              ₹{t.todayRevenue.toLocaleString()}
                            </td>
                            <td className="py-3.5 px-4 text-slate-200">
                              {t.todayBookingsCount} booked
                              {t.todayCancelled > 0 && (
                                <span className="text-rose-400 block text-[10px]">
                                  ({t.todayCancelled} cancelled)
                                </span>
                              )}
                            </td>
                            <td className="py-3.5 px-4 text-[#D4FF00] font-bold">
                              ₹{t.totalRevenue.toLocaleString()}
                            </td>
                            <td className="py-3.5 px-4">
                              {t.isBookingHold ? (
                                <span className="px-2 py-0.5 rounded bg-amber-500/15 text-amber-300 border border-amber-500/30 text-[10px] font-bold">
                                  HOLD ACTIVE
                                </span>
                              ) : (
                                <span className="px-2 py-0.5 rounded bg-emerald-500/15 text-emerald-300 border border-emerald-500/30 text-[10px] font-bold">
                                  LIVE & OPEN
                                </span>
                              )}
                            </td>
                            <td className="py-3.5 px-4">
                              <div className="flex items-center gap-1.5">
                                <button
                                  type="button"
                                  disabled={actionLoadingId === `turf_${t.turfId}`}
                                  onClick={() => handleToggleTurfHold(t.turfId, t.isBookingHold)}
                                  className={`px-2.5 py-1 rounded-md text-xs font-semibold transition-all disabled:opacity-50 active:scale-[0.98] font-mono ${
                                    t.isBookingHold
                                      ? 'bg-emerald-600 hover:bg-emerald-500 text-white'
                                      : 'bg-[#161D2E] text-amber-300 border border-amber-500/30 hover:bg-amber-500/20'
                                  }`}
                                >
                                  {t.isBookingHold ? 'Resume' : 'Hold'}
                                </button>
                                <button
                                  type="button"
                                  disabled={actionLoadingId === `del_turf_${t.turfId}`}
                                  onClick={() => setDeleteConfirmTurf({ turfId: t.turfId, venueName: t.venueName, ownerName: t.ownerName })}
                                  className="p-1 rounded-md text-rose-400 hover:text-white hover:bg-rose-600/30 border border-rose-500/30 transition-all disabled:opacity-50"
                                  title="Delete Venue & Turf Owner"
                                >
                                  <Trash2 className="w-3.5 h-3.5" />
                                </button>
                              </div>
                            </td>
                          </tr>
                        ))
                      ) : (
                        <tr>
                          <td colSpan={7} className="py-8 text-center text-slate-500 font-mono">
                            No revenue records available.
                          </td>
                        </tr>
                      )}
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          )}
        </main>
      </div>

      {/* ========================================================================= */}
      {/* MODALS */}
      {/* ========================================================================= */}

      {/* Registration KYC Inspection Modal */}
      {selectedReg && (
        <RegistrationDetailModal
          registration={selectedReg}
          onClose={() => setSelectedReg(null)}
          onActionComplete={() => {
            loadRegistrations();
            loadOverview();
          }}
        />
      )}

      {/* Cancel Reason Modal */}
      {cancelModalItem && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4">
          <div className="bg-[#0E131F] border border-[#232B3E] rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl animate-in fade-in zoom-in-95 duration-150">
            <h3 className="text-base font-bold text-white font-mono">
              Decline Registration Application
            </h3>
            <p className="text-xs text-slate-400 font-mono">
              Provide a clear reason for declining the venue application for{' '}
              <strong className="text-slate-200">{cancelModalItem.venueName}</strong>:
            </p>
            <textarea
              rows={3}
              value={cancelReasonText}
              onChange={(e) => setCancelReasonText(e.target.value)}
              placeholder="e.g. Document photograph illegible, GST certificate mismatch, turf photos missing..."
              className="w-full p-3 bg-[#05080E] border border-[#1E273A] rounded-lg text-xs text-white placeholder-slate-500 focus:outline-hidden focus:border-rose-500 font-mono"
            />
            <div className="flex items-center justify-end gap-2 pt-2 font-mono">
              <button
                type="button"
                onClick={() => setCancelModalItem(null)}
                className="px-3.5 py-1.5 rounded-lg text-xs font-semibold text-slate-400 hover:text-white"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleQuickCancelConfirm}
                className="px-4 py-1.5 rounded-lg text-xs font-bold bg-rose-600 hover:bg-rose-500 text-white transition-all active:scale-[0.98]"
              >
                Confirm Rejection
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Create Tournament Modal */}
      {showCreateTournModal && (
        <div className="fixed inset-0 z-50 bg-black/80 backdrop-blur-md flex items-center justify-center p-4">
          <div className="bg-[#0E131F] border border-[#1E273A] rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between pb-3 border-b border-[#1E273A]">
              <div className="flex items-center gap-2">
                <Trophy className="w-5 h-5 text-[#D4FF00]" />
                <h3 className="text-base font-bold text-white font-mono">Deploy Tournament</h3>
              </div>
              <button
                onClick={() => setShowCreateTournModal(false)}
                className="text-slate-400 hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleCreateTournament} className="space-y-3.5 text-xs font-mono">
              <div>
                <label className="block text-slate-400 font-medium mb-1">Tournament Title *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Chennai Super League 2026"
                  value={newTournTitle}
                  onChange={(e) => setNewTournTitle(e.target.value)}
                  className="w-full px-3 py-2 bg-[#05080E] border border-[#1E273A] rounded-lg text-white placeholder-slate-500 focus:outline-hidden focus:border-[#D4FF00]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-400 font-medium mb-1">Sport</label>
                  <select
                    value={newTournSport}
                    onChange={(e) => setNewTournSport(e.target.value)}
                    className="w-full px-3 py-2 bg-[#05080E] border border-[#1E273A] rounded-lg text-white focus:outline-hidden focus:border-[#D4FF00]"
                  >
                    <option value="Football">Football</option>
                    <option value="Cricket">Cricket</option>
                    <option value="Badminton">Badminton</option>
                    <option value="Pickleball">Pickleball</option>
                  </select>
                </div>
                <div>
                  <label className="block text-slate-400 font-medium mb-1">Date *</label>
                  <input
                    type="date"
                    required
                    value={newTournDate}
                    onChange={(e) => setNewTournDate(e.target.value)}
                    className="w-full px-3 py-2 bg-[#05080E] border border-[#1E273A] rounded-lg text-white focus:outline-hidden focus:border-[#D4FF00]"
                  />
                </div>
              </div>

              <div>
                <label className="block text-slate-400 font-medium mb-1">Venue Name / Location *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Kickoff Arena, Anna Nagar"
                  value={newTournVenue}
                  onChange={(e) => setNewTournVenue(e.target.value)}
                  className="w-full px-3 py-2 bg-[#05080E] border border-[#1E273A] rounded-lg text-white placeholder-slate-500 focus:outline-hidden focus:border-[#D4FF00]"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-400 font-medium mb-1">Entry Fee (₹)</label>
                  <input
                    type="number"
                    value={newTournEntryFee}
                    onChange={(e) => setNewTournEntryFee(e.target.value)}
                    className="w-full px-3 py-2 bg-[#05080E] border border-[#1E273A] rounded-lg text-white focus:outline-hidden focus:border-[#D4FF00]"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 font-medium mb-1">Prize Pool</label>
                  <input
                    type="text"
                    value={newTournPrize}
                    onChange={(e) => setNewTournPrize(e.target.value)}
                    className="w-full px-3 py-2 bg-[#05080E] border border-[#1E273A] rounded-lg text-white focus:outline-hidden focus:border-[#D4FF00]"
                  />
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-3 border-t border-[#1E273A]">
                <button
                  type="button"
                  onClick={() => setShowCreateTournModal(false)}
                  className="px-3.5 py-2 rounded-lg text-xs font-semibold text-slate-400 hover:text-white"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-lg text-xs font-bold bg-[#D4FF00] hover:bg-[#b8dd00] text-black shadow-lg shadow-[#D4FF00]/15 transition-all active:scale-[0.98]"
                >
                  Deploy Tournament
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Delete Tournament Confirmation Modal */}
      {deleteConfirmTourn && (
        <div className="fixed inset-0 z-60 bg-black/80 backdrop-blur-md flex items-center justify-center p-4">
          <div className="bg-[#0E131F] border border-rose-500/40 rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center gap-3 text-rose-400">
              <div className="w-10 h-10 rounded-xl bg-rose-500/15 border border-rose-500/30 flex items-center justify-center">
                <AlertTriangle className="w-5 h-5 text-rose-400" />
              </div>
              <div>
                <h3 className="text-base font-bold text-white font-mono">Permanently Delete Tournament?</h3>
                <p className="text-xs text-slate-400 font-mono">Irreversible super admin removal</p>
              </div>
            </div>

            <div className="p-4 rounded-xl bg-[#161014] border border-rose-500/20 text-xs text-slate-300 space-y-2">
              <p>
                You are about to delete tournament <strong className="text-white">&quot;{deleteConfirmTourn.title}&quot;</strong> at{' '}
                <strong className="text-white">{deleteConfirmTourn.venueName}</strong>.
              </p>
              <ul className="list-disc pl-4 space-y-1 text-slate-400 font-mono text-[11px]">
                <li>Tournament will be removed from player discovery and tournament schedules.</li>
                <li>Registered squad slots and team applications will be terminated.</li>
              </ul>
            </div>

            <div className="flex items-center justify-end gap-3 pt-2 font-mono">
              <button
                type="button"
                onClick={() => setDeleteConfirmTourn(null)}
                className="px-4 py-2 rounded-lg text-xs font-semibold text-slate-300 hover:text-white bg-[#161D2E] border border-[#28354F]"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={actionLoadingId === `del_tourn_${deleteConfirmTourn.id}`}
                onClick={() => handleDeleteTournament(deleteConfirmTourn.id)}
                className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-bold bg-rose-600 hover:bg-rose-500 text-white shadow-lg shadow-rose-600/30 disabled:opacity-50 active:scale-[0.98]"
              >
                {actionLoadingId === `del_tourn_${deleteConfirmTourn.id}` ? (
                  <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                ) : (
                  <Trash2 className="w-3.5 h-3.5" />
                )}
                <span>Confirm Deletion</span>
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Turf Owner Confirmation Modal */}
      {deleteConfirmTurf && (
        <div className="fixed inset-0 z-60 bg-black/80 backdrop-blur-md flex items-center justify-center p-4">
          <div className="bg-[#0E131F] border border-rose-500/40 rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center gap-3 text-rose-400">
              <div className="w-10 h-10 rounded-xl bg-rose-500/15 border border-rose-500/30 flex items-center justify-center">
                <AlertTriangle className="w-5 h-5 text-rose-400" />
              </div>
              <div>
                <h3 className="text-base font-bold text-white font-mono">Permanently Delete Turf Owner?</h3>
                <p className="text-xs text-slate-400 font-mono">Irreversible super admin removal</p>
              </div>
            </div>

            <div className="p-4 rounded-xl bg-[#161014] border border-rose-500/20 text-xs text-slate-300 space-y-2">
              <p>
                You are about to delete <strong className="text-white">{deleteConfirmTurf.venueName}</strong>
                {deleteConfirmTurf.ownerName ? ` managed by ${deleteConfirmTurf.ownerName}` : ''}.
              </p>
              <ul className="list-disc pl-4 space-y-1 text-slate-400 font-mono text-[11px]">
                <li>Venue will be immediately removed from player app turf listings.</li>
                <li>All bookings, slot offers, and open challenges will be removed.</li>
                <li>Owner portal account will be terminated.</li>
              </ul>
            </div>

            <div className="flex items-center justify-end gap-3 pt-2 font-mono">
              <button
                type="button"
                onClick={() => setDeleteConfirmTurf(null)}
                className="px-4 py-2 rounded-lg text-xs font-semibold text-slate-300 hover:text-white bg-[#161D2E] border border-[#28354F]"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={actionLoadingId === `del_turf_${deleteConfirmTurf.turfId}`}
                onClick={() => handleDeleteTurf(deleteConfirmTurf.turfId)}
                className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-bold bg-rose-600 hover:bg-rose-500 text-white shadow-lg shadow-rose-600/30 disabled:opacity-50 active:scale-[0.98]"
              >
                {actionLoadingId === `del_turf_${deleteConfirmTurf.turfId}` ? (
                  <RefreshCw className="w-3.5 h-3.5 animate-spin" />
                ) : (
                  <Trash2 className="w-3.5 h-3.5" />
                )}
                <span>Confirm Permanent Deletion</span>
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
