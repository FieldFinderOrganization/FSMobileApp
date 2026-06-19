import '../../data/models/refund_request_model.dart';

enum RefundListStatus { initial, loading, success, failure }

class RefundState {
  final RefundListStatus status;
  final List<RefundRequestModel> refunds;
  final String errorMessage;

  const RefundState({
    this.status = RefundListStatus.initial,
    this.refunds = const [],
    this.errorMessage = '',
  });

  RefundState copyWith({
    RefundListStatus? status,
    List<RefundRequestModel>? refunds,
    String? errorMessage,
  }) {
    return RefundState(
      status: status ?? this.status,
      refunds: refunds ?? this.refunds,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
