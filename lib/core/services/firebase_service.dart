import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

// ═══════════════════════════════════════
// FIREBASE SERVICE - Central access point
// ═══════════════════════════════════════
class FirebaseService {
  FirebaseService._();

  // Instances
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore firestore = FirebaseFirestore.instance;
  static final FirebaseStorage storage = FirebaseStorage.instance;

  // ═══════════════════════════════════════
  // COLLECTION REFERENCES
  // ═══════════════════════════════════════

  // Users
  static CollectionReference<Map<String, dynamic>> get usersRef =>
      firestore.collection('users');

  // Categories
  static CollectionReference<Map<String, dynamic>> get categoriesRef =>
      firestore.collection('categories');

  // Products
  static CollectionReference<Map<String, dynamic>> get productsRef =>
      firestore.collection('products');

  // Requirements
  static CollectionReference<Map<String, dynamic>> get requirementsRef =>
      firestore.collection('requirements');

  // App Settings
  static DocumentReference<Map<String, dynamic>> get appSettingsRef =>
      firestore.collection('app_settings').doc('general');

  // Price History subcollection
  static CollectionReference<Map<String, dynamic>> priceHistoryRef(
      String productId) {
    return firestore
        .collection('price_history')
        .doc(productId)
        .collection('history');
  }

  // Notifications subcollection
  static CollectionReference<Map<String, dynamic>> notificationsRef(
      String userId) {
    return firestore
        .collection('notifications')
        .doc(userId)
        .collection('items');
  }

  // ═══════════════════════════════════════
  // STORAGE REFERENCES
  // ═══════════════════════════════════════

  static Reference productImagesRef(String productId, String fileName) =>
      storage.ref('products/$productId/$fileName');

  static Reference userProfileRef(String userId, String fileName) =>
      storage.ref('users/$userId/$fileName');

  static Reference settingsRef(String fileName) =>
      storage.ref('settings/$fileName');

  static Reference catalogRef(String userId, String fileName) =>
      storage.ref('catalogs/$userId/$fileName');

  // ═══════════════════════════════════════
  // CURRENT USER
  // ═══════════════════════════════════════
  static User? get currentUser => auth.currentUser;
  static String? get currentUserId => auth.currentUser?.uid;
}

// ═══════════════════════════════════════
// FIRESTORE COLLECTION NAMES
// ═══════════════════════════════════════
class FirestoreCollections {
  FirestoreCollections._();

  static const String users = 'users';
  static const String categories = 'categories';
  static const String products = 'products';
  static const String requirements = 'requirements';
  static const String priceHistory = 'price_history';
  static const String notifications = 'notifications';
  static const String appSettings = 'app_settings';

  // Subcollections
  static const String historySubcollection = 'history';
  static const String itemsSubcollection = 'items';
}