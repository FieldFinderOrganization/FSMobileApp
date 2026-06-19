import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/bank_account_model.dart';
import '../../data/models/bank_info_model.dart';
import '../cubit/bank_account_cubit.dart';
import '../cubit/bank_account_state.dart';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  @override
  void initState() {
    super.initState();
    context.read<BankAccountCubit>().load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tài khoản ngân hàng'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: BlocConsumer<BankAccountCubit, BankAccountState>(
        listenWhen: (p, c) =>
            c.errorMessage.isNotEmpty && p.errorMessage != c.errorMessage,
        listener: (ctx, state) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            SnackBar(content: Text(state.errorMessage)),
          );
        },
        builder: (ctx, state) {
          if (state.status == BankAccountStatus.loading &&
              state.accounts.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => ctx.read<BankAccountCubit>().load(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _infoBanner(),
                const SizedBox(height: 16),
                if (state.accounts.isEmpty)
                  _emptyState()
                else
                  ...state.accounts.map((a) => _accountCard(ctx, a)),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => _openForm(ctx, state.banks),
                  icon: const Icon(Icons.add),
                  label: Text(state.accounts.isEmpty
                      ? 'Thêm tài khoản nhận hoàn tiền'
                      : 'Thêm tài khoản khác'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _infoBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'Mọi khoản hoàn tiền sẽ được chuyển về tài khoản mặc định bên dưới, '
              'dù bạn thanh toán bằng phương thức nào.',
              style: TextStyle(fontSize: 12.5, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(Icons.account_balance_outlined,
              size: 56, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text('Chưa có tài khoản nhận hoàn tiền',
              style: TextStyle(color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text('Thêm tài khoản để nhận hoàn tiền mặt khi hủy đơn',
              style: TextStyle(color: Colors.grey.shade500, fontSize: 12.5),
              textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _accountCard(BuildContext ctx, BankAccountModel a) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: a.isDefault ? Colors.red.shade300 : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    a.bankName ?? a.bankBin,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                if (a.isDefault) _chip('Mặc định', Colors.red),
                if (a.verified) ...[
                  const SizedBox(width: 6),
                  _chip('Đã xác thực', Colors.green),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(a.maskedAccountNumber ?? a.accountNumber,
                style: const TextStyle(fontSize: 15, letterSpacing: 1.2)),
            const SizedBox(height: 2),
            Text(a.accountName,
                style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                if (!a.isDefault)
                  TextButton(
                    onPressed: () =>
                        ctx.read<BankAccountCubit>().setDefault(a.bankAccountId),
                    child: const Text('Đặt mặc định'),
                  ),
                const Spacer(),
                IconButton(
                  onPressed: () => _confirmDelete(ctx, a),
                  icon: Icon(Icons.delete_outline, color: Colors.grey.shade600),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String text, MaterialColor color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: TextStyle(
              color: color.shade700,
              fontSize: 11,
              fontWeight: FontWeight.w600)),
    );
  }

  void _confirmDelete(BuildContext ctx, BankAccountModel a) {
    showDialog(
      context: ctx,
      builder: (d) => AlertDialog(
        title: const Text('Xóa tài khoản?'),
        content: Text('Xóa ${a.bankName ?? a.bankBin} - ${a.maskedAccountNumber ?? a.accountNumber}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(d), child: const Text('Hủy')),
          TextButton(
            onPressed: () {
              Navigator.pop(d);
              ctx.read<BankAccountCubit>().delete(a.bankAccountId);
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext ctx, List<BankInfoModel> banks) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: ctx.read<BankAccountCubit>(),
        child: _BankAccountForm(banks: banks),
      ),
    );
  }
}

class _BankAccountForm extends StatefulWidget {
  final List<BankInfoModel> banks;
  const _BankAccountForm({required this.banks});

  @override
  State<_BankAccountForm> createState() => _BankAccountFormState();
}

class _BankAccountFormState extends State<_BankAccountForm> {
  final _accountController = TextEditingController();
  final _nameController = TextEditingController();
  BankInfoModel? _selectedBank;

  @override
  void dispose() {
    _accountController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Thêm tài khoản ngân hàng',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _bankPicker(),
          const SizedBox(height: 12),
          TextField(
            controller: _accountController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Số tài khoản',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Tên chủ tài khoản (không dấu)',
              hintText: 'NGUYEN VAN A',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<BankAccountCubit, BankAccountState>(
            builder: (ctx, state) {
              return ElevatedButton(
                onPressed: state.saving ? null : () => _submit(ctx),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: state.saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Lưu tài khoản'),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _bankPicker() {
    return InkWell(
      onTap: _pickBank,
      child: InputDecorator(
        decoration: const InputDecoration(
          labelText: 'Ngân hàng',
          border: OutlineInputBorder(),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _selectedBank?.label ?? 'Chọn ngân hàng',
                style: TextStyle(
                  color:
                      _selectedBank == null ? Colors.grey.shade600 : Colors.black,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Icon(Icons.arrow_drop_down),
          ],
        ),
      ),
    );
  }

  void _pickBank() {
    if (widget.banks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tải được danh sách ngân hàng.')),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _BankPickerSheet(
        banks: widget.banks,
        onSelect: (b) => setState(() => _selectedBank = b),
      ),
    );
  }

  Future<void> _submit(BuildContext ctx) async {
    if (_selectedBank == null) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn ngân hàng.')),
      );
      return;
    }
    final acc = _accountController.text.trim();
    final name = _nameController.text.trim();
    if (acc.isEmpty || name.isEmpty) {
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Nhập đủ số tài khoản và tên chủ TK.')),
      );
      return;
    }
    final ok = await ctx.read<BankAccountCubit>().save(
          bankBin: _selectedBank!.bin,
          bankName: _selectedBank!.shortName,
          accountNumber: acc,
          accountName: name,
        );
    if (ok && ctx.mounted) {
      Navigator.pop(ctx);
      ScaffoldMessenger.of(ctx).showSnackBar(
        const SnackBar(content: Text('Đã lưu tài khoản nhận hoàn tiền.')),
      );
    }
  }
}

class _BankPickerSheet extends StatefulWidget {
  final List<BankInfoModel> banks;
  final ValueChanged<BankInfoModel> onSelect;
  const _BankPickerSheet({required this.banks, required this.onSelect});

  @override
  State<_BankPickerSheet> createState() => _BankPickerSheetState();
}

class _BankPickerSheetState extends State<_BankPickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final filtered = widget.banks.where((b) {
      final q = _query.toLowerCase();
      return q.isEmpty ||
          b.name.toLowerCase().contains(q) ||
          b.shortName.toLowerCase().contains(q);
    }).toList();
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      builder: (_, controller) => Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              decoration: const InputDecoration(
                hintText: 'Tìm ngân hàng...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: filtered.length,
              itemBuilder: (_, i) {
                final b = filtered[i];
                return ListTile(
                  leading: b.logo != null
                      ? Image.network(b.logo!,
                          width: 40,
                          height: 40,
                          errorBuilder: (context, error, stack) =>
                              const Icon(Icons.account_balance))
                      : const Icon(Icons.account_balance),
                  title: Text(b.shortName),
                  subtitle: Text(b.name,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () {
                    widget.onSelect(b);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
