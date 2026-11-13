'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  ShieldCheck,
  FileCheck2,
  Trophy,
  CalendarDays,
  LayoutDashboard,
  Building2,
  Terminal,
  Activity,
  ChevronRight,
  ExternalLink,
} from 'lucide-react';
import { getEffectiveBackendUrl, setEffectiveBackendUrl, DEFAULT_LIVE_BACKEND_URL } from '@/lib/api';

interface NavbarProps {
  waitingCount?: number;
  verifiedCount?: number;
  activeSection?: string;
  onSelectSection?: (section: string) => void;
}

export default function Navbar({
  waitingCount = 0,
  activeSection,
  onSelectSection,
}: NavbarProps) {
  const pathname = usePathname();
  const isMainPage = pathname === '/';
  const [backendUrl, setBackendUrl] = useState<string>('https://games-24-final.onrender.com');

  useEffect(() => {
    setBackendUrl(getEffectiveBackendUrl());
  }, []);

  const handleToggleBackend = () => {
    const isLive = backendUrl.includes('onrender');
    const target = isLive ? 'http://localhost:3000' : DEFAULT_LIVE_BACKEND_URL;
    setEffectiveBackendUrl(target);
    setBackendUrl(target);
    window.location.reload();
  };

  const handleNavClick = (sectionKey: string) => {
    if (onSelectSection && isMainPage) {
      onSelectSection(sectionKey);
    }
  };

  const navItems = [
    { key: 'OVERVIEW', label: 'Overview', icon: LayoutDashboard },
    { key: 'REGISTRATIONS', label: 'Approvals', icon: FileCheck2, badge: waitingCount },
    { key: 'BOOKINGS', label: 'Bookings & Holds', icon: CalendarDays },
    { key: 'TOURNAMENTS', label: 'Tournaments', icon: Trophy },
    { key: 'TURFS', label: 'Turf Revenues', icon: Building2 },
  ];

  return (
    <header className="sticky top-0 z-40 w-full border-b border-[#1E2638] bg-[#0B0F19]/90 backdrop-blur-md">
      {/* Top micro-bar: Environment & Systems Health */}
      <div className="border-b border-[#171E2E] bg-[#080B13] px-4 sm:px-6 lg:px-8 py-1.5 text-[11px] text-slate-400">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          <div className="flex items-center gap-2">
            <span className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded font-mono text-[10px] font-semibold uppercase tracking-wider ${
              backendUrl.includes('onrender')
                ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20'
                : 'bg-amber-500/10 text-amber-400 border border-amber-500/20'
            }`}>
              <span className={`w-1.5 h-1.5 rounded-full ${backendUrl.includes('onrender') ? 'bg-emerald-400' : 'bg-amber-400'}`}></span>
              {backendUrl.includes('onrender') ? 'LIVE CLOUD' : 'LOCAL'}
            </span>
            <span className="text-slate-600">/</span>
            <button
              onClick={handleToggleBackend}
              title="Click to toggle between Live Render Cloud and Localhost backend"
              className="inline-flex items-center gap-1.5 px-2 py-0.5 rounded bg-[#161D2F] hover:bg-[#1E273E] text-slate-300 hover:text-white border border-[#28354F] transition-all cursor-pointer font-mono text-[11px]"
            >
              <span>{backendUrl.replace(/^https?:\/\//, '')}</span>
              <span className="text-[9px] text-indigo-400 bg-indigo-500/15 px-1 py-0.5 rounded ml-0.5">switch</span>
            </button>
            <span className="hidden sm:inline-block text-slate-600">•</span>
            <span className="hidden sm:inline-flex items-center gap-1.5 text-emerald-400 font-medium">
              <span className="relative flex h-2 w-2">
                <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
                <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
              </span>
              Connected
            </span>
          </div>

          <div className="flex items-center gap-3">
            <span className="hidden md:inline-flex items-center gap-1 font-mono text-[11px] text-slate-400">
              <Terminal className="w-3 h-3 text-slate-500" />
              Node.js v20 • PostgreSQL Prisma
            </span>
            <div className="h-3 w-px bg-slate-800 hidden sm:block"></div>
            <span className="text-slate-400 font-mono text-[10px]">SuperAdmin v2.4</span>
          </div>
        </div>
      </div>

      {/* Main Navbar */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo & Workspace Selector */}
          <div className="flex items-center gap-4">
            <Link href="/" className="flex items-center gap-3 group">
              <div className="w-9 h-9 rounded-xl bg-gradient-to-tr from-indigo-600 to-violet-500 flex items-center justify-center text-white shadow-lg shadow-indigo-600/25 group-hover:scale-105 transition-all">
                <ShieldCheck className="w-5 h-5" />
              </div>
              <div className="flex flex-col">
                <div className="flex items-center gap-1.5">
                  <span className="font-extrabold text-base text-white tracking-tight">
                    Games<span className="text-indigo-400">24</span>
                  </span>
                  <span className="text-slate-600 text-xs">/</span>
                  <span className="text-xs font-semibold text-slate-200">Control Center</span>
                </div>
                <span className="text-[10px] text-slate-400 font-medium -mt-0.5">
                  Render Operations & Turf Audit
                </span>
              </div>
            </Link>
          </div>

          {/* Navigation Links */}
          <nav className="flex items-center gap-1 overflow-x-auto py-1 scrollbar-none">
            {isMainPage && (
              <>
                {navItems.map((item) => {
                  const Icon = item.icon;
                  const isActive = activeSection === item.key;
                  return (
                    <button
                      key={item.key}
                      type="button"
                      onClick={() => handleNavClick(item.key)}
                      className={`relative flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all duration-150 ${
                        isActive
                          ? 'bg-[#182033] text-indigo-300 border border-indigo-500/30 shadow-xs'
                          : 'text-slate-400 hover:text-slate-200 hover:bg-[#141A29]'
                      }`}
                    >
                      <Icon className={`w-3.5 h-3.5 ${isActive ? 'text-indigo-400' : 'text-slate-500'}`} />
                      <span>{item.label}</span>
                      {Boolean(item.badge && item.badge > 0) && (
                        <span className="ml-0.5 px-1.5 py-0.2 text-[10px] font-bold rounded-full bg-amber-500/20 text-amber-300 border border-amber-500/30 animate-pulse">
                          {item.badge}
                        </span>
                      )}
                      {isActive && (
                        <span className="absolute bottom-0 left-2 right-2 h-0.5 bg-indigo-500 rounded-full shadow-[0_0_8px_rgba(99,102,241,0.8)]"></span>
                      )}
                    </button>
                  );
                })}
              </>
            )}

            <div className="h-4 w-px bg-slate-800 mx-1 hidden sm:block"></div>

            <Link
              href="/admins"
              className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all ${
                pathname === '/admins'
                  ? 'bg-[#182033] text-indigo-300 border border-indigo-500/30'
                  : 'text-slate-400 hover:text-slate-200 hover:bg-[#141A29]'
              }`}
            >
              <ShieldCheck className="w-3.5 h-3.5 text-indigo-400" />
              <span>Verified Directory</span>
            </Link>
          </nav>
        </div>
      </div>
    </header>
  );
}
