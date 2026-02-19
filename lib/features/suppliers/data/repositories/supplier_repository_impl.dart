import 'package:matjary/features/suppliers/data/datasources/supplier_local_data_source.dart';
import 'package:matjary/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:matjary/features/suppliers/data/models/supplier_model.dart';
import 'package:matjary/features/suppliers/domain/entities/supplier.dart';
import 'package:matjary/features/suppliers/domain/repositories/supplier_repository.dart';

class SupplierRepositoryImpl implements SupplierRepository {
  final SupplierLocalDataSource localDataSource;
  final TransactionLocalDataSource transactionLocalDataSource;

  SupplierRepositoryImpl({
    required this.localDataSource,
    required this.transactionLocalDataSource,
  });

  @override
  Future<void> addSupplier(Supplier supplier) async {
    final model = SupplierModel.fromEntity(supplier);
    await localDataSource.addSupplier(model);
  }

  @override
  Future<void> deleteSupplier(String id) async {
    await localDataSource.deleteSupplier(id);
    await transactionLocalDataSource.deleteTransactionsByParty(id);
  }

  @override
  Future<Supplier?> getSupplier(String id) async {
    final suppliers = await localDataSource.getSuppliers();
    try {
      return suppliers.firstWhere((element) => element.id == id).toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Supplier>> getSuppliers() async {
    final models = await localDataSource.getSuppliers();
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> updateSupplier(Supplier supplier) async {
    await localDataSource.updateSupplier(SupplierModel.fromEntity(supplier));
  }
}
