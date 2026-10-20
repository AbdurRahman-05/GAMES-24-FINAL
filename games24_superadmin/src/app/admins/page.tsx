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
  Image as ImageIcon,
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
    } catch (err: any) {
      console.error('Error fetching verified admins:', err);
    } finally {
      setLoading(false);
    }
  }, [searchTerm, page]);

  useEffect(() => {
    loadAdmins();
  }, [loadAdmins]);

  const getFullFileUrl = (url: string | null) => {
    if (!url) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return `${BACKEND_URL}${url.startsWith('/') ? '' : '/'}${url}`;
  };

  return (
    <div className="min-h-screen flex flex-col bg-slate-50">
      <Navbar waitingCount={stats.waiting} verifiedCount={stats.verified} />

      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
        {/* Top Header & Overview */}
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <div className="flex items-center gap-2 text-xs font-semibold text-slate-500 mb-1">
              <Link href="/" className="hover:text-emerald-700 hover:underline">
                Registrations
              </Link>
              <span>/</span>
              <span className="text-slate-800">Verified Admins</span>
            </div>
            <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight flex items-center gap-2.5">
              <span>Verified Turf Admins Directory</span>
              <span className="text-xs px-2.5 py-0.5 rounded-full font-bold bg-emerald-100 text-emerald-800 border border-emerald-200">
                {totalCount} Verified
              </span>
            </h1>
            <p className="text-sm text-slate-500 mt-1">
              Active verified turf partners stored in the <code className="font-mono text-xs bg-slate-200/70 px-1.5 py-0.5 rounded text-slate-800 font-semibold">VerifiedAdmin</code> database table.
            </p>
          </div>

          <div className="flex items-center gap-3">
            <Link
              href="/"
              className="px-4 py-2 text-xs font-bold text-slate-700 bg-white hover:bg-slate-50 border border-slate-200 rounded-xl transition-all flex items-center gap-1.5 shadow-2xs"
            >
              <FileCheck2 className="w-4 h-4 text-slate-500" />
              <span>Back to Registrations</span>
            </Link>

            <button
              onClick={() => loadAdmins()}
              disabled={loading}
              className="p-2.5 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-slate-600 hover:text-slate-900 shadow-2xs transition-all disabled:opacity-50"
              title="Refresh Directory"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin text-emerald-600' : ''}`} />
            </button>
          </div>
        </div>

        {/* Search & Counter Bar */}
        <div className="bg-white rounded-2xl border border-slate-200/80 shadow-2xs p-3 flex flex-col sm:flex-row sm:items-center sm:justify-between gap-3">
          <div className="relative w-full sm:w-96">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search by venue, owner, phone, email, area..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-9 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-emerald-500 transition-all"
            />
          </div>

          <div className="text-xs font-semibold text-slate-500 flex items-center gap-2">
            <ShieldCheck className="w-4 h-4 text-emerald-600" />
            <span>Showing {admins.length} of {totalCount} verified turf owners</span>
          </div>
        </div>

        {/* Admin Cards Grid */}
        {loading ? (
          <div className="py-20 flex flex-col items-center justify-center gap-3 text-slate-400">
            <RefreshCw className="w-8 h-8 animate-spin text-emerald-600" />
            <span className="text-sm font-semibold">Loading verified admins...</span>
          </div>
        ) : admins.length === 0 ? (
          <div className="py-20 bg-white rounded-2xl border border-slate-200 text-center p-8 space-y-3">
            <div className="w-12 h-12 mx-auto rounded-full bg-emerald-50 text-emerald-600 flex items-center justify-center">
              <ShieldCheck className="w-6 h-6" />
            </div>
            <h3 className="font-bold text-slate-800 text-base">No verified admins found</h3>
            <p className="text-xs text-slate-500 max-w-sm mx-auto">
              Once turf registrations in the Waiting tab are verified by clicking &quot;Verify&quot;, they will
              be stored in the <code className="font-mono font-bold text-slate-700">VerifiedAdmin</code> table and appear here.
            </p>
            <div className="pt-2">
              <Link
                href="/"
                className="inline-flex items-center gap-1.5 px-4 py-2 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 rounded-xl transition-all shadow-md shadow-emerald-600/20"
              >
                Go to Pending Registrations
              </Link>
            </div>
          </div>
        ) : (
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-5">
            {admins.map((admin) => (
              <div
                key={admin.id}
                onClick={() => setSelectedAdmin(admin)}
                className="bg-white rounded-2xl border border-slate-200/90 shadow-2xs hover:shadow-md hover:border-emerald-300 transition-all cursor-pointer p-5 flex flex-col justify-between group"
              >
                <div className="space-y-3">
                  {/* Card Top: Tracking & Verified Badge */}
                  <div className="flex items-center justify-between">
                    <span className="font-mono text-[11px] font-bold px-2.5 py-0.5 rounded-full bg-slate-100 text-slate-700 border border-slate-200">
                      {admin.trackingCode || `#ADM-${admin.id}`}
                    </span>
                    <span className="px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider bg-emerald-100 text-emerald-800 rounded-full flex items-center gap-1">
                      <ShieldCheck className="w-3 h-3 text-emerald-600" />
                      Verified Partner
                    </span>
                  </div>

                  {/* Venue & Location */}
                  <div>
                    <h3 className="text-base font-bold text-slate-900 group-hover:text-emerald-700 transition-colors">
                      {admin.venueName}
                    </h3>
                    <p className="text-xs text-slate-500 flex items-center gap-1 mt-0.5">
                      <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                      <span>{admin.neighborhoodArea}</span>
                    </p>
                  </div>

                  {/* Owner Contact */}
                  <div className="space-y-1.5 text-xs bg-slate-50/80 p-3 rounded-xl border border-slate-100">
                    <div className="flex items-center justify-between">
                      <span className="text-slate-500">Owner</span>
                      <span className="font-semibold text-slate-800">{admin.ownerName}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-slate-500">Mobile</span>
                      <span className="font-semibold text-slate-800">{admin.ownerPhone}</span>
                    </div>
                    <div className="flex items-center justify-between truncate">
                      <span className="text-slate-500 shrink-0">Email</span>
                      <span className="font-semibold text-slate-800 truncate ml-2">
                        {admin.ownerEmail}
                      </span>
                    </div>
                  </div>

                  {/* Photos Preview Thumbnail */}
                  {admin.photoUrls && admin.photoUrls.length > 0 && (
                    <div className="flex items-center gap-1.5 overflow-hidden">
                      {admin.photoUrls.slice(0, 3).map((photo, pIdx) => (
                        <img
                          key={pIdx}
                          src={getFullFileUrl(photo)}
                          alt="Thumbnail"
                          className="w-14 h-10 object-cover rounded-lg border border-slate-200"
                          onError={(e) => {
                            (e.target as HTMLElement).style.display = 'none';
                          }}
                        />
                      ))}
                      {admin.photoUrls.length > 3 && (
                        <div className="w-10 h-10 rounded-lg bg-slate-100 border border-slate-200 text-[10px] font-bold text-slate-600 flex items-center justify-center">
                          +{admin.photoUrls.length - 3}
                        </div>
                      )}
                    </div>
                  )}

                  {/* Facilities list preview */}
                  {admin.amenities && admin.amenities.length > 0 && (
                    <div className="flex flex-wrap gap-1">
                      {admin.amenities.slice(0, 3).map((am, amIdx) => (
                        <span
                          key={amIdx}
                          className="px-2 py-0.5 rounded text-[10px] font-medium bg-slate-100 text-slate-700"
                        >
                          {am}
                        </span>
                      ))}
                      {admin.amenities.length > 3 && (
                        <span className="px-1.5 py-0.5 text-[10px] text-slate-400">
                          +{admin.amenities.length - 3} more
                        </span>
                      )}
                    </div>
                  )}
                </div>

                {/* Card Bottom: Verified Date & Click Action */}
                <div className="pt-4 border-t border-slate-100 mt-4 flex items-center justify-between text-xs">
                  <span className="text-slate-400 text-[11px] flex items-center gap-1">
                    <Calendar className="w-3 h-3" />
                    {new Date(admin.verifiedAt).toLocaleDateString()}
                  </span>

                  <span className="text-emerald-600 font-bold flex items-center gap-1 group-hover:translate-x-0.5 transition-transform">
                    <span>View Admin Details</span>
                    <ChevronRight className="w-3.5 h-3.5" />
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}

        {/* Pagination Controls */}
        {totalPages > 1 && (
          <div className="flex items-center justify-center gap-2 pt-6">
            <button
              onClick={() => setPage((p) => Math.max(1, p - 1))}
              disabled={page <= 1}
              className="px-4 py-2 text-xs font-semibold text-slate-700 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 disabled:opacity-40"
            >
              Previous
            </button>
            <span className="text-xs font-semibold text-slate-600 px-3">
              Page {page} of {totalPages}
            </span>
            <button
              onClick={() => setPage((p) => Math.min(totalPages, p + 1))}
              disabled={page >= totalPages}
              className="px-4 py-2 text-xs font-semibold text-slate-700 bg-white border border-slate-200 rounded-xl hover:bg-slate-50 disabled:opacity-40"
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
