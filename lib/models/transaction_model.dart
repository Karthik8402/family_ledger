import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionModel {
  static const String typeExpense = 'expense';
  static const String typeIncome = 'income';
  static const String visibilityShared = 'shared';
  static const String visibilityPrivate = 'private';

  final String id;
  final double amount;
  final String category;
  final DateTime date;
  final String userId;
  final String userName;
  final String type; // use typeExpense or typeIncome
  final String visibility; // use visibilityShared or visibilityPrivate
  final String? familyId;
  final String? tabId;
  final String note;

  TransactionModel({
    required this.id,
    required this.amount,
    required this.category,
    required this.date,
    required this.userId,
    required this.userName,
    required this.type,
    required this.visibility,
    this.familyId,
    this.tabId,
    this.note = '',
  });

  // Convert from Firestore Document
  factory TransactionModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TransactionModel(
      id: doc.id,
      amount: (data['amount'] as num).toDouble(),
      category: data['category'] ?? '',
      date: (data['date'] as Timestamp).toDate(),
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? '',
      type: data['type'] ?? 'expense',
      visibility: data['visibility'] ?? 'private',
      familyId: data['familyId'],
      tabId: data['tabId'],
      note: data['note'] ?? '',
    );
  }

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'category': category,
      'date': Timestamp.fromDate(date),
      'userId': userId,
      'userName': userName,
      'type': type,
      'visibility': visibility,
      'familyId': familyId,
      'tabId': tabId,
      'note': note,
    };
  }
}

