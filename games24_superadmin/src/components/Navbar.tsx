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
  Server,
  ArrowRightLeft,
  CircleDot,
  Radio,
} from 'lucide-react';
import { getEffectiveBackendUrl, setEffectiveBackendUrl, DEFAULT_LIVE_BACKEND_URL, DEFAULT_LOCAL_BACKEND_URL } from '@/lib/api';

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
  const [backendUrl, setBackendUrl] = useState<string>(() => {
    if (typeof window !== 'undefined') {
      return getEffectiveBackendUrl();
    }
    return DEFAULT_LOCAL_BACKEND_URL;
  });
  const [currentTime, setCurrentTime] = useState<string>('');

  useEffect(() => {
    const updateTime = () => {
      const now = new Date();
      setCurrentTime(now.toLocaleTimeString('en-US', { hour12: false, hour: '2-digit', minute: '2-digit', second: '2-digit' }));
    };
    updateTime();
    const interval = setInterval(updateTime, 1000);
    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    const current = getEffectiveBackendUrl();
    if (current !== backendUrl) {
      setBackendUrl(current);
    }
  }, [backendUrl]);

  const handleToggleBackend = () => {
    const isLive = backendUrl.includes('onrender');
    const target = isLive ? DEFAULT_LOCAL_BACKEND_URL : DEFAULT_LIVE_BACKEND_URL;
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
    { key: 'OVERVIEW', label: 'Command Hub', icon: LayoutDashboard },
    { key: 'REGISTRATIONS', label: 'Venue Approvals', icon: FileCheck2, badge: waitingCount },
    { key: 'BOOKINGS', label: 'Slots & Holds', icon: CalendarDays },
    { key: 'TOURNAMENTS', label: 'Championships', icon: Trophy },
    { key: 'TURFS', label: 'Turf Performance', icon: Building2 },
  ];

  const isLive = backendUrl.includes('onrender');

  return (
    <header className="sticky top-0 z-40 w-full border-b border-[#1E273A] bg-[#080B11]/95 backdrop-blur-md">
      {/* Top telemetry bar */}
      <div className="border-b border-[#151D2E] bg-[#05070B] px-4 sm:px-6 lg:px-8 py-1.5 text-[11px] text-slate-400">
        <div className="max-w-7xl mx-auto flex items-center justify-between">
          {/* Left: Backend Environment Selector */}
          <div className="flex items-center gap-2.5">
            <div className={`inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md font-mono text-[10px] font-bold tracking-wider uppercase border ${
              isLive
                ? 'bg-emerald-500/10 text-emerald-400 border-emerald-500/30'
                : 'bg-[#D4FF00]/10 text-[#D4FF00] border-[#D4FF00]/30'
            }`}>
              <span className={`w-1.5 h-1.5 rounded-full animate-pulse ${isLive ? 'bg-emerald-400' : 'bg-[#D4FF00]'}`}></span>
              {isLive ? 'RENDER CLOUD' : 'LOCAL ENGINE'}
            </div>

            <button
              onClick={handleToggleBackend}
              title="Click to toggle between Live Render Cloud and Localhost backend"
              className="group inline-flex items-center gap-1.5 px-2 py-0.5 rounded-md bg-[#0E131F] hover:bg-[#161D2E] text-slate-300 hover:text-white border border-[#1E273A] hover:border-slate-600 transition-all cursor-pointer font-mono text-[11px]"
            >
              <Server className="w-3 h-3 text-slate-400 group-hover:text-slate-200" />
              <span>{backendUrl.replace(/^https?:\/\//, '')}</span>
              <span className="text-[9px] font-semibold text-[#D4FF00] bg-[#D4FF00]/10 border border-[#D4FF00]/20 px-1 py-0.2 rounded ml-1 flex items-center gap-1">
                <ArrowRightLeft className="w-2.5 h-2.5" />
                switch
              </span>
            </button>

            <div className="hidden sm:flex items-center gap-1.5 text-slate-500 font-mono text-[11px]">
              <span>•</span>
              <span className="inline-flex items-center gap-1 text-emerald-400 font-medium">
                <Radio className="w-3 h-3 animate-pulse text-emerald-400" />
                API Active
              </span>
            </div>
          </div>

          {/* Right: Architecture & Time */}
          <div className="flex items-center gap-3">
            <span className="hidden md:inline-flex items-center gap-1.5 font-mono text-[11px] text-slate-400">
              <Terminal className="w-3 h-3 text-slate-500" />
              PostgreSQL • Prisma ORM
            </span>
            <div className="h-3 w-px bg-slate-800 hidden sm:block"></div>
            {currentTime && (
              <span className="font-mono text-[11px] text-slate-300 font-medium">
                {currentTime} UTC+5:30
              </span>
            )}
            <div className="h-3 w-px bg-slate-800 hidden sm:block"></div>
            <span className="text-[10px] font-bold font-mono px-1.5 py-0.5 rounded bg-slate-800 text-slate-300">
              EXEC V2.6
            </span>
          </div>
        </div>
      </div>

      {/* Main Navbar */}
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo & Platform ID */}
          <div className="flex items-center gap-4">
            <Link href="/" className="flex items-center gap-3 group">
              <div className="w-9 h-9 rounded-lg bg-[#D4FF00] flex items-center justify-center text-black font-black shadow-md shadow-[#D4FF00]/15 group-hover:scale-105 transition-transform duration-150">
                <span className="font-mono text-base font-black tracking-tighter">G24</span>
              </div>
              <div className="flex flex-col">
                <div className="flex items-center gap-2">
                  <span className="font-black text-base text-white tracking-tight">
                    GAMES<span className="text-[#D4FF00]">24</span>
                  </span>
                  <span className="text-slate-600 text-xs">/</span>
                  <span className="text-xs font-bold text-slate-200 tracking-wide uppercase">Control Center</span>
                </div>
                <span className="text-[10px] text-slate-400 font-medium tracking-wide">
                  Venue Approvals & Platform Oversight
                </span>
              </div>
            </Link>
          </div>

          {/* Navigation Items */}
          <nav className="flex items-center gap-1.5 overflow-x-auto py-1 scrollbar-none">
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
                      className={`relative flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all duration-150 cursor-pointer ${
                        isActive
                          ? 'bg-[#151D2E] text-white border border-[#2A374F] shadow-sm'
                          : 'text-slate-400 hover:text-slate-100 hover:bg-[#0E131F] border border-transparent'
                      }`}
                    >
                      <Icon className={`w-3.5 h-3.5 ${isActive ? 'text-[#D4FF00]' : 'text-slate-400'}`} />
                      <span>{item.label}</span>
                      {Boolean(item.badge && item.badge > 0) && (
                        <span className="ml-0.5 px-1.5 py-0.2 text-[10px] font-bold rounded-full bg-amber-500/20 text-amber-300 border border-amber-500/30 font-mono animate-pulse">
                          {item.badge}
                        </span>
                      )}
                      {isActive && (
                        <span className="absolute bottom-0 left-2 right-2 h-0.5 bg-[#D4FF00] rounded-full"></span>
                      )}
                    </button>
                  );
                })}
              </>
            )}

            <div className="h-4 w-px bg-slate-800 mx-1 hidden sm:block"></div>

            <Link
              href="/admins"
              className={`flex items-center gap-2 px-3 py-1.5 rounded-lg text-xs font-semibold transition-all duration-150 ${
                pathname === '/admins'
                  ? 'bg-[#151D2E] text-white border border-[#2A374F]'
                  : 'text-slate-400 hover:text-slate-100 hover:bg-[#0E131F] border border-transparent'
              }`}
            >
              <ShieldCheck className="w-3.5 h-3.5 text-[#D4FF00]" />
              <span>Verified Directory</span>
            </Link>
          </nav>
        </div>
      </div>
    </header>
  );
}
