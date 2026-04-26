import '../../domain/entities/admin_discount_entity.dart';
import '../../domain/entities/user_discount_entity.dart';
import '../../domain/repositories/discount_repository.dart';
import '../datasources/discount_remote_data_source.dart';

class DiscountRepositoryImpl implements DiscountRepository {
  final DiscountRemoteDataSource _dataSource;

  DiscountRepositoryImpl(this._dataSource);

  @override
  Future<List<UserDiscountEntity>> getWallet(String userId) =>
      _dataSource.getWallet(userId);

  @override
  Future<List<AdminDiscountEntity>> getAllDiscounts() =>
      _dataSource.getAllDiscounts();

  @override
  Future<AdminDiscountEntity> createDiscount(Map<String, dynamic> body) =>
      _dataSource.createDiscount(body);

  @override
  Future<AdminDiscountEntity> updateDiscount(
          String id, Map<String, dynamic> body) =>
      _dataSource.updateDiscount(id, body);

  @override
  Future<AdminDiscountEntity> toggleStatus(String id, String status) =>
      _dataSource.toggleStatus(id, status);

  @override
  Future<void> assignToUsers(String id, List<String> userIds) =>
      _dataSource.assignToUsers(id, userIds);

  @override
  Future<void> deleteDiscount(String id) => _dataSource.deleteDiscount(id);
}
