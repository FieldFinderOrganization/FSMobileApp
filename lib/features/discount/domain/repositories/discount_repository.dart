import '../entities/admin_discount_entity.dart';
import '../entities/user_discount_entity.dart';

abstract class DiscountRepository {
  Future<List<UserDiscountEntity>> getWallet(String userId);
  Future<List<AdminDiscountEntity>> getAllDiscounts();
  Future<AdminDiscountEntity> createDiscount(Map<String, dynamic> body);
  Future<AdminDiscountEntity> updateDiscount(String id, Map<String, dynamic> body);
  Future<AdminDiscountEntity> toggleStatus(String id, String status);
  Future<void> assignToUsers(String id, List<String> userIds);
  Future<void> deleteDiscount(String id);
}
