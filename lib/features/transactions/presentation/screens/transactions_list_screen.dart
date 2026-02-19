import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matjary/features/transactions/presentation/cubit/transaction_cubit.dart';
import 'package:matjary/features/transactions/presentation/cubit/transaction_state.dart';
import 'package:matjary/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:matjary/core/constants/enums.dart';

class TransactionsListScreen extends StatelessWidget {
  const TransactionsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          TransactionCubit(context.read<TransactionRepository>())
            ..loadTransactions(),
      child: const TransactionsListView(),
    );
  }
}

class TransactionsListView extends StatelessWidget {
  const TransactionsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('سجل المعاملات')),
      body: BlocBuilder<TransactionCubit, TransactionState>(
        builder: (context, state) {
          if (state is TransactionLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          } else if (state is TransactionError) {
            return Center(child: Text('خطأ: ${state.message}'));
          } else if (state is TransactionLoaded) {
            if (state.transactions.isEmpty) {
              return const Center(
                child: Text(
                  "لا يوجد معاملات حتى الان",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.transactions.length,
              itemBuilder: (context, index) {
                final transaction = state.transactions[index];
                final isPayment = transaction.type == TransactionType.payment;
                return Card(
                  color: const Color(0xFF1E1E1E),
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isPayment
                          ? Colors.green.withValues(alpha: 0.2)
                          : Colors.red.withValues(alpha: 0.2),
                      child: Icon(
                        isPayment ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isPayment ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(
                      transaction.amount.toStringAsFixed(2),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      transaction.date.toString().substring(
                        0,
                        10,
                      ), // Simple date format YYYY-MM-DD
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    trailing: Text(
                      transaction.partyType == PartyType.supplier
                          ? "مورد"
                          : "عميل",
                      style: const TextStyle(color: Color(0xFFD4AF37)),
                    ),
                  ),
                );
              },
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }
}
