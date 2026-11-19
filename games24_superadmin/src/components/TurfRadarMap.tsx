'use client';

import { useState, useEffect, useRef } from 'react';
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
} from 'lucide-react';
import {
  NearbyPlayer,
  NearbyPlayersResponse,
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
}: Props) {
  const [radiusKm, setRadiusKm] = useState<number>(10);
  const [tileStyle, setTileStyle] = useState<MapTileStyle>('dark');
  const [isFullscreen, setIsFullscreen] = useState<boolean>(false);
  const [activeSideTab, setActiveSideTab] = useState<'PLAYERS' | 'SLOTS_MATCHES'>('PLAYERS');
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<NearbyPlayersResponse | null>(null);
  const [selectedPlayer, setSelectedPlayer] = useState<NearbyPlayer | null>(null);
  const [selectedMatch, setSelectedMatch] = useState<TurfOpenMatch | null>(null);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedSportFilter, setSelectedSportFilter] = useState<string>('ALL');

  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<any>(null);
  const tileLayerRef = useRef<any>(null);
  const circleLayerRef = useRef<any>(null);
  const markersLayerRef = useRef<any>(null);

  // Keyboard shortcut: ESC to exit fullscreen
  useEffect(() => {
    const handleKeyDown = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && isFullscreen) {
        setIsFullscreen(false);
      }
    };
    window.addEventListener('keydown', handleKeyDown);
    return () => window.removeEventListener('keydown', handleKeyDown);
  }, [isFullscreen]);

  // Recalculate Leaflet map dimensions on fullscreen toggle
  useEffect(() => {
    const timer = setTimeout(() => {
      mapInstanceRef.current?.invalidateSize();
    }, 200);
    return () => clearTimeout(timer);
  }, [isFullscreen]);

  // Load nearby real players & live turf operations from API
  useEffect(() => {
    let isMounted = true;
    setLoading(true);
    setError(null);

    getNearbyPlayers({
      turfId,
      lat: initialLat,
      lng: initialLng,
      radiusKm,
    })
      .then((res) => {
        if (!isMounted) return;
        setData(res);
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
  }, [turfId, initialLat, initialLng, radiusKm]);

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

      const turfLat = data?.turf?.latitude || initialLat;
      const turfLng = data?.turf?.longitude || initialLng;

      // Initialize map instance if not already created
      if (!mapInstanceRef.current) {
        const map = L.map(mapContainerRef.current, {
          center: [turfLat, turfLng],
          zoom: radiusKm <= 5 ? 14 : radiusKm <= 15 ? 12 : 11,
          zoomControl: false,
        });

        L.control.zoom({ position: 'bottomright' }).addTo(map);

        mapInstanceRef.current = map;
      }

      const map = mapInstanceRef.current;
      map.setView([turfLat, turfLng]);

      // Add/Swap clean keyless tile layer (Zero API key / zero watermark)
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

      // Draw Radius Circle
      const circle = L.circle([turfLat, turfLng], {
        radius: radiusKm * 1000,
        color: '#D4FF00',
        weight: 1.8,
        dashArray: '6, 6',
        fillColor: '#D4FF00',
        fillOpacity: 0.08,
      }).addTo(map);
      circleLayerRef.current = circle;

      // Markers Layer Group
      const markersGroup = L.layerGroup().addTo(map);
      markersLayerRef.current = markersGroup;

      // 1. Turf Stadium Pin
      const turfIconHtml = `
        <div style="
          position: relative;
          width: 44px;
          height: 44px;
          display: flex;
          align-items: center;
          justify-content: center;
          cursor: pointer;
        ">
          <div style="
            position: absolute;
            width: 44px;
            height: 44px;
            background: rgba(212, 255, 0, 0.25);
            border-radius: 50%;
            animation: ping 2s cubic-bezier(0, 0, 0.2, 1) infinite;
          "></div>
          <div style="
            position: relative;
            width: 36px;
            height: 36px;
            background: #000;
            border: 2px solid #D4FF00;
            border-radius: 50%;
            display: flex;
            align-items: center;
            justify-content: center;
            box-shadow: 0 0 15px rgba(212, 255, 0, 0.8);
          ">
            <span style="font-size: 16px;">🏟️</span>
          </div>
        </div>
      `;

      const turfCustomIcon = L.divIcon({
        html: turfIconHtml,
        className: 'turf-marker-pin',
        iconSize: [44, 44],
        iconAnchor: [22, 22],
      });

      const turfMarker = L.marker([turfLat, turfLng], { icon: turfCustomIcon })
        .addTo(markersGroup)
        .bindPopup(
          `<div style="font-family: sans-serif; padding: 6px; color: #fff; background: #141414; min-width: 170px;">
            <b style="color: #D4FF00; font-size: 13px;">${venueName}</b><br/>
            <span style="color: #A1A1AA; font-size: 11px;">${neighborhoodArea}</span><br/>
            <span style="color: #71717A; font-size: 10px;">${turfLat.toFixed(4)}° N, ${turfLng.toFixed(4)}° E</span><br/>
            <div style="margin-top: 6px; padding: 4px; background: #1F2916; border: 1px solid rgba(212,255,0,0.3); border-radius: 4px; font-size: 10px; color: #D4FF00; font-weight: bold; text-align: center;">
              ⚡ Click to View Live Matches & Slots
            </div>
          </div>`,
          { className: 'custom-dark-popup' }
        );

      turfMarker.on('click', () => {
        setActiveSideTab('SLOTS_MATCHES');
      });

      // 2. Real Player Pins (from Player App only)
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
              width: ${isSelected ? '32px' : '26px'};
              height: ${isSelected ? '32px' : '26px'};
              background: ${isSelected ? '#D4FF00' : '#18181B'};
              border: 1.8px solid ${isSelected ? '#000' : '#3F3F46'};
              border-radius: 50%;
              display: flex;
              align-items: center;
              justify-content: center;
              cursor: pointer;
              transition: transform 0.2s;
              box-shadow: 0 2px 8px rgba(0,0,0,0.6);
            ">
              <span style="font-size: ${isSelected ? '14px' : '11px'};">${sportEmoji}</span>
            </div>
          `;

          const playerCustomIcon = L.divIcon({
            html: playerIconHtml,
            className: 'player-marker-pin',
            iconSize: isSelected ? [32, 32] : [26, 26],
            iconAnchor: isSelected ? [16, 16] : [13, 13],
          });

          const pMarker = L.marker([player.latitude, player.longitude], {
            icon: playerCustomIcon,
          }).addTo(markersGroup);

          pMarker.on('click', () => {
            setSelectedPlayer(player);
            setActiveSideTab('PLAYERS');
          });
        });
      }
    });

    return () => {
      isCancelled = true;
    };
  }, [data, radiusKm, tileStyle, selectedPlayer, initialLat, initialLng, venueName, neighborhoodArea]);

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
  const finalMapUrl =
    googleMapsUrl ||
    data?.turf?.googleMapsUrl ||
    `https://www.google.com/maps?q=${activeLat},${activeLng}`;

  return (
    <div
      className={`relative flex flex-col bg-[#0A0A0A] text-white border border-[#262626] transition-all duration-300 ${
        isFullscreen
          ? 'fixed inset-0 z-[9999] w-screen h-screen rounded-none m-0 p-0 shadow-none'
          : isEmbedded
          ? 'w-full h-[720px] rounded-2xl overflow-hidden shadow-2xl'
          : 'w-full max-w-6xl mx-auto h-[840px] rounded-2xl overflow-hidden shadow-2xl'
      }`}
    >
      {/* Top Header Bar */}
      <div className="flex items-center justify-between px-6 py-4 bg-[#121212] border-b border-[#262626] z-10">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-[#1F2916] border border-[#D4FF00]/40 flex items-center justify-center">
            <Crosshair className="w-5 h-5 text-[#D4FF00] animate-spin-slow" />
          </div>
          <div>
            <div className="flex items-center gap-2">
              <h2 className="text-base font-black tracking-tight text-white">
                {data?.turf?.venueName || venueName}
              </h2>
              <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-[#1F2916] text-[#D4FF00] border border-[#D4FF00]/30 font-mono">
                TURF RADAR & MATCHES
              </span>
              {isFullscreen && (
                <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-emerald-500/15 text-emerald-400 border border-emerald-500/30 font-mono">
                  FULLSCREEN
                </span>
              )}
            </div>
            <p className="text-xs text-zinc-400">
              {data?.turf?.streetAddress || streetAddress} •{' '}
              <span className="text-[#D4FF00]">
                {activeLat.toFixed(4)}° N, {activeLng.toFixed(4)}° E
              </span>
            </p>
          </div>
        </div>

        <div className="flex items-center gap-2 sm:gap-3">
          {/* Fullscreen Toggle Button */}
          <button
            type="button"
            onClick={() => setIsFullscreen(!isFullscreen)}
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#161D2E] hover:bg-[#1E273A] border border-[#28354F] text-xs font-semibold text-slate-200 hover:text-white transition-all shadow-sm"
            title={isFullscreen ? 'Exit Fullscreen (Esc)' : 'Expand to Fullscreen'}
          >
            {isFullscreen ? (
              <>
                <Minimize2 className="w-3.5 h-3.5 text-[#D4FF00]" />
                <span className="hidden sm:inline">Exit Fullscreen</span>
              </>
            ) : (
              <>
                <Maximize2 className="w-3.5 h-3.5 text-[#D4FF00]" />
                <span className="hidden sm:inline">Fullscreen Map</span>
              </>
            )}
          </button>

          {/* External Google Maps Button */}
          <a
            href={finalMapUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="hidden sm:flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#1E1E1E] hover:bg-[#2A2A2A] border border-[#333333] text-xs font-semibold text-zinc-200 transition-colors"
          >
            <MapPin className="w-3.5 h-3.5 text-[#D4FF00]" />
            <span>Google Maps</span>
            <ExternalLink className="w-3 h-3 text-zinc-400" />
          </a>

          {onClose && (
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-lg bg-[#1E1E1E] hover:bg-zinc-800 border border-[#333] flex items-center justify-center text-zinc-400 hover:text-white transition-colors"
              title="Close Modal"
            >
              <X className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>

      {/* Main Content: Map (Left/Center) + Operations Inspector (Right) */}
      <div className="flex-1 flex flex-col lg:flex-row relative overflow-hidden">
        {/* Left: Map & Radar Controls */}
        <div className="flex-1 relative flex flex-col">
          {/* Floating Range & Filter Controls */}
          <div className="absolute top-4 left-4 z-[500] flex flex-wrap items-center gap-2 bg-[#121212]/90 backdrop-blur-md p-2 rounded-xl border border-[#2E2E2E] shadow-xl">
            <div className="flex items-center gap-1.5 px-2 text-xs font-bold text-zinc-300">
              <Sliders className="w-3.5 h-3.5 text-[#D4FF00]" />
              <span>Range:</span>
            </div>
            {[2, 5, 10, 15, 25, 50].map((km) => (
              <button
                key={km}
                onClick={() => setRadiusKm(km)}
                className={`px-2.5 py-1 rounded-lg text-xs font-bold transition-all ${
                  radiusKm === km
                    ? 'bg-[#D4FF00] text-black shadow-lg shadow-[#D4FF00]/20'
                    : 'bg-[#1E1E1E] text-zinc-400 hover:text-white hover:bg-zinc-800'
                }`}
              >
                {km} km
              </button>
            ))}

            <div className="h-4 w-[1px] bg-zinc-800 mx-1 hidden sm:block" />

            {/* Map Tile Style Switcher (100% Free & Keyless) */}
            <div className="flex items-center gap-1 bg-[#1A1A1A] p-0.5 rounded-lg border border-[#333]">
              <button
                type="button"
                onClick={() => setTileStyle('dark')}
                className={`px-2 py-0.5 rounded text-[11px] font-semibold transition-all ${
                  tileStyle === 'dark'
                    ? 'bg-[#D4FF00] text-black font-bold shadow-xs'
                    : 'text-zinc-400 hover:text-white'
                }`}
                title="Esri Clean Dark Gray Basemap (No API key needed)"
              >
                🌙 Dark
              </button>
              <button
                type="button"
                onClick={() => setTileStyle('satellite')}
                className={`px-2 py-0.5 rounded text-[11px] font-semibold transition-all ${
                  tileStyle === 'satellite'
                    ? 'bg-[#D4FF00] text-black font-bold shadow-xs'
                    : 'text-zinc-400 hover:text-white'
                }`}
                title="Real Satellite Aerial View"
              >
                🛰️ Satellite
              </button>
              <button
                type="button"
                onClick={() => setTileStyle('street')}
                className={`px-2 py-0.5 rounded text-[11px] font-semibold transition-all ${
                  tileStyle === 'street'
                    ? 'bg-[#D4FF00] text-black font-bold shadow-xs'
                    : 'text-zinc-400 hover:text-white'
                }`}
                title="OpenStreetMap Street View"
              >
                🗺️ Streets
              </button>
            </div>

            <div className="h-4 w-[1px] bg-zinc-800 mx-1 hidden sm:block" />

            <div className="flex items-center gap-1 px-2.5 py-1 rounded-lg bg-[#1F2916] border border-[#D4FF00]/30 text-[#D4FF00] text-xs font-bold">
              <Zap className="w-3 h-3" />
              <span>
                {loading
                  ? 'Scanning...'
                  : `${data?.totalPlayersFound || 0} Registered Players`}
              </span>
            </div>
          </div>

          {/* Leaflet Map Div */}
          <div ref={mapContainerRef} className="w-full h-full min-h-[420px] bg-[#0A0A0A]" />

          {/* Map Legend */}
          <div className="absolute bottom-4 left-4 z-[500] bg-[#121212]/90 backdrop-blur-md px-3 py-2 rounded-lg border border-[#2E2E2E] flex items-center gap-4 text-[11px] text-zinc-300">
            <button
              onClick={() => setActiveSideTab('SLOTS_MATCHES')}
              className="flex items-center gap-1.5 hover:text-[#D4FF00] transition-colors"
            >
              <span className="text-base">🏟️</span>
              <span className="font-semibold text-white">Turf Pin (Matches & Slots)</span>
            </button>
            <div className="flex items-center gap-1.5">
              <span className="w-3 h-3 rounded-full bg-[#D4FF00] border border-black inline-block" />
              <span>Radius ({radiusKm} km)</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span>⚽ 🏏 🏸</span>
              <span>Player App Users ({data?.players?.length || 0})</span>
            </div>
          </div>
        </div>

        {/* Right: Dual-Mode Inspector (Players Directory OR Turf Matches & Slots) */}
        <div className="w-full lg:w-[420px] bg-[#0D0D0D] border-t lg:border-t-0 lg:border-l border-[#262626] flex flex-col z-10">
          {/* Side Tabs Selector */}
          <div className="grid grid-cols-2 p-2 bg-[#121212] border-b border-[#262626] gap-1.5 font-mono">
            <button
              type="button"
              onClick={() => setActiveSideTab('PLAYERS')}
              className={`flex items-center justify-center gap-1.5 py-2 px-3 rounded-lg text-xs font-bold transition-all ${
                activeSideTab === 'PLAYERS'
                  ? 'bg-[#1F2916] text-[#D4FF00] border border-[#D4FF00]/40 shadow-sm'
                  : 'text-zinc-400 hover:text-white hover:bg-zinc-800/60'
              }`}
            >
              <Users className="w-3.5 h-3.5" />
              <span>Players ({data?.players?.length || 0})</span>
            </button>

            <button
              type="button"
              onClick={() => setActiveSideTab('SLOTS_MATCHES')}
              className={`flex items-center justify-center gap-1.5 py-2 px-3 rounded-lg text-xs font-bold transition-all ${
                activeSideTab === 'SLOTS_MATCHES'
                  ? 'bg-[#1F2916] text-[#D4FF00] border border-[#D4FF00]/40 shadow-sm'
                  : 'text-zinc-400 hover:text-white hover:bg-zinc-800/60'
              }`}
            >
              <Swords className="w-3.5 h-3.5" />
              <span>Matches & Slots</span>
            </button>
          </div>

          {/* ========================================================================= */}
          {/* VIEW A: REAL PLAYERS FROM PLAYER APP */}
          {/* ========================================================================= */}
          {activeSideTab === 'PLAYERS' && (
            <div className="flex-1 flex flex-col overflow-hidden">
              {/* Selected Player Profile Popup Card (If clicked) */}
              {selectedPlayer ? (
                <div className="p-4 bg-[#141414] border-b border-[#2A2A2A] relative">
                  <button
                    onClick={() => setSelectedPlayer(null)}
                    className="absolute top-3 right-3 text-zinc-500 hover:text-white"
                  >
                    <X className="w-4 h-4" />
                  </button>

                  <div className="flex items-center gap-3 mb-3">
                    <div className="w-12 h-12 rounded-full bg-[#1F2916] border-2 border-[#D4FF00] flex items-center justify-center font-black text-base text-[#D4FF00]">
                      {selectedPlayer.fullName.substring(0, 2).toUpperCase()}
                    </div>
                    <div>
                      <h3 className="text-sm font-black text-white flex items-center gap-1.5">
                        {selectedPlayer.fullName}
                        <span className="text-xs">
                          {selectedPlayer.preferredSport === 'Cricket'
                            ? '🏏'
                            : selectedPlayer.preferredSport === 'Badminton'
                            ? '🏸'
                            : '⚽'}
                        </span>
                      </h3>
                      <div className="flex items-center gap-2 mt-0.5">
                        <span className="px-1.5 py-0.5 rounded bg-zinc-800 text-[10px] font-bold text-zinc-300">
                          {selectedPlayer.rank}
                        </span>
                        <span className="text-[11px] text-[#D4FF00] font-bold">
                          {selectedPlayer.distanceKm} km from turf
                        </span>
                      </div>
                    </div>
                  </div>

                  {/* Player Details Grid */}
                  <div className="grid grid-cols-2 gap-2 text-xs bg-[#1A1A1A] p-2.5 rounded-lg mb-3 border border-[#2E2E2E]">
                    <div>
                      <span className="text-[10px] text-zinc-500 uppercase tracking-wider block">
                        Contact Phone
                      </span>
                      <span className="font-semibold text-zinc-200">
                        {selectedPlayer.mobileNumber}
                      </span>
                    </div>
                    <div>
                      <span className="text-[10px] text-zinc-500 uppercase tracking-wider block">
                        Matches Played
                      </span>
                      <span className="font-semibold text-[#D4FF00]">
                        {selectedPlayer.matchesPlayed} Matches
                      </span>
                    </div>
                    <div>
                      <span className="text-[10px] text-zinc-500 uppercase tracking-wider block">
                        Preferred Sport
                      </span>
                      <span className="font-semibold text-zinc-200">
                        {selectedPlayer.preferredSport}
                      </span>
                    </div>
                    <div>
                      <span className="text-[10px] text-zinc-500 uppercase tracking-wider block">
                        Coordinates
                      </span>
                      <span className="font-semibold text-zinc-400 text-[10px]">
                        {selectedPlayer.latitude.toFixed(4)}, {selectedPlayer.longitude.toFixed(4)}
                      </span>
                    </div>
                  </div>

                  {/* Action Buttons for Player */}
                  <div className="flex items-center gap-2">
                    <a
                      href={`tel:${selectedPlayer.mobileNumber}`}
                      className="flex-1 flex items-center justify-center gap-1.5 py-2 rounded-lg bg-[#D4FF00] hover:bg-[#bce400] text-black font-black text-xs transition-colors"
                    >
                      <Phone className="w-3.5 h-3.5" />
                      <span>Call Player</span>
                    </a>
                    <a
                      href={`https://wa.me/${selectedPlayer.mobileNumber.replace(/\D/g, '')}`}
                      target="_blank"
                      rel="noopener noreferrer"
                      className="flex items-center justify-center px-3 py-2 rounded-lg bg-[#1E1E1E] hover:bg-zinc-800 border border-[#333] text-emerald-400 text-xs font-bold transition-colors"
                    >
                      <MessageSquare className="w-3.5 h-3.5" />
                    </a>
                  </div>
                </div>
              ) : (
                <div className="p-3 bg-[#141414] border-b border-[#2A2A2A]">
                  <div className="flex items-center gap-2 text-xs text-zinc-400">
                    <Shield className="w-4 h-4 text-[#D4FF00]" />
                    <span>
                      Registered players present in the Player App within {radiusKm} km.
                    </span>
                  </div>
                </div>
              )}

              {/* Search & Filter Header */}
              <div className="p-3 border-b border-[#262626] bg-[#0E0E0E] flex flex-col gap-2">
                <input
                  type="text"
                  placeholder="Search player name, phone, or rank..."
                  value={searchQuery}
                  onFocus={(e) => e.stopPropagation()}
                  onChange={(e) => setSearchQuery(e.target.value)}
                  className="w-full px-3 py-1.5 bg-[#181818] border border-[#2E2E2E] rounded-lg text-xs text-white placeholder-zinc-500 focus:outline-none focus:border-[#D4FF00]"
                />
                <div className="flex items-center gap-1.5 overflow-x-auto pb-0.5">
                  {['ALL', 'Football', 'Cricket', 'Badminton'].map((sp) => (
                    <button
                      key={sp}
                      onClick={() => setSelectedSportFilter(sp)}
                      className={`px-2.5 py-1 rounded text-[11px] font-semibold whitespace-nowrap transition-colors ${
                        selectedSportFilter === sp
                          ? 'bg-[#1F2916] text-[#D4FF00] border border-[#D4FF00]/40'
                          : 'bg-[#181818] text-zinc-400 hover:text-white'
                      }`}
                    >
                      {sp}
                    </button>
                  ))}
                </div>
              </div>

              {/* Scrollable Player List */}
              <div className="flex-1 overflow-y-auto p-2 space-y-1.5 divide-y divide-[#1A1A1A]">
                {loading ? (
                  <div className="flex flex-col items-center justify-center h-48 text-zinc-500 text-xs gap-2">
                    <Activity className="w-5 h-5 animate-spin text-[#D4FF00]" />
                    <span>Scanning registered players from database...</span>
                  </div>
                ) : filteredPlayers.length === 0 ? (
                  <div className="flex flex-col items-center justify-center h-48 text-zinc-500 text-xs gap-2 p-4 text-center">
                    <Users className="w-8 h-8 opacity-40 text-zinc-400" />
                    <p className="font-semibold text-zinc-300">No registered players in {radiusKm} km radius.</p>
                    <p className="text-[11px] text-zinc-500">
                      Players who set their location in the Player App Settings will automatically populate here.
                    </p>
                    <button
                      onClick={() => setRadiusKm((prev) => Math.min(50, prev + 15))}
                      className="mt-1 px-3 py-1 bg-[#1A1A1A] hover:bg-zinc-800 border border-[#333] rounded-lg text-[#D4FF00] font-bold text-xs"
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
                        onClick={() => {
                          setSelectedPlayer(player);
                          if (mapInstanceRef.current) {
                            mapInstanceRef.current.panTo([
                              player.latitude,
                              player.longitude,
                            ]);
                          }
                        }}
                        className={`pt-2 p-2.5 rounded-lg cursor-pointer transition-all flex items-center justify-between ${
                          isSelected
                            ? 'bg-[#1F2916] border border-[#D4FF00]/50'
                            : 'hover:bg-[#181818]'
                        }`}
                      >
                        <div className="flex items-center gap-2.5 min-w-0">
                          <div className="w-8 h-8 rounded-full bg-[#182014] border border-[#D4FF00]/40 flex items-center justify-center font-bold text-xs text-[#D4FF00] shrink-0">
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
                            <p className="text-[10px] text-zinc-400 truncate">
                              {player.mobileNumber} • {player.rank}
                            </p>
                          </div>
                        </div>

                        <div className="text-right shrink-0">
                          <span className="text-xs font-black text-[#D4FF00] block">
                            {player.distanceKm} km
                          </span>
                          <span className="text-[9.5px] text-zinc-500">
                            {player.city}
                          </span>
                        </div>
                      </div>
                    );
                  })
                )}
              </div>
            </div>
          )}

          {/* ========================================================================= */}
          {/* VIEW B: TURF LIVE SLOTS & OPEN MATCHES (WAITING / OPPONENT GOT) */}
          {/* ========================================================================= */}
          {activeSideTab === 'SLOTS_MATCHES' && (
            <div className="flex-1 flex flex-col overflow-hidden">
              {/* Operations Stats Overview Grid */}
              <div className="p-3 bg-[#11161F] border-b border-[#1E273A] grid grid-cols-4 gap-1.5 text-center font-mono">
                <div className="p-2 rounded-lg bg-[#0E131F] border border-[#1E273A]">
                  <span className="text-[9px] text-emerald-400 font-bold block">AVAILABLE</span>
                  <span className="text-base font-black text-white">
                    {data?.slotsOverview?.availableCount ?? 12}
                  </span>
                </div>
                <div className="p-2 rounded-lg bg-[#0E131F] border border-[#1E273A]">
                  <span className="text-[9px] text-rose-400 font-bold block">BOOKED</span>
                  <span className="text-base font-black text-white">
                    {data?.slotsOverview?.bookedCount ?? 0}
                  </span>
                </div>
                <div className="p-2 rounded-lg bg-[#0E131F] border border-[#1E273A]">
                  <span className="text-[9px] text-amber-400 font-bold block">WAITING</span>
                  <span className="text-base font-black text-amber-300">
                    {data?.slotsOverview?.waitingOpponentCount ?? 0}
                  </span>
                </div>
                <div className="p-2 rounded-lg bg-[#0E131F] border border-[#1E273A]">
                  <span className="text-[9px] text-[#D4FF00] font-bold block">OPPONENT GOT</span>
                  <span className="text-base font-black text-[#D4FF00]">
                    {data?.slotsOverview?.opponentGotCount ?? 0}
                  </span>
                </div>
              </div>

              {/* Scrollable Matches & Slots Breakdown */}
              <div className="flex-1 overflow-y-auto p-3 space-y-4">
                {/* 1. Live Open Matches (VS Style Cards) */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs font-bold text-white flex items-center gap-1.5 font-mono">
                      <Swords className="w-3.5 h-3.5 text-[#D4FF00]" />
                      <span>OPEN MATCH CHALLENGES</span>
                    </span>
                    <span className="text-[10px] text-zinc-400 font-mono">
                      {data?.openMatches?.length || 0} Total
                    </span>
                  </div>

                  <div className="space-y-2.5">
                    {data?.openMatches && data.openMatches.length > 0 ? (
                      data.openMatches.map((m) => {
                        const isWaiting = m.status === 'WAITING_FOR_OPPONENT';
                        return (
                          <div
                            key={m.id}
                            className="p-3 rounded-xl bg-[#12161A] border border-[#222B38] space-y-2 hover:border-[#D4FF00]/40 transition-all shadow-md"
                          >
                            {/* Sport Tag & Time Slot Header */}
                            <div className="flex items-center justify-between text-[11px] pb-1.5 border-b border-[#1E2633]">
                              <span className="flex items-center gap-1 px-2 py-0.5 rounded-full bg-[#1F2916] text-[#D4FF00] font-bold text-[10px]">
                                ⚡ {m.sport}
                              </span>
                              <span className="text-zinc-300 font-mono text-[10px] flex items-center gap-1">
                                <Clock className="w-3 h-3 text-zinc-400" />
                                {m.date} • {m.time}
                              </span>
                            </div>

                            {/* Head-to-Head VS Match Row */}
                            <div className="flex items-center justify-between gap-2 py-1">
                              {/* Challenger / Host Team */}
                              <div className="flex items-center gap-2 flex-1 min-w-0">
                                <div className="w-8 h-8 rounded-full bg-emerald-600 flex items-center justify-center font-black text-xs text-white shrink-0">
                                  {m.challengerTeamInitials || 'TC'}
                                </div>
                                <div className="truncate">
                                  <span className="text-xs font-bold text-white block truncate">
                                    {m.challengerName}
                                  </span>
                                  <span className="text-[10px] text-zinc-400">
                                    Host Team ({m.teamSize})
                                  </span>
                                </div>
                              </div>

                              {/* Neon VS Badge */}
                              <div className="flex flex-col items-center shrink-0 px-2">
                                <div className="w-7 h-7 rounded-full bg-[#1C2415] border border-[#D4FF00] flex items-center justify-center font-black text-[10px] text-[#D4FF00] shadow-sm shadow-[#D4FF00]/20 italic">
                                  VS
                                </div>
                              </div>

                              {/* Opponent Team or Open Slot */}
                              <div className="flex items-center gap-2 flex-1 min-w-0 justify-end text-right">
                                <div className="truncate">
                                  <span
                                    className={`text-xs font-bold block truncate ${
                                      isWaiting ? 'text-amber-400 italic' : 'text-emerald-400'
                                    }`}
                                  >
                                    {isWaiting ? 'Open Slot' : m.opponentName}
                                  </span>
                                  <span className="text-[10px] text-zinc-400">
                                    {isWaiting ? 'Waiting Opponent' : 'Confirmed'}
                                  </span>
                                </div>
                                <div
                                  className={`w-8 h-8 rounded-full flex items-center justify-center font-black text-xs shrink-0 ${
                                    isWaiting
                                      ? 'bg-zinc-800 border border-dashed border-zinc-600 text-zinc-500'
                                      : 'bg-indigo-600 text-white'
                                  }`}
                                >
                                  {isWaiting ? '?' : m.opponentName.substring(0, 2).toUpperCase()}
                                </div>
                              </div>
                            </div>

                            {/* Status Chip & Host Contact */}
                            <div className="flex items-center justify-between pt-1 border-t border-[#1E2633] text-[10px] font-mono">
                              <span
                                className={`px-2 py-0.5 rounded-md font-bold flex items-center gap-1 ${
                                  isWaiting
                                    ? 'bg-amber-500/15 text-amber-300 border border-amber-500/30'
                                    : 'bg-emerald-500/15 text-emerald-300 border border-emerald-500/30'
                                }`}
                              >
                                {isWaiting ? (
                                  <>
                                    <Clock className="w-2.5 h-2.5 animate-pulse" />
                                    <span>Waiting for Opponent</span>
                                  </>
                                ) : (
                                  <>
                                    <CheckCircle2 className="w-2.5 h-2.5" />
                                    <span>Opponent Got / Locked</span>
                                  </>
                                )}
                              </span>

                              <a
                                href={`tel:${m.creatorPhone}`}
                                className="text-zinc-400 hover:text-white flex items-center gap-1"
                              >
                                <Phone className="w-3 h-3 text-[#D4FF00]" />
                                <span>{m.creatorPhone}</span>
                              </a>
                            </div>
                          </div>
                        );
                      })
                    ) : (
                      <div className="p-4 rounded-xl bg-[#12161A] border border-[#222B38] text-center text-xs text-zinc-400 space-y-1">
                        <Swords className="w-5 h-5 mx-auto text-zinc-500 opacity-60" />
                        <p>No active open challenges right now.</p>
                      </div>
                    )}
                  </div>
                </div>

                {/* 2. Today's Hourly Slot Status Grid */}
                <div>
                  <div className="flex items-center justify-between mb-2">
                    <span className="text-xs font-bold text-white flex items-center gap-1.5 font-mono">
                      <Clock className="w-3.5 h-3.5 text-[#D4FF00]" />
                      <span>TODAY&apos;S COURT SLOTS</span>
                    </span>
                    <span className="text-[10px] text-zinc-400 font-mono">
                      16 Standard Hours
                    </span>
                  </div>

                  <div className="grid grid-cols-2 gap-2 text-xs font-mono">
                    {data?.slotsOverview?.slots?.map((slot, idx) => {
                      const isBooked = slot.status === 'BOOKED';
                      const isOpenMatch = slot.status === 'OPEN_MATCH';
                      return (
                        <div
                          key={idx}
                          className={`p-2.5 rounded-lg border flex flex-col justify-between ${
                            isOpenMatch
                              ? 'bg-[#1C2014] border-[#D4FF00]/40'
                              : isBooked
                              ? 'bg-[#1F1214] border-rose-500/30'
                              : 'bg-[#0E131F] border-[#1E273A]'
                          }`}
                        >
                          <span className="text-[10px] text-zinc-400 font-medium">
                            {slot.timeSlot.split(' - ')[0]}
                          </span>

                          <div className="flex items-center justify-between mt-1">
                            <span
                              className={`text-[10px] font-bold ${
                                isOpenMatch
                                  ? 'text-[#D4FF00]'
                                  : isBooked
                                  ? 'text-rose-400'
                                  : 'text-emerald-400'
                              }`}
                            >
                              {isOpenMatch
                                ? '⚡ Challenge'
                                : isBooked
                                ? 'Booked'
                                : 'Available'}
                            </span>
                            <span className="text-[10px] text-zinc-500">₹{slot.rate}</span>
                          </div>
                        </div>
                      );
                    })}
                  </div>
                </div>
              </div>
            </div>
          )}

          {/* Footer Stats Summary */}
          <div className="p-3 bg-[#111111] border-t border-[#262626] flex items-center justify-between text-xs text-zinc-400 font-mono">
            <span>
              Turf Radar:{' '}
              <strong className="text-white">
                {data?.totalPlayersFound || 0} Real Players
              </strong>
            </span>
            <span className="text-[#D4FF00] font-bold">
              Radius: {radiusKm} km
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
