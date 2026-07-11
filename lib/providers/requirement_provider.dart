import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:price_catalog_app/data/models/requirement_model.dart';
import 'package:price_catalog_app/data/repositories/requirement_repository.dart';

// ═══════════════════════════════════════
// REPOSITORY PROVIDER
// ═══════════════════════════════════════
final requirementRepositoryProvider =
    Provider<RequirementRepository>((ref) {
  return RequirementRepository();
});

// ═══════════════════════════════════════
// ADMIN - WATCH ALL REQUIREMENTS
// ═══════════════════════════════════════
final allRequirementsProvider =
    StreamProvider<List<RequirementModel>>((ref) {
  return ref
      .watch(requirementRepositoryProvider)
      .watchAllRequirements();
});

// ═══════════════════════════════════════
// ADMIN - WATCH BY STATUS
// ═══════════════════════════════════════
final requirementsByStatusProvider =
    StreamProvider.family<List<RequirementModel>, RequirementStatus>(
        (ref, status) {
  return ref
      .watch(requirementRepositoryProvider)
      .watchAllRequirements(status: status);
});

// ═══════════════════════════════════════
// ADMIN - PENDING COUNT
// ═══════════════════════════════════════
final pendingRequirementsCountProvider = StreamProvider<int>((ref) {
  return ref.watch(requirementRepositoryProvider).watchPendingCount();
});

// ═══════════════════════════════════════
// TRADER - WATCH OWN REQUIREMENTS
// ═══════════════════════════════════════
final traderRequirementsProvider =
    StreamProvider.family<List<RequirementModel>, String>(
        (ref, traderId) {
  return ref
      .watch(requirementRepositoryProvider)
      .watchTraderRequirements(traderId: traderId);
});

// ═══════════════════════════════════════
// TRADER - WATCH BY STATUS
// ═══════════════════════════════════════
final traderRequirementsByStatusProvider = StreamProvider.family<
    List<RequirementModel>,
    ({String traderId, RequirementStatus status})>((ref, params) {
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
}

final requirementNotifierProvider =
    StateNotifierProvider<RequirementNotifier, AsyncValue<void>>((ref) {
  return RequirementNotifier(ref.watch(requirementRepositoryProvider));
});