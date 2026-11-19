'use client';

import { useState } from 'react';
import { VerifiedAdmin, resolveFileUrl, verifyRegistration, cancelRegistration } from '@/lib/api';
import {
  X,
  ShieldCheck,
  Building,
  Phone,
  Mail,
  MapPin,
  Image as ImageIcon,
  CreditCard,
  CheckCircle2,
  Tag,
  Trash2,
  GitBranch,
  Check,
  AlertCircle,
  Loader2,
  FileText,
  ExternalLink,
  Building2,
  PlayCircle,
  PauseCircle,
  Crosshair,
} from 'lucide-react';
import TurfRadarMap from '@/components/TurfRadarMap';

interface Props {
  admin: VerifiedAdmin | null;
  onClose: () => void;
  onToggleHold?: (admin: VerifiedAdmin) => void;
  onDelete?: (admin: VerifiedAdmin) => void;
  onBranchUpdated?: () => void;
}

export default function AdminDetailModal({ admin, onClose, onToggleHold, onDelete, onBranchUpdated }: Props) {
  const [previewImage, setPreviewImage] = useState<string | null>(null);
  const [showRadarModal, setShowRadarModal] = useState(false);
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
    } catch (err: unknown) {
      setActionMsg({ text: (err as Error).message || 'Failed to approve branch', type: 'error' });
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
    } catch (err: unknown) {
      setActionMsg({ text: (err as Error).message || 'Failed to reject branch', type: 'error' });
    } finally {
      setActionLoadingId(null);
    }
  };

  const getFullFileUrl = (url: string | null) => {
    return resolveFileUrl(url);
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
      <div className="relative bg-[#0A0E17] rounded-2xl max-w-4xl w-full max-h-[92vh] flex flex-col shadow-2xl border border-[#1E273A] text-slate-100 animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#1E273A] bg-[#0E131F] rounded-t-2xl">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-500/15 text-emerald-400 border border-emerald-500/30 flex items-center justify-center shadow-lg shadow-emerald-500/10 shrink-0">
              <ShieldCheck className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2 flex-wrap">
                <h2 className="text-lg font-bold text-white tracking-tight">{admin.venueName}</h2>
                <span className="font-mono text-xs px-2.5 py-0.5 rounded-md bg-[#161D2E] text-slate-300 font-semibold border border-[#28354F]">
                  {admin.trackingCode || `#ADM-${admin.id}`}
                </span>
                <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-mono font-bold bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                  VERIFIED PARTNER
                </span>
                {admin.isBookingHold && (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-mono font-bold bg-amber-500/15 text-amber-300 border border-amber-500/30">
                    HOLD ACTIVE
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
            className="p-1.5 rounded-lg text-slate-400 hover:text-white hover:bg-[#161D2E] transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Scrollable Content */}
        <div className="overflow-y-auto p-6 space-y-5">
          {/* Owner & Venue Location */}
          <div className="bg-[#0E131F] rounded-xl p-5 border border-[#1E273A]">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#D4FF00] mb-4 flex items-center gap-2 font-mono">
              <Building2 className="w-4 h-4" /> Owner Identity & Coordinates
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-xs text-slate-400">Owner Full Name</span>
                <p className="font-semibold text-white mt-0.5">{admin.ownerName}</p>
              </div>
              <div>
                <span className="text-xs text-slate-400">Venue Area</span>
                <p className="font-semibold text-white mt-0.5 flex items-center gap-1.5 font-mono">
                  <MapPin className="w-3.5 h-3.5 text-[#D4FF00]" />
                  {admin.neighborhoodArea}
                </p>
              </div>
              <div>
                <span className="text-xs text-slate-400">Verified Mobile</span>
                <div className="flex items-center gap-2 mt-0.5">
                  <Phone className="w-3.5 h-3.5 text-slate-400" />
                  <span className="font-mono text-white font-medium">{admin.ownerPhone}</span>
                  <span className="inline-flex items-center gap-1 px-2 py-0.5 text-[10px] font-mono font-bold rounded bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                    <Check className="w-3 h-3" /> Verified
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

              {/* Turf Google Map & Radar Bar */}
              <div className="md:col-span-2 p-3.5 rounded-xl bg-[#070A10] border border-[#1E273A] flex flex-wrap items-center justify-between gap-3">
                <div className="flex items-center gap-2.5">
                  <div className="w-8 h-8 rounded-lg bg-[#1F2916] border border-[#D4FF00]/40 flex items-center justify-center text-[#D4FF00]">
                    <Crosshair className="w-4 h-4 animate-spin-slow" />
                  </div>
                  <div>
                    <span className="text-[11px] font-bold text-white block">
                      Google Maps Location & Surrounding Players Radar
                    </span>
                    <span className="text-[10px] text-zinc-400">
                      {admin.latitude && admin.longitude
                        ? `${admin.latitude.toFixed(4)}° N, ${admin.longitude.toFixed(4)}° E`
                        : 'Coordinates ready for radar scanning'}
                    </span>
                  </div>
                </div>

                <div className="flex items-center gap-2">
                  {admin.googleMapsUrl && (
                    <a
                      href={admin.googleMapsUrl}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="px-2.5 py-1.5 rounded-lg bg-[#161D2E] hover:bg-[#1E273A] text-slate-300 text-xs font-semibold flex items-center gap-1 border border-[#28354F]"
                    >
                      <MapPin className="w-3.5 h-3.5 text-[#D4FF00]" />
                      <span>Google Maps</span>
                      <ExternalLink className="w-3 h-3 text-slate-400" />
                    </a>
                  )}
                  <button
                    onClick={() => setShowRadarModal(true)}
                    className="px-3 py-1.5 rounded-lg bg-[#D4FF00] hover:bg-[#bce400] text-black text-xs font-black flex items-center gap-1.5 shadow-md shadow-[#D4FF00]/20 transition-all"
                  >
                    <Crosshair className="w-3.5 h-3.5" />
                    <span>Launch Player Radar Map</span>
                  </button>
                </div>
              </div>
            </div>
          </div>

          {/* Pricing & Rate Cards */}
          <div className="bg-[#0E131F] rounded-xl p-5 border border-[#1E273A]">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#D4FF00] mb-4 flex items-center gap-2 font-mono">
              <Tag className="w-4 h-4" /> Active Hourly Rate Matrix
            </h3>
            <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
              <div className="p-3 rounded-lg bg-[#05080E] border border-[#1E273A]">
                <span className="text-[11px] text-slate-400 font-mono">Weekday Hourly</span>
                <p className="font-mono text-sm font-bold text-white mt-1">₹{admin.weekdayRate || 1200}/hr</p>
              </div>
              <div className="p-3 rounded-lg bg-[#05080E] border border-[#1E273A]">
                <span className="text-[11px] text-slate-400 font-mono">Weekend Hourly</span>
                <p className="font-mono text-sm font-bold text-[#D4FF00] mt-1">₹{admin.weekendRate || 1600}/hr</p>
              </div>
              <div className="p-3 rounded-lg bg-[#05080E] border border-[#1E273A]">
                <span className="text-[11px] text-slate-400 font-mono">Day Slot</span>
                <p className="font-mono text-sm font-bold text-white mt-1">₹{admin.dayRate || 1000}/hr</p>
              </div>
              <div className="p-3 rounded-lg bg-[#05080E] border border-[#1E273A]">
                <span className="text-[11px] text-slate-400 font-mono">Night Slot (Floodlights)</span>
                <p className="font-mono text-sm font-bold text-amber-300 mt-1">₹{admin.nightRate || 1800}/hr</p>
              </div>
            </div>
          </div>

          {/* Tax & Identity KYC Compliance */}
          <div className="bg-[#0E131F] rounded-xl p-5 border border-[#1E273A]">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#D4FF00] mb-4 flex items-center gap-2 font-mono">
              <FileText className="w-4 h-4" /> Tax & Identity KYC Compliance
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {/* Aadhaar */}
              <div className="p-3.5 rounded-lg bg-[#05080E] border border-[#1E273A]">
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-xs text-slate-400">Aadhaar Card</span>
                  {admin.aadhaarDocUrl ? (
                    <a
                      href={getFullFileUrl(admin.aadhaarDocUrl)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-[#D4FF00] hover:underline inline-flex items-center gap-1 font-mono font-semibold"
                    >
                      View PDF <ExternalLink className="w-3 h-3" />
                    </a>
                  ) : (
                    <span className="text-[10px] text-slate-500 font-mono">No Doc</span>
                  )}
                </div>
                <p className="font-mono text-xs font-semibold text-white">
                  {admin.aadhaarNumber ? `•••• •••• ${admin.aadhaarNumber.slice(-4)}` : 'Not provided'}
                </p>
              </div>

              {/* PAN */}
              <div className="p-3.5 rounded-lg bg-[#05080E] border border-[#1E273A]">
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-xs text-slate-400">PAN Card</span>
                  {admin.panDocUrl ? (
                    <a
                      href={getFullFileUrl(admin.panDocUrl)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-[#D4FF00] hover:underline inline-flex items-center gap-1 font-mono font-semibold"
                    >
                      View PDF <ExternalLink className="w-3 h-3" />
                    </a>
                  ) : (
                    <span className="text-[10px] text-slate-500 font-mono">No Doc</span>
                  )}
                </div>
                <p className="font-mono text-xs font-semibold text-white">
                  {admin.panNumber || 'Not provided'}
                </p>
              </div>

              {/* GSTIN */}
              <div className="p-3.5 rounded-lg bg-[#05080E] border border-[#1E273A]">
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-xs text-slate-400">GST Registration</span>
                  {admin.gstDocUrl ? (
                    <a
                      href={getFullFileUrl(admin.gstDocUrl)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-[#D4FF00] hover:underline inline-flex items-center gap-1 font-mono font-semibold"
                    >
                      View PDF <ExternalLink className="w-3 h-3" />
                    </a>
                  ) : (
                    <span className="text-[10px] text-slate-500 font-mono">No Doc</span>
                  )}
                </div>
                <p className="font-mono text-xs font-semibold text-white">
                  {admin.gstin || 'Unregistered'}
                </p>
              </div>
            </div>
          </div>

          {/* Payout & KYC Info */}
          <div className="bg-[#0E131F] rounded-xl p-5 border border-[#1E273A]">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#D4FF00] mb-4 flex items-center gap-2 font-mono">
              <CreditCard className="w-4 h-4" /> Payout & Settlement Gateway
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm font-mono">
              <div>
                <span className="text-xs text-slate-400">Bank Account</span>
                <p className="text-white mt-0.5">{admin.bankAccount || 'Not provided'}</p>
              </div>
              <div>
                <span className="text-xs text-slate-400">IFSC Code</span>
                <p className="text-white mt-0.5">{admin.ifscCode || 'Not provided'}</p>
              </div>
              <div>
                <span className="text-xs text-slate-400">UPI ID for Payouts</span>
                <p className="text-[#D4FF00] font-semibold mt-0.5">{admin.upiId || 'Not provided'}</p>
              </div>
            </div>
          </div>

          {/* Venue Photos */}
          {admin.photoUrls && admin.photoUrls.length > 0 && (
            <div className="bg-[#0E131F] rounded-xl p-5 border border-[#1E273A]">
              <h3 className="text-xs font-bold uppercase tracking-wider text-[#D4FF00] mb-4 flex items-center gap-2 font-mono">
                <ImageIcon className="w-4 h-4" /> Venue Photos ({admin.photoUrls.length})
              </h3>
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
                {admin.photoUrls.map((url, i) => (
                  <div
                    key={i}
                    onClick={() => setPreviewImage(getFullFileUrl(url))}
                    className="relative aspect-video rounded-lg overflow-hidden border border-[#1E273A] bg-[#05080E] cursor-pointer group"
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
                className="text-xs opacity-75 hover:opacity-100 font-mono"
              >
                Dismiss
              </button>
            </div>
          )}

          {/* Pending Branch Applications */}
          {admin.pendingBranchApplications && admin.pendingBranchApplications.length > 0 && (
            <div className="bg-[#0E131F] rounded-xl p-5 border border-amber-500/40 shadow-lg shadow-amber-500/5">
              <div className="flex items-center justify-between mb-4">
                <h3 className="text-xs font-bold uppercase tracking-wider text-amber-400 flex items-center gap-2 font-mono">
                  <GitBranch className="w-4 h-4 text-amber-400" /> Pending Branch Requests ({admin.pendingBranchApplications.length})
                </h3>
                <span className="text-[10px] font-mono font-semibold uppercase px-2 py-0.5 rounded bg-amber-500/20 text-amber-300 border border-amber-500/30">
                  Verification Required
                </span>
              </div>

              <div className="space-y-4">
                {admin.pendingBranchApplications.map((branch) => (
                  <div
                    key={branch.id}
                    className="p-4 rounded-xl bg-[#05080E] border border-[#1E273A] space-y-3"
                  >
                    <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-2 border-b border-[#1E273A] pb-3">
                      <div>
                        <div className="flex items-center gap-2">
                          <h4 className="text-sm font-bold text-white">{branch.venueName}</h4>
                          <span className="font-mono text-[10px] px-2 py-0.5 rounded bg-[#161D2E] text-slate-300 border border-[#28354F]">
                            {branch.trackingCode || `#BR-${branch.id}`}
                          </span>
                        </div>
                        <p className="text-xs text-slate-400 mt-1 flex items-center gap-1.5 font-mono">
                          <MapPin className="w-3.5 h-3.5 text-[#D4FF00]" />
                          <span>{branch.neighborhoodArea}</span>
                          <span className="text-slate-600">•</span>
                          <span>{branch.streetAddress}</span>
                        </p>
                      </div>

                      <div className="flex items-center gap-2 self-end sm:self-auto font-mono">
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
                          className="px-3.5 py-1.5 rounded-lg text-xs font-bold bg-[#D4FF00] hover:bg-[#b8dd00] text-black shadow-lg shadow-[#D4FF00]/15 transition-all flex items-center gap-1.5 disabled:opacity-50 active:scale-[0.98]"
                        >
                          {actionLoadingId === `approve_${branch.id}` ? (
                            <>
                              <Loader2 className="w-3.5 h-3.5 animate-spin" />
                              <span>Approving...</span>
                            </>
                          ) : (
                            <>
                              <Check className="w-3.5 h-3.5 stroke-[2.5]" />
                              <span>Approve & Activate</span>
                            </>
                          )}
                        </button>
                      </div>
                    </div>

                    {/* Branch Contacts */}
                    <div className="grid grid-cols-1 sm:grid-cols-2 gap-2 text-xs font-mono text-slate-300">
                      <div>
                        <span className="text-slate-500">Owner Contact:</span>{' '}
                        <span className="text-white">{branch.ownerPhone}</span>
                      </div>
                      {branch.alternativePhone && (
                        <div>
                          <span className="text-slate-500">Branch Phone:</span>{' '}
                          <span className="text-[#D4FF00]">{branch.alternativePhone}</span>
                        </div>
                      )}
                    </div>

                    {/* Branch Photos Gallery */}
                    {branch.photoUrls && branch.photoUrls.length > 0 ? (
                      <div>
                        <span className="text-[11px] font-semibold text-slate-400 uppercase tracking-wider block mb-2 font-mono">
                          Uploaded Branch Photos ({branch.photoUrls.length})
                        </span>
                        <div className="grid grid-cols-2 sm:grid-cols-4 gap-2">
                          {branch.photoUrls.map((pUrl, pIdx) => (
                            <div
                              key={pIdx}
                              onClick={() => setPreviewImage(getFullFileUrl(pUrl))}
                              className="relative aspect-video rounded-lg overflow-hidden border border-[#1E273A] bg-[#0A0E17] cursor-pointer group"
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
            <div className="bg-[#0E131F] rounded-xl p-5 border border-[#1E273A]">
              <h3 className="text-xs font-bold uppercase tracking-wider text-emerald-400 mb-4 flex items-center gap-2 font-mono">
                <GitBranch className="w-4 h-4 text-emerald-400" /> Active Verified Branches ({admin.approvedBranches.length})
              </h3>
              <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
                {admin.approvedBranches.map((br) => (
                  <div
                    key={br.id}
                    className="p-3.5 rounded-xl bg-[#05080E] border border-[#1E273A] space-y-2"
                  >
                    <div className="flex items-center justify-between">
                      <span className="font-bold text-white text-sm">{br.venueName}</span>
                      <span className="text-[10px] font-mono font-semibold px-2 py-0.5 rounded bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                        ACTIVE
                      </span>
                    </div>
                    <p className="text-xs text-slate-400 flex items-center gap-1.5 font-mono">
                      <MapPin className="w-3.5 h-3.5 text-[#D4FF00]" />
                      <span>{br.neighborhoodArea}</span>
                    </p>
                    <div className="flex items-center justify-between text-xs text-slate-400 pt-1 border-t border-[#1E273A] font-mono">
                      <span>Photos: {br.photosCount || br.photoUrls?.length || 0}</span>
                      <span className="text-[#D4FF00] font-semibold">₹{br.weekdayRate || 1200}/hr</span>
                    </div>
                  </div>
                ))}
              </div>
            </div>
          )}
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-[#1E273A] bg-[#0E131F] rounded-b-2xl flex items-center justify-between font-mono">
          <div className="flex items-center gap-2">
            {onToggleHold && (
              <button
                type="button"
                onClick={() => onToggleHold(admin)}
                className={`px-3 py-1.5 rounded-lg text-xs font-bold transition-all active:scale-[0.98] ${
                  admin.isBookingHold || admin.status === 'HOLD'
                    ? 'bg-emerald-600 hover:bg-emerald-500 text-white'
                    : 'bg-[#161D2E] hover:bg-amber-500/20 text-amber-300 border border-amber-500/30'
                }`}
              >
                {admin.isBookingHold || admin.status === 'HOLD' ? 'Resume Account & Bookings' : 'Hold Account'}
              </button>
            )}
            {onDelete && (
              <button
                type="button"
                onClick={() => onDelete(admin)}
                className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-rose-600/15 hover:bg-rose-600 hover:text-white text-rose-300 border border-rose-500/30 transition-all flex items-center gap-1.5 active:scale-[0.98]"
              >
                <Trash2 className="w-3.5 h-3.5" />
                <span>Delete Account</span>
              </button>
            )}
          </div>

          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-lg text-xs font-semibold text-slate-300 hover:text-white bg-[#161D2E] hover:bg-[#20293F] border border-[#28354F] transition-all"
          >
            Close Dossier
          </button>
        </div>

        {/* Turf Radar Map Modal */}
        {showRadarModal && (
          <div className="fixed inset-0 z-70 bg-black/90 backdrop-blur-md flex items-center justify-center p-4">
            <div className="w-full max-w-6xl">
              <TurfRadarMap
                turfId={admin.id}
                initialLat={admin.latitude || 9.9252}
                initialLng={admin.longitude || 78.1198}
                venueName={admin.venueName}
                streetAddress={admin.streetAddress}
                neighborhoodArea={admin.neighborhoodArea}
                googleMapsUrl={admin.googleMapsUrl || undefined}
                onClose={() => setShowRadarModal(false)}
              />
            </div>
          </div>
        )}

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
