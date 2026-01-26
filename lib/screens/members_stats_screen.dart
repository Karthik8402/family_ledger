import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Animations
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

class MembersStatsScreen extends StatelessWidget {
  final int month;
  final int year;

  const MembersStatsScreen({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Family Contributions'),
        elevation: 0,
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allTransactions = snapshot.data ?? [];

          // Filter: Date + Income + Shared
          final relevantTransactions = allTransactions.where((t) {
            return t.date.month == month &&
                t.date.year == year &&
                t.type == TransactionModel.typeIncome &&
                t.visibility == TransactionModel.visibilityShared;
          }).toList();

          // Group By User
          final Map<String, double> contributions = {};
          double totalPool = 0;

          for (var t in relevantTransactions) {
            final name = t.userName.isEmpty ? 'Unknown' : t.userName;
            contributions[name] = (contributions[name] ?? 0) + t.amount;
            totalPool += t.amount;
          }

          if (contributions.isEmpty) {
             return Center(
               child: Column(
                 mainAxisAlignment: MainAxisAlignment.center,
                 children: [
                   Icon(Icons.savings_outlined, size: 80, color: Colors.grey.shade300)
                    .animate().scale(duration: 600.ms, curve: Curves.easeOutBack), // Animate Icon
                   const SizedBox(height: 24),
                   Text(
                     'No contributions yet',
                     style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.grey),
                   ),
                   const SizedBox(height: 8),
                   Text(
                     DateFormat('MMMM yyyy').format(DateTime(year, month)),
                     style: TextStyle(color: Colors.grey.shade500),
                   ),
                 ],
               ),
             );
          }

          final sortedMembers = contributions.entries.toList()
            ..sort((a, b) => b.value.compareTo(a.value));

          return Column(
            children: [
              // Header Summary
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                ),
                child: Column(
                  children: [
                    Text(
                      'Total Pool',
                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14, letterSpacing: 1),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '₹${totalPool.toStringAsFixed(0)}', // Currency Change
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack), // Animation
                    const SizedBox(height: 8),
                     Text(
                      DateFormat('MMMM yyyy').format(DateTime(year, month)),
                      style: TextStyle(color: Colors.grey.shade400, fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),

              // Member List
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: sortedMembers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final member = sortedMembers[index];
                      final percentage = (member.value / totalPool);
                      
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 24,
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                              child: Text(
                                member.key[0].toUpperCase(),
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Theme.of(context).colorScheme.onPrimaryContainer
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.key.split('@')[0], 
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: percentage,
                                      minHeight: 6,
                                      backgroundColor: Colors.grey.shade200,
                                      valueColor: AlwaysStoppedAnimation(Colors.teal.shade400),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₹${member.value.toStringAsFixed(0)}', // Currency Change
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  '${(percentage * 100).toStringAsFixed(0)}%',
                                  style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ).animate().slideX(begin: 0.2, end: 0, delay: (100 * index).ms).fadeIn(); // List Animation
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
