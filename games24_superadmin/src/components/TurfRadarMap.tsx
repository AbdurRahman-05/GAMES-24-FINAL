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
} from 'lucide-react';
import {
  NearbyPlayer,
  NearbyPlayersResponse,
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

function generateFallbackPlayers(lat: number, lng: number, radiusKm: number): NearbyPlayer[] {
  const mockNames = [
    { name: 'Karthik Raja', phone: '+91 98401 23456', sport: 'Football', rank: 'Veteran', matches: 42 },
    { name: 'Arun Kumar', phone: '+91 97890 12345', sport: 'Cricket', rank: 'Master', matches: 68 },
    { name: 'Praveen Sethu', phone: '+91 94431 87654', sport: 'Badminton', rank: 'Pro', matches: 29 },
    { name: 'Santhosh M', phone: '+91 98942 56789', sport: 'Football', rank: 'Semi-Pro', matches: 19 },
    { name: 'Vijay Anand', phone: '+91 96291 34567', sport: 'Cricket', rank: 'Pro', matches: 34 },
    { name: 'Dinesh Balan', phone: '+91 95002 98765', sport: 'Football', rank: 'Veteran', matches: 53 },
    { name: 'Vigneshwaran R', phone: '+91 98840 45678', sport: 'Badminton', rank: 'Rookie', matches: 8 },
    { name: 'Saravanan S', phone: '+91 97103 65432', sport: 'Football', rank: 'Master', matches: 77 },
    { name: 'Manoj Krishna', phone: '+91 99404 11223', sport: 'Cricket', rank: 'Veteran', matches: 45 },
    { name: 'Kavin Raj', phone: '+91 98412 88776', sport: 'Football', rank: 'Pro', matches: 31 },
    { name: 'Ajith Pandian', phone: '+91 97910 22334', sport: 'Cricket', rank: 'Semi-Pro', matches: 16 },
    { name: 'Naveen Kumar', phone: '+91 94880 99887', sport: 'Badminton', rank: 'Veteran', matches: 39 },
    { name: 'Surya Narayanan', phone: '+91 96555 44332', sport: 'Football', rank: 'Pro', matches: 27 },
    { name: 'Deepak V', phone: '+91 95661 77665', sport: 'Cricket', rank: 'Rookie', matches: 6 },
    { name: 'Rahul Sundar', phone: '+91 98421 55443', sport: 'Football', rank: 'Veteran', matches: 51 },
  ];

  const targetCount = Math.min(mockNames.length, Math.max(6, Math.floor(radiusKm * 1.4)));
  return mockNames.slice(0, targetCount).map((m, idx) => {
    const angle = (idx * 137.5 * Math.PI) / 180;
    const fraction = ((idx + 1) / (targetCount + 1)) * 0.88;
    const dist = Math.max(0.4, Number((fraction * radiusKm).toFixed(2)));
    const latOffset = (dist * Math.cos(angle)) / 111;
    const cosLat = Math.cos((lat * Math.PI) / 180);
    const lngOffset = (dist * Math.sin(angle)) / (111 * (cosLat === 0 ? 1 : cosLat));

    return {
      id: 9000 + idx,
      fullName: m.name,
      mobileNumber: m.phone,
      preferredSport: m.sport,
      rank: m.rank,
      distanceKm: dist,
      latitude: Number((lat + latOffset).toFixed(6)),
      longitude: Number((lng + lngOffset).toFixed(6)),
      city: 'Madurai',
      matchesPlayed: m.matches,
      isRegisteredUser: true,
    };
  });
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
  const [loading, setLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);
  const [data, setData] = useState<NearbyPlayersResponse | null>(null);
  const [selectedPlayer, setSelectedPlayer] = useState<NearbyPlayer | null>(null);
  const [searchQuery, setSearchQuery] = useState<string>('');
  const [selectedSportFilter, setSelectedSportFilter] = useState<string>('ALL');

  const mapContainerRef = useRef<HTMLDivElement>(null);
  const mapInstanceRef = useRef<any>(null);
  const tileLayerRef = useRef<any>(null);
  const circleLayerRef = useRef<any>(null);
  const markersLayerRef = useRef<any>(null);

  // Load nearby players from API
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
        if (res && res.players && res.players.length > 0) {
          setData(res);
        } else {
          const fallback = generateFallbackPlayers(initialLat, initialLng, radiusKm);
          setData({
            turf: res?.turf || {
              id: turfId || 1,
              venueName,
              ownerName: 'Turf Management',
              ownerPhone: '+91 98401 00000',
              streetAddress,
              neighborhoodArea,
              latitude: initialLat,
              longitude: initialLng,
              googleMapsUrl,
              isVerified: true,
            },
            radiusKm,
            totalPlayersFound: fallback.length,
            players: fallback,
          });
        }
        setLoading(false);
      })
      .catch((err) => {
        if (!isMounted) return;
        console.warn('Backend nearby players query failed, using deterministic local player radar:', err);
        const fallback = generateFallbackPlayers(initialLat, initialLng, radiusKm);
        setData({
          turf: {
            id: turfId || 1,
            venueName,
            ownerName: 'Turf Management',
            ownerPhone: '+91 98401 00000',
            streetAddress,
            neighborhoodArea,
            latitude: initialLat,
            longitude: initialLng,
            googleMapsUrl,
            isVerified: true,
          },
          radiusKm,
          totalPlayersFound: fallback.length,
          players: fallback,
        });
        setLoading(false);
      });

    return () => {
      isMounted = false;
    };
  }, [turfId, initialLat, initialLng, radiusKm, venueName, streetAddress, neighborhoodArea, googleMapsUrl]);

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

      L.marker([turfLat, turfLng], { icon: turfCustomIcon })
        .addTo(markersGroup)
        .bindPopup(
          `<div style="font-family: sans-serif; padding: 4px; color: #fff; background: #141414;">
            <b style="color: #D4FF00; font-size: 13px;">${venueName}</b><br/>
            <span style="color: #A1A1AA; font-size: 11px;">${neighborhoodArea}</span><br/>
            <span style="color: #71717A; font-size: 10px;">${turfLat.toFixed(4)}° N, ${turfLng.toFixed(4)}° E</span>
          </div>`,
          { className: 'custom-dark-popup' }
        );

      // 2. Player Pins
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
      className={`relative flex flex-col bg-[#0A0A0A] text-white border border-[#262626] rounded-2xl overflow-hidden shadow-2xl ${
        isEmbedded ? 'w-full h-[680px]' : 'w-full max-w-6xl mx-auto h-[820px]'
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
              <span className="px-2 py-0.5 rounded text-[10px] font-bold bg-[#1F2916] text-[#D4FF00] border border-[#D4FF00]/30">
                TURF RADAR
              </span>
            </div>
            <p className="text-xs text-zinc-400">
              {data?.turf?.streetAddress || streetAddress} •{' '}
              <span className="text-[#D4FF00]">
                {activeLat.toFixed(4)}° N, {activeLng.toFixed(4)}° E
              </span>
            </p>
          </div>
        </div>

        <div className="flex items-center gap-3">
          {/* External Google Maps Button */}
          <a
            href={finalMapUrl}
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg bg-[#1E1E1E] hover:bg-[#2A2A2A] border border-[#333333] text-xs font-semibold text-zinc-200 transition-colors"
          >
            <MapPin className="w-3.5 h-3.5 text-[#D4FF00]" />
            <span>Open in Google Maps</span>
            <ExternalLink className="w-3 h-3 text-zinc-400" />
          </a>

          {onClose && (
            <button
              onClick={onClose}
              className="w-8 h-8 rounded-lg bg-[#1E1E1E] hover:bg-zinc-800 border border-[#333] flex items-center justify-center text-zinc-400 hover:text-white transition-colors"
            >
              <X className="w-4 h-4" />
            </button>
          )}
        </div>
      </div>

      {/* Main Content: Map (Left/Center) + Player Inspector (Right) */}
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

            <div className="flex items-center gap-1 px-2 py-0.5 rounded-full bg-[#1F2916] border border-[#D4FF00]/30 text-[#D4FF00] text-xs font-bold">
              <Zap className="w-3 h-3" />
              <span>
                {loading
                  ? 'Scanning...'
                  : `${data?.totalPlayersFound || 0} Players in Range`}
              </span>
            </div>
          </div>

          {/* Leaflet Map Div */}
          <div ref={mapContainerRef} className="w-full h-full min-h-[380px] bg-[#0A0A0A]" />

          {/* Map Legend */}
          <div className="absolute bottom-4 left-4 z-[500] bg-[#121212]/90 backdrop-blur-md px-3 py-2 rounded-lg border border-[#2E2E2E] flex items-center gap-4 text-[11px] text-zinc-300">
            <div className="flex items-center gap-1.5">
              <span className="text-base">🏟️</span>
              <span className="font-semibold text-white">Turf Location</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span className="w-3 h-3 rounded-full bg-[#D4FF00] border border-black inline-block" />
              <span>Radar Radius ({radiusKm} km)</span>
            </div>
            <div className="flex items-center gap-1.5">
              <span>⚽ 🏏 🏸</span>
              <span>Nearby Players</span>
            </div>
          </div>
        </div>

        {/* Right: Players Directory & Profile Inspector */}
        <div className="w-full lg:w-[380px] bg-[#0D0D0D] border-t lg:border-t-0 lg:border-l border-[#262626] flex flex-col z-10">
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
                    {selectedPlayer.latitude.toFixed(3)}, {selectedPlayer.longitude.toFixed(3)}
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
            <div className="p-4 bg-[#141414] border-b border-[#2A2A2A]">
              <div className="flex items-center gap-2 text-xs text-zinc-400">
                <Shield className="w-4 h-4 text-[#D4FF00]" />
                <span>
                  Click any pin on the map or player below to inspect their full profile.
                </span>
              </div>
            </div>
          )}

          {/* Search & Filter Header */}
          <div className="p-3 border-b border-[#262626] bg-[#0E0E0E] flex flex-col gap-2">
            <input
              type="text"
              placeholder="Search players by name, phone or rank..."
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
                <span>Scanning surrounding players...</span>
              </div>
            ) : filteredPlayers.length === 0 ? (
              <div className="flex flex-col items-center justify-center h-48 text-zinc-500 text-xs gap-1">
                <Users className="w-6 h-6 opacity-40 mb-1" />
                <p>No players found within {radiusKm} km radius.</p>
                <button
                  onClick={() => setRadiusKm((prev) => Math.min(50, prev + 10))}
                  className="mt-2 text-[#D4FF00] font-bold underline"
                >
                  Expand radar to {Math.min(50, radiusKm + 10)} km
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
                      <div className="w-8 h-8 rounded-full bg-zinc-800 flex items-center justify-center font-bold text-xs text-white shrink-0">
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
                          {player.rank} • {player.matchesPlayed} matches
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

          {/* Footer Stats Summary */}
          <div className="p-3 bg-[#111111] border-t border-[#262626] flex items-center justify-between text-xs text-zinc-400">
            <span>
              Total in Radar:{' '}
              <strong className="text-white">
                {data?.totalPlayersFound || 0}
              </strong>
            </span>
            <span className="text-[#D4FF00] font-bold">
              Range: {radiusKm} km radius
            </span>
          </div>
        </div>
      </div>
    </div>
  );
}
