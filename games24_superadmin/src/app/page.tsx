'use client';

import { useState, useEffect, useMemo, useCallback } from 'react';
import Navbar from '@/components/Navbar';
import RegistrationDetailModal from '@/components/RegistrationDetailModal';
import {
  AdminRegistration,
  SystemStats,
  getRegistrations,
  verifyRegistration,
  cancelRegistration,
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
  ExternalLink,
  ChevronRight,
  ShieldCheck,
  FileText,
  Image as ImageIcon,
  AlertCircle,
  Filter,
} from 'lucide-react';
import Link from 'next/link';

export default function RegistrationsPage() {
  const [activeTab, setActiveTab] = useState<'WAITING' | 'VERIFIED' | 'CANCEL'>('WAITING');
  const [items, setItems] = useState<AdminRegistration[]>([]);
  const [stats, setStats] = useState<SystemStats>({
    total: 0,
    waiting: 0,
    verified: 0,
    cancelled: 0,
    totalVerifiedTable: 0,
  });
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedReg, setSelectedReg] = useState<AdminRegistration | null>(null);
  const [page, setPage] = useState(1);
  const [quickVerifyingId, setQuickVerifyingId] = useState<number | null>(null);
  const [quickCancellingId, setQuickCancellingId] = useState<number | null>(null);
  const [cancelModalItem, setCancelModalItem] = useState<AdminRegistration | null>(null);
  const [cancelReasonText, setCancelReasonText] = useState('');
  const [toastMessage, setToastMessage] = useState<{ text: string; type: 'success' | 'error' } | null>(
    null
  );

  const showToast = (text: string, type: 'success' | 'error' = 'success') => {
    setToastMessage({ text, type });
    setTimeout(() => setToastMessage(null), 4000);
  };

  const loadData = useCallback(async () => {
    setLoading(true);
    try {
      let statusQuery = 'PENDING_APPROVAL';
      if (activeTab === 'VERIFIED') statusQuery = 'VERIFIED';
      if (activeTab === 'CANCEL') statusQuery = 'CANCELLED';

      const data = await getRegistrations({
        status: statusQuery,
        search: searchTerm,
        page,
        limit: 50,
      });

      setItems(data.items);
      setStats(data.stats);
    } catch (err: any) {
      showToast(err.message || 'Error connecting to backend server', 'error');
    } finally {
      setLoading(false);
    }
  }, [activeTab, searchTerm, page]);

  useEffect(() => {
    loadData();
  }, [loadData]);

  const handleQuickVerify = async (reg: AdminRegistration) => {
    setQuickVerifyingId(reg.id);
    try {
      await verifyRegistration(reg.id, { verifiedBy: 'Super Admin' });
      showToast(`Venue "${reg.venueName}" successfully verified & added to VerifiedAdmin!`);
      loadData();
    } catch (err: any) {
      showToast(err.message || 'Failed to verify registration', 'error');
    } finally {
      setQuickVerifyingId(null);
    }
  };

  const handleQuickCancelConfirm = async () => {
    if (!cancelModalItem) return;
    if (!cancelReasonText.trim()) {
      showToast('Please provide a reason for rejection', 'error');
      return;
    }

    setQuickCancellingId(cancelModalItem.id);
    try {
      await cancelRegistration(cancelModalItem.id, { reason: cancelReasonText.trim() });
      showToast(`Application for "${cancelModalItem.venueName}" cancelled`);
      setCancelModalItem(null);
      setCancelReasonText('');
      loadData();
    } catch (err: any) {
      showToast(err.message || 'Failed to cancel application', 'error');
    } finally {
      setQuickCancellingId(null);
    }
  };

  const getFullFileUrl = (url: string | null) => {
    if (!url) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return `${BACKEND_URL}${url.startsWith('/') ? '' : '/'}${url}`;
  };

  return (
    <div className="min-h-screen flex flex-col bg-slate-50">
      <Navbar waitingCount={stats.waiting} verifiedCount={stats.verified} />

      {/* Floating Toast Notification */}
      {toastMessage && (
        <div className="fixed top-20 right-6 z-50 animate-in fade-in slide-in-from-top-4 duration-200">
          <div
            className={`flex items-center gap-2.5 px-4 py-3 rounded-xl shadow-lg border text-sm font-semibold ${
              toastMessage.type === 'success'
                ? 'bg-emerald-900 text-white border-emerald-700 shadow-emerald-950/20'
                : 'bg-rose-900 text-white border-rose-700 shadow-rose-950/20'
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

      <main className="flex-1 max-w-7xl w-full mx-auto px-4 sm:px-6 lg:px-8 py-8 space-y-6">
        {/* Page Top Heading & Stats Overview */}
        <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4">
          <div>
            <h1 className="text-2xl font-extrabold text-slate-900 tracking-tight flex items-center gap-2.5">
              <span>Turf Owner Registrations</span>
              <span className="text-xs px-2.5 py-0.5 rounded-full font-bold bg-slate-200 text-slate-700">
                {stats.total} Total
              </span>
            </h1>
            <p className="text-sm text-slate-500 mt-1">
              Verify new turf owner applications, review venue photos & KYC documents in real time.
            </p>
          </div>

          <div className="flex items-center gap-3">
            <Link
              href="/admins"
              className="px-4 py-2 text-xs font-bold text-emerald-700 bg-emerald-50 hover:bg-emerald-100 border border-emerald-200 rounded-xl transition-all flex items-center gap-1.5 shadow-2xs"
            >
              <ShieldCheck className="w-4 h-4 text-emerald-600" />
              <span>View Verified Admins Table ({stats.totalVerifiedTable})</span>
            </Link>

            <button
              onClick={() => loadData()}
              disabled={loading}
              className="p-2.5 rounded-xl border border-slate-200 bg-white hover:bg-slate-50 text-slate-600 hover:text-slate-900 shadow-2xs transition-all disabled:opacity-50"
              title="Refresh Registrations"
            >
              <RefreshCw className={`w-4 h-4 ${loading ? 'animate-spin text-emerald-600' : ''}`} />
            </button>
          </div>
        </div>

        {/* 3 Metric Summary Cards */}
        <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
          {/* Waiting Card */}
          <div
            onClick={() => setActiveTab('WAITING')}
            className={`p-4 rounded-2xl border transition-all cursor-pointer ${
              activeTab === 'WAITING'
                ? 'bg-amber-50/70 border-amber-300 ring-2 ring-amber-400/30 shadow-sm'
                : 'bg-white border-slate-200/80 hover:border-amber-200 shadow-2xs'
            }`}
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold uppercase tracking-wider text-amber-800">
                Waiting Verification
              </span>
              <div className="w-8 h-8 rounded-lg bg-amber-100 text-amber-700 flex items-center justify-center">
                <Clock className="w-4 h-4" />
              </div>
            </div>
            <div className="mt-3 flex items-baseline gap-2">
              <span className="text-3xl font-extrabold text-slate-900">{stats.waiting}</span>
              <span className="text-xs text-amber-700 font-semibold">Pending Super Admin review</span>
            </div>
          </div>

          {/* Verified Card */}
          <div
            onClick={() => setActiveTab('VERIFIED')}
            className={`p-4 rounded-2xl border transition-all cursor-pointer ${
              activeTab === 'VERIFIED'
                ? 'bg-emerald-50/70 border-emerald-300 ring-2 ring-emerald-400/30 shadow-sm'
                : 'bg-white border-slate-200/80 hover:border-emerald-200 shadow-2xs'
            }`}
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold uppercase tracking-wider text-emerald-800">
                Verified & Approved
              </span>
              <div className="w-8 h-8 rounded-lg bg-emerald-100 text-emerald-700 flex items-center justify-center">
                <CheckCircle2 className="w-4 h-4" />
              </div>
            </div>
            <div className="mt-3 flex items-baseline gap-2">
              <span className="text-3xl font-extrabold text-slate-900">{stats.verified}</span>
              <span className="text-xs text-emerald-700 font-semibold">Stored in VerifiedAdmin table</span>
            </div>
          </div>

          {/* Cancelled Card */}
          <div
            onClick={() => setActiveTab('CANCEL')}
            className={`p-4 rounded-2xl border transition-all cursor-pointer ${
              activeTab === 'CANCEL'
                ? 'bg-rose-50/70 border-rose-300 ring-2 ring-rose-400/30 shadow-sm'
                : 'bg-white border-slate-200/80 hover:border-rose-200 shadow-2xs'
            }`}
          >
            <div className="flex items-center justify-between">
              <span className="text-xs font-bold uppercase tracking-wider text-rose-800">
                Cancelled / Rejected
              </span>
              <div className="w-8 h-8 rounded-lg bg-rose-100 text-rose-700 flex items-center justify-center">
                <XCircle className="w-4 h-4" />
              </div>
            </div>
            <div className="mt-3 flex items-baseline gap-2">
              <span className="text-3xl font-extrabold text-slate-900">{stats.cancelled}</span>
              <span className="text-xs text-rose-700 font-semibold">Rejected applications</span>
            </div>
          </div>
        </div>

        {/* Section Tabs & Search Filter Bar */}
        <div className="bg-white rounded-2xl border border-slate-200/80 shadow-2xs p-3 flex flex-col md:flex-row md:items-center md:justify-between gap-3">
          {/* Tabs */}
          <div className="flex items-center gap-1.5 p-1 bg-slate-100 rounded-xl">
            <button
              onClick={() => {
                setActiveTab('WAITING');
                setPage(1);
              }}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all ${
                activeTab === 'WAITING'
                  ? 'bg-white text-slate-900 shadow-xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <Clock className="w-3.5 h-3.5 text-amber-600" />
              <span>Waiting ({stats.waiting})</span>
            </button>

            <button
              onClick={() => {
                setActiveTab('VERIFIED');
                setPage(1);
              }}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all ${
                activeTab === 'VERIFIED'
                  ? 'bg-white text-slate-900 shadow-xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
              <span>Verified ({stats.verified})</span>
            </button>

            <button
              onClick={() => {
                setActiveTab('CANCEL');
                setPage(1);
              }}
              className={`flex items-center gap-2 px-4 py-2 rounded-lg text-xs font-bold transition-all ${
                activeTab === 'CANCEL'
                  ? 'bg-white text-slate-900 shadow-xs'
                  : 'text-slate-600 hover:text-slate-900'
              }`}
            >
              <XCircle className="w-3.5 h-3.5 text-rose-600" />
              <span>Cancel ({stats.cancelled})</span>
            </button>
          </div>

          {/* Search Box */}
          <div className="relative w-full md:w-80">
            <Search className="w-4 h-4 text-slate-400 absolute left-3 top-1/2 -translate-y-1/2" />
            <input
              type="text"
              placeholder="Search venue, owner, phone, email..."
              value={searchTerm}
              onChange={(e) => setSearchTerm(e.target.value)}
              className="w-full pl-9 pr-4 py-2 text-xs bg-slate-50 border border-slate-200 rounded-xl focus:bg-white focus:outline-hidden focus:ring-2 focus:ring-emerald-500 transition-all"
            />
          </div>
        </div>

        {/* Content List Section */}
        {loading ? (
          <div className="py-20 flex flex-col items-center justify-center gap-3 text-slate-400">
            <RefreshCw className="w-8 h-8 animate-spin text-emerald-600" />
            <span className="text-sm font-semibold">Loading applications from database...</span>
          </div>
        ) : items.length === 0 ? (
          <div className="py-20 bg-white rounded-2xl border border-slate-200 text-center p-8 space-y-3">
            <div className="w-12 h-12 mx-auto rounded-full bg-slate-100 flex items-center justify-center text-slate-400">
              <Filter className="w-6 h-6" />
            </div>
            <h3 className="font-bold text-slate-800 text-base">No registrations found</h3>
            <p className="text-xs text-slate-500 max-w-sm mx-auto">
              There are currently no turf owner applications in the{' '}
              <span className="font-semibold">{activeTab.toLowerCase()}</span> section matching your
              filter.
            </p>
          </div>
        ) : (
          <div className="space-y-4">
            {items.map((item) => (
              <div
                key={item.id}
                className="bg-white rounded-2xl border border-slate-200/90 shadow-2xs hover:shadow-md hover:border-slate-300 transition-all p-5"
              >
                <div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-4">
                  {/* Left Column: Venue & Owner Info */}
                  <div className="flex-1 space-y-3">
                    <div className="flex flex-wrap items-center gap-2">
                      <span className="font-mono text-xs font-bold px-2.5 py-0.5 rounded-full bg-slate-100 text-slate-800 border border-slate-200">
                        {item.trackingCode || `#REG-${item.id}`}
                      </span>

                      {item.status === 'PENDING_APPROVAL' && (
                        <span className="px-2.5 py-0.5 text-xs font-bold bg-amber-100 text-amber-800 rounded-full flex items-center gap-1">
                          <Clock className="w-3 h-3" /> Waiting Verification
                        </span>
                      )}
                      {item.status === 'VERIFIED' && (
                        <span className="px-2.5 py-0.5 text-xs font-bold bg-emerald-100 text-emerald-800 rounded-full flex items-center gap-1">
                          <CheckCircle2 className="w-3 h-3" /> Verified Partner
                        </span>
                      )}
                      {item.status === 'CANCELLED' && (
                        <span className="px-2.5 py-0.5 text-xs font-bold bg-rose-100 text-rose-800 rounded-full flex items-center gap-1">
                          <XCircle className="w-3 h-3" /> Cancelled
                        </span>
                      )}

                      <span className="text-xs text-slate-400">
                        Submitted: {new Date(item.createdAt).toLocaleDateString()}
                      </span>
                    </div>

                    <div>
                      <h3 className="text-lg font-bold text-slate-900 flex items-center gap-2">
                        <span>{item.venueName}</span>
                        <span className="text-xs font-normal text-slate-500">
                          in <span className="font-semibold text-slate-700">{item.neighborhoodArea}</span>
                        </span>
                      </h3>
                      <p className="text-xs text-slate-500 flex items-center gap-1 mt-0.5">
                        <MapPin className="w-3.5 h-3.5 text-slate-400 shrink-0" />
                        <span>{item.streetAddress}</span>
                      </p>
                    </div>

                    {/* Owner Details Pill Grid */}
                    <div className="grid grid-cols-1 sm:grid-cols-3 gap-2 text-xs pt-1">
                      <div className="flex items-center gap-1.5 text-slate-700 bg-slate-50 px-2.5 py-1.5 rounded-lg border border-slate-100">
                        <User className="w-3.5 h-3.5 text-slate-400" />
                        <span className="font-semibold">{item.ownerName}</span>
                      </div>
                      <div className="flex items-center gap-1.5 text-slate-700 bg-slate-50 px-2.5 py-1.5 rounded-lg border border-slate-100">
                        <Phone className="w-3.5 h-3.5 text-emerald-600" />
                        <span className="font-semibold">{item.ownerPhone}</span>
                        <span className="text-[10px] text-emerald-700 font-bold">✓</span>
                      </div>
                      <div className="flex items-center gap-1.5 text-slate-700 bg-slate-50 px-2.5 py-1.5 rounded-lg border border-slate-100 truncate">
                        <Mail className="w-3.5 h-3.5 text-emerald-600 shrink-0" />
                        <span className="font-semibold truncate">{item.ownerEmail}</span>
                        <span className="text-[10px] text-emerald-700 font-bold shrink-0">✓</span>
                      </div>
                    </div>

                    {/* Venue Photos Thumbnail Carousel */}
                    {item.photoUrls && item.photoUrls.length > 0 && (
                      <div className="pt-1">
                        <div className="text-[11px] font-bold text-slate-500 uppercase tracking-wider mb-1.5 flex items-center gap-1">
                          <ImageIcon className="w-3.5 h-3.5 text-slate-400" />
                          <span>Venue Photos ({item.photoUrls.length})</span>
                        </div>
                        <div className="flex items-center gap-2 overflow-x-auto pb-1">
                          {item.photoUrls.map((imgUrl, idx) => (
                            <img
                              key={idx}
                              src={getFullFileUrl(imgUrl)}
                              alt="Venue preview"
                              className="w-16 h-12 object-cover rounded-lg border border-slate-200 cursor-pointer hover:border-emerald-500 transition-all shrink-0"
                              onClick={() => setSelectedReg(item)}
                              onError={(e) => {
                                (e.target as HTMLElement).style.display = 'none';
                              }}
                            />
                          ))}
                        </div>
                      </div>
                    )}

                    {/* KYC Document Badges */}
                    <div className="flex flex-wrap items-center gap-2 pt-1">
                      <span className="text-[11px] font-bold text-slate-500 uppercase tracking-wider mr-1">
                        Documents:
                      </span>
                      <span
                        className={`text-xs px-2.5 py-1 rounded-md font-semibold flex items-center gap-1 border ${
                          item.aadhaarDocUrl
                            ? 'bg-emerald-50 border-emerald-200 text-emerald-800'
                            : 'bg-slate-100 border-slate-200 text-slate-400'
                        }`}
                      >
                        <FileText className="w-3 h-3" /> Aadhaar PDF {item.aadhaarDocUrl ? '✓' : '✗'}
                      </span>

                      <span
                        className={`text-xs px-2.5 py-1 rounded-md font-semibold flex items-center gap-1 border ${
                          item.panDocUrl
                            ? 'bg-emerald-50 border-emerald-200 text-emerald-800'
                            : 'bg-slate-100 border-slate-200 text-slate-400'
                        }`}
                      >
                        <FileText className="w-3 h-3" /> PAN PDF {item.panDocUrl ? '✓' : '✗'}
                      </span>

                      <span
                        className={`text-xs px-2.5 py-1 rounded-md font-semibold flex items-center gap-1 border ${
                          item.gstDocUrl
                            ? 'bg-emerald-50 border-emerald-200 text-emerald-800'
                            : 'bg-slate-100 border-slate-200 text-slate-400'
                        }`}
                      >
                        <FileText className="w-3 h-3" /> GST PDF {item.gstDocUrl ? '✓' : '✗'}
                      </span>
                    </div>

                    {item.cancelReason && (
                      <div className="p-2.5 rounded-lg bg-rose-50 border border-rose-200 text-rose-800 text-xs">
                        <span className="font-bold">Cancellation Reason: </span>
                        {item.cancelReason}
                      </div>
                    )}
                  </div>

                  {/* Right Column: Actions */}
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
                          disabled={quickCancellingId === item.id}
                          className="flex-1 px-3 py-2 text-xs font-bold text-rose-700 bg-rose-50 hover:bg-rose-100 border border-rose-200 rounded-xl transition-all flex items-center justify-center gap-1"
                        >
                          <XCircle className="w-3.5 h-3.5" />
                          <span>Cancel</span>
                        </button>

                        <button
                          onClick={() => handleQuickVerify(item)}
                          disabled={quickVerifyingId === item.id}
                          className="flex-1 px-4 py-2 text-xs font-bold text-white bg-emerald-600 hover:bg-emerald-700 rounded-xl shadow-md shadow-emerald-600/20 transition-all flex items-center justify-center gap-1.5 disabled:opacity-50"
                        >
                          <CheckCircle2 className="w-3.5 h-3.5" />
                          <span>{quickVerifyingId === item.id ? 'Saving...' : 'Verify'}</span>
                        </button>
                      </div>
                    )}

                    {item.status === 'VERIFIED' && (
                      <Link
                        href="/admins"
                        className="px-3 py-1.5 text-xs font-semibold text-emerald-700 bg-emerald-50 hover:bg-emerald-100 border border-emerald-200 rounded-lg flex items-center justify-center gap-1"
                      >
                        <ShieldCheck className="w-3.5 h-3.5" />
                        <span>In Verified Admins</span>
                      </Link>
                    )}
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </main>

      {/* Detail Review Modal */}
      {selectedReg && (
        <RegistrationDetailModal
          registration={selectedReg}
          onClose={() => setSelectedReg(null)}
          onActionComplete={() => {
            loadData();
            showToast('Registration status updated successfully!');
          }}
        />
      )}

      {/* Quick Cancel Reason Confirmation Dialog */}
      {cancelModalItem && (
        <div className="fixed inset-0 z-60 bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
          <div className="bg-white rounded-2xl max-w-md w-full p-6 shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-150 space-y-4">
            <div className="flex items-center gap-3 text-rose-600">
              <div className="w-10 h-10 rounded-xl bg-rose-100 flex items-center justify-center">
                <XCircle className="w-6 h-6" />
              </div>
              <div>
                <h3 className="font-bold text-slate-900 text-base">Reject Registration</h3>
                <p className="text-xs text-slate-500">{cancelModalItem.venueName}</p>
              </div>
            </div>

            <p className="text-xs text-slate-600">
              Please enter the reason for rejecting or cancelling this turf registration. This reason
              will be displayed to the venue owner on their mobile app:
            </p>

            <textarea
              rows={3}
              placeholder="e.g. Invalid PAN document or unclear court photos..."
              value={cancelReasonText}
              onChange={(e) => setCancelReasonText(e.target.value)}
              className="w-full p-3 text-xs border border-slate-300 rounded-xl focus:outline-hidden focus:ring-2 focus:ring-rose-500"
            />

            <div className="flex items-center justify-end gap-2 pt-2">
              <button
                onClick={() => setCancelModalItem(null)}
                className="px-4 py-2 text-xs font-semibold text-slate-600 hover:bg-slate-100 rounded-xl transition-colors"
              >
                Go Back
              </button>
              <button
                onClick={handleQuickCancelConfirm}
                disabled={quickCancellingId === cancelModalItem.id}
                className="px-4 py-2 text-xs font-bold text-white bg-rose-600 hover:bg-rose-700 rounded-xl transition-colors shadow-sm disabled:opacity-50"
              >
                {quickCancellingId === cancelModalItem.id ? 'Cancelling...' : 'Confirm Cancellation'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
