'use client';

import { useState, useEffect, useCallback } from 'react';
import Navbar from '@/components/Navbar';
import AdminDetailModal from '@/components/AdminDetailModal';
import {
  VerifiedAdmin,
  SystemStats,
  getVerifiedAdmins,
  getStats,
  BACKEND_URL,
} from '@/lib/api';
import {
  ShieldCheck,
  Search,
  RefreshCw,
  Building,
  User,
  Phone,
  Mail,
  MapPin,
  ExternalLink,
  ChevronRight,
  FileCheck2,
  Calendar,
  Sparkles,
  Tag,
  CheckCircle2,
} from 'lucide-react';
import Link from 'next/link';

export default function AdminsPage() {
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

  return (
    <div className="min-h-screen flex flex-col bg-[#090D16] text-slate-100 font-sans">
      <Navbar waitingCount={stats.waiting} />

      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
        {/* Render-style Breadcrumb / Header */}
        <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 pb-6 border-b border-[#1E2638]">
          <div>
            <div className="flex items-center gap-2 text-xs text-slate-400 font-mono mb-1">
              <Link href="/" className="hover:text-indigo-400 transition-colors">
                Control Center
              </Link>
              <span>/</span>
              <span className="text-slate-200">Verified Venues Directory</span>
            </div>
            <h1 className="text-2xl font-extrabold text-white tracking-tight flex items-center gap-2.5">
              <span>Verified Partner Directory</span>
              <span className="text-xs px-2.5 py-0.5 rounded-full bg-emerald-500/15 text-emerald-400 border border-emerald-500/30 font-mono font-medium">
                {totalCount} Active Partners
              </span>
            </h1>
            <p className="text-xs text-slate-400 mt-1">
              Authoritative list of KYC-verified turf managers, physical location audits, and rate benchmarks.
            </p>
          </div>

          <div className="flex items-center gap-3">
            <button
              onClick={() => loadAdmins()}
              disabled={loading}
              className="flex items-center gap-2 px-3.5 py-2 rounded-lg text-xs font-semibold bg-[#161D2F] hover:bg-[#1E273E] text-slate-300 hover:text-white border border-[#28354F] transition-all disabled:opacity-50"
            >
              <RefreshCw className={`w-3.5 h-3.5 ${loading ? 'animate-spin text-indigo-400' : ''}`} />
              <span>Refresh</span>
            </button>
            <Link
              href="/"
              className="flex items-center gap-2 px-3.5 py-2 rounded-lg text-xs font-semibold bg-indigo-600 hover:bg-indigo-500 text-white shadow-lg shadow-indigo-600/25 transition-all"
            >
              <span>Back to Overview</span>
              <ChevronRight className="w-3.5 h-3.5" />
            </Link>
          </div>
        </div>

        {/* Search & Filter Toolbar */}
        <div className="flex items-center justify-between gap-4 p-4 rounded-xl bg-[#111625] border border-[#1F293D]">
          <div className="relative flex-1 max-w-md">
            <Search className="w-4 h-4 text-slate-500 absolute left-3.5 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search by venue name, area, or owner phone..."
              value={searchTerm}
              onChange={(e) => {
                setSearchTerm(e.target.value);
                setPage(1);
              }}
              className="w-full pl-9 pr-4 py-2 bg-[#161D2F] border border-[#28354F] rounded-lg text-xs text-white placeholder-slate-500 focus:outline-hidden focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500 transition-all"
            />
          </div>

          <div className="flex items-center gap-2 text-xs font-mono text-slate-400">
            <span>Showing {admins.length} of {totalCount} verified venues</span>
          </div>
        </div>

        {/* Partners Grid */}
        {loading ? (
          <div className="py-20 flex flex-col items-center justify-center text-slate-400">
            <RefreshCw className="w-8 h-8 animate-spin text-indigo-400 mb-3" />
            <span className="text-xs font-mono">Loading verified partner directory...</span>
          </div>
        ) : admins.length === 0 ? (
          <div className="py-20 text-center rounded-xl bg-[#111625] border border-[#1F293D] p-8">
            <ShieldCheck className="w-12 h-12 text-slate-600 mx-auto mb-3" />
            <h3 className="text-sm font-bold text-slate-300">No verified partners found</h3>
            <p className="text-xs text-slate-500 mt-1 max-w-sm mx-auto">
              {searchTerm ? 'Try adjusting your search query.' : 'Approved venues will appear here once verified.'}
            </p>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4">
            {admins.map((admin) => (
              <div
                key={admin.id}
                className="group relative flex flex-col justify-between p-5 rounded-xl bg-[#111625] border border-[#1F293D] hover:border-indigo-500/40 hover:bg-[#13192B] transition-all duration-200 shadow-sm"
              >
                <div>
                  {/* Status & Tracking Chip */}
                  <div className="flex items-center justify-between gap-2 mb-3">
                    <span className="font-mono text-[10px] px-2 py-0.5 rounded bg-[#182033] text-indigo-300 border border-[#28354F]">
                      {admin.trackingCode || `#ADM-${admin.id}`}
                    </span>
                    <span className="inline-flex items-center gap-1 text-[11px] font-semibold text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded-full border border-emerald-500/20">
                      <span className="w-1.5 h-1.5 rounded-full bg-emerald-400"></span>
                      Verified
                    </span>
                  </div>

                  {/* Venue Title & Location */}
                  <h3 className="text-base font-bold text-white group-hover:text-indigo-300 transition-colors">
                    {admin.venueName}
                  </h3>
                  <p className="text-xs text-slate-400 mt-1 flex items-center gap-1.5">
                    <MapPin className="w-3.5 h-3.5 text-indigo-400 shrink-0" />
                    <span>{admin.neighborhoodArea || 'Chennai'}</span>
                  </p>

                  {/* Rates Bar */}
                  <div className="mt-4 pt-3 border-t border-[#1C2538] flex items-center justify-between text-xs font-mono">
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

                {/* Inspect Action */}
                <div className="mt-5 pt-3 border-t border-[#1C2538] flex items-center justify-between gap-2">
                  <a
                    href={`tel:${admin.ownerPhone}`}
                    className="text-xs font-mono text-slate-400 hover:text-white flex items-center gap-1.5 transition-colors"
                  >
                    <Phone className="w-3 h-3 text-slate-500" />
                    <span>{admin.ownerPhone}</span>
                  </a>

                  <button
                    onClick={() => setSelectedAdmin(admin)}
                    className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#182033] hover:bg-indigo-600 hover:text-white text-indigo-300 border border-indigo-500/20 transition-all flex items-center gap-1"
                  >
                    <span>Inspect</span>
                    <ChevronRight className="w-3 h-3" />
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Pagination */}
        {totalPages > 1 && (
          <div className="flex items-center justify-center gap-2 pt-4">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page <= 1}
              className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#111625] border border-[#1F293D] text-slate-300 hover:text-white disabled:opacity-40"
            >
              Previous
            </button>
            <span className="text-xs font-mono text-slate-400 px-3">
              Page {page} of {totalPages}
            </span>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page >= totalPages}
              className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#111625] border border-[#1F293D] text-slate-300 hover:text-white disabled:opacity-40"
            >
              Next
            </button>
          </div>
        )}
      </main>

      {/* Admin Detail Modal */}
      {selectedAdmin && (
        <AdminDetailModal admin={selectedAdmin} onClose={() => setSelectedAdmin(null)} />
      )}
    </div>
  );
}
