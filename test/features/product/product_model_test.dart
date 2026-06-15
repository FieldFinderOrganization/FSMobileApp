import 'package:flutter_test/flutter_test.dart';
import 'package:fsmobileapp/features/product/data/models/product_model.dart';

// Sản phẩm là kết quả trả về của image-search & gợi ý. fromJson phải chịu được
// payload thiếu trường / kiểu lệch mà không ném lỗi (mất 1 card = hỏng cả lưới).
void main() {
  group('ProductModel.fromJson', () {
    test('payload đầy đủ → ánh xạ đúng mọi trường', () {
      final m = ProductModel.fromJson({
        'id': 42,
        'name': 'Áo bóng đá',
        'description': 'mô tả',
        'categoryName': 'Áo',
        'price': 250000,
        'salePercent': 10,
        'salePrice': 225000,
        'imageUrl': 'http://img/1.jpg',
        'brand': 'Nike',
        'sex': 'MALE',
        'tags': ['đỏ', 'sân 5'],
        'totalSold': 7,
        'variants': [
          {'size': 'M', 'quantity': 3, 'stockTotal': 10},
        ],
        'appliedDiscountCodes': ['SALE10'],
        'categoryId': 5,
        'availableGlobalCodes': ['FREESHIP'],
      });

      expect(m.id, '42'); // id số → chuỗi
      expect(m.name, 'Áo bóng đá');
      expect(m.price, 250000.0);
      expect(m.salePrice, 225000.0);
      expect(m.salePercent, 10);
      expect(m.tags, ['đỏ', 'sân 5']);
      expect(m.variants.length, 1);
      expect(m.variants.first.size, 'M');
      expect(m.variants.first.quantity, 3);
      expect(m.categoryId, 5);
      expect(m.availableGlobalCodes, ['FREESHIP']);
    });

    test('payload tối thiểu (chỉ id) → dùng default, không ném', () {
      final m = ProductModel.fromJson({'id': 'p1'});

      expect(m.id, 'p1');
      expect(m.name, '');
      expect(m.price, 0.0);
      expect(m.salePrice, isNull);
      expect(m.salePercent, isNull);
      expect(m.tags, isEmpty);
      expect(m.variants, isEmpty);
      expect(m.availableGlobalCodes, isEmpty);
      expect(m.appliedDiscountCodes, isNull);
    });

    test('price kiểu int và double đều ép về double', () {
      expect(ProductModel.fromJson({'price': 100}).price, 100.0);
      expect(ProductModel.fromJson({'price': 99.5}).price, 99.5);
    });

    test('salePrice null khi không có sale', () {
      final m = ProductModel.fromJson({'id': '1', 'price': 100});
      expect(m.salePrice, isNull);
    });

    test('variants lồng nhau parse từng phần tử với default', () {
      final m = ProductModel.fromJson({
        'id': '1',
        'variants': [
          {'size': 'L'}, // thiếu quantity/stockTotal
          {'size': 'XL', 'quantity': 2, 'stockTotal': 5},
        ],
      });
      expect(m.variants.length, 2);
      expect(m.variants[0].quantity, 0);
      expect(m.variants[0].stockTotal, 0);
      expect(m.variants[1].quantity, 2);
    });
  });
}
