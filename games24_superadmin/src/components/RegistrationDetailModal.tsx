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
    <div className="fixed inset-0 z-50 overflow-y-auto bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
      <div className="relative bg-white rounded-2xl max-w-4xl w-full max-h-[92vh] flex flex-col shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-150">
        {/* Modal Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-200 bg-slate-50/70 rounded-t-2xl">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-100 text-emerald-700 flex items-center justify-center font-bold">
              <Building className="w-5 h-5" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-xl font-bold text-slate-900">{registration.venueName}</h2>
                <span className="font-mono text-xs px-2.5 py-0.5 rounded-full bg-slate-200/80 text-slate-700 font-semibold">
                  {registration.trackingCode || `#REG-${registration.id}`}
                </span>
              </div>
              <p className="text-xs text-slate-500">
                Submitted by <span className="font-semibold text-slate-700">{registration.ownerName}</span> •{' '}
                {new Date(registration.createdAt).toLocaleString()}
              </p>
            </div>
          </div>

          <div className="flex items-center gap-2">
            {registration.status === 'PENDING_APPROVAL' && (
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-amber-100 text-amber-800">
                <Clock className="w-3.5 h-3.5" /> Waiting Review
              </span>
            )}
            {registration.status === 'VERIFIED' && (
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-emerald-100 text-emerald-800">
                <CheckCircle2 className="w-3.5 h-3.5" /> Verified & Approved
              </span>
            )}
            {registration.status === 'CANCELLED' && (
              <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full text-xs font-bold bg-rose-100 text-rose-800">
                <XCircle className="w-3.5 h-3.5" /> Cancelled / Rejected
              </span>
            )}
            <button
              onClick={onClose}
              className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-200/60 transition-colors ml-2"
            >
              <X className="w-5 h-5" />
            </button>
          </div>
        </div>

        {/* Modal Scrollable Body */}
        <div className="overflow-y-auto p-6 space-y-6">
          {actionError && (
            <div className="p-3 rounded-xl bg-rose-50 border border-rose-200 text-rose-700 text-sm flex items-center gap-2">
              <AlertTriangle className="w-4 h-4 shrink-0" />
              <span>{actionError}</span>
            </div>
          )}

          {registration.status === 'CANCELLED' && registration.cancelReason && (
            <div className="p-4 rounded-xl bg-rose-50/70 border border-rose-200 text-rose-800 text-sm">
              <span className="font-bold">Cancellation Reason: </span>
              {registration.cancelReason}
            </div>
          )}

          {/* Section 1: Venue & Owner Identity */}
          <div className="bg-slate-50/80 rounded-xl p-4 border border-slate-200/70">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3 flex items-center gap-2">
              <Building className="w-4 h-4 text-emerald-600" /> Venue & Contact Information
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-xs text-slate-500">Venue Name</span>
                <p className="font-semibold text-slate-800">{registration.venueName}</p>
              </div>
              <div>
                <span className="text-xs text-slate-500">Owner Full Name</span>
                <p className="font-semibold text-slate-800">{registration.ownerName}</p>
              </div>
              <div>
                <span className="text-xs text-slate-500">Contact Mobile</span>
                <div className="flex items-center gap-2 mt-0.5">
                  <Phone className="w-3.5 h-3.5 text-slate-400" />
                  <span className="font-semibold text-slate-800">{registration.ownerPhone}</span>
                  <span className="px-1.5 py-0.5 text-[10px] font-bold bg-emerald-100 text-emerald-800 rounded">
                    OTP Verified ✓
                  </span>
                </div>
              </div>
              <div>
                <span className="text-xs text-slate-500">Contact Email</span>
                <div className="flex items-center gap-2 mt-0.5">
                  <Mail className="w-3.5 h-3.5 text-slate-400" />
                  <span className="font-semibold text-slate-800">{registration.ownerEmail}</span>
                  <span className="px-1.5 py-0.5 text-[10px] font-bold bg-emerald-100 text-emerald-800 rounded">
                    OTP Verified ✓
                  </span>
                </div>
              </div>
              <div className="md:col-span-2">
                <span className="text-xs text-slate-500">Address & Neighborhood</span>
                <div className="flex items-start gap-1.5 mt-0.5">
                  <MapPin className="w-4 h-4 text-slate-400 shrink-0 mt-0.5" />
                  <p className="text-slate-800 font-medium">
                    {registration.streetAddress}, <span className="font-bold">{registration.neighborhoodArea}</span>
                  </p>
                </div>
              </div>
            </div>
          </div>

          {/* Section 2: Facilities & Amenities */}
          <div>
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3 flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-amber-500" /> Turf Amenities & Facilities
            </h3>
            {registration.amenities && registration.amenities.length > 0 ? (
              <div className="flex flex-wrap gap-2">
                {registration.amenities.map((amenity, idx) => (
                  <span
                    key={idx}
                    className="px-3 py-1.5 rounded-lg bg-emerald-50 border border-emerald-200 text-emerald-800 text-xs font-semibold flex items-center gap-1.5"
                  >
                    <CheckCircle2 className="w-3.5 h-3.5 text-emerald-600" />
                    {amenity}
                  </span>
                ))}
              </div>
            ) : (
              <p className="text-xs text-slate-400 italic">No specific amenities selected</p>
            )}
          </div>

          {/* Section 3: Uploaded Venue Photos */}
          <div>
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 flex items-center gap-2">
                <ImageIcon className="w-4 h-4 text-indigo-500" /> Uploaded Venue Photos (
                {registration.photoUrls?.length || 0})
              </h3>
              <span className="text-xs text-slate-400">Click any photo to preview full size</span>
            </div>

            {registration.photoUrls && registration.photoUrls.length > 0 ? (
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                {registration.photoUrls.map((photo, idx) => {
                  const fullUrl = getFullFileUrl(photo);
                  return (
                    <div
                      key={idx}
                      onClick={() => setPreviewImage(fullUrl)}
                      className="group relative aspect-4/3 rounded-xl overflow-hidden border border-slate-200 bg-slate-100 cursor-pointer hover:border-emerald-500 hover:shadow-md transition-all"
                    >
                      <img
                        src={fullUrl}
                        alt={`Venue photo ${idx + 1}`}
                        className="w-full h-full object-cover group-hover:scale-105 transition-transform"
                        onError={(e) => {
                          (e.target as HTMLElement).style.display = 'none';
                        }}
                      />
                      <div className="absolute inset-0 bg-slate-900/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white text-xs font-medium gap-1">
                        <ExternalLink className="w-4 h-4" /> View Full
                      </div>
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="p-6 text-center rounded-xl border border-dashed border-slate-200 text-slate-400 text-xs">
                No venue photos attached
              </div>
            )}
          </div>

          {/* Section 4: KYC Verification Documents (PDF / Files) */}
          <div className="bg-slate-50/80 rounded-xl p-4 border border-slate-200/70">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3 flex items-center gap-2">
              <FileText className="w-4 h-4 text-blue-600" /> KYC Verification Documents
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              {/* Aadhaar Document */}
              <div className="p-3 bg-white rounded-lg border border-slate-200 shadow-2xs">
                <div className="flex items-center justify-between mb-1">
                  <span className="text-xs font-bold text-slate-700">Aadhaar Card</span>
                  {registration.aadhaarDocUrl ? (
                    <span className="text-[10px] font-bold text-emerald-700 bg-emerald-100 px-1.5 py-0.5 rounded">
                      PDF Attached
                    </span>
                  ) : (
                    <span className="text-[10px] text-slate-400">None</span>
                  )}
                </div>
                <p className="font-mono text-xs text-slate-600 mb-2 font-medium">
                  {registration.aadhaarNumber || 'Not provided'}
                </p>
                {registration.aadhaarDocUrl && (
                  <a
                    href={getFullFileUrl(registration.aadhaarDocUrl)}
                    target="_blank"
                    rel="noreferrer"
                    className="inline-flex items-center gap-1 text-xs font-semibold text-emerald-600 hover:text-emerald-700 hover:underline"
                  >
                    <ExternalLink className="w-3.5 h-3.5" /> View / Download PDF
                  </a>
                )}
              </div>

              {/* PAN Document */}
              <div className="p-3 bg-white rounded-lg border border-slate-200 shadow-2xs">
                <div className="flex items-center justify-between mb-1">
                  <span className="text-xs font-bold text-slate-700">PAN Card</span>
                  {registration.panDocUrl ? (
                    <span className="text-[10px] font-bold text-emerald-700 bg-emerald-100 px-1.5 py-0.5 rounded">
                      PDF Attached
                    </span>
                  ) : (
                    <span className="text-[10px] text-slate-400">None</span>
                  )}
                </div>
                <p className="font-mono text-xs text-slate-600 mb-2 font-medium">
                  {registration.panNumber || 'Not provided'}
                </p>
                {registration.panDocUrl && (
                  <a
                    href={getFullFileUrl(registration.panDocUrl)}
                    target="_blank"
                    rel="noreferrer"
                    className="inline-flex items-center gap-1 text-xs font-semibold text-emerald-600 hover:text-emerald-700 hover:underline"
                  >
                    <ExternalLink className="w-3.5 h-3.5" /> View / Download PDF
                  </a>
                )}
              </div>

              {/* GST Document */}
              <div className="p-3 bg-white rounded-lg border border-slate-200 shadow-2xs">
                <div className="flex items-center justify-between mb-1">
                  <span className="text-xs font-bold text-slate-700">GST Registration</span>
                  {registration.gstDocUrl ? (
                    <span className="text-[10px] font-bold text-emerald-700 bg-emerald-100 px-1.5 py-0.5 rounded">
                      PDF Attached
                    </span>
                  ) : (
                    <span className="text-[10px] text-slate-400">None</span>
                  )}
                </div>
                <p className="font-mono text-xs text-slate-600 mb-2 font-medium">
                  {registration.gstin || 'Not provided'}
                </p>
                {registration.gstDocUrl && (
                  <a
                    href={getFullFileUrl(registration.gstDocUrl)}
                    target="_blank"
                    rel="noreferrer"
                    className="inline-flex items-center gap-1 text-xs font-semibold text-emerald-600 hover:text-emerald-700 hover:underline"
                  >
                    <ExternalLink className="w-3.5 h-3.5" /> View / Download PDF
                  </a>
                )}
              </div>
            </div>
          </div>

          {/* Section 5: Banking & Payout Details */}
          <div className="bg-slate-50/80 rounded-xl p-4 border border-slate-200/70">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3 flex items-center gap-2">
              <CreditCard className="w-4 h-4 text-emerald-600" /> Bank & Payout Information
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-sm">
              <div>
                <span className="text-xs text-slate-500">Bank Account Number</span>
                <p className="font-mono font-semibold text-slate-800">
                  {registration.bankAccount || '-'}
                </p>
              </div>
              <div>
                <span className="text-xs text-slate-500">IFSC Code</span>
                <p className="font-mono font-semibold text-slate-800">
                  {registration.ifscCode || '-'}
                </p>
              </div>
              <div>
                <span className="text-xs text-slate-500">Partner UPI ID</span>
                <p className="font-mono font-semibold text-slate-800">
                  {registration.upiId || '-'}
                </p>
              </div>
            </div>
          </div>
        </div>

        {/* Modal Action Footer */}
        <div className="px-6 py-4 border-t border-slate-200 bg-slate-50/90 rounded-b-2xl flex flex-col sm:flex-row items-center justify-between gap-3">
          <div className="text-xs text-slate-500">
            Tracking ID: <span className="font-mono font-semibold text-slate-700">{registration.trackingCode || registration.id}</span>
          </div>

          {registration.status === 'PENDING_APPROVAL' && (
            <div className="flex items-center gap-3 w-full sm:w-auto">
              {!showCancelReasonInput ? (
                <>
                  <button
                    onClick={() => setShowCancelReasonInput(true)}
                    className="w-full sm:w-auto px-4 py-2 text-sm font-semibold text-rose-700 bg-rose-50 hover:bg-rose-100 border border-rose-200 rounded-xl transition-colors flex items-center justify-center gap-2"
                  >
                    <XCircle className="w-4 h-4" /> Reject / Cancel
                  </button>

                  <button
                    onClick={handleVerify}
                    disabled={isVerifying}
                    className="w-full sm:w-auto px-6 py-2 text-sm font-semibold text-white bg-emerald-600 hover:bg-emerald-700 rounded-xl shadow-md shadow-emerald-600/20 transition-all flex items-center justify-center gap-2 disabled:opacity-50"
                  >
                    <CheckCircle2 className="w-4 h-4" />
                    {isVerifying ? 'Verifying & Saving...' : 'Verify & Approve Partner'}
                  </button>
                </>
              ) : (
                <div className="flex flex-col sm:flex-row items-center gap-2 w-full">
                  <input
                    type="text"
                    placeholder="Enter reason for rejection..."
                    value={cancelReason}
                    onChange={(e) => setCancelReason(e.target.value)}
                    className="px-3 py-1.5 text-xs border border-rose-300 rounded-lg w-full sm:w-64 focus:outline-hidden focus:ring-2 focus:ring-rose-500"
                  />
                  <div className="flex items-center gap-2">
                    <button
                      onClick={handleCancel}
                      disabled={isCancelling}
                      className="px-3 py-1.5 text-xs font-bold text-white bg-rose-600 hover:bg-rose-700 rounded-lg transition-colors"
                    >
                      {isCancelling ? 'Rejecting...' : 'Confirm Reject'}
                    </button>
                    <button
                      onClick={() => setShowCancelReasonInput(false)}
                      className="px-3 py-1.5 text-xs font-semibold text-slate-600 hover:bg-slate-200 rounded-lg transition-colors"
                    >
                      Back
                    </button>
                  </div>
                </div>
              )}
            </div>
          )}

          {registration.status === 'VERIFIED' && (
            <div className="flex items-center gap-2 text-xs font-semibold text-emerald-700">
              <ShieldCheck className="w-4 h-4" /> Verified in VerifiedAdmin Database Table
            </div>
          )}

          {registration.status === 'CANCELLED' && (
            <button
              onClick={onClose}
              className="px-4 py-2 text-xs font-semibold text-slate-700 bg-slate-200 hover:bg-slate-300 rounded-xl transition-colors"
            >
              Close
            </button>
          )}
        </div>
      </div>

      {/* Enlarged Photo Preview Lightbox */}
      {previewImage && (
        <div
          className="fixed inset-0 z-60 bg-black/85 flex items-center justify-center p-4"
          onClick={() => setPreviewImage(null)}
        >
          <div className="relative max-w-3xl max-h-[90vh]">
            <img
              src={previewImage}
              alt="Enlarged view"
              className="max-w-full max-h-[85vh] rounded-lg object-contain"
            />
            <button
              onClick={() => setPreviewImage(null)}
              className="absolute -top-10 right-0 text-white hover:text-slate-300 p-2 text-sm font-semibold flex items-center gap-1"
            >
              <X className="w-5 h-5" /> Close Preview
            </button>
          </div>
        </div>
      )}
    </div>
  );
}
