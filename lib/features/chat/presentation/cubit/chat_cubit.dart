import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/location/location_helper.dart';
import '../../../pitch/data/datasources/booking_remote_datasource.dart';
import '../../../pitch/data/datasources/payment_remote_datasource.dart';
import '../../../pitch/data/models/booking_request_model.dart';
import '../../../pitch/data/models/payment_request_model.dart';
import '../../../pitch/data/models/payment_response_model.dart';
import '../../data/datasources/ai_chat_remote_datasource.dart';
import '../../data/datasources/chat_local_datasource.dart';
import '../../data/models/chat_message_model.dart';
import '../../data/models/chat_session_model.dart';
import 'chat_state.dart';

String _generateId() {
  final rand = Random.secure();
  final bytes = List<int>.generate(16, (_) => rand.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  final h = bytes.map(hex).join();
  return '${h.substring(0, 8)}-${h.substring(8, 12)}-${h.substring(12, 16)}-${h.substring(16, 20)}-${h.substring(20)}';
}

class ChatCubit extends Cubit<ChatState> {
  final AIChatRemoteDatasource remoteDatasource;
  final ChatLocalDatasource localDatasource;
  final PaymentRemoteDataSource paymentDatasource;
  final BookingRemoteDataSource bookingDatasource;

  ChatCubit({
    required this.remoteDatasource,
    required this.localDatasource,
    required this.paymentDatasource,
    required this.bookingDatasource,
  }) : super(const ChatInitial());

  Future<void> loadSessions() async {
    final sessions = await localDatasource.getSessions();
    emit(ChatSessionListLoaded(sessions));
  }

  Future<void> createSession() async {
    final now = DateTime.now();
    final session = ChatSessionModel(
      sessionId: _generateId(),
      title: 'Cuộc trò chuyện mới',
      createdAt: now,
      updatedAt: now,
      messages: [],
    );
    await localDatasource.saveSession(session);
    emit(ChatSessionOpen(session: session));
  }

  Future<void> openSession(String sessionId) async {
    final sessions = await localDatasource.getSessions();
    final session = sessions.firstWhere((s) => s.sessionId == sessionId);
    emit(ChatSessionOpen(session: session));
  }

  Future<void> deleteSession(String sessionId) async {
    await localDatasource.deleteSession(sessionId);
    await loadSessions();
  }

  Future<void> sendMessage(String text) async {
    final current = state;
    if (current is! ChatSessionOpen || current.isLoading) return;

    final userMsg = ChatMessageModel(
      id: _generateId(),
      content: text,
      isUser: true,
      isImage: false,
      createdAt: DateTime.now(),
    );

    final updatedMessages = [...current.session.messages, userMsg];
    final isFirstMessage = current.session.messages.isEmpty;
    final newTitle = isFirstMessage
        ? (text.length > 30 ? text.substring(0, 30) : text)
        : current.session.title;

    var updatedSession = current.session.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
      messages: updatedMessages,
    );

    emit(ChatSessionOpen(session: updatedSession, isLoading: true));

    try {
      // Attach live GPS only for pitch/location-related queries so we don't prompt for
      // location on product chats. Non-blocking: null when permission denied/GPS off ->
      // backend falls back to the user's saved profile coordinates.
      double? lat;
      double? lng;
      final lower = text.toLowerCase();
      final wantsLocation = lower.contains('sân') ||
          lower.contains('gần') ||
          lower.contains('quanh') ||
          lower.contains('gợi ý');
      if (wantsLocation) {
        final pos = await LocationHelper.currentPosition();
        if (pos != null) {
          lat = pos.latitude;
          lng = pos.longitude;
        }
      }

      final response = await remoteDatasource.sendMessage(
        text,
        current.session.sessionId,
        latitude: lat,
        longitude: lng,
      );

      final rawMessage = (response['message'] as String?)?.trim() ?? '';
      final aiMessage = rawMessage.isEmpty
          ? 'Xin lỗi, mình chưa nhận được phản hồi phù hợp. Bạn thử diễn đạt lại nhé (vd: "cho xem các sân 5 người" hoặc "giày rẻ nhất").'
          : rawMessage;
      final aiData = response['data'] as Map<String, dynamic>?;

      final aiMsg = ChatMessageModel(
        id: _generateId(),
        content: aiMessage,
        isUser: false,
        isImage: false,
        createdAt: DateTime.now(),
        aiData: aiData,
      );

      updatedSession = updatedSession.copyWith(
        updatedAt: DateTime.now(),
        messages: [...updatedSession.messages, aiMsg],
      );

      await localDatasource.updateSession(updatedSession);
      emit(ChatSessionOpen(session: updatedSession));
    } catch (e) {
      // Giữ tin nhắn user, hiện lỗi dưới dạng AI message
      final errMsg = ChatMessageModel(
        id: _generateId(),
        content: 'Đã có lỗi xảy ra. Vui lòng thử lại.',
        isUser: false,
        isImage: false,
        createdAt: DateTime.now(),
      );
      updatedSession = updatedSession.copyWith(
        messages: [...updatedSession.messages, errMsg],
      );
      await localDatasource.updateSession(updatedSession);
      emit(ChatSessionOpen(session: updatedSession));
    }
  }

  Future<void> sendImage(File imageFile) async {
    final current = state;
    if (current is! ChatSessionOpen || current.isLoading) return;

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    final userMsg = ChatMessageModel(
      id: _generateId(),
      content: '[Hình ảnh]',
      isUser: true,
      isImage: true,
      imagePath: imageFile.path,
      createdAt: DateTime.now(),
    );

    final isFirstMessage = current.session.messages.isEmpty;
    final newTitle = isFirstMessage ? '🖼 Tìm kiếm bằng hình ảnh' : current.session.title;

    var updatedSession = current.session.copyWith(
      title: newTitle,
      updatedAt: DateTime.now(),
      messages: [...current.session.messages, userMsg],
    );

    emit(ChatSessionOpen(session: updatedSession, isLoading: true));

    try {
      final response = await remoteDatasource.sendImage(
        base64Image,
        current.session.sessionId,
      );

      final rawMessage = (response['message'] as String?)?.trim() ?? '';
      final aiMessage = rawMessage.isEmpty
          ? 'Mình chưa nhận diện được sản phẩm từ hình ảnh. Bạn thử chụp rõ hơn nhé.'
          : rawMessage;
      final aiData = response['data'] as Map<String, dynamic>?;

      final aiMsg = ChatMessageModel(
        id: _generateId(),
        content: aiMessage,
        isUser: false,
        isImage: false,
        createdAt: DateTime.now(),
        aiData: aiData,
      );

      updatedSession = updatedSession.copyWith(
        updatedAt: DateTime.now(),
        messages: [...updatedSession.messages, aiMsg],
      );

      await localDatasource.updateSession(updatedSession);
      emit(ChatSessionOpen(session: updatedSession));
    } catch (e) {
      final errMsg = ChatMessageModel(
        id: _generateId(),
        content: 'Đã có lỗi xảy ra khi xử lý hình ảnh. Vui lòng thử lại.',
        isUser: false,
        isImage: false,
        createdAt: DateTime.now(),
      );
      updatedSession = updatedSession.copyWith(
        messages: [...updatedSession.messages, errMsg],
      );
      await localDatasource.updateSession(updatedSession);
      emit(ChatSessionOpen(session: updatedSession));
    }
  }

  void backToList() {
    loadSessions();
  }

  // ── In-chat checkout ───────────────────────────────────────────────────
  // Trạng thái card (checkoutStatus/paymentStatus) persist trong aiData của
  // message — chat lưu local JSON nên trạng thái sống qua restart app.

  /// Merge [patch] vào aiData của message [messageId], lưu local và emit.
  Future<void> _patchMessageAiData(
      String messageId, Map<String, dynamic> patch) async {
    final current = state;
    if (current is! ChatSessionOpen) return;

    final messages = current.session.messages.map((m) {
      if (m.id != messageId) return m;
      return ChatMessageModel(
        id: m.id,
        content: m.content,
        isUser: m.isUser,
        isImage: m.isImage,
        imagePath: m.imagePath,
        createdAt: m.createdAt,
        aiData: {...?m.aiData, ...patch},
      );
    }).toList();

    final updatedSession = current.session.copyWith(messages: messages);
    await localDatasource.updateSession(updatedSession);
    emit(ChatSessionOpen(session: updatedSession, isLoading: current.isLoading));
  }

  /// Thêm tin nhắn bot local (không gọi AI) — dùng cho xác nhận đơn/QR/lỗi.
  Future<void> _appendBotMessage(String content,
      {Map<String, dynamic>? aiData}) async {
    final current = state;
    if (current is! ChatSessionOpen) return;

    final botMsg = ChatMessageModel(
      id: _generateId(),
      content: content,
      isUser: false,
      isImage: false,
      createdAt: DateTime.now(),
      aiData: aiData,
    );

    final updatedSession = current.session.copyWith(
      updatedAt: DateTime.now(),
      messages: [...current.session.messages, botMsg],
    );
    await localDatasource.updateSession(updatedSession);
    emit(ChatSessionOpen(session: updatedSession, isLoading: current.isLoading));
  }

  String _extractErrorMessage(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        return data['message'] as String? ??
            data['error'] as String? ??
            'Đã xảy ra lỗi không xác định.';
      }
      if (data is String && data.isNotEmpty) return data;
      return error.message ?? 'Lỗi kết nối đến máy chủ.';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  /// Đặt sản phẩm trực tiếp từ card trong chat.
  /// CASH → đặt xong báo thành công. BANK → tạo QR, gửi message payment_qr.
  Future<void> placeProductOrderFromChat({
    required String messageId,
    required String userId,
    required String paymentMethod, // 'CASH' | 'BANK'
    required String deliveryAddress,
    required double destLat,
    required double destLng,
    required List<Map<String, dynamic>> items,
    required List<String> discountCodes,
    required double total,
  }) async {
    await _patchMessageAiData(messageId, {'checkoutStatus': 'processing'});
    try {
      final orderData = await paymentDatasource.createOrder({
        'userId': userId,
        'paymentMethod': paymentMethod,
        'deliveryAddress': deliveryAddress,
        'destLat': destLat,
        'destLng': destLng,
        'items': items,
        'discountCodes': discountCodes,
      });
      final orderId = orderData['orderId'] as int;

      if (paymentMethod == 'BANK') {
        // Đơn đã tạo — nếu bước lấy QR lỗi thì KHÔNG reset card (tránh user
        // bấm lại tạo đơn trùng), hướng dẫn thanh toán từ Đơn hàng của tôi.
        final PaymentResponseModel paymentResp;
        try {
          paymentResp = await paymentDatasource.createShopPayment({
            'userId': userId,
            // Tổng server (đã gồm phí ship) — tránh QR thiếu phí vận chuyển.
            'amount': (orderData['totalAmount'] as num?)?.toDouble() ?? total,
            'paymentMethod': 'BANK',
            'orderCode': orderId,
          });
        } catch (e) {
          await _patchMessageAiData(messageId, {'checkoutStatus': 'done'});
          await _appendBotMessage(
            '⚠️ Đơn hàng #$orderId đã được tạo nhưng chưa lấy được mã QR '
            '(${_extractErrorMessage(e)}). Bạn vào mục Đơn hàng của tôi để '
            'thanh toán lại nhé.',
          );
          return;
        }
        await _patchMessageAiData(messageId, {'checkoutStatus': 'done'});
        await _appendBotMessage(
          'Đơn hàng #$orderId đã được tạo. Bạn quét mã QR bên dưới để '
          'chuyển khoản nhé — mình sẽ tự động xác nhận khi nhận được tiền 👇',
          aiData: {
            'action': 'payment_qr',
            'kind': 'order',
            'refId': orderId.toString(),
            'qrCode': paymentResp.qrCode,
            'ownerName': paymentResp.ownerName,
            'ownerCardNumber': paymentResp.ownerCardNumber,
            'ownerBank': paymentResp.ownerBank,
            // Tổng server (đã gồm phí ship) — hiển thị khớp số tiền QR.
            'amount': (orderData['totalAmount'] as num?)?.toDouble() ?? total,
            'paymentStatus': 'PENDING',
          },
        );
      } else {
        await _patchMessageAiData(messageId, {'checkoutStatus': 'done'});
        await _appendBotMessage(
          '✅ Đặt hàng thành công! Đơn hàng #$orderId sẽ được giao đến '
          '"$deliveryAddress", thanh toán tiền mặt khi nhận hàng. '
          'Bạn có thể theo dõi đơn trong mục Đơn hàng của tôi.',
          aiData: {'action': 'order_success', 'orderId': orderId.toString()},
        );
      }
    } catch (e) {
      await _patchMessageAiData(messageId, {'checkoutStatus': null});
      await _appendBotMessage(
          '❌ Đặt hàng chưa thành công: ${_extractErrorMessage(e)}');
    }
  }

  /// Đặt sân trực tiếp từ card trong chat.
  /// CASH → BE xác nhận luôn. BANK_TRANSFER → tạo QR, gửi message payment_qr.
  Future<void> placeBookingFromChat({
    required String messageId,
    required String userId,
    required String paymentMethod, // 'CASH' | 'BANK_TRANSFER'
    required String pitchId,
    required String pitchName,
    required String bookingDate, // yyyy-MM-dd
    required List<int> slotList,
    required double pitchPrice,
    required List<String> discountCodes,
    required double total,
  }) async {
    await _patchMessageAiData(messageId, {'checkoutStatus': 'processing'});
    try {
      final request = BookingRequestModel(
        pitchId: pitchId,
        userId: userId,
        bookingDate: bookingDate,
        totalPrice: total,
        bookingDetails: slotList.map((slot) {
          return BookingDetailModel(
            slot: slot,
            name: slotTimeRange(slot),
            priceDetail: pitchPrice,
          );
        }).toList(),
        paymentMethod: paymentMethod,
        discountCodes: discountCodes,
      );

      final bookingId = await bookingDatasource.createBooking(request);

      if (paymentMethod == 'BANK_TRANSFER') {
        // Booking đã giữ chỗ — nếu bước lấy QR lỗi thì KHÔNG reset card
        // (tránh đặt trùng), hướng dẫn thanh toán từ Lịch sử đặt sân.
        final PaymentResponseModel paymentResp;
        try {
          paymentResp = await paymentDatasource.createPayment(
            PaymentRequestModel(
              bookingId: bookingId,
              userId: userId,
              amount: total,
              paymentMethod: 'BANK', // khớp enum PaymentMethod phía BE
            ),
          );
        } catch (e) {
          await _patchMessageAiData(messageId, {'checkoutStatus': 'done'});
          await _appendBotMessage(
            '⚠️ Đơn đặt sân "$pitchName" đã được giữ chỗ nhưng chưa lấy được '
            'mã QR (${_extractErrorMessage(e)}). Bạn vào Lịch sử đặt sân để '
            'thanh toán nhé.',
          );
          return;
        }
        await _patchMessageAiData(messageId, {'checkoutStatus': 'done'});
        await _appendBotMessage(
          'Đơn đặt sân "$pitchName" ngày $bookingDate đã được giữ chỗ. '
          'Bạn quét mã QR bên dưới để chuyển khoản nhé — mình sẽ tự động '
          'xác nhận khi nhận được tiền 👇',
          aiData: {
            'action': 'payment_qr',
            'kind': 'booking',
            'refId': bookingId,
            'qrCode': paymentResp.qrCode,
            'ownerName': paymentResp.ownerName,
            'ownerCardNumber': paymentResp.ownerCardNumber,
            'ownerBank': paymentResp.ownerBank,
            'amount': total,
            'paymentStatus': 'PENDING',
          },
        );
      } else {
        await _patchMessageAiData(messageId, {'checkoutStatus': 'done'});
        await _appendBotMessage(
          '✅ Đặt sân thành công và đã được xác nhận! Sân "$pitchName", '
          'ngày $bookingDate, khung giờ ${slotRangeLabel(slotList)} — '
          'thanh toán tiền mặt tại sân. Xem chi tiết trong Lịch sử đặt sân.',
          aiData: {'action': 'booking_success', 'bookingId': bookingId},
        );
      }
    } catch (e) {
      await _patchMessageAiData(messageId, {'checkoutStatus': null});
      await _appendBotMessage(
          '❌ Đặt sân chưa thành công: ${_extractErrorMessage(e)}');
    }
  }

  /// Poll trạng thái thanh toán cho message payment_qr; PAID → patch + báo.
  Future<void> checkChatPaymentStatus(String messageId) async {
    final current = state;
    if (current is! ChatSessionOpen) return;

    ChatMessageModel? msg;
    for (final m in current.session.messages) {
      if (m.id == messageId) {
        msg = m;
        break;
      }
    }
    final aiData = msg?.aiData;
    if (aiData == null || aiData['paymentStatus'] == 'PAID') return;

    final kind = aiData['kind'] as String?;
    final refId = aiData['refId'] as String?;
    if (kind == null || refId == null) return;

    try {
      final status = kind == 'booking'
          ? await paymentDatasource.getPaymentStatusByBookingId(refId)
          : await paymentDatasource.getShopPaymentStatus(refId);
      if (status.isPaid) {
        await _patchMessageAiData(messageId, {'paymentStatus': 'PAID'});
        await _appendBotMessage(
          kind == 'booking'
              ? '✅ Thanh toán thành công! Đơn đặt sân của bạn đã được xác nhận.'
              : '✅ Thanh toán thành công! Đơn hàng của bạn đang được xử lý.',
        );
      }
    } catch (_) {
      // Lỗi poll không làm phiền UI — lần poll sau thử lại.
    }
  }

  /// Slot 1 = 06:00-07:00 ... slot 18 = 23:00-00:00 (giờ bắt đầu = slot + 5).
  static String slotTimeRange(int slot) {
    final start = (slot + 5) % 24;
    final end = (slot + 6) % 24;
    String two(int h) => h.toString().padLeft(2, '0');
    return '${two(start)}:00 - ${two(end)}:00';
  }

  /// "19:00 - 21:00" cho dải slot liên tục (min→max).
  static String slotRangeLabel(List<int> slots) {
    if (slots.isEmpty) return '';
    final minSlot = slots.reduce(min);
    final maxSlot = slots.reduce(max);
    String two(int h) => h.toString().padLeft(2, '0');
    return '${two((minSlot + 5) % 24)}:00 - ${two((maxSlot + 6) % 24)}:00';
  }
}
