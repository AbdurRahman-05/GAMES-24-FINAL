'use client';

import { useState } from 'react';
import { VerifiedAdmin, BACKEND_URL } from '@/lib/api';
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
} from 'lucide-react';

interface Props {
  admin: VerifiedAdmin | null;
  onClose: () => void;
}

export default function AdminDetailModal({ admin, onClose }: Props) {
  const [previewImage, setPreviewImage] = useState<string | null>(null);

  if (!admin) return null;

  const getFullFileUrl = (url: string | null) => {
    if (!url) return '';
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    return `${BACKEND_URL}${url.startsWith('/') ? '' : '/'}${url}`;
  };

  return (
    <div className="fixed inset-0 z-50 overflow-y-auto bg-slate-900/60 backdrop-blur-xs flex items-center justify-center p-4">
      <div className="relative bg-white rounded-2xl max-w-4xl w-full max-h-[92vh] flex flex-col shadow-2xl border border-slate-200 animate-in fade-in zoom-in-95 duration-150">
        {/* Header */}
        <div className="flex items-center justify-between px-6 py-4 border-b border-slate-200 bg-emerald-50/60 rounded-t-2xl">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-emerald-600 text-white flex items-center justify-center shadow-md shadow-emerald-600/20">
              <ShieldCheck className="w-6 h-6" />
            </div>
            <div>
              <div className="flex items-center gap-2">
                <h2 className="text-xl font-bold text-slate-900">{admin.venueName}</h2>
                <span className="font-mono text-xs px-2.5 py-0.5 rounded-full bg-emerald-100 text-emerald-800 font-bold border border-emerald-200">
                  {admin.trackingCode || `#ADM-${admin.id}`}
                </span>
                <span className="px-2 py-0.5 text-[10px] font-bold uppercase tracking-wider bg-emerald-600 text-white rounded">
                  Verified Partner
                </span>
              </div>
              <p className="text-xs text-slate-500">
                Verified on {new Date(admin.verifiedAt).toLocaleDateString()} by{' '}
                <span className="font-semibold text-slate-700">{admin.verifiedBy}</span>
              </p>
            </div>
          </div>

          <button
            onClick={onClose}
            className="p-1.5 rounded-lg text-slate-400 hover:text-slate-700 hover:bg-slate-200/60 transition-colors"
          >
            <X className="w-5 h-5" />
          </button>
        </div>

        {/* Scrollable Content */}
        <div className="overflow-y-auto p-6 space-y-6">
          {/* Owner & Venue Location */}
          <div className="bg-slate-50/80 rounded-xl p-4 border border-slate-200/70">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3 flex items-center gap-2">
              <Building className="w-4 h-4 text-emerald-600" /> Owner Identity & Location
            </h3>
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4 text-sm">
              <div>
                <span className="text-xs text-slate-500">Owner Full Name</span>
                <p className="font-semibold text-slate-800">{admin.ownerName}</p>
              </div>
              <div>
                <span className="text-xs text-slate-500">Venue Area</span>
                <p className="font-semibold text-slate-800">{admin.neighborhoodArea}</p>
              </div>
              <div>
                <span className="text-xs text-slate-500">Verified Mobile</span>
                <div className="flex items-center gap-2 mt-0.5">
                  <Phone className="w-3.5 h-3.5 text-slate-400" />
                  <span className="font-semibold text-slate-800">{admin.ownerPhone}</span>
                  <span className="px-1.5 py-0.5 text-[10px] font-bold bg-emerald-100 text-emerald-800 rounded">
                    Verified ✓
                  </span>
                </div>
              </div>
              <div>
                <span className="text-xs text-slate-500">Verified Email</span>
                <div className="flex items-center gap-2 mt-0.5">
                  <Mail className="w-3.5 h-3.5 text-slate-400" />
                  <span className="font-semibold text-slate-800">{admin.ownerEmail}</span>
                  <span className="px-1.5 py-0.5 text-[10px] font-bold bg-emerald-100 text-emerald-800 rounded">
                    Verified ✓
                  </span>
                </div>
              </div>
              <div className="md:col-span-2">
                <span className="text-xs text-slate-500">Physical Address</span>
                <div className="flex items-start gap-1.5 mt-0.5">
                  <MapPin className="w-4 h-4 text-slate-400 shrink-0 mt-0.5" />
                  <p className="text-slate-800 font-medium">{admin.streetAddress}</p>
                </div>
              </div>
            </div>
          </div>

          {/* Amenities */}
          <div>
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3 flex items-center gap-2">
              <Sparkles className="w-4 h-4 text-amber-500" /> Amenities & Court Features
            </h3>
            {admin.amenities && admin.amenities.length > 0 ? (
              <div className="flex flex-wrap gap-2">
                {admin.amenities.map((amenity, idx) => (
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
              <p className="text-xs text-slate-400 italic">No amenities specified</p>
            )}
          </div>

          {/* Venue Photos */}
          <div>
            <div className="flex items-center justify-between mb-3">
              <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 flex items-center gap-2">
                <ImageIcon className="w-4 h-4 text-indigo-500" /> Verified Venue Photos (
                {admin.photoUrls?.length || 0})
              </h3>
              <span className="text-xs text-slate-400">Click photo to inspect</span>
            </div>

            {admin.photoUrls && admin.photoUrls.length > 0 ? (
              <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
                {admin.photoUrls.map((photo, idx) => {
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
                      />
                      <div className="absolute inset-0 bg-slate-900/40 opacity-0 group-hover:opacity-100 transition-opacity flex items-center justify-center text-white text-xs font-medium gap-1">
                        <ExternalLink className="w-4 h-4" /> Full View
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

          {/* KYC Documents */}
          <div className="bg-slate-50/80 rounded-xl p-4 border border-slate-200/70">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3 flex items-center gap-2">
              <FileText className="w-4 h-4 text-blue-600" /> Audited KYC Documents
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div className="p-3 bg-white rounded-lg border border-slate-200 shadow-2xs">
                <span className="text-xs font-bold text-slate-700 block mb-1">Aadhaar Card</span>
                <p className="font-mono text-xs text-slate-600 mb-2 font-medium">
                  {admin.aadhaarNumber || 'Attached'}
                </p>
                {admin.aadhaarDocUrl && (
                  <a
                    href={getFullFileUrl(admin.aadhaarDocUrl)}
                    target="_blank"
                    rel="noreferrer"
                    className="inline-flex items-center gap-1 text-xs font-semibold text-emerald-600 hover:underline"
                  >
                    <ExternalLink className="w-3.5 h-3.5" /> View Aadhaar PDF
                  </a>
                )}
              </div>

              <div className="p-3 bg-white rounded-lg border border-slate-200 shadow-2xs">
                <span className="text-xs font-bold text-slate-700 block mb-1">PAN Card</span>
                <p className="font-mono text-xs text-slate-600 mb-2 font-medium">
                  {admin.panNumber || 'Attached'}
                </p>
                {admin.panDocUrl && (
                  <a
                    href={getFullFileUrl(admin.panDocUrl)}
                    target="_blank"
                    rel="noreferrer"
                    className="inline-flex items-center gap-1 text-xs font-semibold text-emerald-600 hover:underline"
                  >
                    <ExternalLink className="w-3.5 h-3.5" /> View PAN PDF
                  </a>
                )}
              </div>

              <div className="p-3 bg-white rounded-lg border border-slate-200 shadow-2xs">
                <span className="text-xs font-bold text-slate-700 block mb-1">GST Registration</span>
                <p className="font-mono text-xs text-slate-600 mb-2 font-medium">
                  {admin.gstin || 'Attached'}
                </p>
                {admin.gstDocUrl && (
                  <a
                    href={getFullFileUrl(admin.gstDocUrl)}
                    target="_blank"
                    rel="noreferrer"
                    className="inline-flex items-center gap-1 text-xs font-semibold text-emerald-600 hover:underline"
                  >
                    <ExternalLink className="w-3.5 h-3.5" /> View GST PDF
                  </a>
                )}
              </div>
            </div>
          </div>

          {/* Banking / Payout */}
          <div className="bg-slate-50/80 rounded-xl p-4 border border-slate-200/70">
            <h3 className="text-xs font-bold uppercase tracking-wider text-slate-500 mb-3 flex items-center gap-2">
              <CreditCard className="w-4 h-4 text-emerald-600" /> Bank & Payout Information
            </h3>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-4 text-sm">
              <div>
                <span className="text-xs text-slate-500">Bank Account</span>
                <p className="font-mono font-semibold text-slate-800">{admin.bankAccount || '-'}</p>
              </div>
              <div>
                <span className="text-xs text-slate-500">IFSC Code</span>
                <p className="font-mono font-semibold text-slate-800">{admin.ifscCode || '-'}</p>
              </div>
              <div>
                <span className="text-xs text-slate-500">Partner UPI ID</span>
                <p className="font-mono font-semibold text-slate-800">{admin.upiId || '-'}</p>
              </div>
            </div>
          </div>
        </div>

        {/* Footer */}
        <div className="px-6 py-4 border-t border-slate-200 bg-slate-50 rounded-b-2xl flex items-center justify-between">
          <div className="text-xs text-slate-500 flex items-center gap-2">
            <Calendar className="w-3.5 h-3.5" />
            <span>Record in <code className="font-mono font-bold text-slate-700">VerifiedAdmin</code> table (ID: #{admin.id})</span>
          </div>
          <button
            onClick={onClose}
            className="px-5 py-2 text-xs font-semibold text-slate-700 bg-slate-200 hover:bg-slate-300 rounded-xl transition-colors"
          >
            Close Details
          </button>
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
