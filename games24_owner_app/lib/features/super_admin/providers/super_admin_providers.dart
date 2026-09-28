import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AccountStatus { active, blocked, pending }

class PartnerOwnerModel {
  final String id;
  final String ownerName;
  final String turfName;
  final String area;
  final String phone;
  final String gstNumber;
  final AccountStatus status;
  final double commissionRate;
  final String registeredDate;

  const PartnerOwnerModel({
    required this.id,
    required this.ownerName,
    required this.turfName,
    required this.area,
    required this.phone,
    required this.gstNumber,
    required this.status,
    this.commissionRate = 10.0,
    required this.registeredDate,
  });

  PartnerOwnerModel copyWith({
    AccountStatus? status,
    double? commissionRate,
  }) {
    return PartnerOwnerModel(
      id: id,
      ownerName: ownerName,
      turfName: turfName,
      area: area,
      phone: phone,
      gstNumber: gstNumber,
      status: status ?? this.status,
      commissionRate: commissionRate ?? this.commissionRate,
      registeredDate: registeredDate,
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
    return SuperAdminState(
      partners: const [
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
        PartnerOwnerModel(
          id: 'p2',
          ownerName: 'Muruganandam K',
          turfName: 'Anna Nagar Sports City',
          area: 'Anna Nagar',
          phone: '+91 98765 22222',
          gstNumber: '33BBBBB1111B1Z2',
          status: AccountStatus.pending,
          commissionRate: 12.0,
          registeredDate: 'Yesterday',
        ),
        PartnerOwnerModel(
          id: 'p3',
          ownerName: 'Venkatesh S',
          turfName: 'Vaigai Box Cricket Club',
          area: 'Sellur',
          phone: '+91 98765 33333',
          gstNumber: '33CCCCC2222C1Z8',
          status: AccountStatus.blocked,
          commissionRate: 10.0,
          registeredDate: '01 Feb 2026',
        ),
      ],
      users: const [
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
        UserAccountModel(
          id: 'u3',
          name: 'Abusive User (Reported)',
          phone: '+91 90000 00000',
          area: 'Anna Nagar',
          totalBookings: 1,
          status: AccountStatus.blocked,
          joinedDate: 'Feb 2026',
        ),
      ],
    );
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
