import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/booking_model.dart';
import '../models/match_model.dart';
import '../models/team_model.dart';
import '../repositories/mock_bookings.dart';
import '../repositories/mock_matches.dart';
import '../repositories/mock_teams.dart';

// Theme Provider
class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.light;

  void setThemeMode(ThemeMode mode) => state = mode;
  void toggleTheme() => state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
}

final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(() => ThemeModeNotifier());

// Location / Area Provider
class SelectedAreaNotifier extends Notifier<String> {
  @override
  String build() => 'KK Nagar';

  void setArea(String area) => state = area;
}

final selectedAreaProvider = NotifierProvider<SelectedAreaNotifier, String>(() => SelectedAreaNotifier());

// Search & Filter Providers
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(() => SearchQueryNotifier());

class SelectedSportFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setSport(String? sportId) => state = sportId;
}

final selectedSportFilterProvider = NotifierProvider<SelectedSportFilterNotifier, String?>(() => SelectedSportFilterNotifier());

// Favorites Notifier
class FavoriteVenuesNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {'v1', 'v2'};

  void toggleFavorite(String venueId) {
    if (state.contains(venueId)) {
      state = {...state}..remove(venueId);
    } else {
      state = {...state, venueId};
    }
  }
}

final favoriteVenuesProvider = NotifierProvider<FavoriteVenuesNotifier, Set<String>>(() {
  return FavoriteVenuesNotifier();
});

// Bookings Notifier
class UserBookingsNotifier extends Notifier<List<BookingModel>> {
  @override
  List<BookingModel> build() => MockBookingsRepository.initialBookings;

  void addBooking(BookingModel booking) {
    state = [booking, ...state];
  }

  void cancelBooking(String bookingId) {
    state = [
      for (final b in state)
        if (b.id == bookingId)
          BookingModel(
            id: b.id,
            venueId: b.venueId,
            venueName: b.venueName,
            area: b.area,
            sportName: b.sportName,
            date: b.date,
            timeSlot: b.timeSlot,
            totalPrice: b.totalPrice,
            status: BookingStatus.cancelled,
            qrCodeData: b.qrCodeData,
            imageUrl: b.imageUrl,
          )
        else
          b,
    ];
  }
}

final userBookingsProvider = NotifierProvider<UserBookingsNotifier, List<BookingModel>>(() {
  return UserBookingsNotifier();
});

// Hosted Matches Notifier
class HostedMatchesNotifier extends Notifier<List<MatchModel>> {
  @override
  List<MatchModel> build() => MockMatchesRepository.matches;

  void addMatch(MatchModel match) {
    state = [match, ...state];
  }

  void joinMatch(String matchId) {
    state = [
      for (final m in state)
        if (m.id == matchId && !m.isFull)
          MatchModel(
            id: m.id,
            sportId: m.sportId,
            sportName: m.sportName,
            hostName: m.hostName,
            hostAvatar: m.hostAvatar,
            hostPhone: m.hostPhone,
            venueId: m.venueId,
            venueName: m.venueName,
            area: m.area,
            date: m.date,
            time: m.time,
            skillLevel: m.skillLevel,
            totalPlayersNeeded: m.totalPlayersNeeded,
            joinedPlayersCount: m.joinedPlayersCount + 1,
            playerAvatars: [...m.playerAvatars, 'https://i.pravatar.cc/150?img=68'],
            pricePerPlayer: m.pricePerPlayer,
            description: m.description,
          )
        else
          m,
    ];
  }
}

final hostedMatchesProvider = NotifierProvider<HostedMatchesNotifier, List<MatchModel>>(() {
  return HostedMatchesNotifier();
});

// Teams Notifier
class TeamsNotifier extends Notifier<List<TeamModel>> {
  @override
  List<TeamModel> build() => MockTeamsRepository.teams;

  void addTeam(TeamModel team) {
    state = [team, ...state];
  }
}

final teamsProvider = NotifierProvider<TeamsNotifier, List<TeamModel>>(() {
  return TeamsNotifier();
});
