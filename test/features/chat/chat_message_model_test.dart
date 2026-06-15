import 'package:flutter_test/flutter_test.dart';
import 'package:fsmobileapp/features/chat/data/models/chat_message_model.dart';

// Lịch sử chat cá nhân hóa lưu local (toJson) rồi nạp lại (fromJson). aiData chứa
// payload thẻ sản phẩm/đặt sân/QR → phải sống sót qua vòng encode/decode (jsonEncode lồng).
void main() {
  group('ChatMessageModel round-trip', () {
    test('tin nhắn AI có aiData (thẻ sản phẩm) giữ nguyên qua toJson/fromJson', () {
      final original = ChatMessageModel(
        id: 'm1',
        content: 'Gợi ý cho bạn',
        isUser: false,
        isImage: false,
        createdAt: DateTime.parse('2026-06-15T10:00:00.000'),
        aiData: const {
          'action': 'show_products',
          'products': [
            {'id': '42', 'name': 'Áo Nike'},
          ],
        },
      );

      final restored = ChatMessageModel.fromJson(original.toJson());

      expect(restored.id, 'm1');
      expect(restored.content, 'Gợi ý cho bạn');
      expect(restored.isUser, false);
      expect(restored.createdAt, original.createdAt);
      expect(restored.aiData, isNotNull);
      expect(restored.aiData!['action'], 'show_products');
      expect((restored.aiData!['products'] as List).first['id'], '42');
    });

    test('tin nhắn user gửi ảnh (imagePath, không aiData)', () {
      final original = ChatMessageModel(
        id: 'm2',
        content: '',
        isUser: true,
        isImage: true,
        imagePath: '/tmp/photo.jpg',
        createdAt: DateTime.parse('2026-06-15T11:30:00.000'),
      );

      final restored = ChatMessageModel.fromJson(original.toJson());

      expect(restored.isUser, true);
      expect(restored.isImage, true);
      expect(restored.imagePath, '/tmp/photo.jpg');
      expect(restored.aiData, isNull);
    });

    test('aiData null → toJson lưu null, fromJson đọc lại null (không ném)', () {
      final json = ChatMessageModel(
        id: 'm3',
        content: 'hi',
        isUser: true,
        isImage: false,
        createdAt: DateTime.parse('2026-06-15T12:00:00.000'),
      ).toJson();

      expect(json['aiData'], isNull);
      expect(ChatMessageModel.fromJson(json).aiData, isNull);
    });
  });
}
