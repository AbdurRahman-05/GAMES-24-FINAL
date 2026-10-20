'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { ShieldCheck, Users, FileCheck2, Activity, Sparkles } from 'lucide-react';

interface NavbarProps {
  waitingCount?: number;
  verifiedCount?: number;
}

export default function Navbar({ waitingCount = 0, verifiedCount = 0 }: NavbarProps) {
  const pathname = usePathname();

  const navLinks = [
    {
      name: 'Registrations',
      href: '/',
      icon: FileCheck2,
      badge: waitingCount > 0 ? `${waitingCount} waiting` : undefined,
      badgeColor: 'bg-amber-500 text-white',
    },
    {
      name: 'Admins Directory',
      href: '/admins',
      icon: Users,
      badge: verifiedCount > 0 ? `${verifiedCount} verified` : undefined,
      badgeColor: 'bg-emerald-600 text-white',
    },
  ];

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
                  <span className="font-bold text-lg text-slate-900 tracking-tight">
                    Games<span className="text-emerald-600">24</span>
                  </span>
                  <span className="px-2 py-0.5 text-[10px] font-bold tracking-wider uppercase bg-emerald-100 text-emerald-800 rounded-md">
                    Super Admin
                  </span>
                </div>
                <p className="text-xs text-slate-500">Turf Owner Verification & Audit System</p>
              </div>
            </Link>
          </div>

          {/* Navigation Items */}
          <nav className="flex items-center gap-2">
            {navLinks.map((link) => {
              const Icon = link.icon;
              const isActive =
                link.href === '/' ? pathname === '/' : pathname.startsWith(link.href);
              return (
                <Link
                  key={link.name}
                  href={link.href}
                  className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-semibold transition-all ${
                    isActive
                      ? 'bg-emerald-50 text-emerald-700 border border-emerald-200/80 shadow-xs'
                      : 'text-slate-600 hover:text-slate-900 hover:bg-slate-100/80'
                  }`}
                >
                  <Icon className={`w-4 h-4 ${isActive ? 'text-emerald-600' : 'text-slate-400'}`} />
                  <span>{link.name}</span>
                  {link.badge && (
                    <span
                      className={`ml-1 text-[11px] font-bold px-2 py-0.5 rounded-full shadow-xs ${link.badgeColor}`}
                    >
                      {link.badge}
                    </span>
                  )}
                </Link>
              );
            })}
          </nav>

          {/* Server Live Status */}
          <div className="hidden sm:flex items-center gap-2 px-3 py-1.5 rounded-full bg-slate-100 border border-slate-200 text-xs font-medium text-slate-600">
            <span className="relative flex h-2 w-2">
              <span className="animate-ping absolute inline-flex h-full w-full rounded-full bg-emerald-400 opacity-75"></span>
              <span className="relative inline-flex rounded-full h-2 w-2 bg-emerald-500"></span>
            </span>
            <span>API Online (Port 3000)</span>
          </div>
        </div>
      </div>
    </header>
  );
}
