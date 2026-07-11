import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { admin, trader }
enum TraderStatus { pending, approved, blocked }

class UserModel {
  final String uid;
  final String name;
  final String email;
  final String phone;
  final String businessName;
  final UserRole role;
  final TraderStatus? traderStatus;
  final String? profileImage;
  final String? fcmToken;
  final String? city;
  final String? gstNumber;
  final DateTime createdAt;
  final DateTime? lastLogin;

  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.phone,
    required this.businessName,
    required this.role,
    this.traderStatus,
    this.profileImage,
    this.fcmToken,
    this.city,
    this.gstNumber,
    required this.createdAt,
    this.lastLogin,
  });

  bool get isAdmin => role == UserRole.admin;
  bool get isTrader => role == UserRole.trader;
  bool get isApproved => traderStatus == TraderStatus.approved;

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
      phone: data['phone'] ?? '',
      businessName: data['businessName'] ?? '',
      role: UserRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => UserRole.trader,
      ),
      traderStatus: data['traderStatus'] != null
          ? TraderStatus.values.firstWhere(
              (s) => s.name == data['traderStatus'],
              orElse: () => TraderStatus.pending,
            )
          : null,
      profileImage: data['profileImage'],
      fcmToken: data['fcmToken'],
      city: data['city'],
      gstNumber: data['gstNumber'],
      createdAt: data['createdAt'] is Timestamp
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      lastLogin: data['lastLogin'] != null
          ? (data['lastLogin'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'email': email,
      'phone': phone,
      'businessName': businessName,
      'role': role.name,
      'traderStatus': traderStatus?.name,
      'profileImage': profileImage,
      'fcmToken': fcmToken,
      'city': city,
      'gstNumber': gstNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': lastLogin != null ? Timestamp.fromDate(lastLogin!) : null,
    };
  }

  UserModel copyWith({
    String? name,
    String? phone,
    String? businessName,
    TraderStatus? traderStatus,
    String? profileImage,
    String? fcmToken,
    String? city,
    String? gstNumber,
    DateTime? lastLogin,
  }) {
    return UserModel(
      uid: uid,
      name: name ?? this.name,
      email: email,
      phone: phone ?? this.phone,
      businessName: businessName ?? this.businessName,
      role: role,
      traderStatus: traderStatus ?? this.traderStatus,
      profileImage: profileImage ?? this.profileImage,
      fcmToken: fcmToken ?? this.fcmToken,
      city: city ?? this.city,
      gstNumber: gstNumber ?? this.gstNumber,
      createdAt: createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
    );
  }
}