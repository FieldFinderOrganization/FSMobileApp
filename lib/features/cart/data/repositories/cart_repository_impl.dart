import '../../domain/entities/cart_entity.dart';
import '../../domain/repositories/cart_repository.dart';
import '../datasources/cart_remote_data_source.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource _dataSource;

  CartRepositoryImpl(this._dataSource);

  @override
  Future<CartEntity> getCart() => _dataSource.getCart();

  @override
  Future<void> addItem(int productId, String size, int quantity) =>
      _dataSource.addItem(productId, size, quantity);

  @override
  Future<void> updateItem(int productId, String size, int quantity) =>
      _dataSource.updateItem(productId, size, quantity);

  @override
  Future<void> removeItem(int productId, String size) =>
      _dataSource.removeItem(productId, size);

  @override
  Future<void> clearCart() => _dataSource.clearCart();
}
