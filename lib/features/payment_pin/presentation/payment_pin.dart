import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/network/dio_client.dart';
import '../data/pin_remote_data_source.dart';

/// Lấy mã PIN thanh toán để thực hiện thao tác tiền (đổi TK, rút...).
/// Chưa có PIN ⇒ mở luồng đặt PIN; có PIN ⇒ nhập + xác thực. Trả về pin (đã verify) hoặc null nếu hủy.
Future<String?> ensurePaymentPin(BuildContext context) async {
  final ds = PinRemoteDataSource(dioClient: context.read<DioClient>());
  Map<String, dynamic> st;
  try {
    st = await ds.status();
  } catch (_) {
    return null;
  }
  if (!context.mounted) return null;
  final hasPin = st['hasPin'] == true;
  if (!hasPin) return _showSetPin(context, ds);
  return _showEnterPin(context, ds);
}

/// Mở luồng ĐỔI mã PIN. Chưa có PIN ⇒ chuyển sang đặt PIN mới.
Future<void> changePaymentPin(BuildContext context) async {
  final ds = PinRemoteDataSource(dioClient: context.read<DioClient>());
  Map<String, dynamic> st;
  try {
    st = await ds.status();
  } catch (_) {
    return;
  }
  if (!context.mounted) return;
  if (st['hasPin'] != true) {
    await _showSetPin(context, ds); // chưa có PIN ⇒ đặt mới
    return;
  }
  await _showChangePin(context, ds);
}

Future<void> _showChangePin(BuildContext context, PinRemoteDataSource ds) {
  final cur = TextEditingController();
  final nw = TextEditingController();
  final confirm = TextEditingController();
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      String? error;
      bool busy = false;
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('Đổi mã PIN'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _pinField(cur, 'PIN hiện tại'),
                const SizedBox(height: 10),
                _pinField(nw, 'PIN mới 6 số'),
                const SizedBox(height: 10),
                _pinField(confirm, 'Nhập lại PIN mới'),
                if (error != null) ...[
                  const SizedBox(height: 8),
                  Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                    onPressed: busy
                        ? null
                        : () async {
                            final ok = await _showForgotReset(ctx, ds);
                            if (ok != null && ctx.mounted) Navigator.pop(ctx);
                          },
                    child: const Text('Quên PIN hiện tại?'),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (nw.text.length != 6) {
                        setState(() => error = 'PIN mới phải 6 số.');
                        return;
                      }
                      if (nw.text != confirm.text) {
                        setState(() => error = 'PIN mới nhập lại không khớp.');
                        return;
                      }
                      setState(() { busy = true; error = null; });
                      try {
                        await ds.changePin(cur.text, nw.text);
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(content: Text('Đã đổi mã PIN.')),
                          );
                        }
                      } catch (e) {
                        setState(() { busy = false; error = _errMsg(e, 'Không đổi được PIN.'); });
                      }
                    },
              child: const Text('Đổi PIN'),
            ),
          ],
        );
      });
    },
  );
}

String _errMsg(Object e, String fallback) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['message'] is String) return data['message'] as String;
    if (e.response?.statusCode == 423) return 'PIN đang bị khóa do nhập sai nhiều lần.';
    if (e.response?.statusCode == 400) return 'Mã PIN/OTP không đúng.';
  }
  return fallback;
}

Widget _pinField(TextEditingController c, String label, {void Function(String)? onChanged}) {
  return TextField(
    controller: c,
    keyboardType: TextInputType.number,
    obscureText: true,
    maxLength: 6,
    onChanged: onChanged,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    decoration: InputDecoration(
      labelText: label,
      counterText: '',
      border: const OutlineInputBorder(),
    ),
  );
}

Future<String?> _showSetPin(BuildContext context, PinRemoteDataSource ds) {
  final pin = TextEditingController();
  final confirm = TextEditingController();
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      String? error;
      bool busy = false;
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('Đặt mã PIN thanh toán'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Tạo PIN 6 số để bảo vệ thao tác tiền (đổi TK, rút).',
                  style: TextStyle(fontSize: 12.5)),
              const SizedBox(height: 12),
              _pinField(pin, 'PIN 6 số'),
              const SizedBox(height: 10),
              _pinField(confirm, 'Nhập lại PIN'),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (pin.text.length != 6) {
                        setState(() => error = 'PIN phải 6 số.');
                        return;
                      }
                      if (pin.text != confirm.text) {
                        setState(() => error = 'PIN nhập lại không khớp.');
                        return;
                      }
                      setState(() { busy = true; error = null; });
                      try {
                        await ds.setPin(pin.text);
                        if (ctx.mounted) Navigator.pop(ctx, pin.text);
                      } catch (e) {
                        setState(() { busy = false; error = _errMsg(e, 'Không đặt được PIN.'); });
                      }
                    },
              child: const Text('Lưu PIN'),
            ),
          ],
        );
      });
    },
  );
}

Future<String?> _showEnterPin(BuildContext context, PinRemoteDataSource ds) {
  final pin = TextEditingController();
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      String? error;
      bool busy = false;
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('Nhập PIN thanh toán'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _pinField(pin, 'PIN 6 số'),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
              ],
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  onPressed: busy
                      ? null
                      : () async {
                          final newPin = await _showForgotReset(ctx, ds);
                          if (newPin != null && ctx.mounted) Navigator.pop(ctx, newPin);
                        },
                  child: const Text('Quên PIN?'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: busy
                  ? null
                  : () async {
                      setState(() { busy = true; error = null; });
                      try {
                        await ds.verify(pin.text);
                        if (ctx.mounted) Navigator.pop(ctx, pin.text);
                      } catch (e) {
                        setState(() { busy = false; error = _errMsg(e, 'PIN không đúng.'); });
                      }
                    },
              child: const Text('Xác nhận'),
            ),
          ],
        );
      });
    },
  );
}

Future<String?> _showForgotReset(BuildContext context, PinRemoteDataSource ds) async {
  try {
    await ds.forgot(); // gửi OTP về email
  } catch (_) {}
  if (!context.mounted) return null;
  final otp = TextEditingController();
  final newPin = TextEditingController();
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      String? error;
      bool busy = false;
      return StatefulBuilder(builder: (ctx, setState) {
        return AlertDialog(
          title: const Text('Đặt lại PIN'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Đã gửi mã OTP về email của bạn.', style: TextStyle(fontSize: 12.5)),
              const SizedBox(height: 12),
              TextField(
                controller: otp,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                    labelText: 'Mã OTP', counterText: '', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              _pinField(newPin, 'PIN mới 6 số'),
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12.5)),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Hủy')),
            ElevatedButton(
              onPressed: busy
                  ? null
                  : () async {
                      if (newPin.text.length != 6) {
                        setState(() => error = 'PIN mới phải 6 số.');
                        return;
                      }
                      setState(() { busy = true; error = null; });
                      try {
                        await ds.reset(otp.text, newPin.text);
                        if (ctx.mounted) Navigator.pop(ctx, newPin.text);
                      } catch (e) {
                        setState(() { busy = false; error = _errMsg(e, 'OTP/PIN không hợp lệ.'); });
                      }
                    },
              child: const Text('Đặt lại'),
            ),
          ],
        );
      });
    },
  );
}
