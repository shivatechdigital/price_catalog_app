import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:price_catalog_app/core/services/firebase_service.dart';
import 'package:price_catalog_app/data/models/app_settings_model.dart';
import 'package:price_catalog_app/data/models/user_model.dart';

// ═══════════════════════════════════════
// RUN THIS ONCE TO SETUP INITIAL DATA
// ═══════════════════════════════════════
class FirebaseInitService {
  // Create admin account (run once)
  static Future<void> createAdminAccount({
    required String email,
    required String password,
    required String name,
    required String businessName,
    required String phone,
  }) async {
    try {
      // Create auth user
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = credential.user!.uid;

      // Create admin document
      final admin = UserModel(
        uid: uid,
        name: name,
        email: email,
        phone: phone,
        businessName: businessName,
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

      await FirebaseService.usersRef
          .doc(uid)
          .set(admin.toFirestore());

      // Create default app settings
      await _createDefaultSettings();

      // Create sample categories
      await _createSampleCategories(uid);

      print('✅ Admin account created successfully!');
    } catch (e) {
      print('❌ Error creating admin: $e');
    }
  }

  static Future<void> _createDefaultSettings() async {
    final settings = AppSettingsModel.defaults();
    await FirebaseService.appSettingsRef
        .set(settings.toFirestore());
  }

  static Future<void> _createSampleCategories(String adminId) async {
    final categories = [
      {
        'name': 'Iron & Steel',
        'description': 'All iron and steel products',
        'icon': '🔩',
        'sortOrder': 1,
        'isActive': true,
        'productCount': 0,
        'createdBy': adminId,
        'createdAt': FieldValue.serverTimestamp(),
        'subCategories': [
          {'id': 'sub1', 'name': 'TMT Bar / Sariya', 'icon': '🔧'},
          {'id': 'sub2', 'name': 'Sheet / Plate', 'icon': '📄'},
          {'id': 'sub3', 'name': 'Pipe & Tube', 'icon': '⚙️'},
          {'id': 'sub4', 'name': 'Angle & Channel', 'icon': '📐'},
        ],
      },
      {
        'name': 'Cement & Building',
        'description': 'Cement and construction materials',
        'icon': '🏗️',
        'sortOrder': 2,
        'isActive': true,
        'productCount': 0,
        'createdBy': adminId,
        'createdAt': FieldValue.serverTimestamp(),
        'subCategories': [
          {'id': 'sub5', 'name': 'Cement Bags', 'icon': '🏺'},
          {'id': 'sub6', 'name': 'Sand & Aggregate', 'icon': '🪨'},
        ],
      },
      {
        'name': 'Electrical',
        'description': 'Electrical products and wiring',
        'icon': '⚡',
        'sortOrder': 3,
        'isActive': true,
        'productCount': 0,
        'createdBy': adminId,
        'createdAt': FieldValue.serverTimestamp(),
        'subCategories': [
          {'id': 'sub7', 'name': 'Cables & Wires', 'icon': '🔌'},
          {'id': 'sub8', 'name': 'Switches', 'icon': '🔦'},
        ],
      },
    ];

    for (final category in categories) {
      await FirebaseService.categoriesRef.add(category);
    }

    print('✅ Sample categories created!');
  }
}