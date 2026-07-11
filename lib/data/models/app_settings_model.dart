import 'package:cloud_firestore/cloud_firestore.dart';

class AppSettingsModel {
  final String appName;
  final String companyName;
  final String? companyLogo;
  final String contactPhone;
  final String contactEmail;
  final String address;
  final String? gstNumber;
  final String currency;
  final DateTime updatedAt;

  const AppSettingsModel({
    required this.appName,
    required this.companyName,
    this.companyLogo,
    required this.contactPhone,
    required this.contactEmail,
    required this.address,
    this.gstNumber,
    required this.currency,
    required this.updatedAt,
  });

  factory AppSettingsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AppSettingsModel(
      appName: data['appName'] ?? 'PriceCatalog',
      companyName: data['companyName'] ?? '',
      companyLogo: data['companyLogo'],
      contactPhone: data['contactPhone'] ?? '',
      contactEmail: data['contactEmail'] ?? '',
      address: data['address'] ?? '',
      gstNumber: data['gstNumber'],
      currency: data['currency'] ?? '₹',
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'appName': appName,
      'companyName': companyName,
      'companyLogo': companyLogo,
      'contactPhone': contactPhone,
      'contactEmail': contactEmail,
      'address': address,
      'gstNumber': gstNumber,
      'currency': currency,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  // Default settings
  factory AppSettingsModel.defaults() {
    return AppSettingsModel(
      appName: 'PriceCatalog',
      companyName: 'Your Company Name',
      contactPhone: '',
      contactEmail: '',
      address: '',
      currency: '₹',
      updatedAt: DateTime.now(),
    );
  }
}