import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:price_catalog_app/data/models/order_model.dart';
import 'package:price_catalog_app/data/repositories/order_repository.dart';

// ═══════════════════════════════════════
// REPOSITORY
// ═══════════════════════════════════════
final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

// ═══════════════════════════════════════
// ADMIN: ALL ORDERS
// ═══════════════════════════════════════
final allOrdersProvider = StreamProvider<List<OrderModel>>((ref) {
  return ref.watch(orderRepositoryProvider).watchAllOrders();
});

// ═══════════════════════════════════════
// ADMIN: ORDERS BY STATUS
// ═══════════════════════════════════════
final ordersByStatusProvider =
    StreamProvider.family<List<OrderModel>, OrderStatus>(
        (ref, status) {
  return ref.watch(orderRepositoryProvider).watchAllOrders(
        status: status,
      );
});

// ═══════════════════════════════════════
// ADMIN: PENDING COUNT
// ═══════════════════════════════════════
final pendingOrdersCountProvider = StreamProvider<int>((ref) {
  return ref.watch(orderRepositoryProvider).watchPendingOrderCount();
});

// ═══════════════════════════════════════
// TRADER: MY ORDERS
// ═══════════════════════════════════════
final traderOrdersProvider =
    StreamProvider.family<List<OrderModel>, String>(
        (ref, traderId) {
  return ref.watch(orderRepositoryProvider).watchTraderOrders(
        traderId: traderId,
      );
});

// ═══════════════════════════════════════
// TRADER: SELECTED PRODUCTS FOR NEW ORDER
// ═══════════════════════════════════════
final selectedOrderItemsProvider =
    StateProvider<List<OrderItemModel>>((ref) => []);