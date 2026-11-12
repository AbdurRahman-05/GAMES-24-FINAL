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
  Tag,
  Trash2,
} from 'lucide-react';

interface Props {
  admin: VerifiedAdmin | null;
  onClose: () => void;
  onToggleHold?: (admin: VerifiedAdmin) => void;
  onDelete?: (admin: VerifiedAdmin) => void;
}

export default function AdminDetailModal({ admin, onClose, onToggleHold, onDelete }: Props) {
  const [previewImage, setPreviewImage] = useState<string | null>(null);

  if (!admin) return null;

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
