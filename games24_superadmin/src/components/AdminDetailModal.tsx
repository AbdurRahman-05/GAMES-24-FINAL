'use client';

import { useState } from 'react';
import { VerifiedAdmin, BACKEND_URL, verifyRegistration, cancelRegistration } from '@/lib/api';
import {
  X,
  ShieldCheck,
  Building,
  Phone,
  Mail,
  MapPin,
  Sparkles,
  Image as ImageIcon,
  FileText,
  CreditCard,
  ExternalLink,
  Calendar,
  CheckCircle2,
  Tag,
  Trash2,
  GitBranch,
  Check,
  AlertCircle,
  Loader2,
} from 'lucide-react';

interface Props {
  admin: VerifiedAdmin | null;
  onClose: () => void;
  onToggleHold?: (admin: VerifiedAdmin) => void;
  onDelete?: (admin: VerifiedAdmin) => void;
  onBranchUpdated?: () => void;
}

export default function AdminDetailModal({ admin, onClose, onToggleHold, onDelete, onBranchUpdated }: Props) {
  const [previewImage, setPreviewImage] = useState<string | null>(null);
  const [actionLoadingId, setActionLoadingId] = useState<string | null>(null);
  const [actionMsg, setActionMsg] = useState<{ text: string; type: 'success' | 'error' } | null>(null);

  if (!admin) return null;

  const handleApproveBranch = async (branchId: number) => {
    setActionLoadingId(`approve_${branchId}`);
    setActionMsg(null);
    try {
      await verifyRegistration(branchId);
      setActionMsg({ text: 'Branch successfully approved and activated!', type: 'success' });
      if (onBranchUpdated) {
        setTimeout(() => onBranchUpdated(), 600);
      }
    } catch (err: any) {
      setActionMsg({ text: err.message || 'Failed to approve branch', type: 'error' });
    } finally {
      setActionLoadingId(null);
    }
  };

  const handleRejectBranch = async (branchId: number) => {
    if (!confirm('Are you sure you want to reject this branch application?')) return;
    setActionLoadingId(`reject_${branchId}`);
    setActionMsg(null);
    try {
      await cancelRegistration(branchId, { reason: 'Rejected by Super Admin' });
      setActionMsg({ text: 'Branch application rejected.', type: 'success' });
      if (onBranchUpdated) {
        setTimeout(() => onBranchUpdated(), 600);
      }
    } catch (err: any) {
      setActionMsg({ text: err.message || 'Failed to reject branch', type: 'error' });
    } finally {
      setActionLoadingId(null);
    }
  };

  const getFullFileUrl = (url: string | null) => {
    if (!url) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return `${BACKEND_URL}${url.startsWith('/') ? '' : '/'}${url}`;
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/75 backdrop-blur-md flex items-center justify-center p-4">
      <div className="relative bg-[#0D121F] rounded-2xl max-w-4xl w-full max-h-[92vh] flex flex-col shadow-2xl border border-[#222B3F] text-slate-100 animate-in fade-in zoom-in-95 duration-150">
        {/* Render-style Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#1E2638] bg-[#111727]/80 rounded-t-2xl">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-500/15 text-emerald-400 border border-emerald-500/30 flex items-center justify-center shadow-lg shadow-emerald-500/10">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2 flex-wrap">
                <h2 className="text-lg font-bold text-white tracking-tight">{admin.venueName}</h2>
                <span className="font-mono text-xs px-2.5 py-0.5 rounded-md bg-[#182033] text-indigo-300 font-semibold border border-[#28354F]">
                  {admin.trackingCode || `#ADM-${admin.id}`}
                </span>
                <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                  Verified Partner
                </span>
                {admin.isBookingHold && (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-500/15 text-amber-300 border border-amber-500/30">
                    Booking Hold Active
                  </span>
                )}
              </div>
              <p className="text-xs text-slate-400 mt-0.5 font-mono">
                Verified on {new Date(admin.verifiedAt).toLocaleDateString()} by{' '}
                <span className="text-slate-200 font-medium">{admin.verifiedBy}</span>
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-[#1E273A] transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Scrollable Content */}
        <div className="overflow-y-auto p-6 space-y-6">
          {/* Owner & Venue Location */}
          <div className="bg-[#121827] rounded-xl p-5 border border-[#1E2638]">
            <h3 className="text-xs font-bold uppercase tracking-wider text-indigo-400 mb-4 flex items-center gap-2">
              <Building className="w-4 h-4" /> Owner Identity & Location
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-xs text-slate-400">Owner Full Name</span>
                <p className="font-semibold text-white mt-0.5">{admin.ownerName}</p>
              </div>
              <div>
                <span className="text-xs text-slate-400">Venue Area</span>
                <p className="font-semibold text-white mt-0.5 flex items-center gap-1.5">
                  <MapPin className="w-3.5 h-3.5 text-indigo-400" />
                  {admin.neighborhoodArea}
                </p>
              </div>
              <div>
                <span className="text-xs text-slate-400">Verified Mobile</span>
                <div className="flex items-center gap-2 mt-0.5">
                  <Phone className="w-3.5 h-3.5 text-slate-400" />
                  <span className="font-mono text-white font-medium">{admin.ownerPhone}</span>
                  <span className="px-2 py-0.5 text-[10px] font-bold rounded bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                    Verified ✓
                  </span>
                </div>
              </div>
              <div>
                <span className="text-xs text-slate-400">Verified Email</span>
                <div className="flex items-center gap-2 mt-0.5">
                  <Mail className="w-3.5 h-3.5 text-slate-400" />
                  <span className="font-mono text-white font-medium">{admin.ownerEmail}</span>
                </div>
              </div>
              <div className="md:col-span-2">
                <span className="text-xs text-slate-400">Street Address</span>
                <p className="text-slate-300 mt-0.5">{admin.streetAddress}</p>
              </div>
            </div>
          </div>

          {/* Pricing & Rate Cards */}
          <div className="bg-[#121827] rounded-xl p-5 border border-[#1E2638]">
            <h3 className="text-xs font-bold uppercase tracking-wider text-indigo-400 mb-4 flex items-center gap-2">
              <Tag className="w-4 h-4" /> Active Rate Configuration
            </h3>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              <div className="p-3 rounded-lg bg-[#161D2F] border border-[#232C42]">
                <span className="text-[11px] text-slate-400">Weekday Hourly</span>
                <p className="font-mono text-sm font-bold text-white mt-1">₹{admin.weekdayRate || 1200}/hr</p>
              </div>
              <div className="p-3 rounded-lg bg-[#161D2F] border border-[#232C42]">
                <span className="text-[11px] text-slate-400">Weekend Hourly</span>
                <p className="font-mono text-sm font-bold text-indigo-300 mt-1">₹{admin.weekendRate || 1600}/hr</p>
              </div>
              <div className="p-3 rounded-lg bg-[#161D2F] border border-[#232C42]">
                <span className="text-[11px] text-slate-400">Day Slot</span>
                <p className="font-mono text-sm font-bold text-white mt-1">₹{admin.dayRate || 1000}/hr</p>
              </div>
              <div className="p-3 rounded-lg bg-[#161D2F] border border-[#232C42]">
                <span className="text-[11px] text-slate-400">Night Slot (Floodlights)</span>
                <p className="font-mono text-sm font-bold text-amber-300 mt-1">₹{admin.nightRate || 1800}/hr</p>
              </div>
            </div>
          </div>

          {/* Payout & KYC Info */}
          <div className="bg-[#121827] rounded-xl p-5 border border-[#1E2638]">
            <h3 className="text-xs font-bold uppercase tracking-wider text-indigo-400 mb-4 flex items-center gap-2">
              <CreditCard className="w-4 h-4" /> Payout & Tax Settlement
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
              <div>
                <span className="text-xs text-slate-400">Bank Account</span>
                <p className="font-mono text-white mt-0.5">{admin.bankAccount || 'Not provided'}</p>
              </div>
              <div>
                <span className="text-xs text-slate-400">IFSC Code</span>
                <p className="font-mono text-white mt-0.5">{admin.ifscCode || 'Not provided'}</p>
              </div>
              <div>
                <span className="text-xs text-slate-400">UPI ID</span>
                <p className="font-mono text-indigo-300 font-semibold mt-0.5">{admin.upiId || 'Not provided'}</p>
              </div>
            </div>
          </div>

          {/* Venue Photos */}
          {admin.photoUrls && admin.photoUrls.length > 0 && (
            <div className="bg-[#121827] rounded-xl p-5 border border-[#1E2638]">
              <h3 className="text-xs font-bold uppercase tracking-wider text-indigo-400 mb-4 flex items-center gap-2">
                <ImageIcon className="w-4 h-4" /> Venue Photos ({admin.photoUrls.length})
              </h3>
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
                {admin.photoUrls.map((url, i) => (
                  <div
                    key={i}
                    onClick={() => setPreviewImage(getFullFileUrl(url))}
                    className="relative aspect-video rounded-lg overflow-hidden border border-[#232C42] bg-[#161D2F] cursor-pointer group"
                  >
                    {/* eslint-disable-next-line @next/next/no-img-element */}
                    <img
                      src={getFullFileUrl(url)}
                      alt={`Photo ${i + 1}`}
                      className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
                    />
                    <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                      <span className="text-[11px] text-white font-mono bg-black/70 px-2 py-1 rounded">Zoom</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Action Message Alert */}
          {actionMsg && (
            <div
              className={`p-4 rounded-xl border flex items-center justify-between gap-3 ${
                actionMsg.type === 'success'
                  ? 'bg-emerald-500/15 border-emerald-500/30 text-emerald-300'
                  : 'bg-rose-500/15 border-rose-500/30 text-rose-300'
              }`}
            >
              <div className="flex items-center gap-2 text-sm font-semibold">
                {actionMsg.type === 'success' ? (
                  <Check className="w-4 h-4 text-emerald-400" />
                ) : (
                  <AlertCircle className="w-4 h-4 text-rose-400" />
                )}
                <span>{actionMsg.text}</span>
              </div>
              <button
                type="button"
                onClick={() => setActionMsg(null)}
                className="text-xs opacity-75 hover:opacity-100"
              >
                Dismiss
              </button>
            </div>
          )}

          {/* Pending Branch Applications */}
          {admin.pendingBranchApplications && admin.pendingBranchApplications.length > 0 && (
            <div className="bg-[#121827] rounded-xl p-5 border border-amber-500/40 shadow-lg shadow-amber-500/5">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-xs font-bold uppercase tracking-wider text-amber-400 flex items-center gap-2">
                  <GitBranch className="w-4 h-4 text-amber-400" /> Pending Branch Applications ({admin.pendingBranchApplications.length})
                </h3>
                <span className="text-[10px] font-semibold uppercase px-2 py-0.5 rounded bg-amber-500/20 text-amber-300 border border-amber-500/30">
                  Verification Required
                </span>
              </div>

              <div className="space-y-4">
                {admin.pendingBranchApplications.map((branch) => (
                  <div
                    key={branch.id}
                    className="p-4 rounded-xl bg-[#161D2F] border border-[#232C42] space-y-3"
                  >
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-[#232C42] pb-3">
                      <div>
                        <div className="flex items-center gap-2">
                          <h4 className="text-sm font-bold text-white">{branch.venueName}</h4>
                          <span className="font-mono text-[10px] px-2 py-0.5 rounded bg-[#1F293D] text-indigo-300 border border-[#2D3A54]">
                            {branch.trackingCode || `#BR-${branch.id}`}
                          </span>
                        </div>
                        <p className="text-xs text-slate-400 mt-1 flex items-center gap-1.5">
                          <MapPin className="w-3.5 h-3.5 text-indigo-400" />
                          <span>{branch.neighborhoodArea}</span>
                          <span className="text-slate-600">•</span>
                          <span>{branch.streetAddress}</span>
                        </p>
                      </div>

                      <div className="flex items-center gap-2 self-end sm:self-auto">
                        <button
                          type="button"
                          disabled={actionLoadingId !== null}
                          onClick={() => handleRejectBranch(branch.id)}
                          className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-rose-500/15 hover:bg-rose-500/25 text-rose-300 border border-rose-500/30 transition-all disabled:opacity-50"
                        >
                          {actionLoadingId === `reject_${branch.id}` ? 'Rejecting...' : 'Reject'}
                        </button>
                        <button
                          type="button"
                          disabled={actionLoadingId !== null}
                          onClick={() => handleApproveBranch(branch.id)}
                          className="px-3.5 py-1.5 rounded-lg text-xs font-semibold bg-emerald-600 hover:bg-emerald-500 text-white shadow-lg shadow-emerald-600/20 transition-all flex items-center gap-1.5 disabled:opacity-50"
                        >
                          {actionLoadingId === `approve_${branch.id}` ? (
                            <>
                              <Loader2 className="w-3.5 h-3.5 animate-spin" />
                              <span>Approving...</span>
                            </>
                          ) : (
                            <>
                              <Check className="w-3.5 h-3.5" />
                              <span>Approve & Activate Branch</span>
                            </>
                          )}
                        </button>
                      </div>
                    </div>

                    {/* Branch Contacts */}
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs text-slate-300">
                      <div>
                        <span className="text-slate-500">Owner Contact:</span>{' '}
                        <span className="font-mono text-white">{branch.ownerPhone}</span>
                      </div>
                      {branch.alternativePhone && (
                        <div>
                          <span className="text-slate-500">Alt Phone:</span>{' '}
                          <span className="font-mono text-indigo-300">{branch.alternativePhone}</span>
                        </div>
                      )}
                    </div>

                    {/* Branch Photos Gallery */}
                    {branch.photoUrls && branch.photoUrls.length > 0 ? (
                      <div>
                        <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider block mb-2">
                          Uploaded Branch Photos ({branch.photoUrls.length})
                        </span>
                        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                          {branch.photoUrls.map((pUrl, pIdx) => (
                            <div
                              key={pIdx}
                              onClick={() => setPreviewImage(getFullFileUrl(pUrl))}
                              className="relative aspect-video rounded-lg overflow-hidden border border-[#232C42] bg-[#111727] cursor-pointer group"
                            >
                              {/* eslint-disable-next-line @next/next/no-img-element */}
                              <img
                                src={getFullFileUrl(pUrl)}
                                alt={`Branch Photo ${pIdx + 1}`}
                                className="w-full h-full object-cover group-hover:scale-105 transition-transform duration-200"
                              />
                              <div className="absolute inset-0 bg-black/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center">
                                <span className="text-[10px] text-white font-mono bg-black/70 px-1.5 py-0.5 rounded">
                                  Zoom
                                </span>
                              </div>
                            </div>
                          ))}
                        </div>
                      </div>
                    ) : (
                      <p className="text-xs text-slate-500 italic">No photos uploaded for this branch application.</p>
                    )}
                  </div>
                ))}
              </div>
            </div>
          )}

          {/* Approved Branches */}
          {admin.approvedBranches && admin.approvedBranches.length > 0 && (
            <div className="bg-[#121827] rounded-xl p-5 border border-[#1E2638]">
              <h3 className="text-xs font-bold uppercase tracking-wider text-emerald-400 mb-4 flex items-center gap-2">
                <GitBranch className="w-4 h-4 text-emerald-400" /> Active Verified Branches ({admin.approvedBranches.length})
              </h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {admin.approvedBranches.map((br) => (
                  <div
                    key={br.id}
                    className="p-3.5 rounded-xl bg-[#161D2F] border border-[#232C42] space-y-2"
                  >
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-white text-sm">{br.venueName}</span>
                      <span className="text-[10px] font-semibold px-2 py-0.5 rounded bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                        Active
                      </span>
                    </div>
                    <p className="text-xs text-slate-400 flex items-center gap-1.5">
                      <MapPin className="w-3.5 h-3.5 text-indigo-400" />
                      <span>{br.neighborhoodArea}</span>
                    </p>
                    <div className="flex items-center justify-between text-xs text-slate-400 pt-1 border-t border-[#232C42]">
                      <span className="font-mono">Photos: {br.photosCount || br.photoUrls?.length || 0}</span>
                      <span className="font-mono text-indigo-300 font-semibold">₹{br.weekdayRate || 1200}/hr</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-[#1E2638] bg-[#111727]/90 rounded-b-2xl flex items-center justify-between">
          <div className="flex items-center gap-2">
            {onToggleHold && (
              <button
                type="button"
                onClick={() => onToggleHold(admin)}
                className={`px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                  admin.isBookingHold || admin.status === 'HOLD'
                    ? 'bg-emerald-600 hover:bg-emerald-500 text-white'
                    : 'bg-[#182033] hover:bg-amber-500/20 text-amber-300 border border-amber-500/30'
                }`}
              >
                {admin.isBookingHold || admin.status === 'HOLD' ? 'Resume Account & Bookings' : 'Place Account On Hold'}
              </button>
            )}
            {onDelete && (
              <button
                type="button"
                onClick={() => onDelete(admin)}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-rose-600/20 hover:bg-rose-600 hover:text-white text-rose-300 border border-rose-500/30 transition-all flex items-center gap-1.5"
              >
                <Trash2 className="w-3.5 h-3.5" />
                <span>Delete Account</span>
              </button>
            )}
          </div>

          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-lg text-xs font-semibold text-slate-300 hover:text-white bg-[#182033] hover:bg-[#202A42] border border-[#28354F] transition-all"
          >
            Close
          </button>
        </div>

        {/* Image Zoom Lightbox */}
        {previewImage && (
          <div
            className="fixed inset-0 z-60 bg-black/90 flex items-center justify-center p-4 cursor-pointer"
            onClick={() => setPreviewImage(null)}
          >
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src={previewImage} alt="Preview" className="max-w-4xl max-h-[85vh] rounded-xl object-contain shadow-2xl" />
          </div>
        )}
      </div>
    </div>
  );
}
