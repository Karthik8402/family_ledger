import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';

/// A reusable transaction item card widget with swipe actions
class TransactionItemWidget extends StatelessWidget {
  final TransactionModel transaction;
  final String currentUserId;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const TransactionItemWidget({
    super.key,
    required this.transaction,
    required this.currentUserId,
    this.onEdit,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == TransactionModel.typeIncome;
    final isPrivate = transaction.visibility == TransactionModel.visibilityPrivate;
    final theme = Theme.of(context);
    
    // Only allow edit/delete if:
    // 1. Transaction belongs to current user
    // 2. Transaction was created within the last 30 minutes
    final isOwner = transaction.userId == currentUserId;
    final minutesSinceCreation = DateTime.now().difference(transaction.date).inMinutes;
    final withinTimeLimit = minutesSinceCreation <= 30;
    final canModify = isOwner && withinTimeLimit;
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Slidable(
          key: ValueKey(transaction.id),
          enabled: canModify,
          endActionPane: ActionPane(
            motion: const BehindMotion(),
            extentRatio: 0.4,
            children: [
              CustomSlidableAction(
                onPressed: (_) => onEdit?.call(),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.edit, size: 22),
                    SizedBox(height: 4),
                    Text('Edit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              CustomSlidableAction(
                onPressed: (_) => onDelete?.call(),
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete, size: 22),
                    SizedBox(height: 4),
                    Text('Delete', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              color: theme.cardTheme.color,
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isIncome ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
              title: Text(
                transaction.category,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          DateFormat('MMM d').format(transaction.date),
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 13),
                        ),
                        if (isPrivate) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text('Private', style: TextStyle(fontSize: 10, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                          ),
                        ] else if (transaction.userName.isNotEmpty) ...[
                           const SizedBox(width: 6),
                           Text('• ${transaction.userName.split('@')[0]}', style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.5), fontSize: 12)),
                        ],
                      ],
                    ),
                    if (transaction.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.sticky_note_2_outlined,
                            size: 12,
                            color: theme.colorScheme.primary.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Note: ',
                            style: TextStyle(
                              color: theme.colorScheme.primary.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              transaction.note,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                fontSize: 12,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              trailing: Text(
                '${isIncome ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isIncome ? Colors.green : Colors.red,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
