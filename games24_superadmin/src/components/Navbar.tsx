'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import {
  ShieldCheck,
  FileCheck2,
  Trophy,
  CalendarDays,
  LayoutDashboard,
  Users,
} from 'lucide-react';

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

  const handleNavClick = (sectionKey: string) => {
    if (onSelectSection && isMainPage) {
      onSelectSection(sectionKey);
    }
  };

  return (
    <header className="sticky top-0 z-40 w-full border-b border-slate-200/80 bg-white/95 backdrop-blur-md shadow-xs">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="flex items-center justify-between h-16">
          {/* Logo & Platform Info */}
          <div className="flex items-center gap-3">
            <Link href="/" className="flex items-center gap-3 group">
              <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-emerald-600 to-teal-500 flex items-center justify-center text-white shadow-md shadow-emerald-500/20 group-hover:scale-105 transition-transform">
                <ShieldCheck className="w-6 h-6" />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <span className="font-extrabold text-lg text-slate-900 tracking-tight">
                    Games<span className="text-emerald-600">24</span>
                  </span>
                  <span className="px-2 py-0.5 text-[10px] font-bold tracking-wider uppercase bg-emerald-100 text-emerald-800 rounded-md">
                    Control Center
                  </span>
                </div>
                <p className="text-[11px] text-slate-500 font-medium">
                  Super Admin Management & Live Oversight
                </p>
              </div>
            </Link>
          </div>

          {/* Navigation Items */}
          <nav className="flex items-center gap-1.5 overflow-x-auto py-1">
            {isMainPage && (
              <>
                <button
                  type="button"
                  onClick={() => handleNavClick('OVERVIEW')}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                    activeSection === 'OVERVIEW'
                      ? 'bg-emerald-600 text-white shadow-xs'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                  }`}
                >
                  <LayoutDashboard className="w-3.5 h-3.5" />
                  <span>Live Overview</span>
                </button>

                <button
                  type="button"
                  onClick={() => handleNavClick('REGISTRATIONS')}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                    activeSection === 'REGISTRATIONS'
                      ? 'bg-emerald-600 text-white shadow-xs'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                  }`}
                >
                  <FileCheck2 className="w-3.5 h-3.5" />
                  <span>Approvals</span>
                  {waitingCount > 0 && (
                    <span className="ml-1 text-[10px] font-extrabold px-1.5 py-0.2 rounded-full bg-amber-500 text-white">
                      {waitingCount}
                    </span>
                  )}
                </button>

                <button
                  type="button"
                  onClick={() => handleNavClick('BOOKINGS')}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                    activeSection === 'BOOKINGS'
                      ? 'bg-emerald-600 text-white shadow-xs'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                  }`}
                >
                  <CalendarDays className="w-3.5 h-3.5" />
                  <span>Bookings & Holds</span>
                </button>

                <button
                  type="button"
                  onClick={() => handleNavClick('TOURNAMENTS')}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                    activeSection === 'TOURNAMENTS'
                      ? 'bg-emerald-600 text-white shadow-xs'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                  }`}
                >
                  <Trophy className="w-3.5 h-3.5" />
                  <span>Tournaments</span>
                </button>

                <button
                  type="button"
                  onClick={() => handleNavClick('TURFS')}
                  className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                    activeSection === 'TURFS'
                      ? 'bg-emerald-600 text-white shadow-xs'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
                  }`}
                >
                  <Users className="w-3.5 h-3.5" />
                  <span>Turf Revenues</span>
                </button>
              </>
            )}

            <Link
              href="/admins"
              className={`flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold transition-all ${
                pathname === '/admins'
                  ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                  : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100'
              }`}
            >
              <ShieldCheck className="w-3.5 h-3.5 text-emerald-600" />
              <span>Verified Directory</span>
            </Link>
          </nav>
        </div>
      </div>
    </header>
  );
}
