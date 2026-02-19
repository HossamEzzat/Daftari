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
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: state.transactions.length,
              itemBuilder: (context, index) {
                final transaction = state.transactions[index];
                final isPayment = transaction.type == TransactionType.payment;
                final isSupplier = transaction.partyType == PartyType.supplier;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
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
                            (isPayment
                                    ? const Color(0xFF00BFA5)
                                    : const Color(0xFFCF6679))
                                .withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color:
                              (isPayment
                                      ? const Color(0xFF00BFA5)
                                      : const Color(0xFFCF6679))
                                  .withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          isPayment
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          color: isPayment
                              ? const Color(0xFF00BFA5)
                              : const Color(0xFFCF6679),
                          size: 20,
                        ),
                      ),
                      title: Text(
                        transaction.amount.toStringAsFixed(2),
                        style: const TextStyle(
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          transaction.date.toString().substring(0, 10),
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[500],
                          ),
                        ),
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isSupplier ? "مورد" : "عميل",
                          style: const TextStyle(
                            color: Color(0xFFFFD700),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
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
    );
  }
}
