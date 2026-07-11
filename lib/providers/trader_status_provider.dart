import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:price_catalog_app/data/models/user_model.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';

// ═══════════════════════════════════════
// REAL-TIME TRADER STATUS WATCHER
// Jab admin approve kare, trader ko
// turant pata chale bina restart ke
// ═══════════════════════════════════════
class TraderStatusNotifier extends StateNotifier<TraderStatus?> {
  StreamSubscription<DocumentSnapshot>? _subscription;
  final Ref _ref;

  TraderStatusNotifier(this._ref) : super(null) {
    _startListening();
  }

  void _startListening() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Real-time listen to user document
    _subscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;

      final data = doc.data()!;
      final role = data['role'] as String?;

      // Only for traders
      if (role != 'trader') return;

      final statusStr = data['traderStatus'] as String?;
      if (statusStr == null) return;

      final newStatus = TraderStatus.values.firstWhere(
        (s) => s.name == statusStr,
        orElse: () => TraderStatus.pending,
      );

      // Status change detect karo
      if (state != newStatus) {
        state = newStatus;

        // Agar approved ho gaya to auth reload karo
        if (newStatus == TraderStatus.approved) {
          _onTraderApproved(doc);
        }
      }
    });
  }

  Future<void> _onTraderApproved(DocumentSnapshot doc) async {
    try {
      final user = UserModel.fromFirestore(doc);
      // Auth state update karo
      _ref.read(currentUserProvider.notifier).state = user;
    } catch (e) {
      // ignore
    }
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

final traderStatusProvider =
    StateNotifierProvider<TraderStatusNotifier, TraderStatus?>((ref) {
  return TraderStatusNotifier(ref);
});