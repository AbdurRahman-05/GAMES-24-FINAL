'use client';

import { useState, useEffect, useCallback } from 'react';
import Navbar from '@/components/Navbar';
import RegistrationDetailModal from '@/components/RegistrationDetailModal';
import {
  AdminRegistration,
  DashboardOverview,
  BookingItem,
  TournamentItem,
  getRegistrations,
  getDashboardOverview,
  getAllBookings,
  getAllTournaments,
  verifyRegistration,
  cancelRegistration,
  toggleTurfBookingHold,
  toggleBookingHold,
  cancelBookingByAdmin,
  toggleTournamentHold,
  BACKEND_URL,
} from '@/lib/api';
import {
  Clock,
  CheckCircle2,
  XCircle,
  Search,
  RefreshCw,
  Building,
  User,
  Phone,
  Mail,
  MapPin,
  ChevronRight,
  ShieldCheck,
  FileText,
  Image as ImageIcon,
  AlertCircle,
  CalendarDays,
  Trophy,
  DollarSign,
  PauseCircle,
  PlayCircle,
  Zap,
  Activity,
  Flame,
  CreditCard,
  Plus,
  Users,
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

  // Toast state
  const [toastMessage, setToastMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  const showToast = (text: string, type: 'success' | 'error' = 'success') => {
    setToastMessage({ text, type });
    setTimeout(() => setToastMessage(null), 4000);
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

  // ACTION: Quick Verify Registration
  const handleQuickVerify = async (reg: AdminRegistration) => {
    setQuickVerifyingId(reg.id);
    try {
      await verifyRegistration(reg.id, { verifiedBy: 'Super Admin' });
      showToast(`Venue "${reg.venueName}" successfully verified & added to VerifiedAdmin!`);
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
      showToast(`Application for "${cancelModalItem.venueName}" cancelled`);
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
      const res = await fetch(`${BACKEND_URL}/super-admin/tournaments`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          title: newTournTitle,
          sport: newTournSport,
          venueName: newTournVenue,
          date: newTournDate,
          entryFee: Number(newTournEntryFee) || 0,
          prizePool: newTournPrize,
          maxTeams: 16,
        }),
      });
      if (!res.ok) throw new Error('Failed to create tournament');
      showToast(`Tournament "${newTournTitle}" created successfully!`);
      setShowCreateTournModal(false);
      setNewTournTitle('');
      setNewTournVenue('');
      loadTournaments();
      loadOverview();
    } catch (err: any) {
      showToast(err.message || 'Error creating tournament', 'error');
    }
  };

  const getFullFileUrl = (url: string | null) => {
    if (!url) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return `${BACKEND_URL}${url.startsWith('/') ? '' : '/'}${url}`;
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
    <div className="min-h-screen flex flex-col bg-slate-50 font-sans text-slate-800">
      <Navbar
        waitingCount={regStats.waiting || kpis.pendingOwners}
        activeSection={activeSection}
        onSelectSection={(sec) => setActiveSection(sec as any)}
      />

      {/* Floating Toast Notification */}
      {toastMessage && (
        <div className="fixed top-20 right-6 z-50 animate-in fade-in slide-in-from-top-4 duration-200">
          <div
            className={`flex items-center gap-2.5 px-4 py-3 rounded-xl shadow-lg border text-sm font-semibold ${
              toastMessage.type === 'success'
                ? 'bg-emerald-900 text-white border-emerald-700'
                : 'bg-rose-900 text-white border-rose-700'
            }`}
          >
            {toastMessage.type === 'success' ? (
              <CheckCircle2 className="w-5 h-5 text-emerald-400 shrink-0" />
            ) : (
              <AlertCircle className="w-5 h-5 text-rose-400 shrink-0" />
            )}
            <span>{toastMessage.text}</span>
          </div>
        </div>
      )}

      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-6 space-y-6">
        {/* Navigation Action Pills */}
        <div className="flex flex-wrap items-center justify-between gap-3 bg-white p-3 rounded-2xl border border-slate-200 shadow-2xs">
          <div className="flex items-center gap-1.5 overflow-x-auto">
            <button
              onClick={() => setActiveSection('OVERVIEW')}
              className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
                activeSection === 'OVERVIEW'
                  ? 'bg-emerald-600 text-white shadow-sm'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
              }`}
            >
              <Zap className="w-3.5 h-3.5" />
              <span>Live Overview & KPIs</span>
            </button>

            <button
              onClick={() => setActiveSection('REGISTRATIONS')}
              className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
                activeSection === 'REGISTRATIONS'
                  ? 'bg-emerald-600 text-white shadow-sm'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
              }`}
            >
              <FileText className="w-3.5 h-3.5" />
              <span>Owner Registrations ({kpis.pendingOwners} Pending)</span>
            </button>

            <button
              onClick={() => setActiveSection('BOOKINGS')}
              className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
                activeSection === 'BOOKINGS'
                  ? 'bg-emerald-600 text-white shadow-sm'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
              }`}
            >
              <CalendarDays className="w-3.5 h-3.5" />
              <span>All Bookings & Holds</span>
            </button>

            <button
              onClick={() => setActiveSection('TOURNAMENTS')}
              className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
                activeSection === 'TOURNAMENTS'
                  ? 'bg-emerald-600 text-white shadow-sm'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
              }`}
            >
              <Trophy className="w-3.5 h-3.5" />
              <span>Tournaments ({tournSummary.live} Live)</span>
            </button>

            <button
              onClick={() => setActiveSection('TURFS')}
              className={`flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-bold transition-all ${
                activeSection === 'TURFS'
                  ? 'bg-emerald-600 text-white shadow-sm'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
              }`}
            >
              <Building className="w-3.5 h-3.5" />
              <span>Turf Revenues</span>
            </button>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => {
                loadOverview();
                if (activeSection === 'BOOKINGS') loadBookings();
                if (activeSection === 'TOURNAMENTS') loadTournaments();
                if (activeSection === 'REGISTRATIONS') loadRegistrations();
                showToast('Refreshed real-time data');
              }}
              className="p-2 text-slate-500 hover:text-slate-800 hover:bg-slate-100 rounded-xl transition-all border border-slate-200"
              title="Refresh live metrics"
            >
              <RefreshCw className="w-4 h-4" />
            </button>
          </div>
        </div>

        {/* ========================================================= */}
        {/* SECTION 1: LIVE OVERVIEW & EXECUTIVE ANALYTICS            */}
        {/* ========================================================= */}
        {activeSection === 'OVERVIEW' && (
          <div className="space-y-6">
            {/* Top 7 Master KPI Cards */}
            <div className="grid grid-cols-2 md:grid-cols-4 lg:grid-cols-7 gap-3">
              {/* Total Users */}
              <div className="bg-white p-3.5 rounded-2xl border border-slate-200/90 shadow-2xs">
                <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 block">
                  Players
                </span>
                <div className="mt-1 flex items-baseline gap-1.5">
                  <span className="text-2xl font-extrabold text-slate-900">{kpis.totalUsers}</span>
                  <span className="text-[10px] font-semibold text-emerald-600">Registered</span>
                </div>
                <div className="mt-2 text-[10px] text-slate-400 flex items-center gap-1">
                  <Users className="w-3 h-3 text-slate-400" /> Active Customers
                </div>
              </div>

              {/* Turf Owners */}
              <div className="bg-white p-3.5 rounded-2xl border border-slate-200/90 shadow-2xs">
                <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 block">
                  Turf Owners
                </span>
                <div className="mt-1 flex items-baseline gap-1.5">
                  <span className="text-2xl font-extrabold text-slate-900">{kpis.verifiedOwners}</span>
                  <span className="text-[10px] font-bold text-emerald-700 bg-emerald-50 px-1 rounded">
                    Verified
                  </span>
                </div>
                <div className="mt-2 text-[10px] text-slate-500">
                  {kpis.pendingOwners} Pending Approval
                </div>
              </div>

              {/* Total Revenue GMV */}
              <div className="bg-white p-3.5 rounded-2xl border border-slate-200/90 shadow-2xs">
                <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 block">
                  Total GMV
                </span>
                <div className="mt-1 flex items-baseline gap-1">
                  <span className="text-xl font-black text-slate-900">
                    ₹{kpis.totalRevenue.toLocaleString('en-IN')}
                  </span>
                </div>
                <div className="mt-2 text-[10px] text-emerald-600 font-semibold flex items-center gap-1">
                  <DollarSign className="w-3 h-3" /> All-Time Revenue
                </div>
              </div>

              {/* Today Bookings */}
              <div className="bg-white p-3.5 rounded-2xl border border-emerald-200 bg-emerald-50/30 shadow-2xs">
                <span className="text-[10px] font-bold uppercase tracking-wider text-emerald-800 block">
                  Today Bookings
                </span>
                <div className="mt-1 flex items-baseline gap-1.5">
                  <span className="text-2xl font-black text-emerald-900">
                    {kpis.todayBookingsCount}
                  </span>
                  <span className="text-[10px] font-semibold text-emerald-700">Confirmed</span>
                </div>
                <div className="mt-2 text-[10px] text-emerald-800 font-semibold">
                  ₹{kpis.todayRevenue.toLocaleString('en-IN')} Today GMV
                </div>
              </div>

              {/* Today Cancelled */}
              <div className="bg-white p-3.5 rounded-2xl border border-rose-200 bg-rose-50/30 shadow-2xs">
                <span className="text-[10px] font-bold uppercase tracking-wider text-rose-800 block">
                  Today Cancelled
                </span>
                <div className="mt-1 flex items-baseline gap-1.5">
                  <span className="text-2xl font-black text-rose-900">
                    {kpis.todayCancelledCount}
                  </span>
                  <span className="text-[10px] font-semibold text-rose-700">Slots</span>
                </div>
                <div className="mt-2 text-[10px] text-rose-800 font-medium">Refunds logged</div>
              </div>

              {/* Advance Paid (Online) */}
              <div className="bg-white p-3.5 rounded-2xl border border-slate-200/90 shadow-2xs">
                <span className="text-[10px] font-bold uppercase tracking-wider text-slate-400 block">
                  Online / Advance
                </span>
                <div className="mt-1 flex items-baseline gap-1">
                  <span className="text-xl font-extrabold text-slate-900">
                    ₹{kpis.todayAdvancePaid.toLocaleString('en-IN')}
                  </span>
                </div>
                <div className="mt-2 text-[10px] text-slate-500">
                  Cash: ₹{kpis.todayCashAmount.toLocaleString('en-IN')}
                </div>
              </div>

              {/* Tournaments Snapshot */}
              <div className="bg-white p-3.5 rounded-2xl border border-amber-200 bg-amber-50/30 shadow-2xs">
                <span className="text-[10px] font-bold uppercase tracking-wider text-amber-800 block">
                  Tournaments
                </span>
                <div className="mt-1 flex items-baseline gap-1.5">
                  <span className="text-2xl font-black text-amber-900">{tournSummary.live}</span>
                  <span className="text-[10px] font-bold text-amber-800">Live Now</span>
                </div>
                <div className="mt-2 text-[10px] text-amber-900 font-semibold">
                  {tournSummary.upcoming} Upcoming • {tournSummary.onHold} Held
                </div>
              </div>
            </div>

            {/* Quick Actions & Live Activity Feed Row */}
            <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
              {/* Left 2 Cols: Live Activity Feed (What's Occurring on the App) */}
              <div className="lg:col-span-2 bg-white rounded-2xl border border-slate-200/90 shadow-2xs p-5 space-y-4">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <div className="w-8 h-8 rounded-lg bg-emerald-100 text-emerald-700 flex items-center justify-center">
                      <Flame className="w-4 h-4 text-emerald-600 animate-pulse" />
                    </div>
                    <div>
                      <h2 className="text-base font-bold text-slate-900">
                        Live App Activity Feed
                      </h2>
                      <p className="text-xs text-slate-500">
                        Real-time stream of player bookings, cancellations, and venue actions
                      </p>
                    </div>
                  </div>
                  <span className="px-2.5 py-1 text-[10px] font-bold uppercase tracking-wider bg-slate-100 text-slate-600 rounded-full">
                    Auto-Tracked
                  </span>
                </div>

                <div className="divide-y divide-slate-100 max-h-96 overflow-y-auto pr-1">
                  {overview?.recentLiveActions && overview.recentLiveActions.length > 0 ? (
                    overview.recentLiveActions.map((act) => {
                      const isBooking = act.type === 'BOOKING';
                      const isCancel = act.type === 'CANCELLATION';
                      const isHold = act.type === 'HOLD';
                      const isTourn = act.type === 'TOURNAMENT';

                      return (
                        <div key={act.id} className="py-3 flex items-start justify-between gap-3 text-xs">
                          <div className="flex items-start gap-2.5">
                            <div
                              className={`w-7 h-7 rounded-lg flex items-center justify-center shrink-0 mt-0.5 ${
                                isCancel
                                  ? 'bg-rose-100 text-rose-700'
                                  : isHold
                                  ? 'bg-amber-100 text-amber-700'
                                  : isTourn
                                  ? 'bg-indigo-100 text-indigo-700'
                                  : 'bg-emerald-100 text-emerald-700'
                              }`}
                            >
                              {isCancel ? (
                                <XCircle className="w-3.5 h-3.5" />
                              ) : isHold ? (
                                <PauseCircle className="w-3.5 h-3.5" />
                              ) : isTourn ? (
                                <Trophy className="w-3.5 h-3.5" />
                              ) : (
                                <CheckCircle2 className="w-3.5 h-3.5" />
                              )}
                            </div>
                            <div>
                              <div className="flex items-center gap-2">
                                <span className="font-bold text-slate-800">{act.title}</span>
                                <span className="text-slate-400 font-normal">at</span>
                                <span className="font-semibold text-emerald-700">{act.turfName}</span>
                              </div>
                              <p className="text-slate-500 mt-0.5">{act.description}</p>
                            </div>
                          </div>

                          <div className="text-right shrink-0">
                            {act.amount && (
                              <div className="font-bold text-slate-900">
                                ₹{Number(act.amount).toLocaleString('en-IN')}
                              </div>
                            )}
                            <div className="text-[10px] text-slate-400">
                              {new Date(act.timestamp).toLocaleTimeString([], {
                                hour: '2-digit',
                                minute: '2-digit',
                              })}
                            </div>
                          </div>
                        </div>
                      );
                    })
                  ) : (
                    <div className="py-12 text-center text-slate-400 text-xs">
                      No recent activities recorded yet.
                    </div>
                  )}
                </div>
              </div>

              {/* Right 1 Col: Quick Control Shortcuts */}
              <div className="bg-white rounded-2xl border border-slate-200/90 shadow-2xs p-5 space-y-4">
                <div className="flex items-center gap-2">
                  <div className="w-8 h-8 rounded-lg bg-slate-100 text-slate-700 flex items-center justify-center font-bold">
                    <Zap className="w-4 h-4 text-amber-600" />
                  </div>
                  <div>
                    <h3 className="text-base font-bold text-slate-900">Admin Quick Controls</h3>
                    <p className="text-xs text-slate-500">Global shortcuts & emergency toggles</p>
                  </div>
                </div>

                <div className="space-y-2.5 pt-1">
                  <button
                    onClick={() => setActiveSection('BOOKINGS')}
                    className="w-full p-3 rounded-xl border border-slate-200 hover:border-emerald-300 hover:bg-emerald-50/40 text-left transition-all flex items-center justify-between group"
                  >
                    <div>
                      <div className="text-xs font-bold text-slate-800 group-hover:text-emerald-700">
                        Hold or Manage Bookings
                      </div>
                      <div className="text-[11px] text-slate-500">
                        Lock specific slots or cancel disputed bookings
                      </div>
                    </div>
                    <ChevronRight className="w-4 h-4 text-slate-400 group-hover:text-emerald-600" />
                  </button>

                  <button
                    onClick={() => setActiveSection('TOURNAMENTS')}
                    className="w-full p-3 rounded-xl border border-slate-200 hover:border-amber-300 hover:bg-amber-50/40 text-left transition-all flex items-center justify-between group"
                  >
                    <div>
                      <div className="text-xs font-bold text-slate-800 group-hover:text-amber-800">
                        Pause / Resume Tournaments
                      </div>
                      <div className="text-[11px] text-slate-500">
                        Freeze knockout brackets or create championship
                      </div>
                    </div>
                    <ChevronRight className="w-4 h-4 text-slate-400 group-hover:text-amber-700" />
                  </button>

                  <button
                    onClick={() => setActiveSection('REGISTRATIONS')}
                    className="w-full p-3 rounded-xl border border-slate-200 hover:border-blue-300 hover:bg-blue-50/40 text-left transition-all flex items-center justify-between group"
                  >
                    <div>
                      <div className="text-xs font-bold text-slate-800 group-hover:text-blue-700">
                        Review Owner Applications ({kpis.pendingOwners})
                      </div>
                      <div className="text-[11px] text-slate-500">
                        Audit KYC documents, Aadhaar, PAN & bank data
                      </div>
                    </div>
                    <ChevronRight className="w-4 h-4 text-slate-400 group-hover:text-blue-600" />
                  </button>

                  <button
                    onClick={() => setShowCreateTournModal(true)}
                    className="w-full py-2.5 px-4 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-xl shadow-md shadow-emerald-600/20 transition-all flex items-center justify-center gap-1.5"
                  >
                    <Plus className="w-4 h-4" />
                    <span>Host New Tournament</span>
                  </button>
                </div>
              </div>
            </div>

            {/* Turf-by-Turf Performance & Hold Controls */}
            <div className="bg-white rounded-2xl border border-slate-200/90 shadow-2xs p-5 space-y-4">
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
                <div>
                  <h2 className="text-base font-bold text-slate-900 flex items-center gap-2">
                    <Building className="w-4 h-4 text-emerald-600" />
                    <span>Turf Partners: Performance & Booking Hold Controls</span>
                  </h2>
                  <p className="text-xs text-slate-500">
                    Review revenue per turf owner and toggle instant booking hold for any venue
                  </p>
                </div>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-xs text-left">
                  <thead className="bg-slate-50 text-slate-500 uppercase tracking-wider font-bold border-y border-slate-200">
                    <tr>
                      <th className="py-3 px-3">Turf & Location</th>
                      <th className="py-3 px-3">Owner Contact</th>
                      <th className="py-3 px-3 text-center">Today Bookings</th>
                      <th className="py-3 px-3 text-right">Today Revenue</th>
                      <th className="py-3 px-3 text-center">Total Bookings</th>
                      <th className="py-3 px-3 text-right">Total Revenue</th>
                      <th className="py-3 px-3 text-center">Booking Status</th>
                      <th className="py-3 px-3 text-center">Admin Action</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {overview?.turfRevenueBreakdown && overview.turfRevenueBreakdown.length > 0 ? (
                      overview.turfRevenueBreakdown.map((turf) => (
                        <tr key={turf.turfId} className="hover:bg-slate-50/60 transition-colors">
                          <td className="py-3 px-3">
                            <div className="font-bold text-slate-900">{turf.venueName}</div>
                            <div className="text-[11px] text-slate-400">{turf.neighborhoodArea}</div>
                          </td>
                          <td className="py-3 px-3">
                            <div className="font-semibold text-slate-800">{turf.ownerName}</div>
                            <div className="text-[11px] text-slate-500">{turf.ownerPhone}</div>
                          </td>
                          <td className="py-3 px-3 text-center font-bold text-emerald-700">
                            {turf.todayBookingsCount}
                            {turf.todayCancelled > 0 && (
                              <span className="text-[10px] text-rose-600 block">
                                ({turf.todayCancelled} cancelled)
                              </span>
                            )}
                          </td>
                          <td className="py-3 px-3 text-right font-semibold text-slate-800">
                            ₹{turf.todayRevenue.toLocaleString('en-IN')}
                          </td>
                          <td className="py-3 px-3 text-center font-semibold text-slate-700">
                            {turf.totalBookingsCount}
                          </td>
                          <td className="py-3 px-3 text-right font-bold text-slate-900">
                            ₹{turf.totalRevenue.toLocaleString('en-IN')}
                          </td>
                          <td className="py-3 px-3 text-center">
                            {turf.isBookingHold ? (
                              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-amber-100 text-amber-800 border border-amber-200">
                                ON HOLD
                              </span>
                            ) : (
                              <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800 border border-emerald-200">
                                ACTIVE
                              </span>
                            )}
                          </td>
                          <td className="py-3 px-3 text-center">
                            <button
                              onClick={() => handleToggleTurfHold(turf.turfId, turf.isBookingHold)}
                              disabled={actionLoadingId === `turf_${turf.turfId}`}
                              className={`px-3 py-1.5 rounded-lg text-[11px] font-bold transition-all flex items-center justify-center gap-1 mx-auto ${
                                turf.isBookingHold
                                  ? 'bg-emerald-600 hover:bg-emerald-700 text-white shadow-xs'
                                  : 'bg-amber-100 hover:bg-amber-200 text-amber-900 border border-amber-300'
                              }`}
                            >
                              {turf.isBookingHold ? (
                                <>
                                  <PlayCircle className="w-3 h-3" />
                                  <span>Resume Bookings</span>
                                </>
                              ) : (
                                <>
                                  <PauseCircle className="w-3 h-3" />
                                  <span>Hold Bookings</span>
                                </>
                              )}
                            </button>
                          </td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan={8} className="py-8 text-center text-slate-400 text-xs">
                          No verified turfs yet. Approve venues in Registrations tab.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>

            {/* Player CRM: How Many Times Players Booked */}
            <div className="bg-white rounded-2xl border border-slate-200/90 shadow-2xs p-5 space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h2 className="text-base font-bold text-slate-900 flex items-center gap-2">
                    <Users className="w-4 h-4 text-emerald-600" />
                    <span>Player Engagement & Booking Frequency (CRM)</span>
                  </h2>
                  <p className="text-xs text-slate-500">
                    Track how many times customers booked, total spend, and favorite sports
                  </p>
                </div>
              </div>

              <div className="overflow-x-auto">
                <table className="w-full text-xs text-left">
                  <thead className="bg-slate-50 text-slate-500 uppercase tracking-wider font-bold border-y border-slate-200">
                    <tr>
                      <th className="py-3 px-3">Player Name</th>
                      <th className="py-3 px-3">Mobile Contact</th>
                      <th className="py-3 px-3 text-center">Times Booked</th>
                      <th className="py-3 px-3 text-right">Total Spent</th>
                      <th className="py-3 px-3">Favorite Sport</th>
                      <th className="py-3 px-3 text-right">Last Booking Date</th>
                    </tr>
                  </thead>
                  <tbody className="divide-y divide-slate-100">
                    {overview?.playerStats && overview.playerStats.length > 0 ? (
                      overview.playerStats.map((player, idx) => (
                        <tr key={idx} className="hover:bg-slate-50/60 transition-colors">
                          <td className="py-3 px-3 font-bold text-slate-900">
                            {player.customerName}
                          </td>
                          <td className="py-3 px-3 text-slate-600 font-mono">
                            {player.customerPhone}
                          </td>
                          <td className="py-3 px-3 text-center">
                            <span className="px-2.5 py-0.5 rounded-full font-bold bg-emerald-100 text-emerald-800 text-[11px]">
                              {player.totalBookings} Bookings
                            </span>
                          </td>
                          <td className="py-3 px-3 text-right font-bold text-slate-900">
                            ₹{player.totalSpent.toLocaleString('en-IN')}
                          </td>
                          <td className="py-3 px-3">
                            <span className="px-2 py-0.5 rounded bg-slate-100 font-medium text-slate-700 text-[11px]">
                              {player.favoriteSport}
                            </span>
                          </td>
                          <td className="py-3 px-3 text-right text-slate-500 font-mono">
                            {player.lastBookingDate || '-'}
                          </td>
                        </tr>
                      ))
                    ) : (
                      <tr>
                        <td colSpan={6} className="py-8 text-center text-slate-400 text-xs">
                          No player booking history recorded yet.
                        </td>
                      </tr>
                    )}
                  </tbody>
                </table>
              </div>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* SECTION 2: BOOKINGS CENTRAL & HOLD CONTROLS               */}
        {/* ========================================================= */}
        {activeSection === 'BOOKINGS' && (
          <div className="bg-white rounded-2xl border border-slate-200/90 shadow-2xs p-5 space-y-4">
            <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
              <div>
                <h2 className="text-base font-bold text-slate-900 flex items-center gap-2">
                  <CalendarDays className="w-4 h-4 text-emerald-600" />
                  <span>All Platform Bookings & Admin Hold Management</span>
                </h2>
                <p className="text-xs text-slate-500">
                  Search, monitor, hold or cancel bookings across all registered turfs
                </p>
              </div>

              {/* Status Filters */}
              <div className="flex items-center gap-2">
                <select
                  value={bookingStatusFilter}
                  onChange={(e) => setBookingStatusFilter(e.target.value)}
                  className="px-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-xl font-semibold text-slate-700 focus:outline-hidden"
                >
                  <option value="ALL">All Bookings</option>
                  <option value="OPEN_MATCH">⚡ Open Matches Only</option>
                  <option value="REGULAR">Regular Bookings Only</option>
                  <option value="Confirmed">Confirmed Only</option>
                  <option value="On Hold">On Hold Only</option>
                  <option value="Cancelled">Cancelled Only</option>
                </select>

                <div className="relative w-64">
                  <Search className="w-3.5 h-3.5 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                  <input
                    type="text"
                    placeholder="Search player, phone, court..."
                    value={bookingSearch}
                    onChange={(e) => setBookingSearch(e.target.value)}
                    className="w-full pl-8 pr-3 py-1.5 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-hidden"
                  />
                </div>
              </div>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-xs text-left">
                <thead className="bg-slate-50 text-slate-500 uppercase tracking-wider font-bold border-y border-slate-200">
                  <tr>
                    <th className="py-3 px-3">Booking ID</th>
                    <th className="py-3 px-3">Player Info</th>
                    <th className="py-3 px-3">Venue & Court</th>
                    <th className="py-3 px-3">Date & Slot</th>
                    <th className="py-3 px-3 text-right">Amount</th>
                    <th className="py-3 px-3 text-center">Status</th>
                    <th className="py-3 px-3 text-center">Super Admin Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {bookingsLoading ? (
                    <tr>
                      <td colSpan={7} className="py-12 text-center text-slate-400">
                        <RefreshCw className="w-6 h-6 animate-spin mx-auto text-emerald-600 mb-2" />
                        <span>Loading platform bookings...</span>
                      </td>
                    </tr>
                  ) : bookings.length === 0 ? (
                    <tr>
                      <td colSpan={7} className="py-8 text-center text-slate-400 text-xs">
                        No bookings found matching the criteria.
                      </td>
                    </tr>
                  ) : (
                    bookings.map((b) => (
                      <tr key={b.id} className="hover:bg-slate-50/60 transition-colors">
                        <td className="py-3 px-3 font-mono font-bold text-slate-700">
                          #{b.id}
                        </td>
                        <td className="py-3 px-3">
                          <div className="font-bold text-slate-900">{b.customerName}</div>
                          <div className="text-[11px] text-slate-500 font-mono">{b.customerPhone}</div>
                          {b.isOpenMatch ? (
                            <div className="mt-1">
                              <span className="inline-flex items-center gap-1 px-1.5 py-0.5 rounded text-[9.5px] font-bold bg-amber-50 text-amber-800 border border-amber-200">
                                ⚡ Open Match ({b.teamSize || '7v7'})
                              </span>
                              <div className="text-[10px] text-slate-600 font-semibold mt-0.5">
                                Team: {b.teamName || b.customerName}
                              </div>
                            </div>
                          ) : (
                            <div className="mt-1">
                              <span className="inline-flex items-center px-1.5 py-0.5 rounded text-[9px] font-medium bg-slate-100 text-slate-600">
                                Regular Booking
                              </span>
                            </div>
                          )}
                        </td>
                        <td className="py-3 px-3">
                          <div className="font-semibold text-slate-800">{b.verifiedAdmin?.venueName || 'Venue'}</div>
                          <div className="text-[11px] text-slate-400">{b.courtName} ({b.sport})</div>
                        </td>
                        <td className="py-3 px-3 font-medium text-slate-700">
                          <div>{b.date}</div>
                          <div className="text-[11px] text-emerald-700 font-semibold">{b.timeSlot}</div>
                        </td>
                        <td className="py-3 px-3 text-right font-bold text-slate-900">
                          ₹{b.amount}
                          <span className="text-[10px] text-slate-400 font-normal block">
                            {b.paymentMethod}
                          </span>
                        </td>
                        <td className="py-3 px-3 text-center">
                          {b.status === 'Cancelled' ? (
                            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-rose-100 text-rose-800 border border-rose-200">
                              Cancelled
                            </span>
                          ) : b.isHold || b.status === 'On Hold' ? (
                            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-amber-100 text-amber-800 border border-amber-200">
                              ON HOLD
                            </span>
                          ) : (
                            <span className="px-2.5 py-0.5 rounded-full text-[10px] font-bold bg-emerald-100 text-emerald-800 border border-emerald-200">
                              Confirmed
                            </span>
                          )}

                          {b.isOpenMatch && (
                            <div className="mt-1">
                              {b.openMatchStatus === 'OPPONENT_JOINED' ? (
                                <span className="inline-block px-2 py-0.5 rounded-full text-[9px] font-bold bg-blue-50 text-blue-700 border border-blue-200" title={`Opponent Contact: ${b.opponentPhone || 'N/A'}`}>
                                  Opponent: {b.opponentName || 'Joined'}
                                </span>
                              ) : (
                                <span className="inline-block px-2 py-0.5 rounded-full text-[9px] font-bold bg-amber-50 text-amber-700 border border-amber-200">
                                  Waiting Opponent
                                </span>
                              )}
                            </div>
                          )}
                        </td>
                        <td className="py-3 px-3 text-center">
                          {b.status !== 'Cancelled' && (
                            <div className="flex items-center justify-center gap-1.5">
                              <button
                                onClick={() => handleToggleBookingHold(b.id, b.isHold)}
                                disabled={actionLoadingId === `book_${b.id}`}
                                className={`px-2.5 py-1 rounded text-[10px] font-bold transition-all ${
                                  b.isHold
                                    ? 'bg-emerald-600 hover:bg-emerald-700 text-white'
                                    : 'bg-amber-100 hover:bg-amber-200 text-amber-900'
                                }`}
                              >
                                {b.isHold ? 'Release Hold' : 'Hold'}
                              </button>

                              <button
                                onClick={() => handleCancelBooking(b.id)}
                                disabled={actionLoadingId === `cancel_book_${b.id}`}
                                className="px-2.5 py-1 rounded text-[10px] font-bold bg-rose-100 hover:bg-rose-200 text-rose-800 transition-all"
                              >
                                Cancel
                              </button>
                            </div>
                          )}
                        </td>
                      </tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* SECTION 3: TOURNAMENTS HUB & HOLD CONTROLS                */}
        {/* ========================================================= */}
        {activeSection === 'TOURNAMENTS' && (
          <div className="space-y-6">
            <div className="bg-white rounded-2xl border border-slate-200/90 shadow-2xs p-5 space-y-4">
              <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
                <div>
                  <h2 className="text-base font-bold text-slate-900 flex items-center gap-2">
                    <Trophy className="w-4 h-4 text-amber-500" />
                    <span>Platform Tournaments Manager</span>
                  </h2>
                  <p className="text-xs text-slate-500">
                    Oversee live, upcoming, and finished championships. Hold or resume tournaments as needed.
                  </p>
                </div>

                <div className="flex items-center gap-2">
                  <div className="flex items-center gap-1 bg-slate-100 p-1 rounded-xl">
                    {['ALL', 'LIVE', 'UPCOMING', 'FINISHED', 'ON_HOLD'].map((tab) => (
                      <button
                        key={tab}
                        onClick={() => setTournStatusFilter(tab)}
                        className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                          tournStatusFilter === tab
                            ? 'bg-white text-slate-900 shadow-xs'
                            : 'text-slate-600 hover:text-slate-900'
                        }`}
                      >
                        {tab === 'ALL' ? 'All' : tab}
                      </button>
                    ))}
                  </div>

                  <button
                    onClick={() => setShowCreateTournModal(true)}
                    className="px-3.5 py-1.5 bg-emerald-600 hover:bg-emerald-700 text-white font-bold text-xs rounded-xl shadow-xs transition-all flex items-center gap-1"
                  >
                    <Plus className="w-4 h-4" />
                    <span>Create Tournament</span>
                  </button>
                </div>
              </div>

              {/* Tournament Cards Grid */}
              <div className="grid grid-cols-1 md:grid-cols-3 gap-4 pt-2">
                {tournLoading ? (
                  <div className="col-span-3 py-12 text-center text-slate-400">
                    <RefreshCw className="w-6 h-6 animate-spin mx-auto text-emerald-600 mb-2" />
                    <span>Loading tournaments...</span>
                  </div>
                ) : tournaments.length === 0 ? (
                  <div className="col-span-3 py-12 text-center text-slate-400 text-xs">
                    No tournaments found in this status category.
                  </div>
                ) : (
                  tournaments.map((t) => (
                    <div
                      key={t.id}
                      className="p-4 rounded-xl border border-slate-200 bg-white hover:border-emerald-300 shadow-2xs transition-all space-y-3"
                    >
                      <div className="flex items-start justify-between gap-2">
                        <div>
                          <span className="text-[10px] font-bold uppercase tracking-wider text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded">
                            {t.sport} • {t.format}
                          </span>
                          <h3 className="font-bold text-slate-900 text-sm mt-1">{t.title}</h3>
                          <p className="text-[11px] text-slate-500">{t.venueName}</p>
                        </div>
                        <span
                          className={`text-[10px] font-bold px-2 py-0.5 rounded-full uppercase tracking-wider ${
                            t.isHold || t.status === 'ON_HOLD'
                              ? 'bg-amber-100 text-amber-800'
                              : t.status === 'LIVE'
                              ? 'bg-rose-100 text-rose-800 animate-pulse'
                              : t.status === 'FINISHED'
                              ? 'bg-slate-100 text-slate-700'
                              : 'bg-emerald-100 text-emerald-800'
                          }`}
                        >
                          {t.isHold ? 'ON HOLD' : t.status}
                        </span>
                      </div>

                      <div className="grid grid-cols-2 gap-2 text-xs bg-slate-50 p-2.5 rounded-lg text-slate-600">
                        <div>
                          <span className="text-[10px] text-slate-400 block">Date & Time</span>
                          <span className="font-semibold">{t.date} ({t.time})</span>
                        </div>
                        <div>
                          <span className="text-[10px] text-slate-400 block">Prize Pool</span>
                          <span className="font-bold text-emerald-700">{t.prizePool}</span>
                        </div>
                        <div>
                          <span className="text-[10px] text-slate-400 block">Entry Fee</span>
                          <span className="font-semibold">₹{t.entryFee} / team</span>
                        </div>
                        <div>
                          <span className="text-[10px] text-slate-400 block">Teams</span>
                          <span className="font-semibold">{t.registeredTeams} / {t.maxTeams}</span>
                        </div>
                      </div>

                      <div className="pt-1 flex items-center justify-between gap-2">
                        <button
                          onClick={() => handleToggleTournHold(t.id, t.isHold)}
                          disabled={actionLoadingId === `tourn_${t.id}`}
                          className={`w-full py-1.5 px-3 rounded-lg text-xs font-bold transition-all flex items-center justify-center gap-1.5 ${
                            t.isHold
                              ? 'bg-emerald-600 hover:bg-emerald-700 text-white'
                              : 'bg-amber-100 hover:bg-amber-200 text-amber-900 border border-amber-300'
                          }`}
                        >
                          {t.isHold ? (
                            <>
                              <PlayCircle className="w-3.5 h-3.5" />
                              <span>Resume Tournament</span>
                            </>
                          ) : (
                            <>
                              <PauseCircle className="w-3.5 h-3.5" />
                              <span>Hold / Freeze Tournament</span>
                            </>
                          )}
                        </button>
                      </div>
                    </div>
                  ))
                )}
              </div>
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* SECTION 4: REGISTRATIONS APPROVAL PIPELINE                 */}
        {/* ========================================================= */}
        {activeSection === 'REGISTRATIONS' && (
          <div className="space-y-6">
            {/* Registrations Tabs & Search */}
            <div className="bg-white rounded-2xl border border-slate-200/80 shadow-2xs p-3 flex flex-col md:flex-row md:items-center md:justify-between gap-3">
              <div className="flex items-center gap-1.5 p-1 bg-slate-100 rounded-xl">
                <button
                  onClick={() => setActiveRegTab('WAITING')}
                  className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all ${
                    activeRegTab === 'WAITING'
                      ? 'bg-white text-slate-900 shadow-xs'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  <Clock className="w-3.5 h-3.5 text-amber-600" />
                  <span>Waiting Review ({regStats.waiting})</span>
                </button>

                <button
                  onClick={() => setActiveRegTab('VERIFIED')}
                  className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all ${
                    activeRegTab === 'VERIFIED'
                      ? 'bg-white text-slate-900 shadow-xs'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                  <span>Verified Partners ({regStats.verified})</span>
                </button>

                <button
                  onClick={() => setActiveRegTab('CANCEL')}
                  className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all ${
                    activeRegTab === 'CANCEL'
                      ? 'bg-white text-slate-900 shadow-xs'
                      : 'text-slate-600 hover:text-slate-900'
                  }`}
                >
                  <XCircle className="w-3.5 h-3.5 text-rose-600" />
                  <span>Cancelled / Rejected ({regStats.cancelled})</span>
                </button>
              </div>

              <div className="relative w-full md:w-80">
                <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
                <input
                  type="text"
                  placeholder="Search venue, owner, phone..."
                  value={regSearch}
                  onChange={(e) => setRegSearch(e.target.value)}
                  className="w-full pl-9 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:outline-hidden"
                />
              </div>
            </div>

            {/* Registrations List */}
            <div className="space-y-4">
              {regLoading ? (
                <div className="py-20 text-center text-slate-400">
                  <RefreshCw className="w-8 h-8 animate-spin mx-auto text-emerald-600 mb-2" />
                  <span className="text-sm font-semibold">Loading applications...</span>
                </div>
              ) : regItems.length === 0 ? (
                <div className="py-16 bg-white rounded-2xl border border-slate-200 text-center p-8">
                  <FileText className="w-10 h-10 mx-auto text-slate-300 mb-2" />
                  <h3 className="font-bold text-slate-800 text-base">No registrations found</h3>
                  <p className="text-xs text-slate-500">No applications in this category.</p>
                </div>
              ) : (
                regItems.map((item) => (
                  <div
                    key={item.id}
                    className="bg-white rounded-2xl border border-slate-200/90 shadow-2xs hover:shadow-md transition-all p-5 flex flex-col lg:flex-row lg:items-center justify-between gap-5"
                  >
                    <div className="space-y-3 flex-1">
                      <div className="flex flex-wrap items-center gap-2">
                        <span className="font-mono text-xs px-2.5 py-0.5 rounded-full bg-slate-100 text-slate-700 font-bold border border-slate-200">
                          {item.trackingCode || `#REG-${item.id}`}
                        </span>

                        {item.status === 'PENDING_APPROVAL' && (
                          <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-amber-100 text-amber-800 flex items-center gap-1">
                            <Clock className="w-3 h-3" /> Waiting Verification
                          </span>
                        )}
                        {item.status === 'VERIFIED' && (
                          <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-emerald-100 text-emerald-800 flex items-center gap-1">
                            <CheckCircle2 className="w-3 h-3" /> Verified Partner
                          </span>
                        )}
                        {item.status === 'CANCELLED' && (
                          <span className="px-2.5 py-0.5 rounded-full text-[11px] font-bold bg-rose-100 text-rose-800 flex items-center gap-1">
                            <XCircle className="w-3 h-3" /> Cancelled
                          </span>
                        )}
                      </div>

                      <div>
                        <h3 className="text-lg font-bold text-slate-900">{item.venueName}</h3>
                        <p className="text-xs text-slate-500 flex items-center gap-1">
                          <MapPin className="w-3.5 h-3.5 text-slate-400" />
                          <span>{item.streetAddress} ({item.neighborhoodArea})</span>
                        </p>
                      </div>

                      <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 text-xs">
                        <div className="flex items-center gap-1.5 text-slate-700 bg-slate-50 px-2.5 py-1.5 rounded-lg border border-slate-100">
                          <User className="w-3.5 h-3.5 text-slate-400" />
                          <span className="font-semibold">{item.ownerName}</span>
                        </div>
                        <div className="flex items-center gap-1.5 text-slate-700 bg-slate-50 px-2.5 py-1.5 rounded-lg border border-slate-100">
                          <Phone className="w-3.5 h-3.5 text-emerald-600" />
                          <span className="font-semibold">{item.ownerPhone}</span>
                        </div>
                        <div className="flex items-center gap-1.5 text-slate-700 bg-slate-50 px-2.5 py-1.5 rounded-lg border border-slate-100 truncate">
                          <Mail className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                          <span className="font-semibold truncate">{item.ownerEmail}</span>
                        </div>
                      </div>

                      {item.cancelReason && (
                        <div className="p-2.5 rounded-lg bg-rose-50 border border-rose-200 text-rose-800 text-xs">
                          <span className="font-bold">Cancellation Reason: </span>
                          {item.cancelReason}
                        </div>
                      )}
                    </div>

                    <div className="flex flex-col sm:flex-row lg:flex-col items-stretch lg:items-end justify-center gap-2.5 pt-2 lg:pt-0 shrink-0">
                      <button
                        onClick={() => setSelectedReg(item)}
                        className="px-4 py-2 text-xs font-bold text-slate-700 bg-slate-100 hover:bg-slate-200 rounded-xl transition-all flex items-center justify-center gap-1.5"
                      >
                        <span>Review Full Details</span>
                        <ChevronRight className="w-4 h-4" />
                      </button>

                      {item.status === 'PENDING_APPROVAL' && (
                        <div className="flex items-center gap-2 w-full">
                          <button
                            onClick={() => {
                              setCancelModalItem(item);
                              setCancelReasonText('');
                            }}
                            className="flex-1 px-3 py-2 text-xs font-bold text-rose-700 bg-rose-50 hover:bg-rose-100 border border-rose-200 rounded-xl transition-all"
                          >
                            Cancel
                          </button>

                          <button
                            onClick={() => handleQuickVerify(item)}
                            disabled={quickVerifyingId === item.id}
                            className="flex-1 px-4 py-2 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 rounded-xl shadow-md shadow-emerald-600/20 transition-all flex items-center justify-center gap-1.5"
                          >
                            <span>{quickVerifyingId === item.id ? 'Saving...' : 'Verify'}</span>
                          </button>
                        </div>
                      )}
                    </div>
                  </div>
                ))
              )}
            </div>
          </div>
        )}

        {/* ========================================================= */}
        {/* SECTION 5: TURF REVENUES MATRIX                           */}
        {/* ========================================================= */}
        {activeSection === 'TURFS' && (
          <div className="bg-white rounded-2xl border border-slate-200/90 shadow-2xs p-5 space-y-4">
            <div>
              <h2 className="text-base font-bold text-slate-900 flex items-center gap-2">
                <Building className="w-4 h-4 text-emerald-600" />
                <span>Turf Financials & Payout Ledger</span>
              </h2>
              <p className="text-xs text-slate-500">
                Detailed turnover breakdown, active rate cards, and booking status controls
              </p>
            </div>

            <div className="overflow-x-auto">
              <table className="w-full text-xs text-left">
                <thead className="bg-slate-50 text-slate-500 uppercase tracking-wider font-bold border-y border-slate-200">
                  <tr>
                    <th className="py-3 px-3">Turf Partner</th>
                    <th className="py-3 px-3">Owner & Contact</th>
                    <th className="py-3 px-3 text-center">Weekday / Weekend Rate</th>
                    <th className="py-3 px-3 text-center">Today Bookings</th>
                    <th className="py-3 px-3 text-right">Today Revenue</th>
                    <th className="py-3 px-3 text-center">Total Bookings</th>
                    <th className="py-3 px-3 text-right">Total Revenue</th>
                    <th className="py-3 px-3 text-center">Booking Control</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-100">
                  {overview?.turfRevenueBreakdown && overview.turfRevenueBreakdown.length > 0 ? (
                    overview.turfRevenueBreakdown.map((t) => (
                      <tr key={t.turfId} className="hover:bg-slate-50/60 transition-colors">
                        <td className="py-3 px-3">
                          <div className="font-bold text-slate-900">{t.venueName}</div>
                          <div className="text-[11px] text-slate-500">{t.neighborhoodArea}</div>
                        </td>
                        <td className="py-3 px-3">
                          <div className="font-semibold text-slate-800">{t.ownerName}</div>
                          <div className="text-[11px] text-slate-500">{t.ownerPhone}</div>
                        </td>
                        <td className="py-3 px-3 text-center font-mono font-medium text-slate-700">
                          ₹{t.activeRateWeekday || 1200} / ₹{t.activeRateWeekend || 1600}
                        </td>
                        <td className="py-3 px-3 text-center font-bold text-emerald-700">
                          {t.todayBookingsCount}
                        </td>
                        <td className="py-3 px-3 text-right font-semibold text-slate-800">
                          ₹{t.todayRevenue.toLocaleString('en-IN')}
                        </td>
                        <td className="py-3 px-3 text-center font-semibold text-slate-700">
                          {t.totalBookingsCount}
                        </td>
                        <td className="py-3 px-3 text-right font-bold text-slate-900">
                          ₹{t.totalRevenue.toLocaleString('en-IN')}
                        </td>
                        <td className="py-3 px-3 text-center">
                          <button
                            onClick={() => handleToggleTurfHold(t.turfId, t.isBookingHold)}
                            disabled={actionLoadingId === `turf_${t.turfId}`}
                            className={`px-3 py-1.5 rounded-lg text-[11px] font-bold transition-all ${
                              t.isBookingHold
                                ? 'bg-emerald-600 hover:bg-emerald-700 text-white'
                                : 'bg-amber-100 hover:bg-amber-200 text-amber-900 border border-amber-300'
                            }`}
                          >
                            {t.isBookingHold ? 'Resume' : 'Hold Bookings'}
                          </button>
                        </td>
                      </tr>
                    ))
                  ) : (
                    <tr>
                      <td colSpan={8} className="py-8 text-center text-slate-400 text-xs">
                        No verified turfs available yet.
                      </td>
                    </tr>
                  )}
                </tbody>
              </table>
            </div>
          </div>
        )}
      </main>

      {/* CREATE TOURNAMENT MODAL */}
      {showCreateTournModal && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-lg w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <div className="flex items-center justify-between border-b pb-3">
              <h3 className="font-bold text-slate-900 text-base flex items-center gap-2">
                <Trophy className="w-5 h-5 text-amber-500" />
                <span>Host New Platform Tournament</span>
              </h3>
              <button
                onClick={() => setShowCreateTournModal(false)}
                className="text-slate-400 hover:text-slate-700 text-lg font-bold"
              >
                ✕
              </button>
            </div>

            <form onSubmit={handleCreateTournament} className="space-y-3 text-xs">
              <div>
                <label className="font-bold text-slate-700 block mb-1">Tournament Title *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Games24 City Football Cup"
                  value={newTournTitle}
                  onChange={(e) => setNewTournTitle(e.target.value)}
                  className="w-full px-3 py-2 border rounded-xl"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Sport</label>
                  <select
                    value={newTournSport}
                    onChange={(e) => setNewTournSport(e.target.value)}
                    className="w-full px-3 py-2 border rounded-xl"
                  >
                    <option value="Football">Football</option>
                    <option value="Cricket">Cricket</option>
                    <option value="Badminton">Badminton</option>
                    <option value="Basketball">Basketball</option>
                  </select>
                </div>
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Date *</label>
                  <input
                    type="date"
                    required
                    value={newTournDate}
                    onChange={(e) => setNewTournDate(e.target.value)}
                    className="w-full px-3 py-2 border rounded-xl"
                  />
                </div>
              </div>

              <div>
                <label className="font-bold text-slate-700 block mb-1">Venue / Turf Name *</label>
                <input
                  type="text"
                  required
                  placeholder="e.g. Royal Turf Arena"
                  value={newTournVenue}
                  onChange={(e) => setNewTournVenue(e.target.value)}
                  className="w-full px-3 py-2 border rounded-xl"
                />
              </div>

              <div className="grid grid-cols-2 gap-3">
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Entry Fee (₹)</label>
                  <input
                    type="number"
                    value={newTournEntryFee}
                    onChange={(e) => setNewTournEntryFee(e.target.value)}
                    className="w-full px-3 py-2 border rounded-xl"
                  />
                </div>
                <div>
                  <label className="font-bold text-slate-700 block mb-1">Prize Pool</label>
                  <input
                    type="text"
                    value={newTournPrize}
                    onChange={(e) => setNewTournPrize(e.target.value)}
                    className="w-full px-3 py-2 border rounded-xl"
                  />
                </div>
              </div>

              <div className="pt-2 flex justify-end gap-2">
                <button
                  type="button"
                  onClick={() => setShowCreateTournModal(false)}
                  className="px-4 py-2 font-bold text-slate-600 bg-slate-100 rounded-xl"
                >
                  Cancel
                </button>
                <button
                  type="submit"
                  className="px-5 py-2 font-bold text-white bg-emerald-600 hover:bg-emerald-700 rounded-xl shadow-xs"
                >
                  Launch Tournament
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* QUICK CANCEL MODAL */}
      {cancelModalItem && (
        <div className="fixed inset-0 z-50 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200 space-y-4">
            <h3 className="font-bold text-slate-900 text-base">
              Reject Application for &quot;{cancelModalItem.venueName}&quot;
            </h3>
            <p className="text-xs text-slate-500">
              Please enter the reason for rejecting this turf owner application.
            </p>
            <textarea
              rows={3}
              value={cancelReasonText}
              onChange={(e) => setCancelReasonText(e.target.value)}
              placeholder="e.g. Incomplete KYC documentation or unverified contact"
              className="w-full p-3 text-xs border border-slate-300 rounded-xl focus:outline-hidden focus:ring-2 focus:ring-rose-500"
            />
            <div className="flex justify-end gap-2 text-xs font-bold">
              <button
                onClick={() => setCancelModalItem(null)}
                className="px-4 py-2 text-slate-600 bg-slate-100 rounded-xl"
              >
                Back
              </button>
              <button
                onClick={handleQuickCancelConfirm}
                className="px-4 py-2 text-white bg-rose-600 hover:bg-rose-700 rounded-xl"
              >
                Confirm Reject
              </button>
            </div>
          </div>
        </div>
      )}

      {/* FULL REGISTRATION INSPECTION MODAL */}
      <RegistrationDetailModal
        registration={selectedReg}
        onClose={() => setSelectedReg(null)}
        onActionComplete={() => {
          loadRegistrations();
          loadOverview();
        }}
      />
    </div>
  );
}
