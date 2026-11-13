'use client';

import { useState, useEffect, useCallback } from 'react';
import Navbar from '@/components/Navbar';
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
  BACKEND_URL,
} from '@/lib/api';
import {
  ShieldCheck,
  CheckCircle2,
  XCircle,
  Clock,
  AlertCircle,
  AlertTriangle,
  Trash2,
  Building,
  Calendar,
  Users,
  Trophy,
  Activity,
  ArrowUpRight,
  TrendingUp,
  DollarSign,
  Phone,
  Mail,
  MapPin,
  ExternalLink,
  PauseCircle,
  PlayCircle,
  Plus,
  RefreshCw,
  Search,
  Filter,
  Check,
  X,
  FileCheck2,
  CalendarDays,
  LayoutDashboard,
  Image as ImageIcon,
  Layers,
  ChevronRight,
  Sparkles,
  Tag,
  CreditCard,
  Building2,
  Terminal,
  Radio,
} from 'lucide-react';
import Link from 'next/link';

export default function SuperAdminDashboard() {
  const [activeSection, setActiveSection] = useState<'OVERVIEW' | 'REGISTRATIONS' | 'BOOKINGS' | 'TOURNAMENTS' | 'TURFS'>('OVERVIEW');

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

  // Toast state
  const [toastMessage, setToastMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const showToast = (text: string, type: 'success' | 'error' = 'success') => {
    setToastMessage({ text, type });
    setTimeout(() => setToastMessage(null), 4000);
  };

  const getFullFileUrl = (url: string | null) => {
    if (!url) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return `${BACKEND_URL}${url.startsWith('/') ? '' : '/'}${url}`;
  };

  // Load Overview Data
  const loadOverview = useCallback(async () => {
    setOverviewLoading(true);
    try {
      const data = await getDashboardOverview();
      setOverview(data);
    } catch (err: any) {
      showToast(err.message || 'Error loading dashboard metrics', 'error');
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
        search: regSearch,
        limit: 50,
      });

      setRegItems(data.items);
      setRegStats(data.stats);
    } catch (err: any) {
      showToast(err.message || 'Error loading registrations', 'error');
    } finally {
      setRegLoading(false);
    }
  }, [activeRegTab, regSearch]);

  // Load Bookings
  const loadBookings = useCallback(async () => {
    setBookingsLoading(true);
    try {
      const data = await getAllBookings({
        search: bookingSearch,
        status: bookingStatusFilter === 'ALL' ? undefined : bookingStatusFilter,
        limit: 50,
      });
      setBookings(data.items);
    } catch (err: any) {
      showToast(err.message || 'Error loading bookings', 'error');
    } finally {
      setBookingsLoading(false);
    }
  }, [bookingSearch, bookingStatusFilter]);

  // Load Tournaments
  const loadTournaments = useCallback(async () => {
    setTournLoading(true);
    try {
      const data = await getAllTournaments({
        status: tournStatusFilter === 'ALL' ? undefined : tournStatusFilter,
      });
      setTournaments(data.items);
    } catch (err: any) {
      showToast(err.message || 'Error loading tournaments', 'error');
    } finally {
      setTournLoading(false);
    }
  }, [tournStatusFilter]);

  // Initial load
  useEffect(() => {
    loadOverview();
  }, [loadOverview]);

  useEffect(() => {
    if (activeSection === 'REGISTRATIONS') loadRegistrations();
    if (activeSection === 'BOOKINGS') loadBookings();
    if (activeSection === 'TOURNAMENTS') loadTournaments();
  }, [activeSection, loadRegistrations, loadBookings, loadTournaments]);

  // ACTION: Hold / Resume Turf Bookings
  const handleToggleTurfHold = async (turfId: number, currentHold: boolean) => {
    setActionLoadingId(`turf_${turfId}`);
    try {
      const res = await toggleTurfBookingHold(turfId, !currentHold);
      showToast(res.message);
      loadOverview();
    } catch (err: any) {
      showToast(err.message || 'Failed to update turf booking hold status', 'error');
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
    } catch (err: any) {
      showToast(err.message || 'Failed to update booking hold status', 'error');
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
    } catch (err: any) {
      showToast(err.message || 'Failed to cancel booking', 'error');
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
    } catch (err: any) {
      showToast(err.message || 'Failed to update tournament hold', 'error');
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
    } catch (err: any) {
      showToast(err.message || 'Failed to delete tournament', 'error');
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
    } catch (err: any) {
      showToast(err.message || 'Failed to delete turf owner account', 'error');
    } finally {
      setActionLoadingId(null);
    }
  };

  // ACTION: Quick Verify Registration
  const handleQuickVerify = async (reg: AdminRegistration) => {
    setQuickVerifyingId(reg.id);
    try {
      await verifyRegistration(reg.id, { verifiedBy: 'Super Admin' });
      showToast(`Venue "${reg.venueName}" successfully verified & activated!`);
      loadRegistrations();
      loadOverview();
    } catch (err: any) {
      showToast(err.message || 'Failed to verify registration', 'error');
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
    } catch (err: any) {
      showToast(err.message || 'Failed to cancel registration', 'error');
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
    } catch (err: any) {
      showToast(err.message || 'Error creating tournament', 'error');
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

  return (
    <div className="min-h-screen flex flex-col bg-[#090D16] text-slate-100 font-sans">
      <Navbar
        waitingCount={regStats.waiting || kpis.pendingOwners}
        activeSection={activeSection}
        onSelectSection={(sec) => setActiveSection(sec as any)}
      />

      {/* Floating Toast Notification */}
      {toastMessage && (
        <div className="fixed top-20 right-6 z-50 animate-in fade-in slide-in-from-top-4 duration-200">
          <div
            className={`flex items-center gap-2.5 px-4 py-3 rounded-xl shadow-2xl border text-xs font-semibold backdrop-blur-md ${
              toastMessage.type === 'success'
                ? 'bg-[#0E1D19] text-emerald-300 border-emerald-500/40 shadow-emerald-500/10'
                : 'bg-[#220E14] text-rose-300 border-rose-500/40 shadow-rose-500/10'
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

      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-8">
        {/* Render-style Project Header Bar */}
        <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 pb-6 border-b border-[#1E2638]">
          <div>
            <div className="flex items-center gap-2 text-xs text-slate-400 font-mono mb-1.5">
              <span>Games24 Platform</span>
              <span className="text-slate-600">/</span>
              <span className="text-indigo-400 font-semibold">Production Console</span>
              <span className="text-slate-600">/</span>
              <span className="text-slate-200">{activeSection}</span>
            </div>
            <h1 className="text-2xl sm:text-3xl font-extrabold text-white tracking-tight flex items-center gap-3">
              <span>Control Center</span>
              <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30">
                <span className="relative flex h-2 w-2">
                  <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                  <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
                </span>
                Live Oversight
              </span>
            </h1>
            <p className="text-xs text-slate-400 mt-1 max-w-2xl">
              Render-grade live audit console for managing turf approvals, active slot holds, real-time match oversight, and tournament coordination.
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={() => {
                loadOverview();
                if (activeSection === 'BOOKINGS') loadBookings();
                if (activeSection === 'TOURNAMENTS') loadTournaments();
                if (activeSection === 'REGISTRATIONS') loadRegistrations();
              }}
              disabled={overviewLoading}
              className="flex items-center gap-2 px-3.5 py-2 rounded-lg text-xs font-semibold bg-[#161D2F] hover:bg-[#1E273E] text-slate-300 hover:text-white border border-[#28354F] transition-all disabled:opacity-50"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${overviewLoading ? 'animate-spin text-indigo-400' : 'text-slate-400'}`} />
              <span>Sync Metrics</span>
            </button>

            <button
              onClick={() => setShowCreateTournModal(true)}
              className="flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold bg-indigo-600 hover:bg-indigo-500 text-white shadow-lg shadow-indigo-600/25 transition-all"
            >
              <Plus className="w-4 h-4" />
              <span>Deploy Tournament</span>
            </button>
          </div>
        </div>

        {/* Render-style KPI Metrics Grid (6 Cards) */}
        <div className="grid grid-cols-2 md:grid-cols-3 lg:grid-cols-6 gap-3 sm:gap-4">
          {/* Card 1: Total Revenue / GMV */}
          <div className="p-4 rounded-xl bg-[#111625] border border-[#1F293D] hover:border-indigo-500/40 transition-all duration-200">
            <div className="flex items-center justify-between text-xs text-slate-400 mb-2">
              <span className="font-medium">Total GMV</span>
              <span className="p-1 rounded-md bg-indigo-500/10 text-indigo-400">
                <DollarSign className="w-3.5 h-3.5" />
              </span>
            </div>
            <div className="font-mono text-xl sm:text-2xl font-extrabold text-white tracking-tight">
              ₹{kpis.totalRevenue.toLocaleString()}
            </div>
            <div className="mt-2 text-[11px] text-slate-400 flex items-center justify-between font-mono">
              <span>All-Time Volume</span>
              <span className="text-emerald-400">Live</span>
            </div>
          </div>

          {/* Card 2: Today's Bookings */}
          <div className="p-4 rounded-xl bg-[#111625] border border-[#1F293D] hover:border-indigo-500/40 transition-all duration-200">
            <div className="flex items-center justify-between text-xs text-slate-400 mb-2">
              <span className="font-medium">Today&apos;s Slots</span>
              <span className="p-1 rounded-md bg-emerald-500/10 text-emerald-400">
                <CalendarDays className="w-3.5 h-3.5" />
              </span>
            </div>
            <div className="font-mono text-xl sm:text-2xl font-extrabold text-white tracking-tight flex items-baseline gap-1.5">
              <span>{kpis.todayBookingsCount}</span>
              <span className="text-xs text-emerald-400 font-normal">confirmed</span>
            </div>
            <div className="mt-2 text-[11px] text-slate-400 flex items-center justify-between font-mono">
              <span>₹{kpis.todayRevenue.toLocaleString()} GMV</span>
              {kpis.todayCancelledCount > 0 && (
                <span className="text-rose-400 font-semibold">{kpis.todayCancelledCount} cnl</span>
              )}
            </div>
          </div>

          {/* Card 3: Partner Turfs */}
          <div className="p-4 rounded-xl bg-[#111625] border border-[#1F293D] hover:border-indigo-500/40 transition-all duration-200">
            <div className="flex items-center justify-between text-xs text-slate-400 mb-2">
              <span className="font-medium">Turf Venues</span>
              <span className="p-1 rounded-md bg-indigo-500/10 text-indigo-400">
                <Building2 className="w-3.5 h-3.5" />
              </span>
            </div>
            <div className="font-mono text-xl sm:text-2xl font-extrabold text-white tracking-tight">
              {kpis.verifiedOwners}
            </div>
            <div className="mt-2 text-[11px] text-slate-400 flex items-center justify-between font-mono">
              <span className="text-emerald-400 flex items-center gap-1">
                <span className="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
                Active Live
              </span>
              <span>{kpis.totalOwners} total</span>
            </div>
          </div>

          {/* Card 4: Registered Customers */}
          <div className="p-4 rounded-xl bg-[#111625] border border-[#1F293D] hover:border-indigo-500/40 transition-all duration-200">
            <div className="flex items-center justify-between text-xs text-slate-400 mb-2">
              <span className="font-medium">Players</span>
              <span className="p-1 rounded-md bg-indigo-500/10 text-indigo-400">
                <Users className="w-3.5 h-3.5" />
              </span>
            </div>
            <div className="font-mono text-xl sm:text-2xl font-extrabold text-white tracking-tight">
              {kpis.totalUsers}
            </div>
            <div className="mt-2 text-[11px] text-slate-400 flex items-center justify-between font-mono">
              <span>OTP Verified</span>
              <span className="text-indigo-400">100%</span>
            </div>
          </div>

          {/* Card 5: Tournaments */}
          <div className="p-4 rounded-xl bg-[#111625] border border-[#1F293D] hover:border-indigo-500/40 transition-all duration-200">
            <div className="flex items-center justify-between text-xs text-slate-400 mb-2">
              <span className="font-medium">Tournaments</span>
              <span className="p-1 rounded-md bg-purple-500/10 text-purple-400">
                <Trophy className="w-3.5 h-3.5" />
              </span>
            </div>
            <div className="font-mono text-xl sm:text-2xl font-extrabold text-white tracking-tight flex items-baseline gap-1.5">
              <span>{tournSummary.live}</span>
              <span className="text-xs text-purple-400 font-normal">live now</span>
            </div>
            <div className="mt-2 text-[11px] text-slate-400 flex items-center justify-between font-mono">
              <span>{tournSummary.upcoming} upcoming</span>
              <span>{tournSummary.total} total</span>
            </div>
          </div>

          {/* Card 6: Pending KYC Approvals */}
          <div
            onClick={() => setActiveSection('REGISTRATIONS')}
            className={`p-4 rounded-xl border transition-all duration-200 cursor-pointer ${
              kpis.pendingOwners > 0
                ? 'bg-amber-500/10 border-amber-500/30 hover:border-amber-500/60'
                : 'bg-[#111625] border-[#1F293D] hover:border-indigo-500/40'
            }`}
          >
            <div className="flex items-center justify-between text-xs text-slate-400 mb-2">
              <span className="font-medium">Pending KYC</span>
              <span
                className={`p-1 rounded-md ${
                  kpis.pendingOwners > 0 ? 'bg-amber-500/20 text-amber-300' : 'bg-slate-800 text-slate-400'
                }`}
              >
                <FileCheck2 className="w-3.5 h-3.5" />
              </span>
            </div>
            <div
              className={`font-mono text-xl sm:text-2xl font-extrabold tracking-tight ${
                kpis.pendingOwners > 0 ? 'text-amber-300' : 'text-white'
              }`}
            >
              {kpis.pendingOwners}
            </div>
            <div className="mt-2 text-[11px] flex items-center justify-between font-mono">
              {kpis.pendingOwners > 0 ? (
                <span className="text-amber-400 font-semibold animate-pulse">Needs Review →</span>
              ) : (
                <span className="text-slate-500">Up to date ✓</span>
              )}
            </div>
          </div>
        </div>

        {/* ========================================================================= */}
        {/* SECTION 1: LIVE OVERVIEW & PLATFORM INSIGHTS */}
        {/* ========================================================================= */}
        {activeSection === 'OVERVIEW' && (
          <div className="space-y-8 animate-in fade-in duration-200">
            {/* Split row: Connected Turfs & Real-time Live Actions Stream */}
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
              {/* Left Column (7 cols): Connected Turfs as Render Service Cards */}
              <div className="lg:col-span-7 space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Building2 className="w-4 h-4 text-indigo-400" />
                    <h2 className="text-base font-bold text-white tracking-tight">
                      Active Turf Services & Booking Controls
                    </h2>
                  </div>
                  <button
                    onClick={() => setActiveSection('TURFS')}
                    className="text-xs text-indigo-400 hover:text-indigo-300 font-semibold flex items-center gap-1"
                  >
                    <span>View All Venues</span>
                    <ChevronRight className="w-3.5 h-3.5" />
                  </button>
                </div>

                <div className="space-y-3">
                  {overview?.turfRevenueBreakdown && overview.turfRevenueBreakdown.length > 0 ? (
                    overview.turfRevenueBreakdown.map((turf) => (
                      <div
                        key={turf.turfId}
                        className="p-4 rounded-xl bg-[#111625] border border-[#1F293D] hover:border-[#2E3C58] transition-all flex flex-col sm:flex-row sm:items-center justify-between gap-4"
                      >
                        <div className="flex items-start gap-3">
                          <div className="mt-1">
                            {turf.isBookingHold ? (
                              <span className="relative flex h-2.5 w-2.5">
                                <span className="inline-flex rounded-full h-2.5 w-2.5 bg-amber-400"></span>
                              </span>
                            ) : (
                              <span className="relative flex h-2.5 w-2.5">
                                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                                <span className="relative inline-flex rounded-full h-2.5 w-2.5 bg-emerald-500"></span>
                              </span>
                            )}
                          </div>
                          <div>
                            <div className="flex items-center gap-2">
                              <h3 className="text-sm font-bold text-white">{turf.venueName}</h3>
                              <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-[#182033] text-indigo-300 border border-[#28354F]">
                                #{turf.turfId}
                              </span>
                              {turf.isBookingHold && (
                                <span className="text-[10px] px-2 py-0.5 rounded bg-amber-500/15 text-amber-300 border border-amber-500/30 font-semibold">
                                  Hold Active
                                </span>
                              )}
                            </div>
                            <p className="text-xs text-slate-400 mt-0.5 flex items-center gap-2">
                              <span>{turf.neighborhoodArea || 'Chennai'}</span>
                              <span className="text-slate-600">•</span>
                              <span className="font-mono text-slate-400">{turf.ownerPhone}</span>
                            </p>
                            <div className="flex items-center gap-3 mt-2 text-xs font-mono">
                              <span className="text-slate-400">
                                Today: <strong className="text-white">{turf.todayBookingsCount} slots</strong> (₹{turf.todayRevenue.toLocaleString()})
                              </span>
                              <span className="text-slate-600">•</span>
                              <span className="text-slate-400">
                                All-Time: <strong className="text-indigo-300">₹{turf.totalRevenue.toLocaleString()}</strong>
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
                            className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-50 ${
                              turf.isBookingHold
                                ? 'bg-emerald-600 hover:bg-emerald-500 text-white shadow-md shadow-emerald-600/20'
                                : 'bg-[#182033] hover:bg-amber-600/20 text-amber-300 border border-amber-500/30'
                            }`}
                          >
                            {turf.isBookingHold ? (
                              <>
                                <PlayCircle className="w-3.5 h-3.5" />
                                <span>Resume Bookings</span>
                              </>
                            ) : (
                              <>
                                <PauseCircle className="w-3.5 h-3.5" />
                                <span>Hold Bookings</span>
                              </>
                            )}
                          </button>
                        </div>
                      </div>
                    ))
                  ) : (
                    <div className="p-8 rounded-xl bg-[#111625] border border-[#1F293D] text-center text-xs text-slate-400 font-mono">
                      No active turf venues registered yet.
                    </div>
                  )}
                </div>
              </div>

              {/* Right Column (5 cols): Render-style Live Event Stream & Match Log */}
              <div className="lg:col-span-5 space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <Terminal className="w-4 h-4 text-emerald-400" />
                    <h2 className="text-base font-bold text-white tracking-tight">
                      Live Operations Stream
                    </h2>
                  </div>
                  <span className="text-[10px] font-mono text-emerald-400 flex items-center gap-1">
                    <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping"></span>
                    Realtime Sync
                  </span>
                </div>

                <div className="p-4 rounded-xl bg-[#0B0F19] border border-[#1E2638] font-mono text-xs space-y-3 max-h-[390px] overflow-y-auto">
                  {overview?.recentLiveActions && overview.recentLiveActions.length > 0 ? (
                    overview.recentLiveActions.map((action, i) => (
                      <div
                        key={action.id || i}
                        className="p-3 rounded-lg bg-[#111727] border border-[#1A2338] hover:border-[#2C3B5C] transition-colors"
                      >
                        <div className="flex items-center justify-between text-[10px] text-slate-500 mb-1">
                          <span className="text-slate-400 font-semibold">{action.timestamp}</span>
                          <span
                            className={`px-1.5 py-0.2 rounded text-[9px] font-bold uppercase ${
                              action.type === 'BOOKING'
                                ? 'bg-emerald-500/15 text-emerald-400 border border-emerald-500/30'
                                : action.type === 'CANCELLATION'
                                ? 'bg-rose-500/15 text-rose-400 border border-rose-500/30'
                                : action.type === 'HOLD'
                                ? 'bg-amber-500/15 text-amber-400 border border-amber-500/30'
                                : 'bg-indigo-500/15 text-indigo-400 border border-indigo-500/30'
                            }`}
                          >
                            {action.type}
                          </span>
                        </div>
                        <p className="text-xs font-semibold text-slate-200">{action.title}</p>
                        <p className="text-[11px] text-slate-400 mt-0.5">{action.description}</p>
                        {Boolean(action.amount) && (
                          <div className="mt-1 text-[11px] text-indigo-400 font-bold">
                            Amount: ₹{action.amount}
                          </div>
                        )}
                      </div>
                    ))
                  ) : (
                    <div className="py-12 text-center text-slate-500">
                      Waiting for platform activity...
                    </div>
                  )}
                </div>
              </div>
            </div>

            {/* Top Frequent Players Leaderboard */}
            <div className="space-y-4">
              <div className="flex items-center justify-between">
                <div className="flex items-center gap-2">
                  <Users className="w-4 h-4 text-indigo-400" />
                  <h2 className="text-base font-bold text-white tracking-tight">
                    Active Customers & Player Statistics
                  </h2>
                </div>
                <span className="text-xs font-mono text-slate-400">
                  {overview?.playerStats?.length || 0} Registered active users
                </span>
              </div>

              <div className="rounded-xl bg-[#111625] border border-[#1F293D] overflow-hidden">
                <div className="overflow-x-auto">
                  <table className="w-full text-left border-collapse text-xs">
                    <thead>
                      <tr className="border-b border-[#1E2638] bg-[#0E1321] text-slate-400 font-mono">
                        <th className="py-3 px-4 font-semibold">Player Name</th>
                        <th className="py-3 px-4 font-semibold">Contact</th>
                        <th className="py-3 px-4 font-semibold">Total Bookings</th>
                        <th className="py-3 px-4 font-semibold">Total Spent</th>
                        <th className="py-3 px-4 font-semibold">Fav Sport</th>
                        <th className="py-3 px-4 font-semibold">Last Active</th>
                      </tr>
                    </thead>
                    <tbody className="divide-y divide-[#1C2538] font-mono">
                      {overview?.playerStats && overview.playerStats.length > 0 ? (
                        overview.playerStats.map((p, idx) => (
                          <tr key={idx} className="hover:bg-[#151C2F] transition-colors">
                            <td className="py-3 px-4 font-semibold text-white">{p.customerName}</td>
                            <td className="py-3 px-4 text-slate-400">{p.customerPhone}</td>
                            <td className="py-3 px-4 text-slate-200">
                              <span className="px-2 py-0.5 rounded bg-[#182033] text-indigo-300 font-bold border border-[#28354F]">
                                {p.totalBookings} slots
                              </span>
                            </td>
                            <td className="py-3 px-4 text-emerald-400 font-bold">
                              ₹{p.totalSpent.toLocaleString()}
                            </td>
                            <td className="py-3 px-4">
                              <span className="px-2 py-0.5 rounded-full text-[10px] bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 font-bold">
                                {p.favoriteSport || 'Cricket'}
                              </span>
                            </td>
                            <td className="py-3 px-4 text-slate-400">{p.lastBookingDate || 'Recent'}</td>
                          </tr>
                        ))
                      ) : (
                        <tr>
                          <td colSpan={6} className="py-8 text-center text-slate-500">
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
        {/* SECTION 2: APPROVALS & OWNER REGISTRATIONS */}
        {/* ========================================================================= */}
        {activeSection === 'REGISTRATIONS' && (
          <div className="space-y-6 animate-in fade-in duration-200">
            {/* Filter Tabs & Search */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-4 rounded-xl bg-[#111625] border border-[#1F293D]">
              <div className="flex items-center gap-2">
                <button
                  type="button"
                  onClick={() => setActiveRegTab('WAITING')}
                  className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                    activeRegTab === 'WAITING'
                      ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/25'
                      : 'text-slate-400 hover:text-white hover:bg-[#182033]'
                  }`}
                >
                  Pending Review ({regStats.waiting})
                </button>
                <button
                  type="button"
                  onClick={() => setActiveRegTab('VERIFIED')}
                  className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                    activeRegTab === 'VERIFIED'
                      ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/25'
                      : 'text-slate-400 hover:text-white hover:bg-[#182033]'
                  }`}
                >
                  Verified Venues ({regStats.verified})
                </button>
                <button
                  type="button"
                  onClick={() => setActiveRegTab('CANCEL')}
                  className={`px-3.5 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                    activeRegTab === 'CANCEL'
                      ? 'bg-indigo-600 text-white shadow-md shadow-indigo-600/25'
                      : 'text-slate-400 hover:text-white hover:bg-[#182033]'
                  }`}
                >
                  Cancelled ({regStats.cancelled})
                </button>
              </div>

              <div className="relative flex-1 max-w-xs">
                <Search className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  placeholder="Filter by venue or owner..."
                  value={regSearch}
                  onChange={(e) => setRegSearch(e.target.value)}
                  className="w-full pl-9 pr-3 py-1.5 bg-[#161D2F] border border-[#28354F] rounded-lg text-xs text-white placeholder-slate-500 focus:outline-hidden focus:border-indigo-500"
                />
              </div>
            </div>

            {/* Registrations List */}
            {regLoading ? (
              <div className="py-20 flex flex-col items-center justify-center text-slate-400">
                <RefreshCw className="w-8 h-8 animate-spin text-indigo-400 mb-3" />
                <span className="text-xs font-mono">Loading venue applications...</span>
              </div>
            ) : regItems.length === 0 ? (
              <div className="py-16 text-center rounded-xl bg-[#111625] border border-[#1F293D] p-8">
                <FileCheck2 className="w-10 h-10 text-slate-600 mx-auto mb-2" />
                <h3 className="text-sm font-bold text-slate-300">No applications in this category</h3>
                <p className="text-xs text-slate-500 mt-1">All venue registrations are up to date.</p>
              </div>
            ) : (
              <div className="space-y-3">
                {regItems.map((reg) => (
                  <div
                    key={reg.id}
                    className="p-4 rounded-xl bg-[#111625] border border-[#1F293D] hover:border-[#2C3B5C] transition-all flex flex-col md:flex-row md:items-center justify-between gap-4"
                  >
                    <div>
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="font-mono text-[10px] px-2 py-0.5 rounded bg-[#182033] text-indigo-300 border border-[#28354F]">
                          {reg.trackingCode || `#REG-${reg.id}`}
                        </span>
                        <h3 className="text-sm font-bold text-white">{reg.venueName}</h3>
                        {reg.isBranch && (
                          <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-cyan-500/15 text-cyan-300 border border-cyan-500/30">
                            🏢 New Branch Request
                          </span>
                        )}
                        {reg.status === 'PENDING_APPROVAL' && (
                          <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-500/15 text-amber-300 border border-amber-500/30">
                            <span className="w-1.5 h-1.5 rounded-full bg-amber-400 animate-ping"></span>
                            Review Needed
                          </span>
                        )}
                        {reg.status === 'VERIFIED' && (
                          <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                            Verified Active
                          </span>
                        )}
                      </div>

                      <p className="text-xs text-slate-400 mt-1 flex items-center gap-2 flex-wrap">
                        <span>Owner: <strong className="text-slate-300">{reg.ownerName}</strong></span>
                        <span className="text-slate-600">•</span>
                        <span className="font-mono">{reg.ownerPhone}</span>
                        {reg.alternativePhone && (
                          <>
                            <span className="text-slate-600">•</span>
                            <span className="font-mono text-cyan-400">Alt: {reg.alternativePhone}</span>
                          </>
                        )}
                        <span className="text-slate-600">•</span>
                        <span>{reg.neighborhoodArea}</span>
                      </p>

                      <div className="flex items-center gap-2 mt-2 text-[11px] font-mono text-slate-400">
                        <span>Aadhaar: {reg.aadhaarNumber ? '✓ Provided' : '—'}</span>
                        <span className="text-slate-600">•</span>
                        <span>PAN: {reg.panNumber ? '✓ Provided' : '—'}</span>
                        <span className="text-slate-600">•</span>
                        <span>UPI: {reg.upiId || '—'}</span>
                      </div>

                      {/* Venue Photos Preview Strip */}
                      {reg.photoUrls && reg.photoUrls.length > 0 && (
                        <div className="flex items-center gap-2 mt-3 overflow-x-auto py-1">
                          <span className="text-[10px] text-indigo-400 font-mono font-medium flex items-center gap-1 shrink-0">
                            <ImageIcon className="w-3 h-3" /> {reg.photoUrls.length} Photos:
                          </span>
                          <div className="flex items-center gap-1.5">
                            {reg.photoUrls.slice(0, 4).map((photoUrl, pIdx) => (
                              <button
                                key={pIdx}
                                type="button"
                                onClick={() => setSelectedReg(reg)}
                                className="w-14 h-10 rounded-md overflow-hidden border border-[#232C42] bg-[#161D2F] shrink-0 hover:border-indigo-500/60 transition-all group relative focus:outline-hidden"
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
                        className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#182033] hover:bg-[#222D47] text-slate-300 hover:text-white border border-[#28354F] transition-all"
                      >
                        Inspect KYC
                      </button>

                      {reg.status === 'PENDING_APPROVAL' && (
                        <>
                          <button
                            disabled={quickVerifyingId === reg.id}
                            onClick={() => handleQuickVerify(reg)}
                            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold bg-indigo-600 hover:bg-indigo-500 text-white shadow-md shadow-indigo-600/20 transition-all disabled:opacity-50"
                          >
                            <Check className="w-3.5 h-3.5" />
                            <span>{quickVerifyingId === reg.id ? 'Approving...' : 'Approve'}</span>
                          </button>
                          <button
                            onClick={() => {
                              setCancelModalItem(reg);
                              setCancelReasonText('');
                            }}
                            className="px-3 py-1.5 rounded-lg text-xs font-semibold text-rose-300 bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/30 transition-all"
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
        {/* SECTION 3: BOOKINGS & HOLDS */}
        {/* ========================================================================= */}
        {activeSection === 'BOOKINGS' && (
          <div className="space-y-6 animate-in fade-in duration-200">
            {/* Filter Toolbar */}
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-4 rounded-xl bg-[#111625] border border-[#1F293D]">
              <div className="relative flex-1 max-w-md">
                <Search className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  placeholder="Search by customer phone, booking code, or turf..."
                  value={bookingSearch}
                  onChange={(e) => setBookingSearch(e.target.value)}
                  className="w-full pl-9 pr-3 py-2 bg-[#161D2F] border border-[#28354F] rounded-lg text-xs text-white placeholder-slate-500 focus:outline-hidden focus:border-indigo-500"
                />
              </div>

              <div className="flex items-center gap-2">
                <select
                  value={bookingStatusFilter}
                  onChange={(e) => setBookingStatusFilter(e.target.value)}
                  className="px-3 py-2 bg-[#161D2F] border border-[#28354F] rounded-lg text-xs text-slate-200 focus:outline-hidden focus:border-indigo-500 font-mono"
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
                <RefreshCw className="w-8 h-8 animate-spin text-indigo-400 mb-3" />
                <span className="text-xs font-mono">Fetching booking records...</span>
              </div>
            ) : bookings.length === 0 ? (
              <div className="py-16 text-center rounded-xl bg-[#111625] border border-[#1F293D] p-8">
                <CalendarDays className="w-10 h-10 text-slate-600 mx-auto mb-2" />
                <h3 className="text-sm font-bold text-slate-300">No bookings match the filter</h3>
                <p className="text-xs text-slate-500 mt-1">Try modifying your search or status query.</p>
              </div>
            ) : (
              <div className="space-y-3">
                {bookings.map((booking) => (
                  <div
                    key={booking.id}
                    className="p-4 rounded-xl bg-[#111625] border border-[#1F293D] hover:border-[#2C3B5C] transition-all flex flex-col md:flex-row md:items-center justify-between gap-4"
                  >
                    <div>
                      <div className="flex items-center gap-2 flex-wrap">
                        <span className="font-mono text-xs px-2 py-0.5 rounded bg-[#182033] text-indigo-300 font-bold border border-[#28354F]">
                          {booking.bookingCode || `#BK-${booking.id}`}
                        </span>
                        <span className="text-xs font-semibold px-2 py-0.5 rounded-full bg-indigo-500/10 text-indigo-300 border border-indigo-500/20">
                          {booking.sport}
                        </span>
                        {booking.status === 'CONFIRMED' && (
                          <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
                            Confirmed
                          </span>
                        )}
                        {booking.isHold && (
                          <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-500/15 text-amber-300 border border-amber-500/30">
                            Slot Hold Active
                          </span>
                        )}
                        {booking.status === 'CANCELLED' && (
                          <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-rose-500/15 text-rose-300 border border-rose-500/30">
                            Cancelled
                          </span>
                        )}
                        {booking.isOpenMatch && (
                          <span className="text-[10px] font-bold px-2 py-0.5 rounded bg-rose-950/60 text-rose-300 border border-rose-800/40">
                            ⚔️ Open Challenge
                          </span>
                        )}
                      </div>

                      <div className="mt-1.5">
                        <h4 className="text-sm font-bold text-white">
                          {booking.verifiedAdmin?.venueName || 'Turf Venue'} • {booking.courtName}
                        </h4>
                        <p className="text-xs text-slate-400 mt-0.5 flex items-center gap-2 flex-wrap font-mono">
                          <span>📅 {booking.date}</span>
                          <span className="text-slate-600">•</span>
                          <span>⏰ {booking.timeSlot}</span>
                          <span className="text-slate-600">•</span>
                          <span>Player: <strong className="text-slate-200">{booking.customerName}</strong> ({booking.customerPhone})</span>
                        </p>
                      </div>

                      <div className="mt-2 text-xs font-mono text-slate-400 flex items-center gap-3">
                        <span className="text-white font-bold">Total: ₹{booking.amount}</span>
                        <span className="text-slate-600">•</span>
                        <span>Pay Mode: {booking.paymentMethod}</span>
                      </div>
                    </div>

                    <div className="flex items-center gap-2 shrink-0">
                      {booking.status !== 'CANCELLED' && (
                        <>
                          <button
                            type="button"
                            disabled={actionLoadingId === `book_${booking.id}`}
                            onClick={() => handleToggleBookingHold(booking.id, booking.isHold)}
                            className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all disabled:opacity-50 ${
                              booking.isHold
                                ? 'bg-emerald-600 hover:bg-emerald-500 text-white'
                                : 'bg-[#182033] hover:bg-amber-500/20 text-amber-300 border border-amber-500/30'
                            }`}
                          >
                            {booking.isHold ? 'Release Hold' : 'Hold Slot'}
                          </button>
                          <button
                            type="button"
                            disabled={actionLoadingId === `cancel_book_${booking.id}`}
                            onClick={() => handleCancelBooking(booking.id)}
                            className="px-3 py-1.5 rounded-lg text-xs font-semibold text-rose-300 bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/30 transition-all disabled:opacity-50"
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
        {/* SECTION 4: TOURNAMENTS OVERSIGHT */}
        {/* ========================================================================= */}
        {activeSection === 'TOURNAMENTS' && (
          <div className="space-y-6 animate-in fade-in duration-200">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 p-4 rounded-xl bg-[#111625] border border-[#1F293D]">
              <div>
                <h2 className="text-base font-bold text-white tracking-tight">
                  Tournaments & Championship Management
                </h2>
                <p className="text-xs text-slate-400 mt-0.5">
                  Real-time team registrations, hold toggles, and cash prize pool audits.
                </p>
              </div>

              <div className="flex items-center gap-3">
                <select
                  value={tournStatusFilter}
                  onChange={(e) => setTournStatusFilter(e.target.value)}
                  className="px-3 py-1.5 bg-[#161D2F] border border-[#28354F] rounded-lg text-xs text-slate-200 font-mono"
                >
                  <option value="ALL">All Tournaments</option>
                  <option value="LIVE">Live Now</option>
                  <option value="UPCOMING">Upcoming</option>
                  <option value="ON_HOLD">On Hold</option>
                </select>

                <button
                  onClick={() => setShowCreateTournModal(true)}
                  className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold bg-indigo-600 hover:bg-indigo-500 text-white shadow-md shadow-indigo-600/20 transition-all"
                >
                  <Plus className="w-3.5 h-3.5" />
                  <span>Deploy New</span>
                </button>
              </div>
            </div>

            {tournLoading ? (
              <div className="py-20 flex flex-col items-center justify-center text-slate-400">
                <RefreshCw className="w-8 h-8 animate-spin text-indigo-400 mb-3" />
                <span className="text-xs font-mono">Loading tournaments...</span>
              </div>
            ) : tournaments.length === 0 ? (
              <div className="py-16 text-center rounded-xl bg-[#111625] border border-[#1F293D] p-8">
                <Trophy className="w-10 h-10 text-slate-600 mx-auto mb-2" />
                <h3 className="text-sm font-bold text-slate-300">No tournaments registered</h3>
                <p className="text-xs text-slate-500 mt-1">Deploy your first tournament to attract squads.</p>
              </div>
            ) : (
              <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
                {tournaments.map((tourn) => (
                  <div
                    key={tourn.id}
                    className="p-5 rounded-xl bg-[#111625] border border-[#1F293D] hover:border-indigo-500/40 transition-all flex flex-col justify-between"
                  >
                    <div>
                      <div className="flex items-center justify-between gap-2 mb-2">
                        <span className="text-xs font-semibold px-2 py-0.5 rounded-full bg-indigo-500/10 text-indigo-300 border border-indigo-500/20">
                          {tourn.sport}
                        </span>
                        {tourn.status === 'LIVE' ? (
                          <span className="inline-flex items-center gap-1 text-[10px] font-bold px-2 py-0.5 rounded-full bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping"></span>
                            Live Championship
                          </span>
                        ) : tourn.isHold ? (
                          <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-amber-500/15 text-amber-300 border border-amber-500/30">
                            On Hold
                          </span>
                        ) : (
                          <span className="text-[10px] font-bold px-2 py-0.5 rounded-full bg-slate-800 text-slate-300">
                            Upcoming
                          </span>
                        )}
                      </div>

                      <h3 className="text-base font-bold text-white">{tourn.title}</h3>
                      <p className="text-xs text-slate-400 mt-1 flex items-center gap-1.5">
                        <MapPin className="w-3.5 h-3.5 text-indigo-400 shrink-0" />
                        <span>{tourn.venueName}</span>
                      </p>

                      <div className="mt-3 pt-3 border-t border-[#1C2538] space-y-1.5 text-xs font-mono">
                        <div className="flex items-center justify-between text-slate-400">
                          <span>Prize Pool:</span>
                          <span className="text-amber-300 font-bold">{tourn.prizePool}</span>
                        </div>
                        <div className="flex items-center justify-between text-slate-400">
                          <span>Entry Fee:</span>
                          <span className="text-white font-semibold">₹{tourn.entryFee} / squad</span>
                        </div>
                        <div className="flex items-center justify-between text-slate-400">
                          <span>Teams Registered:</span>
                          <span className="text-indigo-300 font-bold">{tourn.registeredTeams || 0} / {tourn.maxTeams || 16}</span>
                        </div>
                      </div>
                    </div>

                    <div className="mt-5 pt-3 border-t border-[#1C2538] flex items-center justify-between gap-2">
                      <span className="text-[11px] font-mono text-slate-400">📅 {tourn.date}</span>
                      <div className="flex items-center gap-1.5">
                        <button
                          type="button"
                          disabled={actionLoadingId === `tourn_${tourn.id}`}
                          onClick={() => handleToggleTournHold(tourn.id, tourn.isHold)}
                          className={`px-3 py-1 rounded-lg text-xs font-bold transition-all disabled:opacity-50 ${
                            tourn.isHold
                              ? 'bg-emerald-600 hover:bg-emerald-500 text-white'
                              : 'bg-[#182033] text-amber-300 border border-amber-500/30 hover:bg-amber-500/20'
                          }`}
                        >
                          {tourn.isHold ? 'Resume' : 'Hold'}
                        </button>
                        <button
                          type="button"
                          disabled={actionLoadingId === `del_tourn_${tourn.id}`}
                          onClick={() => setDeleteConfirmTourn(tourn)}
                          className="p-1 rounded-lg text-rose-400 hover:text-white hover:bg-rose-600/30 border border-rose-500/30 transition-all disabled:opacity-50"
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
        {/* SECTION 5: TURF REVENUES & RECONCILIATION */}
        {/* ========================================================================= */}
        {activeSection === 'TURFS' && (
          <div className="space-y-6 animate-in fade-in duration-200">
            <div className="p-4 rounded-xl bg-[#111625] border border-[#1F293D] flex items-center justify-between">
              <div>
                <h2 className="text-base font-bold text-white tracking-tight">
                  Venue Financials & Commission Auditing
                </h2>
                <p className="text-xs text-slate-400 mt-0.5">
                  Detailed revenue reconciliation, active hourly rates, and booking hold switches.
                </p>
              </div>
              <Link
                href="/admins"
                className="px-3.5 py-1.5 rounded-lg text-xs font-semibold bg-indigo-600 hover:bg-indigo-500 text-white transition-all"
              >
                Inspect Directory
              </Link>
            </div>

            <div className="rounded-xl bg-[#111625] border border-[#1F293D] overflow-hidden">
              <div className="overflow-x-auto">
                <table className="w-full text-left border-collapse text-xs">
                  <thead>
                    <tr className="border-b border-[#1E2638] bg-[#0E1321] text-slate-400 font-mono">
                      <th className="py-3.5 px-4 font-semibold">Turf Venue</th>
                      <th className="py-3.5 px-4 font-semibold">Location</th>
                      <th className="py-3.5 px-4 font-semibold">Today&apos;s Revenue</th>
                      <th className="py-3.5 px-4 font-semibold">Today&apos;s Slots</th>
                      <th className="py-3.5 px-4 font-semibold">All-Time GMV</th>
                      <th className="py-3.5 px-4 font-semibold">Booking State</th>
                      <th className="py-3.5 px-4 font-semibold">Actions</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-[#1C2538] font-mono">
                    {overview?.turfRevenueBreakdown && overview.turfRevenueBreakdown.length > 0 ? (
                      overview.turfRevenueBreakdown.map((t) => (
                        <tr key={t.turfId} className="hover:bg-[#151C2F] transition-colors">
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
                          <td className="py-3.5 px-4 text-indigo-300 font-bold">
                            ₹{t.totalRevenue.toLocaleString()}
                          </td>
                          <td className="py-3.5 px-4">
                            {t.isBookingHold ? (
                              <span className="px-2 py-0.5 rounded bg-amber-500/15 text-amber-300 border border-amber-500/30 text-[10px] font-bold">
                                Hold Active
                              </span>
                            ) : (
                              <span className="px-2 py-0.5 rounded bg-emerald-500/15 text-emerald-300 border border-emerald-500/30 text-[10px] font-bold">
                                Live & Open
                              </span>
                            )}
                          </td>
                          <td className="py-3.5 px-4">
                            <div className="flex items-center gap-1.5">
                              <button
                                type="button"
                                disabled={actionLoadingId === `turf_${t.turfId}`}
                                onClick={() => handleToggleTurfHold(t.turfId, t.isBookingHold)}
                                className={`px-2.5 py-1 rounded-md text-xs font-semibold transition-all disabled:opacity-50 ${
                                  t.isBookingHold
                                    ? 'bg-emerald-600 hover:bg-emerald-500 text-white'
                                    : 'bg-[#182033] text-amber-300 border border-amber-500/30 hover:bg-amber-500/20'
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
                        <td colSpan={7} className="py-8 text-center text-slate-500">
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
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-md flex items-center justify-center p-4">
          <div className="bg-[#0D121F] border border-[#232B3E] rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl">
            <h3 className="text-base font-bold text-white">
              Reject Registration Application
            </h3>
            <p className="text-xs text-slate-400">
              Provide a clear reason for declining the venue application for{' '}
              <strong className="text-slate-200">{cancelModalItem.venueName}</strong>:
            </p>
            <textarea
              rows={3}
              value={cancelReasonText}
              onChange={(e) => setCancelReasonText(e.target.value)}
              placeholder="e.g. Document photo illegible, GST certificate mismatch..."
              className="w-full p-3 bg-[#161D2F] border border-[#28354F] rounded-lg text-xs text-white placeholder-slate-500 focus:outline-hidden focus:border-rose-500"
            />
            <div className="flex items-center justify-end gap-2 pt-2">
              <button
                type="button"
                onClick={() => setCancelModalItem(null)}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold text-slate-400 hover:text-white"
              >
                Cancel
              </button>
              <button
                type="button"
                onClick={handleQuickCancelConfirm}
                className="px-4 py-1.5 rounded-lg text-xs font-bold bg-rose-600 hover:bg-rose-500 text-white transition-all"
              >
                Confirm Rejection
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Create Tournament Modal */}
      {showCreateTournModal && (
        <div className="fixed inset-0 z-50 bg-black/75 backdrop-blur-md flex items-center justify-center p-4">
          <div className="bg-[#0D121F] border border-[#232B3E] rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center justify-between pb-3 border-b border-[#1E2638]">
              <div className="flex items-center gap-2">
                <Trophy className="w-5 h-5 text-indigo-400" />
                <h3 className="text-base font-bold text-white">Deploy Tournament</h3>
              </div>
              <button
                onClick={() => setShowCreateTournModal(false)}
                className="text-slate-400 hover:text-white"
              >
                <X className="w-4 h-4" />
              </button>
            </div>

            <form onSubmit={handleCreateTournament} className="space-y-3.5 text-xs">
              <div>
                <label className="block text-slate-400 font-medium mb-1">Tournament Title</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Chennai Super Sixes 2026"
                  value={newTournTitle}
                  onChange={(e) => setNewTournTitle(e.target.value)}
                  className="w-full px-3 py-2 bg-[#161D2F] border border-[#28354F] rounded-lg text-white placeholder-slate-500 focus:outline-hidden focus:border-indigo-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-400 font-medium mb-1">Sport</label>
                  <select
                    value={newTournSport}
                    onChange={(e) => setNewTournSport(e.target.value)}
                    className="w-full px-3 py-2 bg-[#161D2F] border border-[#28354F] rounded-lg text-white focus:outline-hidden focus:border-indigo-500"
                  >
                    <option value="Football">Football</option>
                    <option value="Cricket">Cricket</option>
                    <option value="Badminton">Badminton</option>
                    <option value="Pickleball">Pickleball</option>
                  </select>
                </div>
                <div>
                  <label className="block text-slate-400 font-medium mb-1">Date</label>
                  <input
                    type="date"
                    required
                    value={newTournDate}
                    onChange={(e) => setNewTournDate(e.target.value)}
                    className="w-full px-3 py-2 bg-[#161D2F] border border-[#28354F] rounded-lg text-white focus:outline-hidden focus:border-indigo-500 font-mono"
                  />
                </div>
              </div>

              <div>
                <label className="block text-slate-400 font-medium mb-1">Venue Name / Location</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Gullies Arena, Anna Nagar"
                  value={newTournVenue}
                  onChange={(e) => setNewTournVenue(e.target.value)}
                  className="w-full px-3 py-2 bg-[#161D2F] border border-[#28354F] rounded-lg text-white placeholder-slate-500 focus:outline-hidden focus:border-indigo-500"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="block text-slate-400 font-medium mb-1">Entry Fee (₹)</label>
                  <input
                    type="number"
                    value={newTournEntryFee}
                    onChange={(e) => setNewTournEntryFee(e.target.value)}
                    className="w-full px-3 py-2 bg-[#161D2F] border border-[#28354F] rounded-lg text-white font-mono focus:outline-hidden focus:border-indigo-500"
                  />
                </div>
                <div>
                  <label className="block text-slate-400 font-medium mb-1">Prize Pool</label>
                  <input
                    type="text"
                    value={newTournPrize}
                    onChange={(e) => setNewTournPrize(e.target.value)}
                    className="w-full px-3 py-2 bg-[#161D2F] border border-[#28354F] rounded-lg text-white font-mono focus:outline-hidden focus:border-indigo-500"
                  />
                </div>
              </div>

              <div className="flex items-center justify-end gap-2 pt-3 border-t border-[#1E2638]">
                <button
                  type="button"
                  onClick={() => setShowCreateTournModal(false)}
                  className="px-3.5 py-2 rounded-lg text-xs font-semibold text-slate-400 hover:text-white"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-4 py-2 rounded-lg text-xs font-bold bg-indigo-600 hover:bg-indigo-500 text-white shadow-lg shadow-indigo-600/25 transition-all"
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
          <div className="bg-[#0D121F] border border-rose-500/40 rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center gap-3 text-rose-400">
              <div className="w-10 h-10 rounded-xl bg-rose-500/15 border border-rose-500/30 flex items-center justify-center">
                <AlertTriangle className="w-5 h-5 text-rose-400" />
              </div>
              <div>
                <h3 className="text-base font-bold text-white">Permanently Delete Tournament?</h3>
                <p className="text-xs text-slate-400">Irreversible super admin removal</p>
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

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                type="button"
                onClick={() => setDeleteConfirmTourn(null)}
                className="px-4 py-2 rounded-lg text-xs font-semibold text-slate-300 hover:text-white bg-[#161D2F] border border-[#28354F]"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={actionLoadingId === `del_tourn_${deleteConfirmTourn.id}`}
                onClick={() => handleDeleteTournament(deleteConfirmTourn.id)}
                className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-bold bg-rose-600 hover:bg-rose-500 text-white shadow-lg shadow-rose-600/30 disabled:opacity-50"
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
          <div className="bg-[#0D121F] border border-rose-500/40 rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl animate-in fade-in zoom-in-95 duration-150">
            <div className="flex items-center gap-3 text-rose-400">
              <div className="w-10 h-10 rounded-xl bg-rose-500/15 border border-rose-500/30 flex items-center justify-center">
                <AlertTriangle className="w-5 h-5 text-rose-400" />
              </div>
              <div>
                <h3 className="text-base font-bold text-white">Permanently Delete Turf Owner?</h3>
                <p className="text-xs text-slate-400">Irreversible super admin removal</p>
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

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                type="button"
                onClick={() => setDeleteConfirmTurf(null)}
                className="px-4 py-2 rounded-lg text-xs font-semibold text-slate-300 hover:text-white bg-[#161D2F] border border-[#28354F]"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={actionLoadingId === `del_turf_${deleteConfirmTurf.turfId}`}
                onClick={() => handleDeleteTurf(deleteConfirmTurf.turfId)}
                className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-bold bg-rose-600 hover:bg-rose-500 text-white shadow-lg shadow-rose-600/30 disabled:opacity-50"
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
