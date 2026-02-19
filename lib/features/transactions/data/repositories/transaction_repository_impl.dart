import 'package:matjary/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:matjary/features/transactions/data/models/transaction_model.dart';
import 'package:matjary/features/transactions/domain/entities/transaction.dart';
import 'package:matjary/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:matjary/features/customers/domain/repositories/customer_repository.dart';
import 'package:matjary/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:matjary/core/constants/enums.dart';

class TransactionRepositoryImpl implements TransactionRepository {
  final TransactionLocalDataSource localDataSource;
  final CustomerRepository customerRepository;
  final SupplierRepository supplierRepository;

  TransactionRepositoryImpl({
    required this.localDataSource,
    required this.customerRepository,
    required this.supplierRepository,
  });

  @override
  Future<void> addTransaction(Transaction transaction) async {
    // 1. Add Transaction
    await localDataSource.addTransaction(
      TransactionModel.fromEntity(transaction),
    );

    // 2. Update Balance
    if (transaction.partyType == PartyType.customer) {
      final customer = await customerRepository.getCustomer(
        transaction.partyId,
      );
      if (customer != null) {
        double newBalance = customer.balance;
        if (transaction.type == TransactionType.debt) {
          newBalance += transaction.amount;
        } else {
          newBalance -= transaction.amount;
        }
        await customerRepository.updateCustomer(
          customer.copyWith(balance: newBalance),
        );
      }
    } else {
      final supplier = await supplierRepository.getSupplier(
        transaction.partyId,
      );
      if (supplier != null) {
        double newBalance = supplier.balance;
        if (transaction.type == TransactionType.debt) {
          newBalance += transaction.amount;
        } else {
          newBalance -= transaction.amount;
        }
        await supplierRepository.updateSupplier(
          supplier.copyWith(balance: newBalance),
        );
      }
    }
  }

  @override
  Future<void> deleteTransaction(String id) async {
    // 1. Fetch Transaction before deletion to revert balance
    final model = await localDataSource.getTransaction(id);
    if (model == null) return;
    final transaction = model.toEntity();

    // 2. Revert Balance
    if (transaction.partyType == PartyType.customer) {
      final customer = await customerRepository.getCustomer(
        transaction.partyId,
      );
      if (customer != null) {
        double newBalance = customer.balance;
        if (transaction.type == TransactionType.debt) {
          newBalance -= transaction.amount;
        } else {
          newBalance += transaction.amount;
        }
        await customerRepository.updateCustomer(
          customer.copyWith(balance: newBalance),
        );
      }
    } else {
      final supplier = await supplierRepository.getSupplier(
        transaction.partyId,
      );
      if (supplier != null) {
        double newBalance = supplier.balance;
        if (transaction.type == TransactionType.debt) {
          newBalance -= transaction.amount;
        } else {
          newBalance += transaction.amount;
        }
        await supplierRepository.updateSupplier(
          supplier.copyWith(balance: newBalance),
        );
      }
    }

    // 3. Delete Transaction
    await localDataSource.deleteTransaction(id);
  }

  @override
  Future<List<Transaction>> getAllTransactions() async {
    final models = await localDataSource.getAllTransactions();
    // Sort by date descending
    final sorted = models.toList()..sort((a, b) => b.date.compareTo(a.date));
    return sorted.map((e) => e.toEntity()).toList();
  }

  @override
  Future<List<Transaction>> getTransactionsByParty(String partyId) async {
    final models = await localDataSource.getTransactionsByParty(partyId);
    final sorted = models.toList()..sort((a, b) => b.date.compareTo(a.date));
    return sorted.map((e) => e.toEntity()).toList();
  }
}
