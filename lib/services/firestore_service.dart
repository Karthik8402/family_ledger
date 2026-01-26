import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/family_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection References
  CollectionReference get _transactions => _db.collection('transactions');
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _families => _db.collection('families');

  // ========== USER METHODS ==========

  // Create user profile
  Future<void> createUserProfile(String userId, String name, String email) async {
    await _users.doc(userId).set({
      'name': name,
      'email': email,
      'familyId': null,
      'createdAt': Timestamp.now(),
    });
  }

  // Get user profile
  Future<UserModel?> getUserProfile(String userId) async {
    final doc = await _users.doc(userId).get();
    if (doc.exists) {
      return UserModel.fromFirestore(doc);
    }
    return null;
  }

  // Stream user profile
  Stream<UserModel?> streamUserProfile(String userId) {
    return _users.doc(userId).snapshots().map((doc) {
      if (doc.exists) {
        return UserModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Update user's familyId (creates doc if not exists)
  Future<void> updateUserFamily(String userId, String? familyId) async {
    final user = _auth.currentUser;
    await _users.doc(userId).set({
      'familyId': familyId,
      'email': user?.email ?? '',
      'name': user?.email?.split('@')[0] ?? 'User',
      'createdAt': Timestamp.now(),
    }, SetOptions(merge: true));
  }

  // ========== FAMILY METHODS ==========

  // Create new family
  Future<FamilyModel> createFamily(String name, String ownerId) async {
    final code = FamilyModel.generateCode();
    final docRef = await _families.add({
      'name': name,
      'code': code,
      'ownerId': ownerId,
      'memberIds': [ownerId],
      'createdAt': Timestamp.now(),
    });

    // Update user's familyId
    await updateUserFamily(ownerId, docRef.id);

    final doc = await docRef.get();
    return FamilyModel.fromFirestore(doc);
  }

  // Join family by code
  Future<FamilyModel?> joinFamilyByCode(String code, String userId) async {
    final query = await _families.where('code', isEqualTo: code.toUpperCase()).limit(1).get();
    
    if (query.docs.isEmpty) {
      throw Exception('Family not found. Check the code.');
    }

    final familyDoc = query.docs.first;
    final family = FamilyModel.fromFirestore(familyDoc);

    if (family.memberIds.contains(userId)) {
      throw Exception('You are already a member of this family.');
    }

    // Add user to family members
    await familyDoc.reference.update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });

    // Update user's familyId
    await updateUserFamily(userId, familyDoc.id);

    return FamilyModel.fromFirestore(await familyDoc.reference.get());
  }

  // Get family by ID
  Future<FamilyModel?> getFamily(String familyId) async {
    final doc = await _families.doc(familyId).get();
    if (doc.exists) {
      return FamilyModel.fromFirestore(doc);
    }
    return null;
  }

  // Stream family
  Stream<FamilyModel?> streamFamily(String familyId) {
    return _families.doc(familyId).snapshots().map((doc) {
      if (doc.exists) {
        return FamilyModel.fromFirestore(doc);
      }
      return null;
    });
  }

  // Get family members
  Future<List<UserModel>> getFamilyMembers(String familyId) async {
    final family = await getFamily(familyId);
    if (family == null) return [];

    final List<UserModel> members = [];
    for (final memberId in family.memberIds) {
      final user = await getUserProfile(memberId);
      if (user != null) {
        members.add(user);
      }
    }
    return members;
  }

  // Remove member from family (owner only)
  Future<void> removeFamilyMember(String familyId, String memberId, String requesterId) async {
    final family = await getFamily(familyId);
    if (family == null) throw Exception('Family not found');
    if (family.ownerId != requesterId) throw Exception('Only owner can remove members');
    if (memberId == family.ownerId) throw Exception('Owner cannot be removed');

    await _families.doc(familyId).update({
      'memberIds': FieldValue.arrayRemove([memberId]),
    });

    await updateUserFamily(memberId, null);
  }

  // Leave family
  Future<void> leaveFamily(String userId) async {
    final user = await getUserProfile(userId);
    if (user?.familyId == null) return;

    final family = await getFamily(user!.familyId!);
    if (family == null) return;

    if (family.ownerId == userId) {
      throw Exception('Owner cannot leave. Transfer ownership or delete family.');
    }

    await _families.doc(family.id).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });

    await updateUserFamily(userId, null);
  }

  // ========== TRANSACTION METHODS ==========

  // Add Transaction (now includes familyId)
  Future<void> addTransaction(TransactionModel transaction) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Not authenticated');

    final userProfile = await getUserProfile(user.uid);
    if (userProfile?.familyId == null) throw Exception('Join a family first');

    final data = transaction.toMap();
    data['familyId'] = userProfile!.familyId;
    data['userName'] = userProfile.name; // Use name instead of email

    await _transactions.add(data);
  }

  // Get transactions for family (real-time stream)
  Stream<List<TransactionModel>> getTransactions() async* {
    final user = _auth.currentUser;
    if (user == null) {
      yield [];
      return;
    }

    // Simplified approach: Fetch familyId once, then stream transactions.
    // We use await to get the initial family ID to avoid asyncExpand blocking issues.
    final userDoc = await _users.doc(user.uid).get();
    
    if (!userDoc.exists) {
      yield [];
      return;
    }
    
    final userData = userDoc.data() as Map<String, dynamic>?;
    final familyId = userData?['familyId'];
    
    if (familyId == null) {
      yield [];
      return;
    }

    // Real-time stream of transactions
    yield* _transactions
        .where('familyId', isEqualTo: familyId)
        .snapshots()
        .map((snapshot) {
          final transactions = snapshot.docs
              .map((doc) => TransactionModel.fromFirestore(doc))
              .where((txn) {
                // Privacy logic: shared = all family sees, private = only owner sees
                bool isShared = txn.visibility == 'shared';
                bool isMyPrivate = txn.visibility == 'private' && txn.userId == user.uid;
                return isShared || isMyPrivate;
              })
              .toList();
          
          // Sort client-side
          transactions.sort((a, b) => b.date.compareTo(a.date));
          return transactions;
        });
  }

  // Calculate family total
  double calculateHomeTotal(List<TransactionModel> transactions) {
    return transactions
        .where((t) => t.visibility == 'shared')
        .fold(0.0, (sum, t) => t.type == 'expense' ? sum + t.amount : sum - t.amount);
  }

  double calculatePersonalSpend(List<TransactionModel> transactions, String userId) {
    return transactions
        .where((t) => t.visibility == 'private' && t.userId == userId && t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}
