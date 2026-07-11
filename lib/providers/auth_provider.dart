import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  AuthStateNotifier(this._ref) : super(const AuthInitial()) {
    _init();
  }

  // ═══════════════════════════════════════
  // INITIALIZE - Listen to auth changes
  // ═══════════════════════════════════════
  void _init() {
    _authSubscription = _auth.authStateChanges().listen((User? user) async {
      if (user == null) {
        _updateState(const AuthUnauthenticated());
      } else {
        await _loadUserData(user.uid);
      }
    });
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
      _updateState(const AuthLoading());

      // Create Firebase Auth user
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final uid = credential.user!.uid;
      // Create user document in Firestore
      final user = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        phone: phone.trim(),
        businessName: '',
        role: UserRole.trader,
        traderStatus: TraderStatus.pending, // Pending by default
        city: city?.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore
          .collection('users')
          .doc(uid)
          .set(user.toFirestore());

      // Notify admin about new trader registration
      await _notifyAdminNewTrader(user);

      _updateState(const AuthPendingApproval());
      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      _updateState(const AuthUnauthenticated());
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
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

      return const AuthResult.success();
    } on FirebaseAuthException catch (e) {
      _updateState(const AuthUnauthenticated());
      return AuthResult.error(_getAuthErrorMessage(e.code));
    } catch (e) {
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
      return AuthResult.error('Unable to complete profile. Please login again.');
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
        traderStatus:
            role == UserRole.trader ? TraderStatus.pending : null,
        city: city?.trim(),
        gstNumber: gstNumber?.trim(),
        createdAt: DateTime.now(),
      );

      await _firestore.collection('users').doc(currentUser.uid).set(
            user.toFirestore(),
          );

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
          'message':
              '${trader.name} wants to join. Please review.',
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

  const AuthResult.success()
      : isSuccess = true,
        errorMessage = null;

  const AuthResult.error(this.errorMessage) : isSuccess = false;
}

// ═══════════════════════════════════════
// PROVIDERS
// ═══════════════════════════════════════
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AuthState>((ref) {
  return AuthStateNotifier(ref);
});