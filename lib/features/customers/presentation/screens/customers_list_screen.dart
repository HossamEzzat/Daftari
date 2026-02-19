import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matjary/features/customers/presentation/cubit/customers_cubit.dart';
import 'package:matjary/features/customers/presentation/cubit/customers_state.dart';
import 'package:matjary/features/customers/presentation/screens/add_customer_screen.dart';
import 'package:matjary/features/customers/presentation/screens/customer_details_screen.dart';
import 'package:matjary/features/customers/domain/repositories/customer_repository.dart';

class CustomersListScreen extends StatelessWidget {
  const CustomersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          CustomersCubit(context.read<CustomerRepository>())..loadCustomers(),
      child: const CustomersListView(),
    );
  }
}

class CustomersListView extends StatelessWidget {
  const CustomersListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('العملاء')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4AF37),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<CustomersCubit>(),
                child: const AddCustomerScreen(),
              ),
            ),
          ).then((_) {
            if (context.mounted) {
              context.read<CustomersCubit>().loadCustomers();
            }
          });
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: BlocBuilder<CustomersCubit, CustomersState>(
        builder: (context, state) {
          if (state is CustomersLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          } else if (state is CustomersError) {
            return Center(child: Text('خطأ: ${state.message}'));
          } else if (state is CustomersLoaded) {
            if (state.customers.isEmpty) {
              return const Center(
                child: Text(
                  "لا يوجد عملاء حتى الان",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.customers.length,
              itemBuilder: (context, index) {
                final customer = state.customers[index];
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
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      leading: Container(
                        height: 48,
                        width: 48,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            customer.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        customer.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          customer.phone,
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                customer.balance.abs().toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: customer.balance > 0
                                      ? const Color(0xFF00BFA5)
                                      : const Color(0xFFCF6679),
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              Text(
                                customer.balance > 0 ? "لك" : "عليك",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: customer.balance > 0
                                      ? const Color(0xFF00BFA5)
                                      : const Color(0xFFCF6679),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 8),
                          PopupMenuButton<String>(
                            icon: const Icon(
                              Icons.more_vert,
                              color: Colors.grey,
                              size: 20,
                            ),
                            onSelected: (value) {
                              if (value == 'edit') {
                                _showEditCustomerDialog(context, customer);
                              } else if (value == 'delete') {
                                _confirmDeleteCustomer(context, customer);
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'edit',
                                child: Row(
                                  children: [
                                    Icon(Icons.edit_outlined, size: 18),
                                    SizedBox(width: 12),
                                    Text("تعديل"),
                                  ],
                                ),
                              ),
                              const PopupMenuItem(
                                value: 'delete',
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.delete_outline,
                                      color: Colors.red,
                                      size: 18,
                                    ),
                                    SizedBox(width: 12),
                                    Text(
                                      "حذف",
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                CustomerDetailsScreen(customer: customer),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            context.read<CustomersCubit>().loadCustomers();
                          }
                        });
                      },
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

  void _showEditCustomerDialog(BuildContext context, dynamic customer) {
    final nameController = TextEditingController(text: customer.name);
    final phoneController = TextEditingController(text: customer.phone);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        elevation: 24,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFFFD700).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.edit_outlined,
                color: Color(0xFFFFD700),
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            const Text(
              "تعديل العميل",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "اسم العميل",
                prefixIcon: Icon(
                  Icons.person_outline,
                  color: Color(0xFFFFD700),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: phoneController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: "رقم الهاتف",
                prefixIcon: Icon(
                  Icons.phone_outlined,
                  color: Color(0xFFFFD700),
                ),
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              "إلغاء",
              style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFD700),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 4,
            ),
            onPressed: () {
              final updated = customer.copyWith(
                name: nameController.text,
                phone: phoneController.text,
              );
              context.read<CustomersCubit>().updateCustomer(updated);
              Navigator.pop(ctx);
            },
            child: const Text(
              "حفظ التعديلات",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCustomer(BuildContext context, dynamic customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
        title: const Text(
          "تأكيد الحذف",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        content: Text(
          "هل أنت متأكد من حذف ${customer.name}؟ سيتم حذف جميع العمليات المرتبطة.",
          style: const TextStyle(color: Colors.white70),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFCF6679).withValues(alpha: 0.1),
              foregroundColor: const Color(0xFFCF6679),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0xFFCF6679), width: 1),
              ),
            ),
            onPressed: () {
              context.read<CustomersCubit>().deleteCustomer(customer.id);
              Navigator.pop(ctx);
            },
            child: const Text(
              "حذف الآن",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
