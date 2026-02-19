import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matjary/features/dashboard/presentation/cubit/dashboard_cubit.dart';
import 'package:matjary/features/dashboard/presentation/cubit/dashboard_state.dart';
import 'package:matjary/features/suppliers/presentation/screens/suppliers_list_screen.dart';
import 'package:matjary/features/customers/presentation/screens/customers_list_screen.dart';
import 'package:matjary/features/transactions/presentation/screens/transactions_list_screen.dart';
import 'package:matjary/features/suppliers/domain/repositories/supplier_repository.dart';
import 'package:matjary/features/customers/domain/repositories/customer_repository.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Note: BlocProvider creation is in local scope or above?
    // In previous code, I created it here. I should keep it.
    // However, context.read won't work inside create for sibling.
    // I need to be careful. The repos are provided in main.

    // Also need to handle refreshing data when coming back.
    // I previously looked at .then() in navigation.

    return BlocProvider(
      create: (context) => DashboardCubit(
        supplierRepository: context.read<SupplierRepository>(),
        customerRepository: context.read<CustomerRepository>(),
      )..loadDashboardData(),
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'لوحة التحكم',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        body: BlocBuilder<DashboardCubit, DashboardState>(
          builder: (context, state) {
            if (state is DashboardLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
              );
            } else if (state is DashboardError) {
              return Center(child: Text('خطأ: ${state.message}'));
            } else if (state is DashboardLoaded) {
              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSummaryCard(
                      context,
                      'عليك (للموردين)',
                      state.totalPayables,
                      const Color(0xFFCF6679),
                      Icons.arrow_circle_down_rounded,
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryCard(
                      context,
                      'لك (من العملاء)',
                      state.totalReceivables,
                      const Color(0xFF00897B),
                      Icons.arrow_circle_up_rounded,
                    ),
                    const SizedBox(height: 32),

                    _buildMenuButton(
                      context,
                      'إدارة الموردين',
                      Icons.people_outline,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SuppliersListScreen(),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            context.read<DashboardCubit>().loadDashboardData();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      context,
                      'إدارة العملاء',
                      Icons.supervised_user_circle_outlined,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CustomersListScreen(),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            context.read<DashboardCubit>().loadDashboardData();
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildMenuButton(
                      context,
                      'سجل المعاملات',
                      Icons.receipt_long,
                      () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const TransactionsListScreen(),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            context.read<DashboardCubit>().loadDashboardData();
                          }
                        });
                      },
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    BuildContext context,
    String title,
    double amount,
    Color color,
    IconData icon,
  ) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 800),
      tween: Tween(begin: 0.0, end: 1.0),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Glass effect container
            Container(
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: color.withValues(alpha: 0.2),
                  width: 1.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          color.withValues(alpha: 0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withValues(alpha: 0.2),
                                blurRadius: 15,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(icon, color: color, size: 36),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[400],
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                child: Text(
                                  amount.toStringAsFixed(2),
                                  style: TextStyle(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: color,
                                    fontFamily: 'Roboto',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF2C2C2C),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFD4AF37).withValues(alpha: 0.2),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFD4AF37), size: 28),
              const SizedBox(width: 24),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
