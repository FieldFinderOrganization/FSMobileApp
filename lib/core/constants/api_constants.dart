import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConstants {
  static String get baseUrl =>
      dotenv.env['BASE_URL'] ?? 'http://192.168.1.5:8080/api';

  static const String googleLogin = '/auth/google';
  static const String facebookLogin = '/auth/facebook';
  static const String emailLogin = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh-token';
  static const String logout = '/auth/logout';
  static const String sendOtp = '/auth/send-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String sendActivationEmail = '/auth/send-activation-email';
  static const String resetPasswordOtp = '/users/reset-password-otp';
  static const String sendResetOtp = '/users/forgot-password-otp';

  // Home screen endpoints
  static const String products = '/products';
  static const String topProducts = '/products/top-selling';
  static const String pitches = '/pitches';
  static const String providers = '/providers';
  static const String providerAddresses = '/provider-addresses';
  static const String categories = '/categories';
  static const String discounts = '/discounts';
  static const String reviews = '/reviews';

  // Booking endpoints
  static const String bookings = '/bookings';
  static const String bookingSlots = '/bookings/slots';
  static const String userBookings = '/bookings/user';
  static const String providerBookings = '/bookings/provider';

  // Payment endpoints
  static const String payments = '/payments';

  // Order endpoints
  static const String orders = '/orders';

  // AI Chat endpoints
  static const String aiChat = '/ai/chat';
  static const String aiImage = '/ai/image';

  // Cart endpoints
  static const String cart = '/cart';
  static const String cartAdd = '/cart/add';
  static const String cartUpdate = '/cart/update';
  static const String cartRemove = '/cart/remove';
  static const String cartClear = '/cart/clear';

  // User endpoints
  static const String users = '/users';
  static String userUpdate(String userId) => '/users/$userId';
  static const String verifyCurrentPassword = '/users/verify-current-password';
  static const String changePasswordOtp = '/users/change-password-otp';

  // Admin Detail endpoints
  static const String adminUsers = '/admin/users';
  static const String adminUserStats = '/admin/users/stats';
  static const String adminBookingsList = '/admin/bookings';
  static const String adminOrdersList = '/admin/orders';
  static const String adminOrderStats = '/admin/orders/stats';
  static const String adminPitchesList = '/admin/pitches';
  static const String adminReviewStats = '/admin/reviews/stats';

  // Admin Statistics endpoints
  static const String adminStatisticsOverview = '/admin/statistics/overview';
  static const String adminStatisticsRevenue = '/admin/statistics/revenue';
  static const String adminStatisticsBookingsByDay = '/admin/statistics/bookings-by-day';
  static const String adminStatisticsPitchesByType = '/admin/statistics/pitches-by-type';
  static const String adminStatisticsRecentBookings = '/admin/statistics/recent-bookings';
  static const String adminStatisticsProducts = '/admin/statistics/products';

  // User-to-user Chat endpoints
  static const String chatHistory = '/chat/history';
  static const String chatMarkRead = '/chat/mark-read';
  static const String chatUnreadCount = '/chat/unread-count';
  static const String chatConversations = '/chat/conversations';
  static const String chatUploadImage = '/chat/upload-image';
  static String userById(String userId) => '/users/$userId';

  // SockJS requires HTTP URL (not ws://), the library handles the upgrade internally
  static String get wsBaseUrl {
    final base = baseUrl.replaceFirst('/api', '');
    return '$base/ws';
  }

  // Cloudinary
  static String get cloudinaryUrl {
    final cloudName =
        dotenv.env['NEXT_PUBLIC_CLOUDINARY_CLOUD_NAME'] ?? 'dxgy8ilqu';
    return 'https://api.cloudinary.com/v1_1/$cloudName/image/upload';
  }
}
