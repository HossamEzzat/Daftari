import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matjary/features/suppliers/domain/entities/supplier.dart';
import 'package:matjary/features/transactions/presentation/cubit/transaction_cubit.dart';
import 'package:matjary/features/transactions/presentation/cubit/transaction_state.dart';
import 'package:matjary/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:matjary/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:matjary/core/constants/enums.dart';
import 'package:matjary/features/transactions/domain/entities/transaction.dart';
import 'package:uuid/uuid.dart';

class SupplierDetailsScreen extends StatelessWidget {
  final Supplier supplier;

  const SupplierDetailsScreen({super.key, required this.supplier});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TransactionCubit(context.read<TransactionRepository>())
            ..loadTransactions(supplier.id),
      child: SupplierDetailsView(supplier: supplier),
    );
  }
}

class SupplierDetailsView extends StatefulWidget {
  final Supplier supplier;
  const SupplierDetailsView({super.key, required this.supplier});

  @override
  State<SupplierDetailsView> createState() => _SupplierDetailsViewState();
}

class _SupplierDetailsViewState extends State<SupplierDetailsView> {
  late Supplier currentSupplier;

  @override
  void initState() {
    super.initState();
    currentSupplier = widget.supplier;
  }

  void _refreshSupplier() async {
    final updated = await context.read<SupplierRepository>().getSupplier(
      currentSupplier.id,
    );

    if (!mounted) return;

    if (updated != null) {
      setState(() {
        currentSupplier = updated;
      });
    }
    context.read<TransactionCubit>().loadTransactions(currentSupplier.id);
  }

  void _addTransaction(TransactionType type, double amount) async {
    final transaction = Transaction(
      id: const Uuid().v4(),
      partyId: currentSupplier.id,
      partyType: PartyType.supplier,
      amount: amount,
      date: DateTime.now(),
      type: type,
    );

    // Call TransactionRepository which now handles balance updates centrally
    await context.read<TransactionRepository>().addTransaction(transaction);

    if (mounted) {
      _refreshSupplier();
    }
  }

  void _deleteTransaction(Transaction transaction) async {
    // Call TransactionCubit (which calls TransactionRepository)
    // The repository now handles balance reversion centrally
    await context.read<TransactionCubit>().deleteTransaction(transaction);

    if (mounted) {
      _refreshSupplier();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(currentSupplier.name)),
      body: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1E1E1E), Color(0xFF252525)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
              border: Border.all(
                color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "الرصيد الحالي",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                Text(
                  currentSupplier.balance.toStringAsFixed(2),
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Roboto',
                    color: currentSupplier.balance > 0
                        ? const Color(0xFFCF6679)
                        : const Color(0xFF00897B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentSupplier.balance > 0
                      ? "عليك (دين)"
                      : "مدفوع بالكامل", // "Paid fully" or "Credit" if negative
                  style: TextStyle(
                    fontSize: 14,
                    color: currentSupplier.balance > 0
                        ? const Color(0xFFCF6679)
                        : const Color(0xFF00897B),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.add_shopping_cart,
                          color: Colors.black,
                        ),
                        label: const Text(
                          "شراء (دين)",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _showAddTransactionDialogOfType(
                          TransactionType.debt,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCF6679),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(
                          Icons.attach_money,
                          color: Colors.black,
                        ),
                        label: const Text(
                          "دفع",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        onPressed: () => _showAddTransactionDialogOfType(
                          TransactionType.payment,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00897B),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                "سجل العمليات",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[300],
                ),
              ),
            ),
          ),
          Expanded(
            child: BlocBuilder<TransactionCubit, TransactionState>(
              builder: (context, state) {
                if (state is TransactionLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
                  );
                }
                if (state is TransactionLoaded) {
                  if (state.transactions.isEmpty) {
                    return const Center(
                      child: Text(
                        "لا يوجد عمليات",
                        style: TextStyle(color: Colors.grey),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = state.transactions[index];
                      final isDebt = tx.type == TransactionType.debt;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E1E),
                            borderRadius: BorderRadius.circular(12),
                            border: Border(
                              right: BorderSide(
                                color: isDebt
                                    ? const Color(0xFFCF6679)
                                    : const Color(0xFF00897B),
                                width: 4,
                              ),
                            ),
                          ),
                          child: ListTile(
                            onLongPress: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  backgroundColor: const Color(0xFF1E1E1E),
                                  title: const Text(
                                    "حذف العملية",
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  content: const Text(
                                    "هل تريد حذف هذه العملية؟ سيتم تعديل الرصيد تلقائياً.",
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text(
                                        "إلغاء",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        _deleteTransaction(tx);
                                        Navigator.pop(ctx);
                                      },
                                      child: const Text(
                                        "حذف",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            title: Text(
                              isDebt ? "شراء بضاعة" : "دفعة نقدية",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              tx.date.toString().split('.')[0],
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            trailing: Text(
                              tx.amount.toStringAsFixed(2),
                              style: TextStyle(
                                fontFamily: 'Roboto',
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: isDebt
                                    ? const Color(0xFFCF6679)
                                    : const Color(0xFF00897B),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddTransactionDialogOfType(TransactionType type) {
    showDialog(
      context: context,
      builder: (ctx) => AddTransactionDialog(
        initialType: type,
        onSubmit: (t, amount) => _addTransaction(t, amount),
      ),
    );
  }
}

class AddTransactionDialog extends StatefulWidget {
  final Function(TransactionType, double) onSubmit;
  final TransactionType? initialType;

  const AddTransactionDialog({
    super.key,
    required this.onSubmit,
    this.initialType,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  late TransactionType _type;
  final _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _type = widget.initialType ?? TransactionType.debt;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text("إضافة عملية", style: TextStyle(color: Colors.white)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<TransactionType>(
            // key: ValueKey(_type), // Ensure rebuild if needed (though local state update might handle it if we just use initialValue? No, usually initialValue is one-off)
            // Actually, if we use initialValue, we should rely on FormField state.
            // But I will stick to Key to be safe.
            key: ValueKey(_type),
            initialValue: _type,
            dropdownColor: const Color(0xFF2C2C2C),
            items: const [
              DropdownMenuItem(
                value: TransactionType.debt,
                child: Text(
                  "شراء (دين)",
                  style: TextStyle(color: Colors.white),
                ),
              ),
              DropdownMenuItem(
                value: TransactionType.payment,
                child: Text("دفع", style: TextStyle(color: Colors.white)),
              ),
            ],
            onChanged: widget.initialType != null
                ? null
                : (val) => setState(() => _type = val!),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabled: widget.initialType == null,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: "المبلغ",
              labelStyle: const TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: const BorderSide(color: Color(0xFFD4AF37)),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFD4AF37),
            foregroundColor: Colors.black,
          ),
          onPressed: () {
            final amount = double.tryParse(_amountController.text);
            if (amount != null) {
              widget.onSubmit(_type, amount);
              Navigator.pop(context);
            }
          },
          child: const Text(
            "حفظ",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
