'use client';

import { useState } from 'react';
import {
  AdminRegistration,
  BACKEND_URL,
  verifyRegistration,
  cancelRegistration,
} from '@/lib/api';
import {
  X,
  CheckCircle2,
  XCircle,
  Clock,
  ShieldCheck,
  MapPin,
  Phone,
  Mail,
  Building,
  CreditCard,
  FileText,
  Image as ImageIcon,
  ExternalLink,
  AlertTriangle,
  Sparkles,
  Check,
} from 'lucide-react';

interface Props {
  registration: AdminRegistration | null;
  onClose: () => void;
  onActionComplete: () => void;
}

export default function RegistrationDetailModal({
  registration,
  onClose,
  onActionComplete,
}: Props) {
  const [isVerifying, setIsVerifying] = useState(false);
  const [isCancelling, setIsCancelling] = useState(false);
  const [showCancelReasonInput, setShowCancelReasonInput] = useState(false);
  const [cancelReason, setCancelReason] = useState('');
  const [previewImage, setPreviewImage] = useState<string | null>(null);
  const [actionError, setActionError] = useState<string | null>(null);

  if (!registration) return null;

  const getFullFileUrl = (url: string | null) => {
    if (!url) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return `${BACKEND_URL}${url.startsWith('/') ? '' : '/'}${url}`;
  };

  const handleVerify = async () => {
    setIsVerifying(true);
    setActionError(null);
    try {
      await verifyRegistration(registration.id, { verifiedBy: 'Super Admin' });
      onActionComplete();
      onClose();
    } catch (err: any) {
      setActionError(err.message || 'Failed to verify registration');
    } finally {
      setIsVerifying(false);
    }
  };

  const handleCancel = async () => {
    if (!cancelReason.trim()) {
      setActionError('Please provide a reason for cancellation');
      return;
    }
    setIsCancelling(true);
    setActionError(null);
    try {
      await cancelRegistration(registration.id, { reason: cancelReason.trim() });
      onActionComplete();
      onClose();
    } catch (err: any) {
      setActionError(err.message || 'Failed to cancel registration');
    } finally {
      setIsCancelling(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/75 backdrop-blur-md flex items-center justify-center p-4">
      <div className="relative bg-[#0D121F] rounded-2xl max-w-4xl w-full max-h-[92vh] flex flex-col shadow-2xl border border-[#222B3F] text-slate-100 animate-in fade-in zoom-in-95 duration-150">
        {/* Render-style Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#1E2638] bg-[#111727]/80 rounded-t-2xl">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-indigo-600/20 text-indigo-400 border border-indigo-500/30 flex items-center justify-center shadow-lg shadow-indigo-600/10">
              <Building className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2 flex-wrap">
                <h2 className="text-lg font-bold text-white tracking-tight">{registration.venueName}</h2>
                <span className="font-mono text-xs px-2.5 py-0.5 rounded-md bg-[#182033] text-indigo-300 font-semibold border border-[#28354F]">
                  {registration.trackingCode || `#REG-${registration.id}`}
                </span>
                {registration.status === 'PENDING_APPROVAL' && (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-amber-500/15 text-amber-300 border border-amber-500/30">
                    <span className="w-1.5 h-1.5 rounded-full bg-amber-400 animate-ping"></span>
                    Pending Review
                  </span>
                )}
                {registration.status === 'VERIFIED' && (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                    Verified Partner
                  </span>
                )}
                {registration.status === 'CANCELLED' && (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-semibold bg-rose-500/15 text-rose-300 border border-rose-500/30">
                    <XCircle className="w-3.5 h-3.5 text-rose-400" />
                    Cancelled
                  </span>
                )}
              </div>
              <p className="text-xs text-slate-400 mt-0.5 font-mono">
                Submitted on {new Date(registration.createdAt).toLocaleString()} • KYC Audit Console
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

        {/* Error Alert */}
        {actionError && (
          <div className="mx-6 mt-4 p-3 bg-rose-500/10 border border-rose-500/30 rounded-xl text-rose-300 text-xs font-medium flex items-center gap-2">
            <AlertTriangle className="w-4 h-4 text-rose-400 shrink-0" />
            <span>{actionError}</span>
          </div>
        )}

        {/* Scrollable Content */}
        <div className="overflow-y-auto p-6 space-y-6">
          {/* Owner & Identity */}
          <div className="bg-[#121827] rounded-xl p-5 border border-[#1E2638]">
            <h3 className="text-xs font-bold uppercase tracking-wider text-indigo-400 mb-4 flex items-center gap-2">
              <ShieldCheck className="w-4 h-4" /> Owner Identity & Venue Location
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-xs text-slate-400">Owner Full Name</span>
                <p className="font-semibold text-white mt-0.5">{registration.ownerName}</p>
              </div>
              <div>
                <span className="text-xs text-slate-400">Neighborhood / Area</span>
                <p className="font-semibold text-white mt-0.5 flex items-center gap-1.5">
                  <MapPin className="w-3.5 h-3.5 text-indigo-400" />
                  {registration.neighborhoodArea}
                </p>
              </div>
              <div>
                <span className="text-xs text-slate-400">Owner Phone</span>
                <div className="flex items-center gap-2 mt-0.5">
                  <Phone className="w-3.5 h-3.5 text-slate-400" />
                  <span className="font-mono text-white font-medium">{registration.ownerPhone}</span>
                  {registration.isMobileVerified ? (
                    <span className="px-2 py-0.5 text-[10px] font-bold rounded bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                      Verified OTP ✓
                    </span>
                  ) : (
                    <span className="px-2 py-0.5 text-[10px] font-bold rounded bg-amber-500/15 text-amber-300 border border-amber-500/30">
                      Unverified
                    </span>
                  )}
                </div>
              </div>
              <div>
                <span className="text-xs text-slate-400">Owner Email</span>
                <div className="flex items-center gap-2 mt-0.5">
                  <Mail className="w-3.5 h-3.5 text-slate-400" />
                  <span className="font-mono text-white font-medium">{registration.ownerEmail}</span>
                  {registration.isEmailVerified ? (
                    <span className="px-2 py-0.5 text-[10px] font-bold rounded bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                      Verified ✓
                    </span>
                  ) : (
                    <span className="px-2 py-0.5 text-[10px] font-bold rounded bg-slate-800 text-slate-400">
                      Unverified
                    </span>
                  )}
                </div>
              </div>
              <div className="md:col-span-2">
                <span className="text-xs text-slate-400">Street Address</span>
                <p className="text-slate-300 mt-0.5">{registration.streetAddress}</p>
              </div>
            </div>
          </div>

          {/* KYC Documents & Tax Compliance */}
          <div className="bg-[#121827] rounded-xl p-5 border border-[#1E2638]">
            <h3 className="text-xs font-bold uppercase tracking-wider text-indigo-400 mb-4 flex items-center gap-2">
              <FileText className="w-4 h-4" /> Tax & Identity KYC Compliance
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {/* Aadhaar */}
              <div className="p-3.5 rounded-lg bg-[#161D2F] border border-[#232C42]">
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-xs text-slate-400">Aadhaar Card</span>
                  {registration.aadhaarDocUrl && (
                    <a
                      href={getFullFileUrl(registration.aadhaarDocUrl)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-indigo-400 hover:text-indigo-300 inline-flex items-center gap-1 font-mono"
                    >
                      View <ExternalLink className="w-3 h-3" />
                    </a>
                  )}
                </div>
                <p className="font-mono text-xs font-semibold text-white">
                  {registration.aadhaarNumber ? `•••• •••• ${registration.aadhaarNumber.slice(-4)}` : 'Not provided'}
                </p>
              </div>

              {/* PAN */}
              <div className="p-3.5 rounded-lg bg-[#161D2F] border border-[#232C42]">
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-xs text-slate-400">PAN Card</span>
                  {registration.panDocUrl && (
                    <a
                      href={getFullFileUrl(registration.panDocUrl)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-indigo-400 hover:text-indigo-300 inline-flex items-center gap-1 font-mono"
                    >
                      View <ExternalLink className="w-3 h-3" />
                    </a>
                  )}
                </div>
                <p className="font-mono text-xs font-semibold text-white">
                  {registration.panNumber || 'Not provided'}
                </p>
              </div>

              {/* GSTIN */}
              <div className="p-3.5 rounded-lg bg-[#161D2F] border border-[#232C42]">
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-xs text-slate-400">GST Registration</span>
                  {registration.gstDocUrl && (
                    <a
                      href={getFullFileUrl(registration.gstDocUrl)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-indigo-400 hover:text-indigo-300 inline-flex items-center gap-1 font-mono"
                    >
                      View <ExternalLink className="w-3 h-3" />
                    </a>
                  )}
                </div>
                <p className="font-mono text-xs font-semibold text-white">
                  {registration.gstin || 'Unregistered'}
                </p>
              </div>
            </div>
          </div>

          {/* Banking & Settlement Payout Info */}
          <div className="bg-[#121827] rounded-xl p-5 border border-[#1E2638]">
            <h3 className="text-xs font-bold uppercase tracking-wider text-indigo-400 mb-4 flex items-center gap-2">
              <CreditCard className="w-4 h-4" /> Settlement & Payout Details
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm">
              <div>
                <span className="text-xs text-slate-400">Bank Account</span>
                <p className="font-mono text-white mt-0.5">{registration.bankAccount || 'Not provided'}</p>
              </div>
              <div>
                <span className="text-xs text-slate-400">IFSC Code</span>
                <p className="font-mono text-white mt-0.5">{registration.ifscCode || 'Not provided'}</p>
              </div>
              <div>
                <span className="text-xs text-slate-400">UPI ID for Direct Payouts</span>
                <p className="font-mono text-indigo-300 font-semibold mt-0.5">{registration.upiId || 'Not provided'}</p>
              </div>
            </div>
          </div>

          {/* Venue Photos Gallery */}
          {registration.photoUrls && registration.photoUrls.length > 0 && (
            <div className="bg-[#121827] rounded-xl p-5 border border-[#1E2638]">
              <h3 className="text-xs font-bold uppercase tracking-wider text-indigo-400 mb-4 flex items-center gap-2">
                <ImageIcon className="w-4 h-4" /> Uploaded Turf Photos ({registration.photoUrls.length})
              </h3>
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
                {registration.photoUrls.map((url, i) => (
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
        </div>

        {/* Render-style Footer Actions */}
        <div className="px-6 py-4 border-t border-[#1E2638] bg-[#111727]/90 rounded-b-2xl flex items-center justify-between gap-4">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-lg text-xs font-semibold text-slate-300 hover:text-white bg-[#182033] hover:bg-[#202A42] border border-[#28354F] transition-all"
          >
            Close
          </button>

          {registration.status === 'PENDING_APPROVAL' && (
            <div className="flex items-center gap-3">
              {!showCancelReasonInput ? (
                <>
                  <button
                    type="button"
                    onClick={() => setShowCancelReasonInput(true)}
                    className="px-4 py-2 rounded-lg text-xs font-semibold text-rose-300 bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/30 transition-all"
                  >
                    Reject Application
                  </button>
                  <button
                    type="button"
                    disabled={isVerifying}
                    onClick={handleVerify}
                    className="flex items-center gap-2 px-5 py-2 rounded-lg text-xs font-bold text-white bg-indigo-600 hover:bg-indigo-500 shadow-lg shadow-indigo-600/30 transition-all disabled:opacity-50"
                  >
                    <Check className="w-4 h-4" />
                    {isVerifying ? 'Verifying & Deploying...' : 'Approve & Activate Venue'}
                  </button>
                </>
              ) : (
                <div className="flex items-center gap-2">
                  <input
                    type="text"
                    placeholder="Reason for rejection..."
                    value={cancelReason}
                    onChange={(e) => setCancelReason(e.target.value)}
                    className="px-3 py-1.5 text-xs bg-[#161D2F] border border-[#28354F] rounded-lg text-white placeholder-slate-500 focus:outline-hidden focus:border-rose-500"
                  />
                  <button
                    type="button"
                    disabled={isCancelling}
                    onClick={handleCancel}
                    className="px-3 py-1.5 rounded-lg text-xs font-bold text-white bg-rose-600 hover:bg-rose-500 transition-all disabled:opacity-50"
                  >
                    {isCancelling ? 'Rejecting...' : 'Confirm Reject'}
                  </button>
                  <button
                    type="button"
                    onClick={() => setShowCancelReasonInput(false)}
                    className="px-2.5 py-1.5 rounded-lg text-xs text-slate-400 hover:text-white"
                  >
                    Cancel
                  </button>
                </div>
              )}
            </div>
          )}
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
