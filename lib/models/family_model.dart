import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math';

class FamilyModel {
  final String id;
  final String name;
  final String code; // 6-char code for joining
  final String ownerId;
  final List<String> memberIds;
  final DateTime createdAt;

  FamilyModel({
    required this.id,
    required this.name,
    required this.code,
    required this.ownerId,
    required this.memberIds,
    required this.createdAt,
  });

  factory FamilyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FamilyModel(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      ownerId: data['ownerId'] ?? '',
      memberIds: List<String>.from(data['memberIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'ownerId': ownerId,
      'memberIds': memberIds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Generate a random 6-character uppercase code
  static String generateCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(random.nextInt(chars.length))),
    );
  }

  bool isOwner(String userId) => ownerId == userId;
  
  bool isMember(String userId) => memberIds.contains(userId);
}
