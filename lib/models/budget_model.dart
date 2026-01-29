import 'package:cloud_firestore/cloud_firestore.dart';

class BudgetModel {
  final String id;
  final String familyId;
  final String categoryName;
  final double amount;
  final int month;
  final int year;

  BudgetModel({
    required this.id,
    required this.familyId,
    required this.categoryName,
    required this.amount,
    required this.month,
    required this.year,
  });

  factory BudgetModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetModel(
      id: doc.id,
      familyId: data['familyId'] ?? '',
      categoryName: data['categoryName'] ?? '',
      amount: (data['amount'] as num).toDouble(),
      month: data['month'] ?? DateTime.now().month,
      year: data['year'] ?? DateTime.now().year,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'familyId': familyId,
      'categoryName': categoryName,
      'amount': amount,
      'month': month,
      'year': year,
    };
  }
}
