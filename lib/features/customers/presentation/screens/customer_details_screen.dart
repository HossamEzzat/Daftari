import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matjary/features/customers/domain/entities/customer.dart';
import 'package:matjary/features/transactions/presentation/cubit/transaction_cubit.dart';
import 'package:matjary/features/transactions/presentation/cubit/transaction_state.dart';
import 'package:matjary/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:matjary/features/customers/domain/repositories/customer_repository.dart';
import 'package:matjary/core/constants/enums.dart';
import 'package:matjary/features/transactions/domain/entities/transaction.dart';
import 'package:uuid/uuid.dart';

class CustomerDetailsScreen extends StatelessWidget {
  final Customer customer;

  const CustomerDetailsScreen({super.key, required this.customer});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TransactionCubit(context.read<TransactionRepository>())
            ..loadTransactions(customer.id),
      child: CustomerDetailsView(customer: customer),
    );
  }
}

class CustomerDetailsView extends StatefulWidget {
  final Customer customer;
  const CustomerDetailsView({super.key, required this.customer});

  @override
  State<CustomerDetailsView> createState() => _CustomerDetailsViewState();
}

class _CustomerDetailsViewState extends State<CustomerDetailsView> {
  late Customer currentCustomer;

  @override
  void initState() {
    super.initState();
    currentCustomer = widget.customer;
  }

  void _refreshCustomer() async {
    final updated = await context.read<CustomerRepository>().getCustomer(
      currentCustomer.id,
    );
    if (!mounted) return;
    if (updated != null) {
      setState(() {
        currentCustomer = updated;
      });
    }
    context.read<TransactionCubit>().loadTransactions(currentCustomer.id);
  }

  void _addTransaction(TransactionType type, double amount) async {
    final transaction = Transaction(
      id: const Uuid().v4(),
      partyId: currentCustomer.id,
      partyType: PartyType.customer,
      amount: amount,
      date: DateTime.now(),
      type: type,
    );

    // Call TransactionRepository which now handles balance updates centrally
    await context.read<TransactionRepository>().addTransaction(transaction);

    if (mounted) {
      _refreshCustomer();
    }
  }

  void _deleteTransaction(Transaction transaction) async {
    // Call TransactionCubit (which calls TransactionRepository)
    // The repository now handles balance reversion centrally
    await context.read<TransactionCubit>().deleteTransaction(transaction);

    if (mounted) {
      _refreshCustomer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(currentCustomer.name)),
      body: Column(
        children: [
          // Header Card
          Container(
            width: double.infinity,
            margin: const EdgeInsets.all(20),
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1A1A1A),
                  currentCustomer.balance > 0
                      ? const Color(0xFF00BFA5).withValues(alpha: 0.1)
                      : const Color(0xFFCF6679).withValues(alpha: 0.1),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(
                color:
                    (currentCustomer.balance > 0
                            ? const Color(0xFF00BFA5)
                            : const Color(0xFFCF6679))
                        .withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Text(
                  "الرصيد الحالي",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[400],
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                FittedBox(
                  child: Text(
                    currentCustomer.balance.toStringAsFixed(2),
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Roboto',
                      letterSpacing: -1,
                      color: currentCustomer.balance > 0
                          ? const Color(0xFF00BFA5)
                          : const Color(0xFFCF6679),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color:
                        (currentCustomer.balance > 0
                                ? const Color(0xFF00BFA5)
                                : const Color(0xFFCF6679))
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    currentCustomer.balance > 0 ? "لك (عند العميل)" : "خالص",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: currentCustomer.balance > 0
                          ? const Color(0xFF00BFA5)
                          : const Color(0xFFCF6679),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: _buildActionButton(
                        context,
                        "بيع (آجل)",
                        Icons.sell_rounded,
                        const Color(0xFFCF6679),
                        () => _showAddTransactionDialogOfType(
                          TransactionType.debt,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildActionButton(
                        context,
                        "تحصيل",
                        Icons.account_balance_wallet_rounded,
                        const Color(0xFF00BFA5),
                        () => _showAddTransactionDialogOfType(
                          TransactionType.payment,
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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: state.transactions.length,
                    itemBuilder: (context, index) {
                      final tx = state.transactions[index];
                      final isDebt = tx.type == TransactionType.debt;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Dismissible(
                          key: Key(tx.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            alignment: Alignment.centerLeft,
                            padding: const EdgeInsets.only(left: 20),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                          ),
                          onDismissed: (_) => _deleteTransaction(tx),
                          child: Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFF1A1A1A),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color:
                                    (isDebt
                                            ? const Color(0xFFCF6679)
                                            : const Color(0xFF00BFA5))
                                        .withValues(alpha: 0.2),
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 8,
                              ),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color:
                                      (isDebt
                                              ? const Color(0xFFCF6679)
                                              : const Color(0xFF00BFA5))
                                          .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  isDebt
                                      ? Icons.arrow_upward_rounded
                                      : Icons.arrow_downward_rounded,
                                  color: isDebt
                                      ? const Color(0xFFCF6679)
                                      : const Color(0xFF00BFA5),
                                  size: 20,
                                ),
                              ),
                              title: Text(
                                isDebt ? "بيع بضاعة" : "تحصيل نقدية",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  tx.date.toString().split('.')[0],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              trailing: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    tx.amount.toStringAsFixed(2),
                                    style: TextStyle(
                                      fontFamily: 'Roboto',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: isDebt
                                          ? const Color(0xFFCF6679)
                                          : const Color(0xFF00BFA5),
                                    ),
                                  ),
                                  Text(
                                    isDebt ? "دين +" : "دفع -",
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isDebt
                                          ? const Color(0xFFCF6679)
                                          : const Color(0xFF00BFA5),
                                    ),
                                  ),
                                ],
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

  Widget _buildActionButton(
    BuildContext context,
    String label,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: Colors.black, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 8,
        shadowColor: color.withValues(alpha: 0.4),
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
            key: ValueKey(_type),
            initialValue: _type,
            dropdownColor: const Color(0xFF2C2C2C),
            items: const [
              DropdownMenuItem(
                value: TransactionType.debt,
                child: Text("بيع (آجل)", style: TextStyle(color: Colors.white)),
              ),
              DropdownMenuItem(
                value: TransactionType.payment,
                child: Text("تحصيل", style: TextStyle(color: Colors.white)),
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
