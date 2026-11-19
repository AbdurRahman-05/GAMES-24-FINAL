'use client';

import { useState } from 'react';
import {
  AdminRegistration,
  resolveFileUrl,
  verifyRegistration,
  cancelRegistration,
} from '@/lib/api';
import {
  X,
  CheckCircle2,
  XCircle,
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
  Building2,
  Clock,
  CheckCheck,
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

  const isRegistrationComplete = registration.isBranch
    ? true
    : Boolean(
        registration.isMobileVerified &&
        registration.isEmailVerified &&
        (registration.photosCount > 0 || (registration.photoUrls && registration.photoUrls.length > 0)) &&
        registration.aadhaarNumber &&
        registration.bankAccount
      );

  const getFullFileUrl = (url: string | null) => {
    return resolveFileUrl(url);
  };

  const handleVerify = async () => {
    setIsVerifying(true);
    setActionError(null);
    try {
      await verifyRegistration(registration.id, { verifiedBy: 'Super Admin' });
      onActionComplete();
      onClose();
    } catch (err: unknown) {
      setActionError((err as Error).message || 'Failed to verify registration');
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
    } catch (err: unknown) {
      setActionError((err as Error).message || 'Failed to cancel registration');
    } finally {
      setIsCancelling(false);
    }
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-black/85 backdrop-blur-md flex items-center justify-center p-4">
      <div className="relative bg-[#0A0E17] rounded-2xl max-w-4xl w-full max-h-[92vh] flex flex-col shadow-2xl border border-[#1E273A] text-slate-100 animate-in fade-in zoom-in-95 duration-150">
        {/* Command Center Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-[#1E273A] bg-[#0E131F] rounded-t-2xl">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-[#161D2E] text-[#D4FF00] border border-[#28354F] flex items-center justify-center shrink-0">
              <Building2 className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2 flex-wrap">
                <h2 className="text-lg font-bold text-white tracking-tight">{registration.venueName}</h2>
                <span className="font-mono text-xs px-2.5 py-0.5 rounded-md bg-[#161D2E] text-slate-300 font-semibold border border-[#28354F]">
                  {registration.trackingCode || `#REG-${registration.id}`}
                </span>
                {registration.status === 'PENDING_APPROVAL' && (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-mono font-bold bg-amber-500/15 text-amber-300 border border-amber-500/30">
                    <span className="w-1.5 h-1.5 rounded-full bg-amber-400 animate-ping" />
                    PENDING KYC REVIEW
                  </span>
                )}
                {registration.status === 'VERIFIED' && (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-mono font-bold bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-400" />
                    VERIFIED PARTNER
                  </span>
                )}
                {registration.status === 'CANCELLED' && (
                  <span className="inline-flex items-center gap-1.5 px-2.5 py-0.5 rounded-full text-xs font-mono font-bold bg-rose-500/15 text-rose-300 border border-rose-500/30">
                    <XCircle className="w-3.5 h-3.5 text-rose-400" />
                    DECLINED
                  </span>
                )}
              </div>
              <p className="text-xs text-slate-400 mt-0.5 font-mono">
                Submitted on {new Date(registration.createdAt).toLocaleString()} • KYC Audit Dossier
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

        {/* Error Alert */}
        {actionError && (
          <div className="mx-6 mt-4 p-3 bg-rose-500/10 border border-rose-500/30 rounded-xl text-rose-300 text-xs font-medium flex items-center gap-2">
            <AlertTriangle className="w-4 h-4 text-rose-400 shrink-0" />
            <span>{actionError}</span>
          </div>
        )}

        {/* Incomplete Registration Warning */}
        {!isRegistrationComplete && (
          <div className="mx-6 mt-4 p-3.5 bg-amber-500/10 border border-amber-500/30 rounded-xl text-amber-200 text-xs flex items-start gap-3">
            <AlertTriangle className="w-4 h-4 text-amber-400 shrink-0 mt-0.5" />
            <div>
              <p className="font-bold text-amber-300">Incomplete Application Notice</p>
              <p className="mt-0.5 text-slate-300 leading-relaxed font-mono text-[11px]">
                The turf owner has not completed all mandatory steps (OTP verification, venue photos, or KYC documents). Verification is disabled until all data is fully submitted.
              </p>
            </div>
          </div>
        )}

        {/* Scrollable Content */}
        <div className="overflow-y-auto p-6 space-y-5">
          {/* Branch Application Details Banner */}
          {registration.isBranch && (
            <div className="bg-sky-950/30 rounded-xl p-5 border border-sky-500/40 shadow-lg">
              <div className="flex items-center gap-2 mb-3">
                <span className="px-2.5 py-1 rounded-full text-[11px] font-bold bg-sky-500/20 text-sky-300 border border-sky-500/40 flex items-center gap-1.5 font-mono">
                  <Building2 className="w-3.5 h-3.5" /> NEW BRANCH LOCATION APPLICATION
                </span>
                <span className="text-xs text-sky-400 font-mono">
                  Linked to Existing Turf ID #{registration.parentTurfId}
                </span>
              </div>
              <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-xs font-mono">
                <div className="p-3 bg-[#0A0E17] rounded-lg border border-[#1E273A]">
                  <span className="text-[10px] text-slate-400 uppercase tracking-wider block font-semibold">
                    Original / Parent Turf Name:
                  </span>
                  <p className="font-bold text-white text-sm mt-0.5">
                    {registration.parentTurfName || registration.parentTurf?.venueName || 'Primary Turf Arena'}
                  </p>
                </div>
                <div className="p-3 bg-[#0A0E17] rounded-lg border border-[#1E273A]">
                  <span className="text-[10px] text-slate-400 uppercase tracking-wider block font-semibold">
                    Owner Primary Login Phone:
                  </span>
                  <p className="font-mono font-bold text-emerald-400 text-sm mt-0.5">
                    {registration.parentTurfPhone || registration.ownerPhone}
                  </p>
                </div>
                <div className="p-3 bg-[#0A0E17] rounded-lg border border-[#1E273A]">
                  <span className="text-[10px] text-slate-400 uppercase tracking-wider block font-semibold">
                    Branch Manager Alternative Mobile:
                  </span>
                  <p className="font-mono font-bold text-sky-300 text-sm mt-0.5">
                    {registration.alternativePhone || '—'}
                  </p>
                </div>
                <div className="p-3 bg-[#0A0E17] rounded-lg border border-[#1E273A]">
                  <span className="text-[10px] text-slate-400 uppercase tracking-wider block font-semibold">
                    New Branch Neighborhood & Address:
                  </span>
                  <p className="text-slate-200 mt-0.5">
                    {registration.streetAddress}, {registration.neighborhoodArea}
                  </p>
                </div>
              </div>
            </div>
          )}

          {/* Owner & Identity */}
          <div className="bg-[#0E131F] rounded-xl p-5 border border-[#1E273A]">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#D4FF00] mb-4 flex items-center gap-2 font-mono">
              <ShieldCheck className="w-4 h-4" /> Owner Identity & Venue Coordinates
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-xs text-slate-400">Owner Full Name</span>
                <p className="font-semibold text-white mt-0.5">{registration.ownerName}</p>
              </div>
              <div>
                <span className="text-xs text-slate-400">Neighborhood / Area</span>
                <p className="font-semibold text-white mt-0.5 flex items-center gap-1.5 font-mono">
                  <MapPin className="w-3.5 h-3.5 text-[#D4FF00]" />
                  {registration.neighborhoodArea}
                </p>
              </div>
              <div>
                <span className="text-xs text-slate-400">Owner Phone</span>
                <div className="flex items-center gap-2 mt-0.5">
                  <Phone className="w-3.5 h-3.5 text-slate-400" />
                  <span className="font-mono text-white font-medium">{registration.ownerPhone}</span>
                  {registration.isMobileVerified ? (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 text-[10px] font-mono font-bold rounded bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                      <Check className="w-3 h-3" /> OTP Verified
                    </span>
                  ) : (
                    <span className="px-2 py-0.5 text-[10px] font-mono font-bold rounded bg-amber-500/15 text-amber-300 border border-amber-500/30">
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
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 text-[10px] font-mono font-bold rounded bg-emerald-500/15 text-emerald-300 border border-emerald-500/30">
                      <Check className="w-3 h-3" /> Verified
                    </span>
                  ) : (
                    <span className="px-2 py-0.5 text-[10px] font-mono font-bold rounded bg-[#161D2E] text-slate-400">
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
          <div className="bg-[#0E131F] rounded-xl p-5 border border-[#1E273A]">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#D4FF00] mb-4 flex items-center gap-2 font-mono">
              <FileText className="w-4 h-4" /> Tax & Identity KYC Compliance
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
              {/* Aadhaar */}
              <div className="p-3.5 rounded-lg bg-[#05080E] border border-[#1E273A]">
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-xs text-slate-400">Aadhaar Card</span>
                  {registration.aadhaarDocUrl && (
                    <a
                      href={getFullFileUrl(registration.aadhaarDocUrl)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-[#D4FF00] hover:underline inline-flex items-center gap-1 font-mono"
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
              <div className="p-3.5 rounded-lg bg-[#05080E] border border-[#1E273A]">
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-xs text-slate-400">PAN Card</span>
                  {registration.panDocUrl && (
                    <a
                      href={getFullFileUrl(registration.panDocUrl)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-[#D4FF00] hover:underline inline-flex items-center gap-1 font-mono"
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
              <div className="p-3.5 rounded-lg bg-[#05080E] border border-[#1E273A]">
                <div className="flex items-center justify-between mb-1.5">
                  <span className="text-xs text-slate-400">GST Registration</span>
                  {registration.gstDocUrl && (
                    <a
                      href={getFullFileUrl(registration.gstDocUrl)}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="text-xs text-[#D4FF00] hover:underline inline-flex items-center gap-1 font-mono"
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
          <div className="bg-[#0E131F] rounded-xl p-5 border border-[#1E273A]">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#D4FF00] mb-4 flex items-center gap-2 font-mono">
              <CreditCard className="w-4 h-4" /> Settlement & Payout Details
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 text-sm font-mono">
              <div>
                <span className="text-xs text-slate-400">Bank Account</span>
                <p className="text-white mt-0.5">{registration.bankAccount || 'Not provided'}</p>
              </div>
              <div>
                <span className="text-xs text-slate-400">IFSC Code</span>
                <p className="text-white mt-0.5">{registration.ifscCode || 'Not provided'}</p>
              </div>
              <div>
                <span className="text-xs text-slate-400">UPI ID for Payouts</span>
                <p className="text-[#D4FF00] font-semibold mt-0.5">{registration.upiId || 'Not provided'}</p>
              </div>
            </div>
          </div>

          {/* Sports & Amenities */}
          <div className="bg-[#0E131F] rounded-xl p-5 border border-[#1E273A]">
            <h3 className="text-xs font-bold uppercase tracking-wider text-[#D4FF00] mb-3 flex items-center gap-2 font-mono">
              <Sparkles className="w-4 h-4" /> Sports Available & Amenities
            </h3>
            <div className="space-y-3">
              <div>
                <span className="text-xs text-slate-400 font-mono">Configured Sports:</span>
                <div className="flex flex-wrap gap-2 mt-1.5">
                  {registration.sports && registration.sports.length > 0 ? (
                    registration.sports.map((sp, idx) => (
                      <span
                        key={idx}
                        className="px-2.5 py-1 text-xs font-semibold rounded-lg bg-emerald-500/15 text-emerald-300 border border-emerald-500/30 flex items-center gap-1.5 font-mono uppercase"
                      >
                        <span className="w-1.5 h-1.5 rounded-full bg-emerald-400" />
                        {sp}
                      </span>
                    ))
                  ) : (
                    <span className="text-xs text-slate-500 font-mono">Cricket, Football (Default Turf Ground)</span>
                  )}
                </div>
              </div>

              {registration.amenities && registration.amenities.length > 0 && (
                <div>
                  <span className="text-xs text-slate-400 font-mono">Amenities & Facilities:</span>
                  <div className="flex flex-wrap gap-2 mt-1.5">
                    {registration.amenities.map((amenity, idx) => (
                      <span
                        key={idx}
                        className="px-2.5 py-1 text-xs font-medium rounded-lg bg-[#161D2E] text-slate-200 border border-[#28354F] flex items-center gap-1.5"
                      >
                        <Check className="w-3.5 h-3.5 text-emerald-400" />
                        <span>{amenity}</span>
                      </span>
                    ))}
                  </div>
                </div>
              )}
            </div>
          </div>

          {/* Venue Photos Gallery */}
          {registration.photoUrls && registration.photoUrls.length > 0 && (
            <div className="bg-[#0E131F] rounded-xl p-5 border border-[#1E273A]">
              <h3 className="text-xs font-bold uppercase tracking-wider text-[#D4FF00] mb-4 flex items-center gap-2 font-mono">
                <ImageIcon className="w-4 h-4" /> Uploaded Turf Photos ({registration.photoUrls.length})
              </h3>
              <div className="grid grid-cols-2 sm:grid-cols-3 md:grid-cols-4 gap-3">
                {registration.photoUrls.map((url, i) => (
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
        </div>

        {/* Footer Actions */}
        <div className="px-6 py-4 border-t border-[#1E273A] bg-[#0E131F] rounded-b-2xl flex items-center justify-between gap-4">
          <button
            type="button"
            onClick={onClose}
            className="px-4 py-2 rounded-lg text-xs font-semibold text-slate-300 hover:text-white bg-[#161D2E] hover:bg-[#20293F] border border-[#28354F] transition-all font-mono"
          >
            Close Dossier
          </button>

          {registration.status === 'PENDING_APPROVAL' && (
            <div className="flex items-center gap-3">
              {!showCancelReasonInput ? (
                <>
                  <button
                    type="button"
                    onClick={() => setShowCancelReasonInput(true)}
                    className="px-4 py-2 rounded-lg text-xs font-semibold text-rose-300 bg-rose-500/10 hover:bg-rose-500/20 border border-rose-500/30 transition-all font-mono"
                  >
                    Reject Application
                  </button>
                  <button
                    type="button"
                    disabled={isVerifying || !isRegistrationComplete}
                    onClick={handleVerify}
                    className="flex items-center gap-2 px-5 py-2 rounded-lg text-xs font-bold text-black bg-[#D4FF00] hover:bg-[#b8dd00] shadow-lg shadow-[#D4FF00]/15 transition-all disabled:opacity-40 disabled:cursor-not-allowed active:scale-[0.98] font-mono"
                    title={!isRegistrationComplete ? 'Application is incomplete - cannot verify' : 'Approve & Activate Venue'}
                  >
                    <Check className="w-4 h-4 stroke-[2.5]" />
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
                    className="px-3 py-1.5 text-xs bg-[#05080E] border border-[#1E273A] rounded-lg text-white placeholder-slate-500 focus:outline-hidden focus:border-rose-500"
                  />
                  <button
                    type="button"
                    disabled={isCancelling}
                    onClick={handleCancel}
                    className="px-3 py-1.5 rounded-lg text-xs font-bold text-white bg-rose-600 hover:bg-rose-500 transition-all disabled:opacity-50 font-mono active:scale-[0.98]"
                  >
                    {isCancelling ? 'Rejecting...' : 'Confirm Reject'}
                  </button>
                  <button
                    type="button"
                    onClick={() => setShowCancelReasonInput(false)}
                    className="px-2.5 py-1.5 rounded-lg text-xs text-slate-400 hover:text-white font-mono"
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
