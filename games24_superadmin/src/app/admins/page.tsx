'use client';

import { useState, useEffect, useCallback } from 'react';
import Sidebar, { DashboardTab } from '@/components/Sidebar';
import Header from '@/components/Header';
import AdminDetailModal from '@/components/AdminDetailModal';
import {
  VerifiedAdmin,
  SystemStats,
  getVerifiedAdmins,
  getVerifiedAdminById,
  getStats,
  toggleTurfBookingHold,
  deleteVerifiedAdmin,
} from '@/lib/api';
import {
  ShieldCheck,
  Search,
  RefreshCw,
  Phone,
  MapPin,
  ChevronRight,
  Trash2,
  AlertTriangle,
  Check,
  X,
  Building2,
  CalendarDays,
  PlayCircle,
  PauseCircle,
  ExternalLink,
} from 'lucide-react';
import { useRouter } from 'next/navigation';
import Link from 'next/link';

export default function AdminsPage() {
  const router = useRouter();
  const [isMobileSidebarOpen, setIsMobileSidebarOpen] = useState(false);
  const [admins, setAdmins] = useState<VerifiedAdmin[]>([]);
  const [stats, setStats] = useState<SystemStats>({
    total: 0,
    waiting: 0,
    verified: 0,
    cancelled: 0,
    totalVerifiedTable: 0,
  });
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedAdmin, setSelectedAdmin] = useState<VerifiedAdmin | null>(null);
  const [page, setPage] = useState(1);
  const [totalPages, setTotalPages] = useState(1);
  const [totalCount, setTotalCount] = useState(0);

  // Actions state
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [deleteConfirmAdmin, setDeleteConfirmAdmin] = useState<VerifiedAdmin | null>(null);
  const [toast, setToast] = useState<{ message: string; type: 'success' | 'error' } | null>(null);

  const showToast = (message: string, type: 'success' | 'error' = 'success') => {
    setToast({ message, type });
    setTimeout(() => setToast(null), 4000);
  };

  const loadAdmins = useCallback(async () => {
    setLoading(true);
    try {
      const [adminData, statsData] = await Promise.all([
        getVerifiedAdmins({
          search: searchTerm,
          page,
          limit: 24,
        }),
        getStats().catch(() => ({
          total: 0,
          waiting: 0,
          verified: 0,
          cancelled: 0,
          totalVerifiedTable: 0,
        })),
      ]);

      setAdmins(adminData.items);
      setTotalPages(adminData.pagination.totalPages);
      setTotalCount(adminData.pagination.totalCount);
      setStats(statsData);
    } catch (err) {
      console.error('Error loading verified admins:', err);
    } finally {
      setLoading(false);
    }
  }, [searchTerm, page]);

  useEffect(() => {
    loadAdmins();
  }, [loadAdmins]);

  // ACTION: Hold / Resume Turf Owner Account
  const handleToggleHold = async (admin: VerifiedAdmin) => {
    const isCurrentlyHold = admin.isBookingHold || admin.status === 'HOLD';
    setActionLoadingId(`hold_${admin.id}`);
    try {
      const res = await toggleTurfBookingHold(admin.id, !isCurrentlyHold);
      showToast(res.message, 'success');
      
      // Optimistically update local list
      setAdmins((prev) =>
        prev.map((a) =>
          a.id === admin.id
            ? { ...a, isBookingHold: !isCurrentlyHold, status: !isCurrentlyHold ? 'HOLD' : 'VERIFIED' }
            : a
        )
      );

      // If modal is open for this admin, update selectedAdmin
      if (selectedAdmin && selectedAdmin.id === admin.id) {
        setSelectedAdmin({
          ...selectedAdmin,
          isBookingHold: !isCurrentlyHold,
          status: !isCurrentlyHold ? 'HOLD' : 'VERIFIED',
        });
      }
    } catch (err: unknown) {
      showToast((err as Error).message || 'Failed to toggle account hold status', 'error');
    } finally {
      setActionLoadingId(null);
    }
  };

  const handleInspect = async (admin: VerifiedAdmin) => {
    setSelectedAdmin(admin);
    try {
      const full = await getVerifiedAdminById(admin.id);
      setSelectedAdmin(full);
    } catch (e) {
      console.error('Error fetching admin details:', e);
    }
  };

  const handleReloadSelectedAdmin = async (adminId: number) => {
    try {
      const full = await getVerifiedAdminById(adminId);
      setSelectedAdmin(full);
      loadAdmins();
    } catch (e) {
      console.error('Error reloading admin:', e);
    }
  };

  // ACTION: Delete Turf Owner Account Permanently
  const handleDeleteAdmin = async (admin: VerifiedAdmin) => {
    setActionLoadingId(`del_${admin.id}`);
    try {
      const res = await deleteVerifiedAdmin(admin.id);
      showToast(res.message || `Deleted turf owner "${admin.venueName}" successfully.`, 'success');

      // Remove from local lists
      setAdmins((prev) => prev.filter((a) => a.id !== admin.id));
      setTotalCount((c) => Math.max(0, c - 1));
      if (selectedAdmin && selectedAdmin.id === admin.id) {
        setSelectedAdmin(null);
      }
      setDeleteConfirmAdmin(null);
    } catch (err: unknown) {
      showToast((err as Error).message || 'Failed to delete turf owner account', 'error');
    } finally {
      setActionLoadingId(null);
    }
  };

  return (
    <div className="min-h-screen bg-[#080B11] text-slate-100 font-sans selection:bg-[#D4FF00] selection:text-black">
      {/* Enterprise Sidebar */}
      <Sidebar
        activeTab="TURFS"
        onSelectTab={(tab) => {
          if (tab === 'TURFS') {
            // Already here
          } else {
            router.push('/');
          }
        }}
        waitingKycCount={stats.waiting}
        isOpenMobile={isMobileSidebarOpen}
        onCloseMobile={() => setIsMobileSidebarOpen(false)}
      />

      {/* Main Content Area */}
      <div className="lg:pl-72 flex flex-col min-h-screen">
        {/* Top Header */}
        <Header
          onToggleMobileSidebar={() => setIsMobileSidebarOpen(!isMobileSidebarOpen)}
          onSyncMetrics={loadAdmins}
          isSyncing={loading}
          onDeployTournament={() => router.push('/')}
          pendingKycCount={stats.waiting}
          onOpenKyc={() => router.push('/')}
          searchQuery={searchTerm}
          onSearchChange={(val) => {
            setSearchTerm(val);
            setPage(1);
          }}
          activeTabTitle="VERIFIED DIRECTORY"
        />

        {/* Floating Toast Notification */}
        {toast && (
          <div className="fixed bottom-6 right-6 z-50 animate-in slide-in-from-bottom-5 duration-200">
            <div
              className={`flex items-center gap-3 px-4 py-3 rounded-xl border shadow-2xl text-xs font-semibold backdrop-blur-md ${
                toast.type === 'success'
                  ? 'bg-[#0E1E17]/95 border-emerald-500/40 text-emerald-300'
                  : 'bg-[#2A1118]/95 border-rose-500/40 text-rose-300'
              }`}
            >
              {toast.type === 'success' ? (
                <Check className="w-4 h-4 text-emerald-400 shrink-0" />
              ) : (
                <AlertTriangle className="w-4 h-4 text-rose-400 shrink-0" />
              )}
              <span>{toast.message}</span>
              <button onClick={() => setToast(null)} className="ml-2 text-slate-400 hover:text-white">
                <X className="w-3.5 h-3.5" />
              </button>
            </div>
          </div>
        )}

        <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
          {/* Breadcrumb & Header Bar */}
          <div className="flex flex-col sm:flex-row sm:items-end justify-between gap-4 pb-6 border-b border-[#1E273A]">
            <div>
              <div className="flex items-center gap-2 text-[11px] font-mono text-slate-400 mb-2">
                <Link href="/" className="text-[#D4FF00] hover:underline font-bold">
                  GAMES24
                </Link>
                <span className="text-slate-600">/</span>
                <span className="text-slate-400">PARTNERS</span>
                <span className="text-slate-600">/</span>
                <span className="text-slate-200 uppercase">VERIFIED DIRECTORY</span>
              </div>
              <div className="flex items-center gap-3.5 flex-wrap">
                <h1 className="text-2xl sm:text-3xl font-extrabold text-white tracking-tight">
                  Verified Partners Directory
                </h1>
                <span className="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-md text-[11px] font-mono font-bold bg-emerald-500/10 text-emerald-400 border border-emerald-500/30">
                  <ShieldCheck className="w-3.5 h-3.5" />
                  {totalCount} ACTIVE PARTNERS
                </span>
              </div>
              <p className="text-xs text-slate-400 mt-1 max-w-2xl leading-relaxed font-mono">
                Authoritative registry of KYC-verified venue owners, operating court benchmarks, contact links, and account hold switches.
              </p>
            </div>

            <div className="flex items-center gap-3 shrink-0">
              <button
                onClick={() => loadAdmins()}
                disabled={loading}
                className="flex items-center gap-2 px-3.5 py-2 rounded-lg text-xs font-semibold bg-[#111726] hover:bg-[#182033] text-slate-200 border border-[#1E273A] transition-all disabled:opacity-50 font-mono active:scale-[0.98]"
              >
                <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin text-[#D4FF00]' : 'text-slate-400'}`} />
                <span>Refresh</span>
              </button>
              <Link
                href="/"
                className="flex items-center gap-2 px-3.5 py-2 rounded-lg text-xs font-bold bg-[#D4FF00] hover:bg-[#b8dd00] text-black shadow-md shadow-[#D4FF00]/15 transition-all font-mono active:scale-[0.98]"
              >
                <span>Back to Dashboard</span>
                <ChevronRight className="w-3.5 h-3.5 stroke-[2.5]" />
              </Link>
            </div>
          </div>

          {/* Search & Filter Toolbar */}
          <div className="flex items-center justify-between gap-4 p-4 rounded-xl bg-[#0E131F] border border-[#1E273A]">
            <div className="relative flex-1 max-w-md">
              <Search className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input
                type="text"
                placeholder="Search by venue name, neighborhood, or manager phone..."
                value={searchTerm}
                onChange={(e) => {
                  setSearchTerm(e.target.value);
                  setPage(1);
                }}
                className="w-full pl-9 pr-4 py-2 bg-[#05080E] border border-[#1E273A] rounded-lg text-xs text-white placeholder-slate-500 focus:outline-hidden focus:border-[#D4FF00] font-mono transition-all"
              />
            </div>

            <div className="flex items-center gap-2 text-xs font-mono text-slate-400">
              <span>Showing <strong className="text-white">{admins.length}</strong> of {totalCount} venues</span>
            </div>
          </div>

          {/* Partners Grid */}
          {loading ? (
            <div className="py-20 flex flex-col items-center justify-center text-slate-400">
              <RefreshCw className="w-8 h-8 animate-spin text-[#D4FF00] mb-3" />
              <span className="text-xs font-mono">Loading verified partner directory...</span>
            </div>
          ) : admins.length === 0 ? (
            <div className="py-20 text-center rounded-xl bg-[#0E131F] border border-[#1E273A] p-8">
              <ShieldCheck className="w-12 h-12 text-slate-600 mx-auto mb-3" />
              <h3 className="text-sm font-bold text-slate-300">No verified partners found</h3>
              <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto font-mono">
                {searchTerm ? 'Try adjusting your search query.' : 'Approved venues will appear here once verified.'}
              </p>
            </div>
          ) : (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
              {admins.map((admin) => {
                const isHeld = admin.isBookingHold || admin.status === 'HOLD';
                const isLoading = actionLoadingId === `hold_${admin.id}` || actionLoadingId === `del_${admin.id}`;

                return (
                  <div
                    key={admin.id}
                    className={`group relative flex flex-col justify-between p-5 rounded-xl bg-[#0E131F] border transition-all duration-200 ${
                      isHeld
                        ? 'border-amber-500/40 bg-[#16130D]'
                        : 'border-[#1E273A] hover:border-[#D4FF00]/40 hover:bg-[#121827]'
                    }`}
                  >
                    <div>
                      {/* Status & Tracking Chip */}
                      <div className="flex items-center justify-between gap-2 mb-3">
                        <span className="font-mono text-[10px] px-2 py-0.5 rounded bg-[#161D2E] text-slate-300 border border-[#28354F]">
                          {admin.trackingCode || `#ADM-${admin.id}`}
                        </span>

                        {isHeld ? (
                          <span className="inline-flex items-center gap-1.5 text-[11px] font-mono font-bold text-amber-300 bg-amber-500/15 px-2.5 py-0.5 rounded-full border border-amber-500/30">
                            <span className="w-1.5 h-1.5 rounded-full bg-amber-400" />
                            HOLD ACTIVE
                          </span>
                        ) : (
                          <span className="inline-flex items-center gap-1 text-[11px] font-mono font-bold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full border border-emerald-500/20">
                            <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                            VERIFIED
                          </span>
                        )}
                      </div>

                      {/* Venue Title & Location */}
                      <h3 className="text-base font-bold text-white group-hover:text-[#D4FF00] transition-colors">
                        {admin.venueName}
                      </h3>
                      <p className="text-xs text-slate-400 mt-1 flex items-center gap-1.5 font-mono">
                        <MapPin className="w-3.5 h-3.5 text-[#D4FF00] shrink-0" />
                        <span>{admin.neighborhoodArea || 'Tamil Nadu'}</span>
                      </p>

                      {/* Rates Bar */}
                      <div className="mt-4 pt-3 border-t border-[#1E273A] flex items-center justify-between text-xs font-mono">
                        <span className="text-slate-400">Active Rate</span>
                        <span className="text-white font-semibold">
                          ₹{admin.weekdayRate || 1200}
                          <span className="text-slate-500 font-normal"> /hr</span>
                        </span>
                      </div>

                      {/* Owner Contact */}
                      <div className="mt-2.5 flex items-center justify-between text-xs font-mono">
                        <span className="text-slate-400">Manager</span>
                        <span className="text-slate-300">{admin.ownerName}</span>
                      </div>
                    </div>

                    {/* Actions Bar */}
                    <div className="mt-5 pt-3 border-t border-[#1E273A] flex items-center justify-between gap-2">
                      <a
                        href={`tel:${admin.ownerPhone}`}
                        className="text-xs font-mono text-slate-400 hover:text-white flex items-center gap-1.5 transition-colors"
                      >
                        <Phone className="w-3 h-3 text-slate-500" />
                        <span>{admin.ownerPhone}</span>
                      </a>

                      <div className="flex items-center gap-1.5 font-mono">
                        {/* Hold / Resume Button */}
                        <button
                          type="button"
                          disabled={isLoading}
                          onClick={() => handleToggleHold(admin)}
                          className={`px-2.5 py-1.5 rounded-lg text-xs font-bold transition-all flex items-center gap-1 disabled:opacity-50 active:scale-[0.98] ${
                            isHeld
                              ? 'bg-emerald-600 hover:bg-emerald-500 text-white'
                              : 'bg-[#161D2E] hover:bg-amber-500/20 text-amber-300 border border-amber-500/30'
                          }`}
                          title={isHeld ? 'Resume Account & Live Bookings' : 'Place Account On Hold'}
                        >
                          {actionLoadingId === `hold_${admin.id}` ? (
                            <RefreshCw className="w-3 h-3 animate-spin" />
                          ) : isHeld ? (
                            'Resume'
                          ) : (
                            'Hold'
                          )}
                        </button>

                        {/* Delete Account Button */}
                        <button
                          type="button"
                          disabled={isLoading}
                          onClick={() => setDeleteConfirmAdmin(admin)}
                          className="p-1.5 rounded-lg text-rose-400 hover:text-white hover:bg-rose-600/30 border border-rose-500/30 transition-all disabled:opacity-50"
                          title="Delete Turf Owner Permanently"
                        >
                          <Trash2 className="w-3.5 h-3.5" />
                        </button>

                        {/* Inspect Button */}
                        <button
                          type="button"
                          onClick={() => handleInspect(admin)}
                          className="px-2.5 py-1.5 rounded-lg text-xs font-semibold bg-[#161D2E] hover:bg-[#20293F] text-slate-200 border border-[#28354F] transition-all flex items-center gap-1"
                        >
                          <span>Inspect</span>
                          <ChevronRight className="w-3 h-3" />
                        </button>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          {/* Pagination */}
          {totalPages > 1 && (
            <div className="flex items-center justify-center gap-2 pt-4">
              <button
                onClick={() => setPage((p) => Math.max(1, p - 1))}
                disabled={page <= 1}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#0E131F] border border-[#1E273A] text-slate-300 hover:text-white disabled:opacity-40 font-mono"
              >
                Previous
              </button>
              <span className="text-xs font-mono text-slate-400 px-3">
                Page {page} of {totalPages}
              </span>
              <button
                onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
                disabled={page >= totalPages}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#0E131F] border border-[#1E273A] text-slate-300 hover:text-white disabled:opacity-40 font-mono"
              >
                Next
              </button>
            </div>
          )}
        </main>
      </div>

      {/* Admin Detail Modal */}
      {selectedAdmin && (
        <AdminDetailModal
          admin={selectedAdmin}
          onClose={() => setSelectedAdmin(null)}
          onToggleHold={(adm) => handleToggleHold(adm)}
          onDelete={(adm) => {
            setSelectedAdmin(null);
            setDeleteConfirmAdmin(adm);
          }}
          onBranchUpdated={() => handleReloadSelectedAdmin(selectedAdmin.id)}
        />
      )}

      {/* Delete Turf Owner Confirmation Modal */}
      {deleteConfirmAdmin && (
        <div className="fixed inset-0 z-60 bg-black/80 backdrop-blur-md flex items-center justify-center p-4">
          <div className="bg-[#0E131F] border border-rose-500/40 rounded-2xl max-w-md w-full p-6 space-y-4 shadow-2xl animate-in fade-in zoom-in-95 duration-150 font-mono">
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
                You are about to delete <strong className="text-white">{deleteConfirmAdmin.venueName}</strong> managed by{' '}
                <strong className="text-white">{deleteConfirmAdmin.ownerName}</strong> ({deleteConfirmAdmin.ownerPhone}).
              </p>
              <ul className="list-disc pl-4 space-y-1 text-slate-400 font-mono text-[11px]">
                <li>Venue will be completely removed from player app discovery & booking.</li>
                <li>Associated slot offers, operating schedule, and open matches will be deleted.</li>
                <li>Any tournaments hosted at this turf will be cancelled.</li>
                <li>Turf owner will no longer be able to log in to the owner portal.</li>
              </ul>
            </div>

            <div className="flex items-center justify-end gap-3 pt-2">
              <button
                type="button"
                onClick={() => setDeleteConfirmAdmin(null)}
                className="px-4 py-2 rounded-lg text-xs font-semibold text-slate-300 hover:text-white bg-[#161D2E] border border-[#28354F]"
              >
                Cancel
              </button>
              <button
                type="button"
                disabled={actionLoadingId === `del_${deleteConfirmAdmin.id}`}
                onClick={() => handleDeleteAdmin(deleteConfirmAdmin)}
                className="flex items-center gap-1.5 px-4 py-2 rounded-lg text-xs font-bold bg-rose-600 hover:bg-rose-500 text-white shadow-lg shadow-rose-600/30 disabled:opacity-50 active:scale-[0.98]"
              >
                {actionLoadingId === `del_${deleteConfirmAdmin.id}` ? (
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
