import 'package:matjary/features/customers/data/datasources/customer_local_data_source.dart';
import 'package:matjary/features/transactions/data/datasources/transaction_local_data_source.dart';
import 'package:matjary/features/customers/data/models/customer_model.dart';
import 'package:matjary/features/customers/domain/entities/customer.dart';
import 'package:matjary/features/customers/domain/repositories/customer_repository.dart';

class CustomerRepositoryImpl implements CustomerRepository {
  final CustomerLocalDataSource localDataSource;
  final TransactionLocalDataSource transactionLocalDataSource;

  CustomerRepositoryImpl({
    required this.localDataSource,
    required this.transactionLocalDataSource,
  });

  @override
  Future<void> addCustomer(Customer customer) async {
    await localDataSource.addCustomer(CustomerModel.fromEntity(customer));
  }

  @override
  Future<void> deleteCustomer(String id) async {
    await localDataSource.deleteCustomer(id);
    await transactionLocalDataSource.deleteTransactionsByParty(id);
  }

  @override
  Future<Customer?> getCustomer(String id) async {
    final customers = await localDataSource.getCustomers();
    try {
      return customers.firstWhere((element) => element.id == id).toEntity();
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<Customer>> getCustomers() async {
    final models = await localDataSource.getCustomers();
    return models.map((e) => e.toEntity()).toList();
  }

  @override
  Future<void> updateCustomer(Customer customer) async {
    await localDataSource.updateCustomer(CustomerModel.fromEntity(customer));
  }
}
