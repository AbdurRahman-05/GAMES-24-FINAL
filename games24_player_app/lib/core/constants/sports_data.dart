import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class SportItem {
  final String id;
  final String name;
  final IconData icon;
  final Color color;
  final String description;

  const SportItem({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.description,
  });
}

class SportsData {
  SportsData._();

  static const List<SportItem> allSports = [
    SportItem(
      id: 'football',
      name: 'Football',
      icon: Icons.sports_soccer,
      color: Color(0xFF22C55E),
      description: '5v5 & 7v7 Artificial Grass Turfs',
    ),
    SportItem(
      id: 'cricket',
      name: 'Cricket',
      icon: Icons.sports_cricket,
      color: Color(0xFF2563EB),
      description: 'Box Cricket & Net Practice Arenas',
    ),
    SportItem(
      id: 'badminton',
      name: 'Badminton',
      icon: Icons.sports_tennis,
      color: Color(0xFF06B6D4),
      description: 'BWF Standard Wooden & Synthetic Courts',
    ),
    SportItem(
      id: 'snooker',
      name: 'Snooker',
      icon: Icons.pool,
      color: AppColors.primary,
      description: 'Professional Tournament Cue Tables',
    ),
    SportItem(
      id: 'pool',
      name: '8-Ball Pool',
      icon: Icons.sports_bar,
      color: Color(0xFFEC4899),
      description: 'Lounge Cue Tables & Chill Zones',
    ),
    SportItem(
      id: 'bowling',
      name: 'Bowling',
      icon: Icons.sports_score,
      color: Color(0xFFF97316),
      description: 'Automated 10-Pin Lanes & Arcade',
    ),
    SportItem(
      id: 'gokart',
      name: 'Go Kart',
      icon: Icons.directions_car_filled,
      color: Color(0xFFEF4444),
      description: 'High-speed Outdoor Racing Track',
    ),
    SportItem(
      id: 'paintball',
      name: 'Paintball',
      icon: Icons.sports_kabaddi,
      color: Color(0xFFEAB308),
      description: 'Tactical Combat Battlefield',
    ),
    SportItem(
      id: 'shooting',
      name: 'Shooting',
      icon: Icons.center_focus_strong,
      color: Color(0xFF64748B),
      description: '10m Air Rifle Target Range',
    ),
    SportItem(
      id: 'vrgames',
      name: 'VR Games',
      icon: Icons.vrpano,
      color: Color(0xFF3B82F6),
      description: 'Full Motion Immersion VR Pods',
    ),
    SportItem(
      id: 'tabletennis',
      name: 'Table Tennis',
      icon: Icons.sports_tennis_rounded,
      color: Color(0xFF10B981),
      description: 'ITTF Approved Indoor TT Arenas',
    ),
    SportItem(
      id: 'basketball',
      name: 'Basketball',
      icon: Icons.sports_basketball,
      color: Color(0xFFF59E0B),
      description: 'Full & Half Acrylic Hoops Courts',
    ),
    SportItem(
      id: 'volleyball',
      name: 'Volleyball',
      icon: Icons.sports_volleyball,
      color: Color(0xFF14B8A6),
      description: 'Sand Beach & Synthetic Volleyball Courts',
    ),
  ];

  static const List<String> maduraiAreas = [
    'All Madurai',
    'KK Nagar',
    'Anna Nagar',
    'Teppakulam',
    'Kalavasal',
    'SS Colony',
    'Simmakkal',
    'TVS Nagar',
    'Melur Road',
    'Pasumalai',
  ];
}
