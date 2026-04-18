import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../cubit/chat_cubit.dart';
import '../cubit/chat_state.dart';
import '../widgets/ai_product_card.dart';
import '../../../checkout/domain/entities/checkout_item_entity.dart';
import '../../../checkout/presentation/pages/checkout_screen.dart';
import '../../../pitch/domain/entities/pitch_entity.dart';
import '../../../pitch/presentation/pages/pitch_detail_screen.dart';
import '../../../pitch/presentation/pages/booking_screen.dart';
import '../../../pitch/presentation/widgets/pitch_card.dart';
import '../../../product/presentation/pages/product_detail_screen.dart';
import '../widgets/chat_bubble.dart';

class ChatDetailScreen extends StatefulWidget {
  const ChatDetailScreen({super.key});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: Text('Chụp ảnh', style: GoogleFonts.inter()),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text('Chọn từ thư viện', style: GoogleFonts.inter()),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;

    final picked = await _picker.pickImage(source: source, imageQuality: 80);
    if (picked == null || !mounted) return;

    context.read<ChatCubit>().sendImage(File(picked.path));
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    context.read<ChatCubit>().sendMessage(text);
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ChatCubit, ChatState>(
      listener: (context, state) {
        if (state is ChatSessionOpen) {
          _scrollToBottom();
        }
      },
      builder: (context, state) {
        if (state is! ChatSessionOpen) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final session = state.session;
        final isLoading = state.isLoading;

        return Scaffold(
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: Color(0xFF1F2937), size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.title,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1F2937),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Chat AI',
                  style: GoogleFonts.inter(
                      fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: session.messages.isEmpty
                    ? _WelcomeHint()
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        itemCount: session.messages.length,
                        itemBuilder: (context, index) {
                          final msg = session.messages[index];
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ChatBubble(message: msg),
                              if (!msg.isUser &&
                                  msg.aiData != null &&
                                  msg.aiData!['action'] == 'ready_to_order')
                                _CheckoutButton(aiData: msg.aiData!),
                              if (!msg.isUser &&
                                  msg.aiData != null &&
                                  msg.aiData!['showBookingButton'] == true &&
                                  msg.aiData!['suggestedPitch'] != null)
                                _BookPitchButton(aiData: msg.aiData!),
                              if (!msg.isUser &&
                                  msg.aiData != null &&
                                  msg.aiData!['products'] != null)
                                _ProductList(
                                    products: (msg.aiData!['products']
                                        as List<dynamic>)
                                        .cast<Map<String, dynamic>>()),
                              if (!msg.isUser &&
                                  msg.aiData != null &&
                                  msg.aiData!['matchedPitches'] != null)
                                _PitchList(
                                    pitches: (msg.aiData!['matchedPitches']
                                            as List<dynamic>)
                                        .cast<Map<String, dynamic>>()),
                              if (!msg.isUser &&
                                  msg.aiData != null &&
                                  msg.aiData!['showImage'] == true &&
                                  msg.aiData!['product'] != null)
                                _SingleProductImage(aiData: msg.aiData!),
                            ],
                          );
                        },
                      ),
              ),
              if (isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _TypingIndicator(),
                ),
              _InputBar(
                controller: _controller,
                isLoading: isLoading,
                onSend: _send,
                onPickImage: _pickImage,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _WelcomeHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.smart_toy_outlined,
                  color: Color(0xFFDC2626), size: 30),
            ),
            const SizedBox(height: 16),
            Text(
              'Xin chào! Tôi có thể giúp bạn tìm sân bóng, gợi ý sản phẩm hoặc tìm kiếm bằng hình ảnh.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 14, color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProductList extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  const _ProductList({required this.products});

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 266,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 12, right: 4, top: 8, bottom: 8),
        itemCount: products.length,
        itemBuilder: (_, i) => AiProductCard(product: products[i]),
      ),
    );
  }
}

class _PitchList extends StatelessWidget {
  final List<Map<String, dynamic>> pitches;
  const _PitchList({required this.pitches});

  @override
  Widget build(BuildContext context) {
    if (pitches.isEmpty) return const SizedBox.shrink();
    
    return SizedBox(
      height: 210,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.only(left: 12, right: 4, top: 8, bottom: 8),
        itemCount: pitches.length,
        itemBuilder: (_, i) {
          final raw = pitches[i];
          final pitch = PitchEntity(
            pitchId: (raw['pitchId'] ?? raw['id'] ?? '').toString(),
            name: raw['name'] as String? ?? '',
            type: raw['type'] as String? ?? 'FIVE_A_SIDE',
            environment: raw['environment'] as String? ?? 'OUTDOOR',
            price: (raw['price'] as num?)?.toDouble() ?? 0,
            description: raw['description'] as String? ?? '',
            imageUrls: (raw['imageUrls'] as List<dynamic>?)
                    ?.map((e) => e.toString())
                    .toList() ??
                const [],
            address: raw['address'] as String? ?? '',
          );
          
          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 12),
            child: PitchCard(pitch: pitch),
          );
        },
      ),
    );
  }
}


class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(left: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('AI đang trả lời',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.grey)),
            const SizedBox(width: 6),
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primaryRed),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckoutButton extends StatelessWidget {
  final Map<String, dynamic> aiData;

  const _CheckoutButton({required this.aiData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 60, top: 8, bottom: 4),
      child: ElevatedButton.icon(
        onPressed: () => _goToCheckout(context),
        icon: const Icon(Icons.shopping_bag_outlined, size: 18),
        label: Text(
          'Thanh toán ngay',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _goToCheckout(BuildContext context) {
    final product = aiData['product'] as Map<String, dynamic>?;
    final selectedSize = aiData['selectedSize'] as String? ?? '';

    if (product == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin sản phẩm')),
      );
      return;
    }

    final quantity = (aiData['selectedQuantity'] as num?)?.toInt() ?? 1;

    final item = CheckoutItemEntity(
      productId: (product['id'] as num?)?.toInt() ?? 0,
      productName: product['name'] as String? ?? '',
      brand: product['brand'] as String? ?? '',
      imageUrl: product['imageUrl'] as String? ?? '',
      size: selectedSize,
      unitPrice: (product['salePrice'] as num?)?.toDouble() ??
          (product['price'] as num?)?.toDouble() ??
          0,
      originalPrice: (product['price'] as num?)?.toDouble() ?? 0,
      salePercent: (product['salePercent'] as num?)?.toInt(),
      quantity: quantity,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutScreen(items: [item]),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onPickImage;

  const _InputBar({
    required this.controller,
    required this.isLoading,
    required this.onSend,
    required this.onPickImage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 12,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).viewInsets.bottom +
            MediaQuery.of(context).padding.bottom +
            12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: isLoading ? null : onPickImage,
            icon: Icon(
              Icons.image_outlined,
              color: isLoading ? Colors.grey : AppColors.primaryRed,
              size: 24,
            ),
            tooltip: 'Gửi hình ảnh',
          ),
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !isLoading,
              maxLines: 4,
              minLines: 1,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: 'Nhập tin nhắn...',
                hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(20),
                  borderSide: const BorderSide(color: AppColors.primaryRed),
                ),
              ),
              style: GoogleFonts.inter(fontSize: 14),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: isLoading ? null : onSend,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isLoading ? Colors.grey : AppColors.primaryRed,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _BookPitchButton extends StatelessWidget {
  final Map<String, dynamic> aiData;
  const _BookPitchButton({required this.aiData});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 60, top: 8, bottom: 4),
      child: ElevatedButton.icon(
        onPressed: () => _openPitch(context),
        icon: const Icon(Icons.sports_soccer, size: 18),
        label: Text(
          'Đặt sân ngay',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _openPitch(BuildContext context) {
    final raw = aiData['suggestedPitch'] as Map<String, dynamic>?;
    if (raw == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy thông tin sân')),
      );
      return;
    }
    final pitch = PitchEntity(
      pitchId: (raw['pitchId'] ?? raw['id'] ?? '').toString(),
      name: raw['name'] as String? ?? '',
      type: raw['type'] as String? ?? 'FIVE_A_SIDE',
      environment: raw['environment'] as String? ?? 'OUTDOOR',
      price: (raw['price'] as num?)?.toDouble() ?? 0,
      description: raw['description'] as String? ?? '',
      imageUrls: (raw['imageUrls'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      address: raw['address'] as String? ?? '',
    );
    
    final bookingDateStr = aiData['bookingDate'] as String?;
    if (bookingDateStr != null) {
      DateTime? bDate;
      try {
        bDate = DateTime.parse(bookingDateStr);
      } catch (e) {}

      if (bDate != null) {
        final slotListRaw = aiData['slotList'] as List<dynamic>?;
        final slotList = slotListRaw?.map((e) => (e as num).toInt()).toList();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BookingScreen(
              pitch: pitch,
              selectedDate: bDate!,
              initialSlotList: slotList,
            ),
          ),
        );
        return;
      }
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PitchDetailScreen(pitch: pitch)),
    );
  }
}

class _SingleProductImage extends StatelessWidget {
  final Map<String, dynamic> aiData;

  const _SingleProductImage({required this.aiData});

  @override
  Widget build(BuildContext context) {
    final product = aiData['product'] as Map<String, dynamic>?;
    if (product == null) return const SizedBox.shrink();

    final imageUrl = product['imageUrl'] as String? ?? '';
    final name = product['name'] as String? ?? '';
    final rawId = product['id'] ?? product['productId'];
    final productId = rawId?.toString();

    if (imageUrl.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(left: 12, right: 60, top: 4, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () {
              // Phóng to ảnh
              showDialog(
                context: context,
                builder: (_) => Dialog(
                  backgroundColor: Colors.transparent,
                  insetPadding: const EdgeInsets.all(16),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      InteractiveViewer(
                        panEnabled: true,
                        minScale: 0.5,
                        maxScale: 4,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            imageUrl,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image,
                                  color: Colors.grey, size: 48),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 30),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                imageUrl,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: const Color(0xFFF3F4F6),
                  child: const Center(
                    child: Icon(Icons.image_outlined,
                        color: Colors.grey, size: 48),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: const Color(0xFF1F2937),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (productId == null || productId.isEmpty)
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ProductDetailScreen(productId: productId),
                              ),
                            );
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primaryRed,
                      side: const BorderSide(color: AppColors.primaryRed),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Xem chi tiết',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

