import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Collection Reference
  CollectionReference get _transactions => _db.collection('transactions');

  // Add Transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    await _transactions.add(transaction.toMap());
  }

  // Stream of Transactions acting on the Privacy Logic
  // "If visibility == 'shared': Everyone... If 'private': ONLY the user..."
  Stream<List<TransactionModel>> getTransactions() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    // In a real generic query, Firestore doesn't support "OR" filters effectively across different fields easily in one go without composite indexes or client-side filtering.
    // However, we can query where 'visibility' is 'shared' OR 'userId' is current user.
    // A common pattern is to just query ALL and filter client side if dataset is small, 
    // OR allow read access via Rules and query normally.
    // Prompt asks for Logic implementation.
    
    // We will use a query that fetches valid transactions. 
    // Note: Complex OR queries might need index configuration.
    // For simplicity/requirement matching, we'll try to Filter.or if SDK supports it, or simple client side merge.
    // Let's assume we filter on stream.

    return _transactions
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => TransactionModel.fromFirestore(doc)).where((txn) {
        // LOGIC:
        // Shared: Everyone sees it.
        // Private: Only creator sees it.
        
        bool isShared = txn.visibility == 'shared';
        bool isMyPrivate = txn.visibility == 'private' && txn.userId == user.uid;
        
        return isShared || isMyPrivate;
      }).toList();
    });
  }

  // Calculate Totals
  double calculateHomeTotal(List<TransactionModel> transactions) {
    return transactions
        .where((t) => t.visibility == 'shared')
        .fold(0.0, (sum, t) => t.type == 'expense' ? sum + t.amount : sum - t.amount); 
        // Note: Logic for 'Home Total' usually implies constraints. 
        // Assuming 'Home Total' is net expense or just expense sum.
        // Let's assume it handles Type. expense = pos, income = neg? Or just sum of expenses?
        // Prompt says "counts towards 'Home Total'". Usually means expenses. 
        // Let's just return sum of expenses for now to be safe, or handle net.
        // Prompt: "shared... counts towards 'Home Total'".
        // Let's assume specific "Total" means "Total Expenses" for a "Ledger".
        // Or we can return object with income/expense.
    
  }

  double calculatePersonalSpend(List<TransactionModel> transactions, String userId) {
    // "counts towards 'My Personal Spend' but is hidden from the main family total"
    return transactions
        .where((t) => t.visibility == 'private' && t.userId == userId && t.type == 'expense')
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}
