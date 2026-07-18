import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:price_catalog_app/data/repositories/requirement_repository.dart';
import 'package:price_catalog_app/providers/auth_provider.dart';

// ═══════════════════════════════════════
// TRADER: SELECTED PRODUCTS FOR NEW REQUIREMENT (Multi-product)
// ═══════════════════════════════════════
final selectedRequirementItemsProvider =
    StateProvider<List<RequirementItemModel>>((ref) => []);

// ═══════════════════════════════════════
// REPOSITORY PROVIDER
// ═══════════════════════════════════════
final requirementRepositoryProvider = Provider<RequirementRepository>((ref) {
  return RequirementRepository();
});

// ═══════════════════════════════════════
// ADMIN - WATCH ALL REQUIREMENTS
// ═══════════════════════════════════════
final allRequirementsProvider = StreamProvider<List<RequirementModel>>((ref) {
  // Only admins may read all requirements — gate the listener on auth state
  // to avoid [cloud_firestore/permission-denied] stream errors.
  final auth = ref.watch(authStateProvider);
  if (auth is! AuthAuthenticatedAdmin) {
    return Stream.value(const []);
  }
  return ref.watch(requirementRepositoryProvider).watchAllRequirements();
});

// ═══════════════════════════════════════
// ADMIN - WATCH SINGLE REQUIREMENT (live updates)
// ═══════════════════════════════════════
final requirementByIdProvider =
    StreamProvider.family<RequirementModel?, String>((ref, requirementId) {
      return ref
          .watch(requirementRepositoryProvider)
          .watchRequirementById(requirementId);
    });

// ═══════════════════════════════════════
// ADMIN - WATCH BY STATUS
// ═══════════════════════════════════════
final requirementsByStatusProvider =
    StreamProvider.family<List<RequirementModel>, RequirementStatus>((
      ref,
      status,
    ) {
      final auth = ref.watch(authStateProvider);
      if (auth is! AuthAuthenticatedAdmin) {
        return Stream.value(const []);
      }
      return ref
          .watch(requirementRepositoryProvider)
          .watchAllRequirements(status: status);
    });

// ═══════════════════════════════════════
// ADMIN - PENDING COUNT
// ═══════════════════════════════════════
final pendingRequirementsCountProvider = StreamProvider<int>((ref) {
  final auth = ref.watch(authStateProvider);
  if (auth is! AuthAuthenticatedAdmin) {
    return Stream.value(0);
  }
  return ref.watch(requirementRepositoryProvider).watchPendingCount();
});

// ═══════════════════════════════════════
// TRADER - WATCH OWN REQUIREMENTS
// ═══════════════════════════════════════
final traderRequirementsProvider =
    StreamProvider.family<List<RequirementModel>, String>((ref, traderId) {
      return ref
          .watch(requirementRepositoryProvider)
          .watchTraderRequirements(traderId: traderId);
    });

// ═══════════════════════════════════════
// TRADER - WATCH BY STATUS
// ═══════════════════════════════════════
final traderRequirementsByStatusProvider =
    StreamProvider.family<
      List<RequirementModel>,
      ({String traderId, RequirementStatus status})
    >((ref, params) {
      return ref
          .watch(requirementRepositoryProvider)
          .watchTraderRequirements(
            traderId: params.traderId,
            status: params.status,
          );
    });

// ═══════════════════════════════════════
// REQUIREMENT ACTIONS NOTIFIER
// ═══════════════════════════════════════
class RequirementNotifier extends StateNotifier<AsyncValue<void>> {
  final RequirementRepository _repo;

  RequirementNotifier(this._repo) : super(const AsyncValue.data(null));

  // Submit Requirement
  Future<bool> submitRequirement({
    required String traderId,
    required String traderName,
    required String traderBusinessName,
    required String traderPhone,
    required String productId,
    required String productName,
    required String productCode,
    String? productImage,
    String? categoryName,
    required String customerName,
    required String customerPhone,
    required String customerBusinessName,
    required String customerCity,
    String? customerAddress,
    required double quantity,
    required String unit,
    required double productCurrentPrice,
    required double customerDemandedPrice,
    required double traderOfferedPrice,
    required PaymentType paymentType,
    int? creditDays,
    double? advanceAmount,
    DateTime? deliveryDate,
    String? deliveryLocation,
    String? traderNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.submitRequirement(
        traderId: traderId,
        traderName: traderName,
        traderBusinessName: traderBusinessName,
        traderPhone: traderPhone,
        productId: productId,
        productName: productName,
        productCode: productCode,
        productImage: productImage,
        categoryName: categoryName,
        customerName: customerName,
        customerPhone: customerPhone,
        customerBusinessName: customerBusinessName,
        customerCity: customerCity,
        customerAddress: customerAddress,
        quantity: quantity,
        unit: unit,
        productCurrentPrice: productCurrentPrice,
        customerDemandedPrice: customerDemandedPrice,
        traderOfferedPrice: traderOfferedPrice,
        paymentType: paymentType,
        creditDays: creditDays,
        advanceAmount: advanceAmount,
        deliveryDate: deliveryDate,
        deliveryLocation: deliveryLocation,
        traderNote: traderNote,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Submit Bulk Requirement (Multiple products)
  Future<bool> submitBulkRequirement({
    required String traderId,
    required String traderName,
    required String traderBusinessName,
    required String traderPhone,
    required List<RequirementItemModel> items,
    required String customerName,
    required String customerPhone,
    required String customerBusinessName,
    required String customerCity,
    String? customerAddress,
    required PaymentType paymentType,
    int? creditDays,
    double? advanceAmount,
    DateTime? deliveryDate,
    String? deliveryLocation,
    String? traderNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.submitBulkRequirements(
        traderId: traderId,
        traderName: traderName,
        traderBusinessName: traderBusinessName,
        traderPhone: traderPhone,
        items: items,
        customerName: customerName,
        customerPhone: customerPhone,
        customerBusinessName: customerBusinessName,
        customerCity: customerCity,
        customerAddress: customerAddress,
        paymentType: paymentType,
        creditDays: creditDays,
        advanceAmount: advanceAmount,
        deliveryDate: deliveryDate,
        deliveryLocation: deliveryLocation,
        traderNote: traderNote,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Approve
  Future<bool> approveRequirement({
    required String requirementId,
    required String traderId,
    required String productName,
    String? adminNote,
    double? finalPrice,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.approveRequirement(
        requirementId: requirementId,
        traderId: traderId,
        productName: productName,
        adminNote: adminNote,
        finalPrice: finalPrice,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Reject
  Future<bool> rejectRequirement({
    required String requirementId,
    required String traderId,
    required String productName,
    required String rejectionReason,
    String? adminNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.rejectRequirement(
        requirementId: requirementId,
        traderId: traderId,
        productName: productName,
        rejectionReason: rejectionReason,
        adminNote: adminNote,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Counter Offer
  Future<bool> sendCounterOffer({
    required String requirementId,
    required String traderId,
    required String productName,
    required double counterPrice,
    String? adminNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.sendCounterOffer(
        requirementId: requirementId,
        traderId: traderId,
        productName: productName,
        counterPrice: counterPrice,
        adminNote: adminNote,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Per-item action (approve / reject / counter a single product)
  Future<bool> updateItemStatus({
    required RequirementModel requirement,
    required int itemIndex,
    required RequirementStatus itemStatus,
    double? counterPrice,
    String? rejectionReason,
    String? adminNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateItemStatus(
        requirement: requirement,
        itemIndex: itemIndex,
        itemStatus: itemStatus,
        counterPrice: counterPrice,
        rejectionReason: rejectionReason,
        adminNote: adminNote,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Bulk action on all pending items (approve / reject / counter all)
  Future<bool> updateAllItemsStatus({
    required RequirementModel requirement,
    required RequirementStatus itemStatus,
    double? counterPrice,
    String? rejectionReason,
    String? adminNote,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.updateAllItemsStatus(
        requirement: requirement,
        itemStatus: itemStatus,
        counterPrice: counterPrice,
        rejectionReason: rejectionReason,
        adminNote: adminNote,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Accept Counter
  Future<bool> acceptCounterOffer(String requirementId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.acceptCounterOffer(requirementId: requirementId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  // Reject Counter
  Future<bool> rejectCounterOffer(String requirementId) async {
    state = const AsyncValue.loading();
    try {
      await _repo.rejectCounterOffer(requirementId: requirementId);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> acceptItemCounterOffer({
    required RequirementModel requirement,
    required int itemIndex,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.acceptItemCounterOffer(
        requirement: requirement,
        itemIndex: itemIndex,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> sendTraderItemCounterOffer({
    required RequirementModel requirement,
    required int itemIndex,
    required double counterPrice,
    String? note,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.sendTraderItemCounterOffer(
        requirement: requirement,
        itemIndex: itemIndex,
        counterPrice: counterPrice,
        note: note,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> rejectItemCounterOffer({
    required RequirementModel requirement,
    required int itemIndex,
    required String reason,
    required bool proceedWithRemaining,
  }) async {
    state = const AsyncValue.loading();
    try {
      await _repo.rejectItemCounterOffer(
        requirement: requirement,
        itemIndex: itemIndex,
        reason: reason,
        proceedWithRemaining: proceedWithRemaining,
      );
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  Future<bool> confirmPartialRequirement(RequirementModel requirement) async {
    state = const AsyncValue.loading();
    try {
      await _repo.confirmPartialRequirement(requirement);
      state = const AsyncValue.data(null);
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }
}

final requirementNotifierProvider =
    StateNotifierProvider<RequirementNotifier, AsyncValue<void>>((ref) {
      return RequirementNotifier(ref.watch(requirementRepositoryProvider));
    });
