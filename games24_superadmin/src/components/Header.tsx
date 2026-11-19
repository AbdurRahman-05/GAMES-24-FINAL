'use client';

import { useState } from 'react';
import {
  Menu,
  RefreshCw,
  Plus,
  Bell,
  Search,
  Sparkles,
  Command,
  FileCheck2,
} from 'lucide-react';

interface Props {
  onToggleMobileSidebar: () => void;
  onSyncMetrics: () => void;
  isSyncing: boolean;
  onDeployTournament: () => void;
  pendingKycCount?: number;
  onOpenKyc?: () => void;
  searchQuery?: string;
  onSearchChange?: (val: string) => void;
  activeTabTitle: string;
}

export default function Header({
  onToggleMobileSidebar,
  onSyncMetrics,
  isSyncing,
  onDeployTournament,
  pendingKycCount = 0,
  onOpenKyc,
  searchQuery = '',
  onSearchChange,
  activeTabTitle,
}: Props) {
  return (
    <header className="sticky top-0 z-30 h-16 bg-[#080B11]/90 backdrop-blur-md border-b border-[#1E273A] px-4 sm:px-6 lg:px-8 flex items-center justify-between gap-4">
      {/* Left: Mobile Menu Toggle & Title */}
      <div className="flex items-center gap-3">
        <button
          onClick={onToggleMobileSidebar}
          className="p-2 rounded-lg text-slate-400 hover:text-white hover:bg-[#111726] border border-[#1E273A] lg:hidden"
          aria-label="Toggle navigation menu"
        >
          <Menu className="w-5 h-5" />
        </button>

        <div className="hidden sm:block">
          <div className="flex items-center gap-2 text-xs font-mono text-slate-400">
            <span>CONSOLE</span>
            <span className="text-slate-600">/</span>
            <span className="text-white font-bold">{activeTabTitle}</span>
          </div>
        </div>
      </div>

      {/* Middle: Universal Search Bar */}
      <div className="flex-1 max-w-md hidden md:block">
        <div className="relative">
          <Search className="w-4 h-4 text-slate-500 absolute left-3 top-1/2 -translate-y-1/2" />
          <input
            type="text"
            placeholder="Search venue names, player contacts, booking IDs..."
            value={searchQuery}
            onChange={(e) => onSearchChange && onSearchChange(e.target.value)}
            className="w-full pl-9 pr-16 py-1.5 bg-[#0E131F] border border-[#1E273A] rounded-xl text-xs text-white placeholder-slate-500 focus:outline-hidden focus:border-[#D4FF00] font-mono transition-all"
          />
          <div className="absolute right-2.5 top-1/2 -translate-y-1/2 flex items-center gap-0.5 px-1.5 py-0.5 rounded bg-[#161D2E] text-[10px] font-mono text-slate-400 border border-[#28354F]">
            <Command className="w-2.5 h-2.5" />
            <span>K</span>
          </div>
        </div>
      </div>

      {/* Right: Actions */}
      <div className="flex items-center gap-2.5">
        {/* Pending KYC Notification Bell */}
        {pendingKycCount > 0 && onOpenKyc && (
          <button
            onClick={onOpenKyc}
            className="relative p-2 rounded-lg text-amber-300 bg-amber-500/10 hover:bg-amber-500/20 border border-amber-500/30 transition-all active:scale-95 flex items-center gap-1.5"
            title={`${pendingKycCount} venue applications waiting for KYC approval`}
          >
            <Bell className="w-4 h-4" />
            <span className="text-xs font-mono font-bold">{pendingKycCount}</span>
            <span className="absolute -top-1 -right-1 w-2.5 h-2.5 rounded-full bg-amber-400 animate-ping" />
          </button>
        )}

        {/* Sync Metrics Button */}
        <button
          onClick={onSyncMetrics}
          disabled={isSyncing}
          className="flex items-center gap-2 px-3 py-2 rounded-xl text-xs font-semibold bg-[#0E131F] hover:bg-[#161D2E] text-slate-200 border border-[#1E273A] transition-all disabled:opacity-50 font-mono active:scale-95"
          title="Synchronize live platform metrics"
        >
          <RefreshCw className={`w-3.5 h-3.5 ${isSyncing ? 'animate-spin text-[#D4FF00]' : 'text-slate-400'}`} />
          <span className="hidden sm:inline">Sync</span>
        </button>

        {/* Deploy Tournament Button */}
        <button
          onClick={onDeployTournament}
          className="flex items-center gap-2 px-3.5 py-2 rounded-xl text-xs font-bold bg-[#D4FF00] hover:bg-[#b8dd00] text-black shadow-md shadow-[#D4FF00]/15 transition-all font-mono active:scale-95 shrink-0"
        >
          <Plus className="w-3.5 h-3.5 stroke-[2.5]" />
          <span>Deploy Tournament</span>
        </button>
      </div>
    </header>
  );
}
