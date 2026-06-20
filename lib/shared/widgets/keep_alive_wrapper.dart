import 'package:flutter/material.dart';

/// Bọc child trong TabBarView/PageView để giữ state khi chuyển tab khác
/// (TabBarView mặc định dispose tab off-screen → mất nội dung đã nhập / cubit / scroll).
class KeepAliveWrapper extends StatefulWidget {
  final Widget child;

  const KeepAliveWrapper({super.key, required this.child});

  @override
  State<KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
