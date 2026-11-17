import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../api_config.dart';

enum AccountStatus { active, blocked, pending }

class PartnerOwnerModel {
  final String id;
  final int? rawId;
  final String ownerName;
  final String turfName;
  final String area;
  final String phone;
  final String gstNumber;
  final AccountStatus status;
  final double commissionRate;
  final String registeredDate;
  final bool isBranch;
  final String? parentTurfName;
  final String? parentTurfPhone;
  final String? alternativePhone;
  final List<String> photoUrls;
  final List<String> sports;

  const PartnerOwnerModel({
    required this.id,
    this.rawId,
    required this.ownerName,
    required this.turfName,
    required this.area,
    required this.phone,
    required this.gstNumber,
    required this.status,
    this.commissionRate = 10.0,
    required this.registeredDate,
    this.isBranch = false,
    this.parentTurfName,
    this.parentTurfPhone,
    this.alternativePhone,
    this.photoUrls = const [],
    this.sports = const [],
  });

  PartnerOwnerModel copyWith({
    AccountStatus? status,
    double? commissionRate,
    bool? isBranch,
    String? parentTurfName,
    String? parentTurfPhone,
    String? alternativePhone,
    List<String>? photoUrls,
    List<String>? sports,
  }) {
    return PartnerOwnerModel(
      id: id,
      rawId: rawId,
      ownerName: ownerName,
      turfName: turfName,
      area: area,
      phone: phone,
      gstNumber: gstNumber,
      status: status ?? this.status,
      commissionRate: commissionRate ?? this.commissionRate,
      registeredDate: registeredDate,
      isBranch: isBranch ?? this.isBranch,
      parentTurfName: parentTurfName ?? this.parentTurfName,
      parentTurfPhone: parentTurfPhone ?? this.parentTurfPhone,
      alternativePhone: alternativePhone ?? this.alternativePhone,
      photoUrls: photoUrls ?? this.photoUrls,
      sports: sports ?? this.sports,
    );
  }
}

class UserAccountModel {
  final String id;
  final String name;
  final String phone;
  final String area;
  final int totalBookings;
  final AccountStatus status;
  final String joinedDate;

  const UserAccountModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.area,
    required this.totalBookings,
    required this.status,
    required this.joinedDate,
  });

  UserAccountModel copyWith({AccountStatus? status}) {
    return UserAccountModel(
      id: id,
      name: name,
      phone: phone,
      area: area,
      totalBookings: totalBookings,
      status: status ?? this.status,
      joinedDate: joinedDate,
    );
  }
}

// Super Admin State Notifier
class SuperAdminNotifier extends Notifier<SuperAdminState> {
  @override
  SuperAdminState build() {
    // Schedule fetch of live registrations from backend
    Future.microtask(() => fetchRegistrationsFromBackend());

    return const SuperAdminState(
      partners: [
        PartnerOwnerModel(
          id: 'p1',
          ownerName: 'Sundar Rajan',
          turfName: 'Madurai Turf Arena',
          area: 'KK Nagar',
          phone: '+91 98765 11111',
          gstNumber: '33AAAAA0000A1Z5',
          status: AccountStatus.active,
          commissionRate: 10.0,
          registeredDate: '12 Jan 2026',
        ),
      ],
      users: [
        UserAccountModel(
          id: 'u1',
          name: 'Vijay Sethu',
          phone: '+91 98765 43210',
          area: 'KK Nagar',
          totalBookings: 14,
          status: AccountStatus.active,
          joinedDate: 'Jan 2026',
        ),
        UserAccountModel(
          id: 'u2',
          name: 'Manojh Kumar',
          phone: '+91 94433 11224',
          area: 'KK Nagar',
          totalBookings: 9,
          status: AccountStatus.active,
          joinedDate: 'Jan 2026',
        ),
      ],
    );
  }

  Future<void> fetchRegistrationsFromBackend() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/super-admin/registrations?limit=50'),
        headers: {
          'x-admin-key': 'g24_super_admin_secret_2026',
        },
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rawItems = data['items'] as List<dynamic>? ?? [];

        final livePartners = rawItems.map((item) {
          final rawId = item['id'] as int?;
          final statusStr = (item['status'] ?? 'PENDING_APPROVAL').toString().toUpperCase();
          final status = statusStr == 'VERIFIED'
              ? AccountStatus.active
              : (statusStr == 'CANCELLED' ? AccountStatus.blocked : AccountStatus.pending);

          final photos = <String>[];
          if (item['photoUrls'] is List) {
            for (final p in item['photoUrls'] as List) {
              if (p != null && p.toString().trim().isNotEmpty) {
                photos.add(p.toString().trim());
              }
            }
          }

          final sports = <String>[];
          if (item['sports'] is List) {
            for (final s in item['sports'] as List) {
              if (s != null && s.toString().trim().isNotEmpty) {
                sports.add(s.toString().trim());
              }
            }
          }

          return PartnerOwnerModel(
            id: 'reg_${rawId ?? item['trackingCode'] ?? DateTime.now().millisecondsSinceEpoch}',
            rawId: rawId,
            ownerName: (item['ownerName'] ?? 'Turf Owner').toString(),
            turfName: (item['venueName'] ?? 'Turf Arena').toString(),
            area: (item['neighborhoodArea'] ?? 'Madurai').toString(),
            phone: (item['ownerPhone'] ?? '').toString(),
            gstNumber: (item['gstin'] ?? 'Not Provided').toString(),
            status: status,
            commissionRate: 10.0,
            registeredDate: item['createdAt'] != null
                ? item['createdAt'].toString().substring(0, 10)
                : 'Recent',
            isBranch: item['isBranch'] == true,
            parentTurfName: item['parentTurfName']?.toString(),
            parentTurfPhone: item['parentTurfPhone']?.toString(),
            alternativePhone: item['alternativePhone']?.toString(),
            photoUrls: photos,
            sports: sports,
          );
        }).toList();

        if (livePartners.isNotEmpty) {
          state = state.copyWith(partners: livePartners);
        }
      }
    } catch (e) {
      debugPrint('Error fetching super-admin registrations: $e');
    }
  }

  Future<bool> verifyPartnerRegistration(String partnerId) async {
    final partner = state.partners.firstWhere(
      (p) => p.id == partnerId,
      orElse: () => state.partners.first,
    );

    if (partner.rawId != null) {
      try {
        final res = await http.post(
          Uri.parse('${ApiConfig.baseUrl}/super-admin/registrations/${partner.rawId}/verify'),
          headers: {
            'x-admin-key': 'g24_super_admin_secret_2026',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({'verifiedBy': 'Super Admin'}),
        );

        if (res.statusCode == 200 || res.statusCode == 201) {
          await fetchRegistrationsFromBackend();
          return true;
        }
      } catch (e) {
        debugPrint('Error verifying partner in backend: $e');
      }
    }

    // Fallback local state update
    updatePartnerStatus(partnerId, AccountStatus.active);
    return true;
  }

  void updatePartnerStatus(String partnerId, AccountStatus newStatus) {
    final updated = state.partners.map((p) {
      if (p.id == partnerId) {
        return p.copyWith(status: newStatus);
      }
      return p;
    }).toList();
    state = state.copyWith(partners: updated);
  }

  void updateUserStatus(String userId, AccountStatus newStatus) {
    final updated = state.users.map((u) {
      if (u.id == userId) {
        return u.copyWith(status: newStatus);
      }
      return u;
    }).toList();
    state = state.copyWith(users: updated);
  }
}

class SuperAdminState {
  final List<PartnerOwnerModel> partners;
  final List<UserAccountModel> users;

  const SuperAdminState({
    required this.partners,
    required this.users,
  });

  SuperAdminState copyWith({
    List<PartnerOwnerModel>? partners,
    List<UserAccountModel>? users,
  }) {
    return SuperAdminState(
      partners: partners ?? this.partners,
      users: users ?? this.users,
    );
  }
}

final superAdminProvider =
    NotifierProvider<SuperAdminNotifier, SuperAdminState>(
  () => SuperAdminNotifier(),
);
