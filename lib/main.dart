import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';

import 'features/suppliers/data/models/supplier_model.dart';
import 'features/customers/data/models/customer_model.dart';
import 'features/transactions/data/models/transaction_model.dart';

import 'features/suppliers/data/datasources/supplier_local_data_source.dart';
import 'features/suppliers/data/repositories/supplier_repository_impl.dart';
import 'features/suppliers/domain/repositories/supplier_repository.dart';

import 'features/customers/data/datasources/customer_local_data_source.dart';
import 'features/customers/data/repositories/customer_repository_impl.dart';
import 'features/customers/domain/repositories/customer_repository.dart';

import 'features/transactions/data/datasources/transaction_local_data_source.dart';
import 'features/transactions/data/repositories/transaction_repository_impl.dart';
import 'features/transactions/domain/repositories/transaction_repository.dart';

import 'core/constants/app_constants.dart';
import 'features/dashboard/presentation/screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();

  Hive.registerAdapter(SupplierModelAdapter());
  Hive.registerAdapter(CustomerModelAdapter());
  Hive.registerAdapter(TransactionModelAdapter());

  final supplierBox = await Hive.openBox<SupplierModel>(
    AppConstants.kSuppliersBox,
  );
  final customerBox = await Hive.openBox<CustomerModel>(
    AppConstants.kCustomersBox,
  );
  final transactionBox = await Hive.openBox<TransactionModel>(
    AppConstants.kTransactionsBox,
  );

  runApp(
    MatjaryApp(
      supplierBox: supplierBox,
      customerBox: customerBox,
      transactionBox: transactionBox,
    ),
  );
}

class MatjaryApp extends StatelessWidget {
  final Box<SupplierModel> supplierBox;
  final Box<CustomerModel> customerBox;
  final Box<TransactionModel> transactionBox;

  const MatjaryApp({
    super.key,
    required this.supplierBox,
    required this.customerBox,
    required this.transactionBox,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Initialize DataSource that is shared
    final txLocalDataSource = TransactionLocalDataSourceImpl(
      transactionBox: transactionBox,
    );

    return MultiRepositoryProvider(
      providers: [
        // 2. Repositories that depend on txLocalDataSource
        RepositoryProvider<SupplierRepository>(
          create: (context) => SupplierRepositoryImpl(
            localDataSource: SupplierLocalDataSourceImpl(
              supplierBox: supplierBox,
            ),
            transactionLocalDataSource: txLocalDataSource,
          ),
        ),
        RepositoryProvider<CustomerRepository>(
          create: (context) => CustomerRepositoryImpl(
            localDataSource: CustomerLocalDataSourceImpl(
              customerBox: customerBox,
            ),
            transactionLocalDataSource: txLocalDataSource,
          ),
        ),
        // 3. TransactionRepository depends on the other repositories
        RepositoryProvider<TransactionRepository>(
          create: (context) => TransactionRepositoryImpl(
            localDataSource: txLocalDataSource,
            customerRepository: context.read<CustomerRepository>(),
            supplierRepository: context.read<SupplierRepository>(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'دفتري - Daftari',
        debugShowCheckedModeBanner: false,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        theme: ThemeData(
          brightness: Brightness.dark,
          scaffoldBackgroundColor: const Color(0xFF121212),
          primaryColor: const Color(0xFFD4AF37), // Gold
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFD4AF37), // Gold
            secondary: Color(0xFF00897B), // Teal
            surface: Color(0xFF1E1E1E), // Dark Grey Card
            error: Color(0xFFCF6679),
          ),
          useMaterial3: true,
          textTheme: GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme),
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF1E1E1E),
            elevation: 0,
            centerTitle: true,
          ),
          cardTheme: CardThemeData(
            color: const Color(0xFF1E1E1E),
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        home: const DashboardScreen(),
      ),
    );
  }
}
