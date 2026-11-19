'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import {
  LayoutDashboard,
  TrendingUp,
  FileCheck2,
  CalendarDays,
  Trophy,
  Building2,
  ShieldCheck,
  Terminal,
  Activity,
  Server,
  Database,
  Clock,
  Sparkles,
  ChevronRight,
  ExternalLink,
  ChevronDown,
  Crosshair,
  MapPin,
} from 'lucide-react';
import {
  DEFAULT_LOCAL_BACKEND_URL,
  DEFAULT_LIVE_BACKEND_URL,
  getEffectiveBackendUrl,
  setEffectiveBackendUrl,
} from '@/lib/api';

export type DashboardTab =
  | 'OVERVIEW'
  | 'ANALYTICS'
  | 'REGISTRATIONS'
  | 'BOOKINGS'
  | 'TOURNAMENTS'
  | 'TURFS'
  | 'MAP_RADAR';

interface Props {
  activeTab: DashboardTab;
  onSelectTab: (tab: DashboardTab) => void;
  waitingKycCount?: number;
  isOpenMobile?: boolean;
  onCloseMobile?: () => void;
}

export default function Sidebar({
  activeTab,
  onSelectTab,
  waitingKycCount = 0,
  isOpenMobile = false,
  onCloseMobile,
}: Props) {
  const [currentUrl, setCurrentUrl] = useState('');
  const [isLive, setIsLive] = useState(false);
  const [currentTime, setCurrentTime] = useState('');

  useEffect(() => {
    const url = getEffectiveBackendUrl();
    setCurrentUrl(url);
    setIsLive(url.includes('render.com') || url.includes('https://'));

    const updateClock = () => {
      const now = new Date();
      setCurrentTime(
        now.toLocaleTimeString('en-US', {
          hour12: false,
          hour: '2-digit',
          minute: '2-digit',
          second: '2-digit',
          timeZone: 'Asia/Kolkata',
        })
      );
    };
    updateClock();
    const interval = setInterval(updateClock, 1000);
    return () => clearInterval(interval);
  }, []);

  const toggleBackend = () => {
    if (isLive) {
      setEffectiveBackendUrl(DEFAULT_LOCAL_BACKEND_URL);
    } else {
      setEffectiveBackendUrl(DEFAULT_LIVE_BACKEND_URL);
    }
    window.location.reload();
  };

  const navGroups = [
    {
      group: 'COMMAND & AUDIT',
      items: [
        {
          id: 'OVERVIEW' as DashboardTab,
          label: 'Executive Overview',
          icon: LayoutDashboard,
          badge: null,
        },
        {
          id: 'ANALYTICS' as DashboardTab,
          label: 'Analytics & Insights',
          icon: TrendingUp,
          badge: null,
        },
      ],
    },
    {
      group: 'VENUE PARTNERS',
      items: [
        {
          id: 'REGISTRATIONS' as DashboardTab,
          label: 'KYC Authorizations',
          icon: FileCheck2,
          badge: waitingKycCount > 0 ? waitingKycCount : null,
          badgeAlert: true,
        },
        {
          id: 'TURFS' as DashboardTab,
          label: 'Partner Turfs',
          icon: Building2,
          badge: null,
        },
        {
          id: 'MAP_RADAR' as DashboardTab,
          label: 'Turf & Player Radar',
          icon: Crosshair,
          badge: 'RADAR',
        },
      ],
    },
    {
      group: 'RESERVATIONS & PLAY',
      items: [
        {
          id: 'BOOKINGS' as DashboardTab,
          label: 'Slot Bookings',
          icon: CalendarDays,
          badge: null,
        },
        {
          id: 'TOURNAMENTS' as DashboardTab,
          label: 'Championships',
          icon: Trophy,
          badge: null,
        },
      ],
    },
  ];

  const handleNavClick = (tabId: DashboardTab) => {
    onSelectTab(tabId);
    if (onCloseMobile) onCloseMobile();
  };

  return (
    <>
      {/* Mobile Backdrop */}
      {isOpenMobile && (
        <div
          className="fixed inset-0 z-40 bg-black/80 backdrop-blur-sm lg:hidden"
          onClick={onCloseMobile}
        />
      )}

      {/* Main Sidebar Shell */}
      <aside
        className={`fixed top-0 bottom-0 left-0 z-50 w-72 bg-[#0B0F19] border-r border-[#1E273A] flex flex-col justify-between transition-transform duration-200 lg:translate-x-0 ${
          isOpenMobile ? 'translate-x-0' : '-translate-x-full'
        }`}
      >
        {/* Top Organization Header */}
        <div>
          <div className="p-5 border-b border-[#1E273A] bg-[#0E131F]">
            <div className="flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl bg-[#D4FF00] flex items-center justify-center text-black font-black shadow-lg shadow-[#D4FF00]/15">
                <span className="font-mono text-sm tracking-tighter">G24</span>
              </div>
              <div className="flex-1 min-w-0">
                <div className="flex items-center gap-1.5">
                  <span className="font-extrabold text-white text-sm tracking-tight truncate">
                    GAMES24 // PRO
                  </span>
                  <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-ping shrink-0" />
                </div>
                <div className="flex items-center gap-1.5 text-[11px] font-mono text-slate-400 truncate">
                  <span className="text-[#D4FF00] font-semibold">SUPER ADMIN</span>
                  <span>•</span>
                  <span>v2.6 OS</span>
                </div>
              </div>
            </div>
          </div>

          {/* Grouped Navigation */}
          <nav className="p-4 space-y-6 overflow-y-auto max-h-[calc(100vh-270px)]">
            {navGroups.map((group) => (
              <div key={group.group} className="space-y-1.5">
                <span className="px-3 text-[10px] font-mono font-bold uppercase tracking-wider text-slate-500 block">
                  {group.group}
                </span>

                <div className="space-y-1">
                  {group.items.map((item) => {
                    const Icon = item.icon;
                    const isActive = activeTab === item.id;

                    return (
                      <button
                        key={item.id}
                        onClick={() => handleNavClick(item.id)}
                        className={`w-full flex items-center justify-between px-3 py-2.5 rounded-xl text-xs font-semibold font-mono transition-all duration-150 ${
                          isActive
                            ? 'bg-[#182033] text-white border border-[#28354F] shadow-sm'
                            : 'text-slate-400 hover:text-white hover:bg-[#111726]'
                        }`}
                      >
                        <div className="flex items-center gap-2.5 truncate">
                          <Icon
                            className={`w-4 h-4 shrink-0 transition-colors ${
                              isActive ? 'text-[#D4FF00]' : 'text-slate-400'
                            }`}
                          />
                          <span className="truncate">{item.label}</span>
                        </div>

                        {item.badge !== null && (
                          <span
                            className={`px-2 py-0.5 text-[10px] font-bold rounded-full font-mono ${
                              item.badgeAlert
                                ? 'bg-amber-500 text-black animate-pulse'
                                : 'bg-[#161D2E] text-slate-300'
                            }`}
                          >
                            {item.badge}
                          </span>
                        )}
                      </button>
                    );
                  })}
                </div>
              </div>
            ))}

            {/* Direct Link to Verified Directory */}
            <div className="pt-2 border-t border-[#1E273A]">
              <Link
                href="/admins"
                className="w-full flex items-center justify-between px-3 py-2.5 rounded-xl text-xs font-semibold font-mono text-slate-400 hover:text-white hover:bg-[#111726] transition-all"
              >
                <div className="flex items-center gap-2.5">
                  <ShieldCheck className="w-4 h-4 text-emerald-400" />
                  <span>Verified Directory</span>
                </div>
                <ChevronRight className="w-3.5 h-3.5 text-slate-500" />
              </Link>
            </div>
          </nav>
        </div>

        {/* Bottom Telemetry Box */}
        <div className="p-4 border-t border-[#1E273A] bg-[#0E131F]/90 space-y-3 font-mono text-xs">
          {/* Environment Switcher */}
          <div className="flex items-center justify-between p-2.5 rounded-xl bg-[#05080E] border border-[#1E273A]">
            <div className="flex items-center gap-2 truncate">
              <Server className="w-3.5 h-3.5 text-slate-400 shrink-0" />
              <div className="truncate">
                <span className="block text-[10px] text-slate-400">ENGINE GATEWAY</span>
                <span className={`text-[11px] font-bold ${isLive ? 'text-emerald-400' : 'text-sky-400'}`}>
                  {isLive ? 'RENDER CLOUD' : 'LOCAL HOST'}
                </span>
              </div>
            </div>

            <button
              onClick={toggleBackend}
              className="px-2.5 py-1 text-[10px] font-bold rounded-md bg-[#161D2E] hover:bg-[#20293F] text-slate-200 border border-[#28354F] transition-all shrink-0 active:scale-95"
            >
              Switch
            </button>
          </div>

          {/* Telemetry Status Row */}
          <div className="flex items-center justify-between px-1 text-[11px] text-slate-400">
            <span className="flex items-center gap-1.5 text-emerald-400">
              <span className="w-1.5 h-1.5 rounded-full bg-emerald-400 animate-pulse" />
              DB Synced
            </span>
            <span className="flex items-center gap-1 text-slate-400">
              <Clock className="w-3 h-3 text-slate-500" />
              {currentTime || 'IST'}
            </span>
          </div>
        </div>
      </aside>
    </>
  );
}
