import 'package:cloud_firestore/cloud_firestore.dart';

class TrackingTab {
  final String id;
  final String name;
  final String familyId;
  final DateTime createdAt;

  TrackingTab({
    required this.id,
    required this.name,
    required this.familyId,
    required this.createdAt,
  });

  factory TrackingTab.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return TrackingTab(
      id: doc.id,
      name: data['name'] ?? '',
      familyId: data['familyId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'familyId': familyId,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
