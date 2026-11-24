'use client';

import { useState, useEffect, useRef, useCallback } from 'react';
import {
  MapPin,
  Crosshair,
  Users,
  Phone,
  Trophy,
  ExternalLink,
  Sliders,
  X,
  Zap,
  Activity,
  ArrowRight,
  Shield,
  MessageSquare,
  Maximize2,
  Minimize2,
  Swords,
  CalendarDays,
  Clock,
  CheckCircle2,
  AlertCircle,
  Eye,
  Copy,
  Check,
  Building2,
  Share2,
  PhoneCall,
  Search,
} from 'lucide-react';
import {
  NearbyPlayer,
  NearbyPlayersResponse,
  NearbyTurfSummary,
  TurfOpenMatch,
  TurfSlotItem,
  getNearbyPlayers,
} from '@/lib/api';

type MapTileStyle = 'dark' | 'satellite' | 'street';

const TILE_CONFIGS: Record<MapTileStyle, { url: string; attribution: string; maxZoom: number }> = {
  dark: {
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
    attribution: '&copy; Esri &mdash; Esri, DeLorme, NAVTEQ',
    maxZoom: 16,
  },
  satellite: {
    url: 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}',
    attribution: '&copy; Esri, Maxar, Earthstar Geographics',
    maxZoom: 19,
  },
  street: {
    url: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '&copy; OpenStreetMap contributors',
    maxZoom: 19,
  },
};

export interface OutreachTarget {
  type: 'CHALLENGE' | 'SLOT';
  title: string;
  detail: string;
  sport: string;
  time: string;
  date?: string;
  rate?: number;
  challengerName?: string;
}

interface Props {
  turfId?: number;
  initialLat?: number;
  initialLng?: number;
  venueName?: string;
  streetAddress?: string;
  neighborhoodArea?: string;
  googleMapsUrl?: string;
  onClose?: () => void;
  isEmbedded?: boolean;
  isFullscreen?: boolean;
  onToggleFullscreen?: () => void;
  onSelectTurfId?: (turfId: number) => void;
  onOpenKycDetails?: (turfId: number) => void;
}

export default function TurfRadarMap({
  turfId,
  initialLat = 9.9252,
  initialLng = 78.1198,
  venueName = 'Selected Turf',
  streetAddress = 'Madurai, Tamil Nadu',
  neighborhoodArea = 'Madurai',
  googleMapsUrl,
  onClose,
  isEmbedded = false,
  isFullscreen = false,
  onToggleFullscreen,
  onSelectTurfId,
  onOpenKycDetails,
}: Props) {
  const [selectedTurfId, setSelectedTurfId] = useState<number | undefined>(turfId);
  const [radiusKm, setRadiusKm] = useState<number>(10);
  const [tileStyle, setTileStyle] = useState<MapTileStyle>('dark');
  const [localFullscreen, setLocalFullscreen] = useState<boolean>(false);
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<NearbyPlayersResponse | null>(null);
  const [selectedPlayer, setSelectedPlayer] = useState<NearbyPlayer | null>(null);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedSportFilter, setSelectedSportFilter] = useState<string>('ALL');
  const [outreachTarget, setOutreachTarget] = useState<OutreachTarget | null>(null);
  const [copiedPlayerId, setCopiedPlayerId] = useState<number | null>(null);

  const isFull = isFullscreen || localFullscreen;

  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<any>(null);
  const tileLayerRef = useRef<any>(null);
  const circleLayerRef = useRef<any>(null);
  const markersLayerRef = useRef<any>(null);

  // Sync prop changes
  useEffect(() => {
    if (turfId && turfId !== selectedTurfId) {
      setSelectedTurfId(turfId);
    }
  }, [turfId]);

  // Recalculate Leaflet map dimensions on resize or fullscreen
  const invalidateMapSize = useCallback(() => {
    if (mapInstanceRef.current) {
      mapInstanceRef.current.invalidateSize();
    }
  }, []);

  useEffect(() => {
    const timer = setTimeout(invalidateMapSize, 150);
    return () => clearTimeout(timer);
  }, [isFull, invalidateMapSize]);

  // ResizeObserver for dynamic display-size fitting
  useEffect(() => {
    if (!mapContainerRef.current) return;
    const observer = new ResizeObserver(() => {
      invalidateMapSize();
    });
    observer.observe(mapContainerRef.current);
    window.addEventListener('resize', invalidateMapSize);

    return () => {
      observer.disconnect();
      window.removeEventListener('resize', invalidateMapSize);
    };
  }, [invalidateMapSize]);

  // Load nearby real players & live turf operations for the selected turf
  const loadTurfData = useCallback((tId?: number, rKm: number = radiusKm) => {
    let isMounted = true;
    setLoading(true);
    setError(null);

    getNearbyPlayers({
      turfId: tId,
      radiusKm: rKm,
    })
      .then((res) => {
        if (!isMounted) return;
        setData(res);
        if (res.turf?.id && (!selectedTurfId || selectedTurfId !== res.turf.id)) {
          setSelectedTurfId(res.turf.id);
        }
        setLoading(false);
      })
      .catch((err) => {
        if (!isMounted) return;
        setError(err.message || 'Failed to load surrounding players');
        setLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [radiusKm, selectedTurfId]);

  useEffect(() => {
    const cleanup = loadTurfData(selectedTurfId, radiusKm);
    return cleanup;
  }, [selectedTurfId, radiusKm]);

  // Handle switching selected turf (e.g. clicking turf pin or dropdown)
  const handleSelectTurf = useCallback(
    (t: { id: number; latitude: number; longitude: number; venueName: string }) => {
      setSelectedTurfId(t.id);
      onSelectTurfId?.(t.id);
      setSelectedPlayer(null);

      if (mapInstanceRef.current) {
        mapInstanceRef.current.setView([t.latitude, t.longitude], radiusKm <= 5 ? 14 : radiusKm <= 15 ? 13 : 12, {
          animate: true,
          duration: 0.8,
        });
      }
    },
    [onSelectTurfId, radiusKm]
  );

  // Initialize and update Leaflet Map
  useEffect(() => {
    if (typeof window === 'undefined' || !mapContainerRef.current) return;

    let isCancelled = false;

    import('leaflet').then((L) => {
      if (isCancelled || !mapContainerRef.current) return;

      // Ensure Leaflet CSS is loaded in document head
      if (!document.getElementById('leaflet-css')) {
        const link = document.createElement('link');
        link.id = 'leaflet-css';
        link.rel = 'stylesheet';
        link.href = 'https://unpkg.com/leaflet@1.9.4/dist/leaflet.css';
        document.head.appendChild(link);
      }

      const activeLat = data?.turf?.latitude || initialLat;
      const activeLng = data?.turf?.longitude || initialLng;

      // Initialize map instance if not already created
      if (!mapInstanceRef.current) {
        const map = L.map(mapContainerRef.current, {
          center: [activeLat, activeLng],
          zoom: radiusKm <= 5 ? 14 : radiusKm <= 15 ? 13 : 12,
          zoomControl: false,
        });

        L.control.zoom({ position: 'bottomright' }).addTo(map);
        mapInstanceRef.current = map;
      }

      const map = mapInstanceRef.current;

      // Add/Swap clean keyless tile layer (Esri Dark, Satellite, OSM)
      if (tileLayerRef.current) {
        map.removeLayer(tileLayerRef.current);
      }
      const tileCfg = TILE_CONFIGS[tileStyle];
      tileLayerRef.current = L.tileLayer(tileCfg.url, {
        attribution: tileCfg.attribution,
        maxZoom: tileCfg.maxZoom,
      }).addTo(map);

      // Remove existing layers
      if (circleLayerRef.current) {
        map.removeLayer(circleLayerRef.current);
      }
      if (markersLayerRef.current) {
        map.removeLayer(markersLayerRef.current);
      }

      // Draw Radar Radius Circle on Active Selected Turf
      const circle = L.circle([activeLat, activeLng], {
        radius: radiusKm * 1000,
        color: '#D4FF00',
        weight: 2,
        dashArray: '6, 6',
        fillColor: '#D4FF00',
        fillOpacity: 0.07,
      }).addTo(map);
      circleLayerRef.current = circle;

      // Markers Layer Group
      const markersGroup = L.layerGroup().addTo(map);
      markersLayerRef.current = markersGroup;

      // =======================================================================
      // 1. PLOT ALL TURFS ON MAP (Selected has glowing neon pulse, others clickable)
      // =======================================================================
      const turfsToPlot = data?.allTurfs && data.allTurfs.length > 0
        ? data.allTurfs
        : data?.turf
        ? [
            {
              id: data.turf.id,
              venueName: data.turf.venueName,
              ownerName: data.turf.ownerName,
              ownerPhone: data.turf.ownerPhone,
              streetAddress: data.turf.streetAddress,
              neighborhoodArea: data.turf.neighborhoodArea,
              latitude: data.turf.latitude,
              longitude: data.turf.longitude,
              googleMapsUrl: data.turf.googleMapsUrl,
              openMatchesCount: data.openMatches?.length || 0,
              waitingChallengesCount: data.slotsOverview?.waitingOpponentCount || 0,
              isVerified: data.turf.isVerified ?? true,
            },
          ]
        : [];

      turfsToPlot.forEach((t) => {
        const isSelected = t.id === (data?.turf?.id || selectedTurfId);
        const waitingBadge =
          t.waitingChallengesCount > 0
            ? `<div style="
                position: absolute;
                top: -6px;
                right: -6px;
                background: #F59E0B;
                color: #000;
                font-size: 10px;
                font-weight: 900;
                border-radius: 9999px;
                padding: 1px 5px;
                box-shadow: 0 0 8px rgba(245, 158, 11, 0.9);
                border: 1px solid #000;
                display: flex;
                align-items: center;
                gap: 2px;
              ">⚡${t.waitingChallengesCount}</div>`
            : '';

        let turfIconHtml = '';

        if (isSelected) {
          turfIconHtml = `
            <div style="
              position: relative;
              width: 50px;
              height: 50px;
              display: flex;
              align-items: center;
              justify-content: center;
              cursor: pointer;
            ">
              <div style="
                position: absolute;
                width: 50px;
                height: 50px;
                background: rgba(212, 255, 0, 0.3);
                border-radius: 50%;
                animation: ping 2s cubic-bezier(0, 0, 0.2, 1) infinite;
              "></div>
              <div style="
                position: relative;
                width: 38px;
                height: 38px;
                background: #000000;
                border: 2.5px solid #D4FF00;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                box-shadow: 0 0 20px rgba(212, 255, 0, 0.9);
              ">
                <span style="font-size: 18px;">🏟️</span>
              </div>
              ${waitingBadge}
            </div>
          `;
        } else {
          turfIconHtml = `
            <div style="
              position: relative;
              width: 36px;
              height: 36px;
              display: flex;
              align-items: center;
              justify-content: center;
              cursor: pointer;
              transition: transform 0.2s;
            ">
              <div style="
                position: relative;
                width: 32px;
                height: 32px;
                background: #0F172A;
                border: 1.8px solid #38BDF8;
                border-radius: 50%;
                display: flex;
                align-items: center;
                justify-content: center;
                box-shadow: 0 4px 10px rgba(0, 0, 0, 0.7);
              ">
                <span style="font-size: 14px;">🏟️</span>
              </div>
              ${waitingBadge}
            </div>
          `;
        }

        const customIcon = L.divIcon({
          html: turfIconHtml,
          className: isSelected ? 'turf-marker-active' : 'turf-marker-idle',
          iconSize: isSelected ? [50, 50] : [36, 36],
          iconAnchor: isSelected ? [25, 25] : [18, 18],
        });

        const tMarker = L.marker([t.latitude, t.longitude], {
          icon: customIcon,
          zIndexOffset: isSelected ? 1000 : 500,
        }).addTo(markersGroup);

        // Tooltip showing venue name & neighborhood
        tMarker.bindTooltip(
          `<div style="font-family: monospace; font-size: 11px; font-weight: bold; color: ${
            isSelected ? '#D4FF00' : '#E2E8F0'
          };">
            ${t.venueName} ${isSelected ? '(SELECTED TARGET)' : '• Click to inspect slots & players'}
          </div>`,
          { direction: 'top', offset: [0, -18], className: 'custom-tooltip' }
        );

        tMarker.on('click', () => {
          handleSelectTurf(t);
        });
      });

      // =======================================================================
      // 2. PLOT SURROUNDING PLAYERS (Only real registered players from Player App)
      // =======================================================================
      if (data?.players) {
        data.players.forEach((player) => {
          const isSelected = selectedPlayer?.id === player.id;
          const sportEmoji =
            player.preferredSport?.toLowerCase().includes('cricket')
              ? '🏏'
              : player.preferredSport?.toLowerCase().includes('badminton')
              ? '🏸'
              : '⚽';

          const playerIconHtml = `
            <div style="
              width: ${isSelected ? '34px' : '28px'};
              height: ${isSelected ? '34px' : '28px'};
              background: ${isSelected ? '#D4FF00' : '#18181B'};
              border: ${isSelected ? '2.5px solid #000' : '1.8px solid #52525B'};
              border-radius: 50%;
              display: flex;
              align-items: center;
              justify-content: center;
              cursor: pointer;
              transition: transform 0.2s;
              box-shadow: ${isSelected ? '0 0 12px rgba(212, 255, 0, 0.8)' : '0 2px 8px rgba(0,0,0,0.6)'};
            ">
              <span style="font-size: ${isSelected ? '15px' : '12px'};">${sportEmoji}</span>
            </div>
          `;

          const playerCustomIcon = L.divIcon({
            html: playerIconHtml,
            className: 'player-marker-pin',
            iconSize: isSelected ? [34, 34] : [28, 28],
            iconAnchor: isSelected ? [17, 17] : [14, 14],
          });

          const pMarker = L.marker([player.latitude, player.longitude], {
            icon: playerCustomIcon,
            zIndexOffset: isSelected ? 800 : 200,
          }).addTo(markersGroup);

          pMarker.bindTooltip(
            `<div style="font-family: monospace; font-size: 11px;">
              <b>${player.fullName}</b> • ${player.distanceKm} km away<br/>
              <span style="color: #A1A1AA;">${player.preferredSport} • ${player.rank}</span>
            </div>`,
            { direction: 'top', offset: [0, -12] }
          );

          pMarker.on('click', () => {
            setSelectedPlayer(player);
          });
        });
      }
    });

    return () => {
      isCancelled = true;
    };
  }, [data, radiusKm, tileStyle, selectedPlayer, initialLat, initialLng, selectedTurfId, handleSelectTurf]);

  // Filter players for directory list
  const filteredPlayers = (data?.players || []).filter((p) => {
    const matchesSearch =
      p.fullName.toLowerCase().includes(searchQuery.toLowerCase()) ||
      p.mobileNumber.includes(searchQuery) ||
      p.rank.toLowerCase().includes(searchQuery.toLowerCase());
    const matchesSport =
      selectedSportFilter === 'ALL' ||
      p.preferredSport.toLowerCase() === selectedSportFilter.toLowerCase();
    return matchesSearch && matchesSport;
  });

  const activeLat = data?.turf?.latitude || initialLat;
  const activeLng = data?.turf?.longitude || initialLng;
  const activeVenueName = data?.turf?.venueName || venueName;
  const activeArea = data?.turf?.neighborhoodArea || neighborhoodArea;
  const finalMapUrl =
    googleMapsUrl ||
    data?.turf?.googleMapsUrl ||
    `https://www.google.com/maps?q=${activeLat},${activeLng}`;

  // Message builder for WhatsApp outreach based on active context
  const getOutreachMessage = (player: NearbyPlayer): string => {
    if (outreachTarget?.type === 'CHALLENGE') {
      return `Hello ${player.fullName}! We have an open match challenge at ${activeVenueName} (${activeArea}) for ${outreachTarget.sport} on ${outreachTarget.date || 'Today'} at ${outreachTarget.time}. Team '${outreachTarget.challengerName || 'Host'}' is looking for an opponent! Are you and your team available to play? Let us know to lock your spot!`;
    }
    if (outreachTarget?.type === 'SLOT') {
      return `Hello ${player.fullName}! We have a court slot available at ${activeVenueName} (${activeArea}) today from ${outreachTarget.time} for ${outreachTarget.sport} at ₹${outreachTarget.rate || 1200}. Would you like us to book this slot for you?`;
    }
    return `Hello ${player.fullName}! We noticed you're active around ${activeVenueName}. We have prime slots and open challenges available today for ${player.preferredSport}. Would you like to reserve a court or join a match?`;
  };

  const handleCopyPitch = (player: NearbyPlayer) => {
    const msg = getOutreachMessage(player);
    navigator.clipboard.writeText(msg);
    setCopiedPlayerId(player.id);
    setTimeout(() => setCopiedPlayerId(null), 2000);
  };

  const handleToggleFs = () => {
    if (onToggleFullscreen) {
      onToggleFullscreen();
    } else {
      setLocalFullscreen(!localFullscreen);
    }
  };

  return (
    <div
      className={`relative flex flex-col bg-[#0A0A0A] text-white border border-[#222B38] transition-all duration-300 ${
        isFull
          ? 'fixed inset-0 z-[99999] w-screen h-screen rounded-none m-0 p-0 shadow-none'
          : 'w-full h-full flex-1 rounded-xl overflow-hidden shadow-2xl min-h-0'
      }`}
    >
      {/* ========================================================================= */}
      {/* TOP COMPACT CONTROL BAR (Fits cleanly on any screen size) */}
      {/* ========================================================================= */}
      <div className="flex flex-wrap items-center justify-between px-3 sm:px-4 py-2 bg-[#0E131F] border-b border-[#1E273A] z-20 gap-2 shrink-0">
        {/* Left: Venue Switcher & Radar Indicator */}
        <div className="flex items-center gap-2.5 min-w-0">
          <div className="w-8 h-8 rounded-lg bg-[#1F2916] border border-[#D4FF00]/40 flex items-center justify-center text-[#D4FF00] shrink-0">
            <Crosshair className="w-4 h-4 animate-spin-slow" />
          </div>

          <div className="min-w-0">
            <div className="flex items-center gap-2 flex-wrap">
              {/* Turf Selector Dropdown */}
              {data?.allTurfs && data.allTurfs.length > 0 ? (
                <select
                  value={data?.turf?.id || selectedTurfId || ''}
                  onChange={(e) => {
                    const id = Number(e.target.value);
                    const found = data.allTurfs?.find((t) => t.id === id);
                    if (found) handleSelectTurf(found);
                  }}
                  className="px-2.5 py-1 bg-[#05080E] border border-[#28354F] rounded-lg text-xs font-bold text-white focus:outline-hidden focus:border-[#D4FF00] max-w-[220px] sm:max-w-[280px] font-mono cursor-pointer"
                >
                  {data.allTurfs.map((t) => (
                    <option key={t.id} value={t.id}>
                      {t.venueName} ({t.neighborhoodArea || 'Madurai'}) {t.waitingChallengesCount > 0 ? `⚡ ${t.waitingChallengesCount} challenges` : ''}
                    </option>
                  ))}
                </select>
              ) : (
                <span className="text-xs sm:text-sm font-black text-white font-mono truncate">
                  {activeVenueName}
                </span>
              )}

              <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-[#1F2916] text-[#D4FF00] border border-[#D4FF00]/30 font-mono shrink-0">
                RADAR LIVE
              </span>

              {isFull && (
                <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30 font-mono shrink-0">
                  FULLSCREEN
                </span>
              )}
            </div>

            <p className="text-[11px] text-slate-400 truncate font-mono mt-0.5">
              {activeArea} • <span className="text-[#D4FF00]">{activeLat.toFixed(4)}° N, {activeLng.toFixed(4)}° E</span>
              {data?.turf?.ownerPhone && (
                <span className="text-slate-400"> • Owner: {data.turf.ownerPhone}</span>
              )}
            </p>
          </div>
        </div>

        {/* Right: Quick Actions */}
        <div className="flex items-center gap-1.5 sm:gap-2">
          {onOpenKycDetails && data?.turf?.id && (
            <button
              type="button"
              onClick={() => onOpenKycDetails(data.turf.id)}
              className="px-2.5 py-1.5 rounded-lg bg-[#161D2E] hover:bg-[#1E273A] border border-[#28354F] text-[11px] font-bold text-slate-200 flex items-center gap-1 font-mono transition-colors"
              title="View KYC Verification Details"
            >
              <Shield className="w-3.5 h-3.5 text-[#D4FF00]" />
              <span className="hidden sm:inline">KYC</span>
            </button>
          )}

          <a
            href={finalMapUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="px-2.5 py-1.5 rounded-lg bg-[#161D2E] hover:bg-[#1E273A] border border-[#28354F] text-[11px] font-bold text-slate-200 flex items-center gap-1 font-mono transition-colors"
            title="Open in Google Maps"
          >
            <MapPin className="w-3.5 h-3.5 text-[#D4FF00]" />
            <span className="hidden md:inline">Google Maps</span>
            <ExternalLink className="w-3 h-3 text-slate-400" />
          </a>

          {/* Fullscreen Toggle Button */}
          <button
            type="button"
            onClick={handleToggleFs}
            className={`px-3 py-1.5 rounded-lg border text-xs font-bold font-mono flex items-center gap-1.5 transition-all shadow-sm ${
              isFull
                ? 'bg-rose-500/20 text-rose-300 border-rose-500/40 hover:bg-rose-500/30'
                : 'bg-[#161D2E] hover:bg-[#1E273A] border-[#28354F] text-slate-200 hover:text-white'
            }`}
            title={isFull ? 'Exit Fullscreen (Esc)' : 'Expand to Full Window'}
          >
            {isFull ? (
              <>
                <Minimize2 className="w-3.5 h-3.5 text-rose-400" />
                <span>Exit Fullscreen</span>
              </>
            ) : (
              <>
                <Maximize2 className="w-3.5 h-3.5 text-[#D4FF00]" />
                <span>Fullscreen</span>
              </>
            )}
          </button>

          {onClose && (
            <button
              onClick={onClose}
              className="w-7 h-7 rounded-lg bg-[#161D2E] hover:bg-slate-800 border border-[#28354F] flex items-center justify-center text-slate-400 hover:text-white"
            >
              <X className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>

      {/* ========================================================================= */}
      {/* MAIN ADAPTIVE BODY (Left: Leaflet Radar Map, Right: Turf Details, Slots & Players) */}
      {/* ========================================================================= */}
      <div className="flex-1 flex flex-col lg:flex-row relative overflow-hidden min-h-0">
        {/* LEFT: LEAFLET RADAR MAP CANVAS */}
        <div className="flex-1 relative flex flex-col min-h-0 min-w-0">
          {/* Floating Radar Range & Basemap Controls */}
          <div className="absolute top-3 left-3 z-[500] flex flex-wrap items-center gap-1.5 bg-[#0A0E17]/90 backdrop-blur-md p-1.5 rounded-xl border border-[#1E273A] shadow-2xl">
            <div className="flex items-center gap-1 px-1.5 text-[11px] font-mono font-bold text-slate-300">
              <Sliders className="w-3 h-3 text-[#D4FF00]" />
              <span>Range:</span>
            </div>
            {[2, 5, 10, 15, 25, 50].map((km) => (
              <button
                key={km}
                type="button"
                onClick={() => setRadiusKm(km)}
                className={`px-2 py-0.5 rounded-md text-[11px] font-mono font-bold transition-all ${
                  radiusKm === km
                    ? 'bg-[#D4FF00] text-black shadow-md shadow-[#D4FF00]/30'
                    : 'bg-[#141A28] text-slate-400 hover:text-white hover:bg-[#1E273A]'
                }`}
              >
                {km} km
              </button>
            ))}

            <div className="h-4 w-[1px] bg-[#1E273A] mx-1 hidden sm:block" />

            {/* Tile Style Switcher */}
            <div className="flex items-center gap-0.5 bg-[#141A28] p-0.5 rounded-lg border border-[#1E273A]">
              <button
                type="button"
                onClick={() => setTileStyle('dark')}
                className={`px-1.5 py-0.5 rounded text-[10px] font-mono font-semibold transition-all ${
                  tileStyle === 'dark' ? 'bg-[#D4FF00] text-black font-bold' : 'text-slate-400 hover:text-white'
                }`}
              >
                🌙 Dark
              </button>
              <button
                type="button"
                onClick={() => setTileStyle('satellite')}
                className={`px-1.5 py-0.5 rounded text-[10px] font-mono font-semibold transition-all ${
                  tileStyle === 'satellite' ? 'bg-[#D4FF00] text-black font-bold' : 'text-slate-400 hover:text-white'
                }`}
              >
                🛰️ Sat
              </button>
              <button
                type="button"
                onClick={() => setTileStyle('street')}
                className={`px-1.5 py-0.5 rounded text-[10px] font-mono font-semibold transition-all ${
                  tileStyle === 'street' ? 'bg-[#D4FF00] text-black font-bold' : 'text-slate-400 hover:text-white'
                }`}
              >
                🗺️ Streets
              </button>
            </div>

            <div className="h-4 w-[1px] bg-[#1E273A] mx-1 hidden sm:block" />

            <div className="flex items-center gap-1 px-2 py-0.5 rounded-md bg-[#1F2916] border border-[#D4FF00]/30 text-[#D4FF00] text-[10px] font-mono font-bold">
              <Zap className="w-3 h-3" />
              <span>
                {loading ? 'Scanning...' : `${data?.totalPlayersFound || 0} Surrounding Athletes`}
              </span>
            </div>
          </div>

          {/* Leaflet Map Div */}
          <div ref={mapContainerRef} className="w-full h-full flex-1 min-h-[350px] bg-[#0A0A0A]" />

          {/* Map Legend Overlay */}
          <div className="absolute bottom-3 left-3 z-[500] bg-[#0A0E17]/90 backdrop-blur-md px-3 py-1.5 rounded-lg border border-[#1E273A] flex items-center gap-3 text-[10px] font-mono text-slate-300">
            <div className="flex items-center gap-1.5">
              <span className="text-sm">🏟️</span>
              <span className="text-white font-bold">Turfs ({data?.allTurfs?.length || 1})</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-2.5 h-2.5 rounded-full bg-[#D4FF00] border border-black inline-block" />
              <span>Radius ({radiusKm} km)</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span>⚽ 🏏 🏸</span>
              <span>Athletes ({data?.players?.length || 0})</span>
            </div>
          </div>
        </div>

        {/* ========================================================================= */}
        {/* RIGHT: TURF DETAILS, SLOTS & SURROUNDING PLAYERS (EXACTLY AS REQUESTED) */}
        {/* ========================================================================= */}
        <div className="w-full lg:w-[450px] xl:w-[480px] bg-[#0A0E17] border-t lg:border-t-0 lg:border-l border-[#1E273A] flex flex-col z-10 min-h-0">
          {/* 1. TURF DETAILS */}
          <div className="p-3 bg-[#0E131F] border-b border-[#1E273A] shrink-0">
            <div className="flex items-start justify-between gap-2">
              <div className="min-w-0">
                <div className="flex items-center gap-1.5">
                  <span className="text-base">🏟️</span>
                  <h3 className="text-sm font-black text-white font-mono truncate">
                    {activeVenueName}
                  </h3>
                  <span className="px-1.5 py-0.2 rounded text-[9.5px] font-bold bg-[#1F2916] text-[#D4FF00] border border-[#D4FF00]/30 font-mono">
                    ACTIVE TURF
                  </span>
                </div>
                <p className="text-[11px] text-slate-400 font-mono mt-0.5 truncate">
                  {data?.turf?.streetAddress || streetAddress}
                </p>
                {data?.turf?.ownerPhone && (
                  <div className="flex items-center gap-2 mt-1 font-mono text-[11px]">
                    <span className="text-slate-400">Owner: <strong className="text-slate-200">{data.turf.ownerName}</strong></span>
                    <a
                      href={`tel:${data.turf.ownerPhone}`}
                      className="flex items-center gap-1 text-[#D4FF00] hover:underline font-bold"
                    >
                      <Phone className="w-3 h-3" />
                      <span>{data.turf.ownerPhone}</span>
                    </a>
                  </div>
                )}
              </div>

              {/* Slot Counts Pill */}
              <div className="text-right shrink-0 font-mono text-[10px]">
                <span className="px-2 py-0.5 rounded font-bold bg-emerald-500/15 text-emerald-300 border border-emerald-500/30 block mb-1">
                  {data?.slotsOverview?.availableCount ?? 16} Available
                </span>
                <span className="px-2 py-0.5 rounded font-bold bg-rose-500/15 text-rose-300 border border-rose-500/30 block">
                  {data?.slotsOverview?.bookedCount ?? 0} Booked
                </span>
              </div>
            </div>
          </div>

          {/* 2. UPCOMING OPEN CHALLENGES & TODAY'S COURT SLOTS */}
          <div className="p-2.5 bg-[#0A0E17] border-b border-[#1E273A] shrink-0 space-y-2.5">
            {/* Upcoming Challenges Header */}
            <div className="flex items-center justify-between font-mono text-xs">
              <span className="font-bold text-white flex items-center gap-1.5">
                <Zap className="w-3.5 h-3.5 text-amber-400" />
                <span>Upcoming Open Challenges</span>
                {data?.openMatches && data.openMatches.length > 0 && (
                  <span className="px-1.5 py-0.2 rounded text-[9.5px] font-black bg-amber-500/20 text-amber-300 border border-amber-500/40 font-mono">
                    {data.openMatches.length}
                  </span>
                )}
              </span>
              <span className="text-[10px] text-slate-400 font-mono">
                {data?.openMatches && data.openMatches.length > 0 ? 'Recruit opponents below' : 'None active'}
              </span>
            </div>

            {/* Open Matches Cards (Only upcoming matches) */}
            {data?.openMatches && data.openMatches.length > 0 ? (
              <div className="space-y-1.5 max-h-36 overflow-y-auto pr-0.5 custom-scrollbar">
                {data.openMatches.map((m) => {
                  const isWaiting = m.status === 'WAITING_FOR_OPPONENT';
                  return (
                    <div
                      key={m.id}
                      className={`p-2 rounded-lg border text-xs font-mono flex items-center justify-between gap-2 ${
                        isWaiting ? 'bg-amber-500/10 border-amber-500/40 text-amber-200' : 'bg-[#0E131F] border-[#1E273A]'
                      }`}
                    >
                      <div className="min-w-0">
                        <div className="flex items-center gap-1.5 flex-wrap">
                          <span className="text-[10px] font-bold text-[#D4FF00]">⚡ {m.sport} ({m.teamSize})</span>
                          <span className="text-[9.5px] px-1.5 py-0.2 rounded bg-[#1A2333] text-sky-300 font-bold font-mono">
                            {m.date}
                          </span>
                          <span className="text-[10px] text-slate-400">{m.time}</span>
                        </div>
                        <p className="text-[11px] text-white font-bold truncate mt-0.5">
                          {m.challengerName} vs{' '}
                          <span className={isWaiting ? 'text-amber-400 italic' : 'text-emerald-400'}>
                            {isWaiting ? 'Waiting Opponent' : m.opponentName}
                          </span>
                        </p>
                      </div>

                      {isWaiting && (
                        <button
                          type="button"
                          onClick={() => {
                            setOutreachTarget({
                              type: 'CHALLENGE',
                              title: `Challenge: ${m.sport}`,
                              detail: `${m.date} (${m.time}) vs ${m.challengerName}`,
                              sport: m.sport,
                              time: m.time,
                              date: m.date,
                              challengerName: m.challengerName,
                            });
                          }}
                          className="px-2 py-1 rounded bg-[#1F2916] text-[#D4FF00] border border-[#D4FF00]/40 text-[10px] font-bold shrink-0 hover:bg-[#2b3a1e] transition-colors"
                        >
                          Target Players Below
                        </button>
                      )}
                    </div>
                  );
                })}
              </div>
            ) : (
              <div className="py-2 px-3 rounded-lg border border-dashed border-[#1E273A] bg-[#0E131F]/50 text-center font-mono text-[10.5px] text-slate-400">
                No upcoming open challenges for this venue.
              </div>
            )}

            {/* Today's Court Slots Header */}
            <div className="flex items-center justify-between font-mono text-xs pt-1 border-t border-[#1E273A]/60">
              <span className="font-bold text-white flex items-center gap-1.5">
                <Clock className="w-3.5 h-3.5 text-[#D4FF00]" />
                <span>Today&apos;s Court Slots</span>
              </span>
              <span className="text-[10px] text-slate-400 font-mono">
                {data?.slotsOverview?.availableCount ?? 16} Available • 16 Standard Hours
              </span>
            </div>

            {/* Hourly Operating Slots Grid (4 columns) */}
            <div className="grid grid-cols-4 gap-1 font-mono text-[9.5px]">
              {data?.slotsOverview?.slots?.map((slot, idx) => {
                const isBooked = slot.status === 'BOOKED';
                const isOpenMatch = slot.status === 'OPEN_MATCH';
                const isSelected = outreachTarget?.type === 'SLOT' && outreachTarget.time === slot.timeSlot;

                return (
                  <div
                    key={idx}
                    onClick={() => {
                      if (!isBooked) {
                        setOutreachTarget({
                          type: 'SLOT',
                          title: `Slot: ${slot.timeSlot.split(' - ')[0]}`,
                          detail: `₹${slot.rate} • ${slot.sport || 'Court'}`,
                          sport: slot.sport || 'Football',
                          time: slot.timeSlot,
                          rate: slot.rate,
                        });
                      }
                    }}
                    className={`p-1.5 rounded border text-center transition-all cursor-pointer ${
                      isSelected
                        ? 'bg-[#D4FF00] text-black border-[#D4FF00] font-black shadow-sm'
                        : isOpenMatch
                        ? 'bg-[#1C2014] border-[#D4FF00]/50 text-[#D4FF00]'
                        : isBooked
                        ? 'bg-[#1F1214] border-rose-500/30 text-rose-400'
                        : 'bg-[#0E131F] border-[#1E273A] text-emerald-400 hover:border-emerald-400'
                    }`}
                    title={`${slot.timeSlot}: ${slot.status} (Click to target players below)`}
                  >
                    <span className={`block text-[8.5px] truncate ${isSelected ? 'text-black font-bold' : 'text-slate-400'}`}>
                      {slot.timeSlot.split(' - ')[0]}
                    </span>
                    <span className="font-bold block truncate">
                      {isOpenMatch ? '⚡Match' : isBooked ? 'Booked' : '₹' + slot.rate}
                    </span>
                  </div>
                );
              })}
            </div>
          </div>

          {/* Active Outreach Context Banner (If Admin selected an Open Match or Court Slot to fill) */}
          {outreachTarget && (
            <div className="p-2 bg-[#1F2916] border-b border-[#D4FF00]/40 flex items-center justify-between gap-2 shrink-0 animate-in fade-in duration-150">
              <div className="flex items-center gap-2 min-w-0 font-mono text-xs">
                <Zap className="w-3.5 h-3.5 text-[#D4FF00] shrink-0" />
                <span className="text-white truncate">
                  Targeting: <strong className="text-[#D4FF00]">{outreachTarget.title}</strong> ({outreachTarget.detail})
                </span>
              </div>
              <button
                type="button"
                onClick={() => setOutreachTarget(null)}
                className="text-slate-400 hover:text-white shrink-0 p-1"
                title="Clear target"
              >
                <X className="w-3 h-3" />
              </button>
            </div>
          )}

          {/* 3. SURROUNDING ATHLETES DIRECTORY */}
          <div className="flex-1 flex flex-col overflow-hidden min-h-0">
            {/* Selected Player Profile Popup Card (If clicked) */}
            {selectedPlayer && (
              <div className="p-3 bg-[#121622] border-b border-[#28354F] relative shrink-0">
                <button
                  onClick={() => setSelectedPlayer(null)}
                  className="absolute top-2.5 right-2.5 text-slate-400 hover:text-white"
                >
                  <X className="w-4 h-4" />
                </button>

                <div className="flex items-center gap-3 mb-2.5">
                  <div className="w-10 h-10 rounded-full bg-[#1F2916] border-2 border-[#D4FF00] flex items-center justify-center font-black text-sm text-[#D4FF00] shrink-0 font-mono">
                    {selectedPlayer.fullName.substring(0, 2).toUpperCase()}
                  </div>
                  <div className="min-w-0">
                    <h3 className="text-xs font-black text-white flex items-center gap-1.5 truncate">
                      <span>{selectedPlayer.fullName}</span>
                      <span className="text-xs">
                        {selectedPlayer.preferredSport === 'Cricket'
                          ? '🏏'
                          : selectedPlayer.preferredSport === 'Badminton'
                          ? '🏸'
                          : '⚽'}
                      </span>
                    </h3>
                    <div className="flex items-center gap-2 mt-0.5 font-mono text-[10px]">
                      <span className="px-1.5 py-0.2 rounded bg-slate-800 text-slate-300 font-bold">
                        {selectedPlayer.rank}
                      </span>
                      <span className="text-[#D4FF00] font-bold">
                        {selectedPlayer.distanceKm} km from turf
                      </span>
                    </div>
                  </div>
                </div>

                {/* Player Details Grid */}
                <div className="grid grid-cols-2 gap-2 text-xs bg-[#0A0E17] p-2 rounded-lg mb-2.5 border border-[#1E273A] font-mono text-[10px]">
                  <div>
                    <span className="text-slate-500 uppercase block">Contact Phone</span>
                    <span className="font-bold text-white">{selectedPlayer.mobileNumber}</span>
                  </div>
                  <div>
                    <span className="text-slate-500 uppercase block">Matches Played</span>
                    <span className="font-bold text-[#D4FF00]">{selectedPlayer.matchesPlayed} Matches</span>
                  </div>
                </div>

                {/* DIRECT ACTIONS: CALL & WHATSAPP INVITE */}
                <div className="flex items-center gap-2">
                  <a
                    href={`tel:${selectedPlayer.mobileNumber}`}
                    className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg bg-[#D4FF00] hover:bg-[#bce400] text-black font-black text-xs font-mono transition-colors shadow-md shadow-[#D4FF00]/20"
                  >
                    <PhoneCall className="w-3.5 h-3.5" />
                    <span>Call Athlete Now</span>
                  </a>

                  <a
                    href={`https://wa.me/${selectedPlayer.mobileNumber.replace(/\D/g, '')}?text=${encodeURIComponent(
                      getOutreachMessage(selectedPlayer)
                    )}`}
                    target="_blank"
                    rel="noopener noreferrer"
                    className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg bg-[#161D2E] hover:bg-[#1E273A] border border-emerald-500/40 text-emerald-400 font-bold text-xs font-mono transition-colors"
                  >
                    <MessageSquare className="w-3.5 h-3.5 text-emerald-400" />
                    <span>WhatsApp Invite</span>
                  </a>

                  <button
                    type="button"
                    onClick={() => handleCopyPitch(selectedPlayer)}
                    className="px-2.5 py-2 rounded-lg bg-[#161D2E] hover:bg-[#1E273A] border border-[#28354F] text-slate-300 hover:text-white"
                    title="Copy outreach text"
                  >
                    {copiedPlayerId === selectedPlayer.id ? (
                      <Check className="w-3.5 h-3.5 text-emerald-400" />
                    ) : (
                      <Copy className="w-3.5 h-3.5" />
                    )}
                  </button>
                </div>
              </div>
            )}

            {/* Header with Athlete Count & Filter */}
            <div className="p-2.5 border-b border-[#1E273A] bg-[#0A0E17] flex flex-col gap-2 shrink-0">
              <div className="flex items-center justify-between text-xs font-mono">
                <span className="font-bold text-white flex items-center gap-1.5">
                  <Users className="w-3.5 h-3.5 text-[#D4FF00]" />
                  <span>Surrounding Players Around Turf ({filteredPlayers.length})</span>
                </span>
                <span className="text-[10px] text-slate-400 font-mono">Within {radiusKm} km</span>
              </div>

              <div className="flex items-center gap-2">
                <div className="relative flex-1">
                  <Search className="w-3.5 h-3.5 text-slate-500 absolute left-2.5 top-2.5" />
                  <input
                    type="text"
                    placeholder="Search player name, phone, or rank..."
                    value={searchQuery}
                    onFocus={(e) => e.stopPropagation()}
                    onChange={(e) => setSearchQuery(e.target.value)}
                    className="w-full pl-8 pr-3 py-1.5 bg-[#0E131F] border border-[#1E273A] rounded-lg text-xs text-white placeholder-slate-500 focus:outline-hidden focus:border-[#D4FF00] font-mono"
                  />
                </div>

                {/* Sport Filter Chips */}
                <div className="flex items-center gap-1 font-mono shrink-0">
                  {['ALL', 'Football', 'Cricket'].map((sp) => (
                    <button
                      key={sp}
                      type="button"
                      onClick={() => setSelectedSportFilter(sp)}
                      className={`px-2 py-1 rounded text-[10px] font-bold whitespace-nowrap transition-colors ${
                        selectedSportFilter === sp
                          ? 'bg-[#1F2916] text-[#D4FF00] border border-[#D4FF00]/40'
                          : 'bg-[#0E131F] text-slate-400 hover:text-white border border-[#1E273A]'
                      }`}
                    >
                      {sp}
                    </button>
                  ))}
                </div>
              </div>
            </div>

            {/* Scrollable Player Cards List */}
            <div className="flex-1 overflow-y-auto p-2 space-y-2">
              {loading ? (
                <div className="flex flex-col items-center justify-center h-48 text-slate-400 text-xs gap-2 font-mono">
                  <Activity className="w-5 h-5 animate-spin text-[#D4FF00]" />
                  <span>Scanning registered athletes within {radiusKm} km...</span>
                </div>
              ) : filteredPlayers.length === 0 ? (
                <div className="flex flex-col items-center justify-center h-48 text-slate-400 text-xs gap-2 p-4 text-center font-mono">
                  <Users className="w-8 h-8 opacity-40 text-slate-500" />
                  <p className="font-semibold text-slate-300">
                    No athletes found within {radiusKm} km radius of {activeVenueName}.
                  </p>
                  <p className="text-[11px] text-slate-500">
                    Click another turf pin on the map or expand the radar range slider.
                  </p>
                  <button
                    type="button"
                    onClick={() => setRadiusKm((prev) => Math.min(50, prev + 15))}
                    className="mt-1 px-3 py-1 bg-[#141A28] hover:bg-[#1E273A] border border-[#28354F] rounded-lg text-[#D4FF00] font-bold text-xs"
                  >
                    Expand range to {Math.min(50, radiusKm + 15)} km
                  </button>
                </div>
              ) : (
                filteredPlayers.map((player) => {
                  const isSelected = selectedPlayer?.id === player.id;
                  return (
                    <div
                      key={player.id}
                      className={`p-2.5 rounded-xl border transition-all ${
                        isSelected
                          ? 'bg-[#1F2916] border-[#D4FF00]/60 shadow-md shadow-[#D4FF00]/10'
                          : 'bg-[#0E131F] border-[#1E273A] hover:border-[#2C3B5C]'
                      }`}
                    >
                      <div
                        onClick={() => {
                          setSelectedPlayer(player);
                          if (mapInstanceRef.current) {
                            mapInstanceRef.current.panTo([player.latitude, player.longitude]);
                          }
                        }}
                        className="flex items-center justify-between cursor-pointer"
                      >
                        <div className="flex items-center gap-2.5 min-w-0">
                          <div className="w-8 h-8 rounded-full bg-[#182014] border border-[#D4FF00]/40 flex items-center justify-center font-bold text-xs text-[#D4FF00] shrink-0 font-mono">
                            {player.fullName.substring(0, 2).toUpperCase()}
                          </div>
                          <div className="truncate">
                            <p className="text-xs font-bold text-white truncate flex items-center gap-1">
                              {player.fullName}
                              <span className="text-[10px]">
                                {player.preferredSport === 'Cricket'
                                  ? '🏏'
                                  : player.preferredSport === 'Badminton'
                                  ? '🏸'
                                  : '⚽'}
                              </span>
                            </p>
                            <p className="text-[10px] text-slate-400 truncate font-mono">
                              {player.mobileNumber} • {player.rank}
                            </p>
                          </div>
                        </div>

                        <div className="text-right shrink-0 font-mono">
                          <span className="text-xs font-black text-[#D4FF00] block">
                            {player.distanceKm} km
                          </span>
                          <span className="text-[9.5px] text-slate-500">
                            {player.city}
                          </span>
                        </div>
                      </div>

                      {/* Direct Action Quick Buttons */}
                      <div className="flex items-center gap-1.5 mt-2 pt-2 border-t border-[#161D2E] font-mono">
                        <a
                          href={`tel:${player.mobileNumber}`}
                          className="flex-1 flex items-center justify-center gap-1 py-1 rounded bg-[#161D2E] hover:bg-[#1E273A] text-white border border-[#28354F] text-[10px] font-bold transition-colors"
                        >
                          <Phone className="w-3 h-3 text-[#D4FF00]" />
                          <span>Call</span>
                        </a>

                        <a
                          href={`https://wa.me/${player.mobileNumber.replace(/\D/g, '')}?text=${encodeURIComponent(
                            getOutreachMessage(player)
                          )}`}
                          target="_blank"
                          rel="noopener noreferrer"
                          className="flex-1 flex items-center justify-center gap-1 py-1 rounded bg-[#161D2E] hover:bg-emerald-500/20 text-emerald-300 border border-emerald-500/30 text-[10px] font-bold transition-colors"
                        >
                          <MessageSquare className="w-3 h-3 text-emerald-400" />
                          <span>WhatsApp</span>
                        </a>

                        <button
                          type="button"
                          onClick={() => handleCopyPitch(player)}
                          className="px-2 py-1 rounded bg-[#161D2E] hover:bg-[#1E273A] border border-[#28354F] text-slate-300 text-[10px]"
                          title="Copy invitation pitch"
                        >
                          {copiedPlayerId === player.id ? (
                            <Check className="w-3 h-3 text-emerald-400" />
                          ) : (
                            <Copy className="w-3 h-3" />
                          )}
                        </button>
                      </div>
                    </div>
                  );
                })
              )}
            </div>
          </div>

          {/* Footer Stats Bar */}
          <div className="p-2.5 bg-[#080B11] border-t border-[#1E273A] flex items-center justify-between text-[11px] text-slate-400 font-mono shrink-0">
            <span>
              Target: <strong className="text-white">{activeVenueName}</strong>
            </span>
            <span className="text-[#D4FF00] font-bold">
              {data?.totalPlayersFound || 0} Athletes in {radiusKm} km
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
