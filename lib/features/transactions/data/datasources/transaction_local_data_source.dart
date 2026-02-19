import 'package:hive_flutter/hive_flutter.dart';
import '../models/transaction_model.dart';

abstract class TransactionLocalDataSource {
  Future<List<TransactionModel>> getAllTransactions();
  Future<List<TransactionModel>> getTransactionsByParty(String partyId);
  Future<TransactionModel?> getTransaction(String id);
  Future<void> addTransaction(TransactionModel transaction);
  Future<void> deleteTransaction(String id);
  Future<void> deleteTransactionsByParty(String partyId);
}

class TransactionLocalDataSourceImpl implements TransactionLocalDataSource {
  final Box<TransactionModel> transactionBox;

  TransactionLocalDataSourceImpl({required this.transactionBox});

  @override
  Future<List<TransactionModel>> getAllTransactions() async {
    return transactionBox.values.toList();
  }

  @override
  Future<List<TransactionModel>> getTransactionsByParty(String partyId) async {
    return transactionBox.values.where((tx) => tx.partyId == partyId).toList();
  }

  @override
  Future<TransactionModel?> getTransaction(String id) async {
    return transactionBox.get(id);
  }

  @override
  Future<void> addTransaction(TransactionModel transaction) async {
    await transactionBox.put(transaction.id, transaction);
  }

  @override
  Future<void> deleteTransaction(String id) async {
    await transactionBox.delete(id);
  }

  @override
  Future<void> deleteTransactionsByParty(String partyId) async {
    final keysToDel = transactionBox.values
        .where((tx) => tx.partyId == partyId)
        .map((tx) => tx.id)
        .toList();
    await transactionBox.deleteAll(keysToDel);
  }
}
