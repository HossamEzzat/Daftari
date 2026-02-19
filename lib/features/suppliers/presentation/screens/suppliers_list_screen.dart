import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:matjary/features/suppliers/presentation/cubit/suppliers_cubit.dart';
import 'package:matjary/features/suppliers/presentation/cubit/suppliers_state.dart';
import 'package:matjary/features/suppliers/domain/repositories/supplier_repository.dart';
import 'add_supplier_screen.dart';
import 'supplier_details_screen.dart';

class SuppliersListScreen extends StatelessWidget {
  const SuppliersListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SuppliersCubit(context.read<SupplierRepository>())..loadSuppliers(),
      child: const SuppliersListView(),
    );
  }
}

class SuppliersListView extends StatelessWidget {
  const SuppliersListView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('الموردين')),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFD4AF37),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<SuppliersCubit>(),
                child: const AddSupplierScreen(),
              ),
            ),
          );
        },
        child: const Icon(Icons.add, color: Colors.black),
      ),
      body: BlocBuilder<SuppliersCubit, SuppliersState>(
        builder: (context, state) {
          if (state is SuppliersLoading) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFD4AF37)),
            );
          } else if (state is SuppliersError) {
            return Center(child: Text('خطأ: ${state.message}'));
          } else if (state is SuppliersLoaded) {
            if (state.suppliers.isEmpty) {
              return const Center(
                child: Text(
                  "لا يوجد موردين حتى الان",
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: state.suppliers.length,
              itemBuilder: (context, index) {
                final supplier = state.suppliers[index];
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
                            supplier.name[0].toUpperCase(),
                            style: const TextStyle(
                              color: Color(0xFFFFD700),
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        supplier.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          supplier.phone,
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
                                supplier.balance.abs().toStringAsFixed(2),
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: supplier.balance > 0
                                      ? const Color(0xFFCF6679)
                                      : const Color(0xFF00BFA5),
                                  fontFamily: 'Roboto',
                                ),
                              ),
                              Text(
                                supplier.balance > 0 ? "عليك" : "لك",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: supplier.balance > 0
                                      ? const Color(0xFFCF6679)
                                      : const Color(0xFF00BFA5),
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
                                _showEditSupplierDialog(context, supplier);
                              } else if (value == 'delete') {
                                _confirmDeleteSupplier(context, supplier);
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
                                SupplierDetailsScreen(supplier: supplier),
                          ),
                        ).then((_) {
                          if (context.mounted) {
                            context.read<SuppliersCubit>().loadSuppliers();
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

  void _showEditSupplierDialog(BuildContext context, dynamic supplier) {
    final nameController = TextEditingController(text: supplier.name);
    final phoneController = TextEditingController(text: supplier.phone);
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
              "تعديل المورد",
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
                labelText: "اسم المورد",
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
              final updated = supplier.copyWith(
                name: nameController.text,
                phone: phoneController.text,
              );
              context.read<SuppliersCubit>().updateSupplier(updated);
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

  void _confirmDeleteSupplier(BuildContext context, dynamic supplier) {
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
          "هل أنت متأكد من حذف ${supplier.name}؟ سيتم حذف جميع العمليات المرتبطة.",
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
              context.read<SuppliersCubit>().deleteSupplier(supplier.id);
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
