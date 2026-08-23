import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:price_catalog_app/core/services/notification_service.dart';
import 'package:price_catalog_app/core/services/firebase_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:price_catalog_app/data/models/user_model.dart';

// ═══════════════════════════════════════
// AUTH STATE - Sealed class
// ═══════════════════════════════════════
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthPendingApproval extends AuthState {
  const AuthPendingApproval();
}

class AuthProfileIncomplete extends AuthState {
  const AuthProfileIncomplete();
}

class AuthAuthenticatedAdmin extends AuthState {
  final UserModel user;
  const AuthAuthenticatedAdmin(this.user);
}

class AuthAuthenticatedTrader extends AuthState {
  final UserModel user;
  const AuthAuthenticatedTrader(this.user);
}

// Extension for when() pattern
extension AuthStateX on AuthState {
  T when<T>({
    required T Function() initial,
    required T Function() loading,
    required T Function() unauthenticated,
    required T Function() pendingApproval,
    required T Function() profileIncomplete,
    required T Function(UserModel user) authenticatedAdmin,
    required T Function(UserModel user) authenticatedTrader,
  }) {
    return switch (this) {
      AuthInitial() => initial(),
      AuthLoading() => loading(),
      AuthUnauthenticated() => unauthenticated(),
      AuthPendingApproval() => pendingApproval(),
      AuthProfileIncomplete() => profileIncomplete(),
      AuthAuthenticatedAdmin(:final user) => authenticatedAdmin(user),
      AuthAuthenticatedTrader(:final user) => authenticatedTrader(user),
    };
  }
}

// ═══════════════════════════════════════
// CURRENT USER PROVIDER
// ═══════════════════════════════════════
final currentUserProvider = StateProvider<UserModel?>((ref) => null);

// ═══════════════════════════════════════
// AUTH STATE NOTIFIER
// ═══════════════════════════════════════
class AuthStateNotifier extends StateNotifier<AuthState> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Ref _ref;

  StreamController<AuthState> streamController =
      StreamController<AuthState>.broadcast();

  @override
  Stream<AuthState> get stream => streamController.stream;

  StreamSubscription<User?>? _authSubscription;

  // Flag to prevent auth listener from interfering during registration
  bool _isRegistering = false;

  AuthStateNotifier(this._ref) : super(const AuthInitial()) {
    _init();
  }

  // ═══════════════════════════════════════
  // INITIALIZE - Listen to auth changes
  // ═══════════════════════════════════════
  void _init() {
    _authSubscription = _auth.authStateChanges().listen((User? user) async {
      // Skip while registration is in progress to avoid race conditions
      if (_isRegistering) return;
      if (user == null) {
        _updateState(const AuthUnauthenticated());
      } else {
        await _loadUserData(user.uid);
      }
    });
  }

  Future<void> loadUserDataPublic(String uid) async {
    await _loadUserData(uid);
  }

  // Alternatively, seedha expose karo:
  Future<void> reloadUserData() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      await _loadUserData(uid);
    }
  }

  // ═══════════════════════════════════════
  // LOAD USER DATA FROM FIRESTORE
  // ═══════════════════════════════════════
  Future<void> _loadUserData(String uid) async {
    try {
      _updateState(const AuthLoading());

      final doc = await _firestore.collection('users').doc(uid).get();

      if (!doc.exists) {
        _updateState(const AuthProfileIncomplete());
        return;
      }

      final user = UserModel.fromFirestore(doc);

      // Save current user
      _ref.read(currentUserProvider.notifier).state = user;

      // Ensure user's FCM token (if available) is saved to their document.
      try {
        final token = await NotificationService.getFCMToken();
        if (token != null && token.isNotEmpty) {
          await FirebaseService.usersRef.doc(user.uid).update({
            'fcmToken': token,
          });
        }
      } catch (_) {}

      if (user.isAdmin) {
        _updateState(AuthAuthenticatedAdmin(user));
      } else if (user.isTrader) {
        if (user.traderStatus == TraderStatus.approved) {
          _updateState(AuthAuthenticatedTrader(user));
        } else if (user.traderStatus == TraderStatus.pending) {
          _updateState(const AuthPendingApproval());
        } else {
          // Blocked
          await _auth.signOut();
          _updateState(const AuthUnauthenticated());
        }
      }
    } catch (e, st) {
      // If loading user data fails, sign the user out and restart auth flow.
      debugPrint('Failed to load user data for auth state: $e\n$st');
      await _auth.signOut();
      _updateState(const AuthUnauthenticated());
    }
  }

  void _updateState(AuthState newState) {
    state = newState;
    streamController.add(newState);
  }

  // ═══════════════════════════════════════
  // LOGIN
  // ═══════════════════════════════════════
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      _updateState(const AuthLoading());

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      // Update last login
      final uid = _auth.currentUser?.uid;
      if (uid != null) {
        await _firestore.collection('users').doc(uid).update({
          'lastLogin': FieldValue.serverTimestamp(),
        });
      }

      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      _updateState(const AuthUnauthenticated());
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      _updateState(const AuthUnauthenticated());
      return AuthResult.error('Something went wrong. Please try again.');
    }
  }

  // ═══════════════════════════════════════
  // REGISTER TRADER
  // ═══════════════════════════════════════
  Future<AuthResult> registerTrader({
    required String name,
    required String phone,
    required String email,
    required String password,
    String? city,
  }) async {
    try {
      _isRegistering = true;
      _updateState(const AuthLoading());

      // Step 1: Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      // Step 2: Save user document to Firestore
      final user = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        businessName: '',
        role: UserRole.trader,
        traderStatus: TraderStatus.pending,
        city: city?.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(user.toFirestore());

      // Notify admin about new trader registration
      await _notifyAdminNewTrader(user);

      _isRegistering = false;
      _updateState(const AuthPendingApproval());
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      _isRegistering = false;
      _updateState(const AuthUnauthenticated());
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      _isRegistering = false;
      _updateState(const AuthUnauthenticated());
      return AuthResult.error('Registration failed. Please try again.');
    }
  }

  Future<AuthResult> registerAdmin({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    try {
      _isRegistering = true;
      _updateState(const AuthLoading());

      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;

      final user = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        businessName: 'Admin',
        role: UserRole.admin,
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(uid).set(user.toFirestore());

      _isRegistering = false;
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      _isRegistering = false;
      _updateState(const AuthUnauthenticated());
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      _isRegistering = false;
      _updateState(const AuthUnauthenticated());
      return AuthResult.error('Admin registration failed. Please try again.');
    }
  }

  Future<AuthResult> completeProfile({
    required String name,
    required String phone,
    required UserRole role,
    String? businessName,
    String? city,
    String? gstNumber,
  }) async {
    final currentUser = _auth.currentUser;
    if (currentUser == null) {
      return AuthResult.error(
        'Unable to complete profile. Please login again.',
      );
    }

    try {
      _updateState(const AuthLoading());

      final user = UserModel(
        uid: currentUser.uid,
        name: name.trim(),
        email: currentUser.email ?? '',
        phone: phone.trim(),
        businessName: role == UserRole.admin
            ? 'Admin'
            : (businessName?.trim() ?? ''),
        role: role,
        traderStatus: role == UserRole.trader ? TraderStatus.pending : null,
        city: city?.trim(),
        gstNumber: gstNumber?.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(user.toFirestore());

      if (role == UserRole.admin) {
        _updateState(AuthAuthenticatedAdmin(user));
      } else {
        _updateState(const AuthPendingApproval());
      }

      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      _updateState(const AuthUnauthenticated());
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      _updateState(const AuthUnauthenticated());
      return AuthResult.error('Profile setup failed. Please try again.');
    }
  }

  Future<AuthResult> updateProfile({
    required String name,
    required String phone,
    String? businessName,
    String? city,
    String? gstNumber,
  }) async {
    final currentUser = _ref.read(currentUserProvider);
    if (currentUser == null) {
      return AuthResult.error('Please login again.');
    }

    try {
      // Do not set global AuthLoading here — the UI shows a local loader.
      // Setting global loading can trigger router redirects or splash
      // because the auth state changes briefly. Avoid that.

      final updatedUser = currentUser.copyWith(
        name: name.trim(),
        phone: phone.trim(),
        businessName: businessName?.trim(),
        city: city?.trim(),
        gstNumber: gstNumber?.trim(),
      );

      await _firestore.collection('users').doc(currentUser.uid).update({
        'name': updatedUser.name,
        'phone': updatedUser.phone,
        'businessName': updatedUser.businessName,
        'city': updatedUser.city,
        'gstNumber': updatedUser.gstNumber,
      });

      _ref.read(currentUserProvider.notifier).state = updatedUser;

      final currentState = state;
      if (currentState is AuthAuthenticatedAdmin) {
        _updateState(AuthAuthenticatedAdmin(updatedUser));
      } else if (currentState is AuthAuthenticatedTrader) {
        _updateState(AuthAuthenticatedTrader(updatedUser));
      } else {
        _updateState(currentState);
      }

      return const AuthResult.success();
    } catch (e) {
      // Don't log out the user on update failure - restore the previous state
      final currentState = state;
      if (currentState is AuthAuthenticatedAdmin) {
        _updateState(AuthAuthenticatedAdmin(currentUser));
      } else if (currentState is AuthAuthenticatedTrader) {
        _updateState(AuthAuthenticatedTrader(currentUser));
      } else {
        _updateState(currentState);
      }
      return AuthResult.error('Unable to update profile. Please try again.');
    }
  }

  // ═══════════════════════════════════════
  // LOGOUT
  // ═══════════════════════════════════════
  Future<void> logout() async {
    try {
      await _auth.signOut();
      _ref.read(currentUserProvider.notifier).state = null;
      _updateState(const AuthUnauthenticated());
    } catch (e) {
      _updateState(const AuthUnauthenticated());
    }
  }

  Future<AuthResult> deleteAccount({String? password}) async {
    final user = _auth.currentUser;
    if (user == null) {
      return const AuthResult.error('No user is currently signed in.');
    }

    try {
      if (password != null && password.isNotEmpty && user.email != null) {
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user.reauthenticateWithCredential(credential);
      }

      final notificationSnapshot = await _firestore
          .collection('notifications')
          .doc(user.uid)
          .collection('items')
          .get();
      if (notificationSnapshot.docs.isNotEmpty) {
        final batch = _firestore.batch();
        for (final notification in notificationSnapshot.docs) {
          batch.delete(notification.reference);
        }
        await batch.commit();
      }

      for (final path in [
        'users/${user.uid}',
        'trader_documents/${user.uid}',
        'traders/${user.uid}/catalog',
        'exports/${user.uid}',
      ]) {
        try {
          final listing = await FirebaseService.storage.ref(path).listAll();
          for (final file in listing.items) {
            await file.delete();
          }
        } catch (_) {
          // A missing or already-cleaned storage folder should not block deletion.
        }
      }

      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
      _ref.read(currentUserProvider.notifier).state = null;
      _updateState(const AuthUnauthenticated());
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        return const AuthResult.error(
          'For your security, please log out, log in again, and retry account deletion.',
        );
      }
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
      return const AuthResult.error(
        'Unable to delete your account right now. Please try again.',
      );
    }
  }

  // ═══════════════════════════════════════
  // FORGOT PASSWORD
  // ═══════════════════════════════════════
  Future<AuthResult> forgotPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      return AuthResult.error(_getAuthErrorMessage(e.code));
    }
  }

  // ═══════════════════════════════════════
  // CHANGE PASSWORD
  // ═══════════════════════════════════════
  Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return const AuthResult.error('No user logged in.');
      }

      final email = user.email;
      if (email == null) {
        return const AuthResult.error('User email not found.');
      }

      // Re-authenticate with current password
      final credential = EmailAuthProvider.credential(
        email: email,
        password: currentPassword,
      );

      try {
        await user.reauthenticateWithCredential(credential);
      } on FirebaseAuthException catch (e) {
        if (e.code == 'wrong-password') {
          return const AuthResult.error('Current password is incorrect.');
        }
        return AuthResult.error(_getAuthErrorMessage(e.code));
      }

      // Update password
      try {
        await user.updatePassword(newPassword);

        // Sign out the user after password change
        await logout();

        return const AuthResult.success();
      } on FirebaseAuthException catch (e) {
        return AuthResult.error(_getAuthErrorMessage(e.code));
      }
    } catch (e) {
      return const AuthResult.error(
        'Failed to change password. Please try again.',
      );
    }
  }

  // ═══════════════════════════════════════
  // NOTIFY ADMIN - New trader registered
  // ═══════════════════════════════════════
  Future<void> _notifyAdminNewTrader(UserModel trader) async {
    try {
      // Get admin users
      final adminQuery = await _firestore
          .collection('users')
          .where('role', isEqualTo: 'admin')
          .get();

      for (final adminDoc in adminQuery.docs) {
        await _firestore
            .collection('notifications')
            .doc(adminDoc.id)
            .collection('items')
            .add({
              'title': 'New Trader Registration',
              'message': '${trader.name} wants to join. Please review.',
              'type': 'new_trader',
              'traderId': trader.uid,
              'traderName': trader.name,
              'read': false,
              'createdAt': FieldValue.serverTimestamp(),
            });
      }
    } catch (e) {
      // Silently fail notification
    }
  }

  // ═══════════════════════════════════════
  // ERROR MESSAGES
  // ═══════════════════════════════════════
  String _getAuthErrorMessage(String code) {
    return switch (code) {
      'user-not-found' => 'No account found with this email.',
      'wrong-password' => 'Incorrect password. Please try again.',
      'email-already-in-use' => 'This email is already registered.',
      'weak-password' => 'Password should be at least 6 characters.',
      'invalid-email' => 'Please enter a valid email address.',
      'user-disabled' => 'Your account has been disabled.',
      'too-many-requests' => 'Too many attempts. Please try again later.',
      'network-request-failed' => 'No internet connection.',
      'invalid-credential' => 'Invalid email or password.',
      _ => 'Authentication failed. Please try again.',
    };
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    streamController.close();
    super.dispose();
  }
}

// ═══════════════════════════════════════
// AUTH RESULT
// ═══════════════════════════════════════
class AuthResult {
  final bool isSuccess;
  final String? errorMessage;

  const AuthResult.success() : isSuccess = true, errorMessage = null;

  const AuthResult.error(this.errorMessage) : isSuccess = false;
}

// ═══════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AuthState>((
  ref,
) {
  return AuthStateNotifier(ref);
});
