import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Animation Import
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/transaction_model.dart';
import 'add_transaction_screen.dart';
import 'members_stats_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Date Filtering State
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Search State
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final user = FirebaseAuth.instance.currentUser;
    final String currentUserId = user?.uid ?? 'test_user_id';

    return Scaffold(
      appBar: _buildAppBar(),
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
          final filteredTransactions = _filterTransactions(allTransactions);
          
          // Calculate Totals
          final familySpend = _calculateTotal(filteredTransactions, TransactionModel.typeExpense, TransactionModel.visibilityShared);
          final personalSpend = _calculateTotal(filteredTransactions, TransactionModel.typeExpense, TransactionModel.visibilityPrivate, userId: currentUserId);
          final familyIncome = _calculateTotal(filteredTransactions, TransactionModel.typeIncome, TransactionModel.visibilityShared);
          final balance = familyIncome - familySpend;

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Filter UI
                      _buildDateSelector(),
                      const SizedBox(height: 24),

                      // Main Balance Card (Animated)
                      _buildTotalBalanceCard(balance, familyIncome, familySpend)
                          .animate().slideY(begin: 0.2, end: 0, duration: 500.ms, curve: Curves.easeOut).fadeIn(),
                      const SizedBox(height: 20),

                      // Secondary Stats Row (Animated)
                      Row(
                        children: [
                          Expanded(child: _buildStatCard('My Spending', personalSpend, Icons.person, Colors.purple)),
                          const SizedBox(width: 16),
                          Expanded(child: _buildStatCard('Family Savings', balance > 0 ? balance : 0, Icons.savings, Colors.teal)),
                        ],
                      ).animate().slideY(begin: 0.3, end: 0, delay: 200.ms, duration: 500.ms, curve: Curves.easeOut).fadeIn(),
                      
                      const SizedBox(height: 32),

                      // Transactions Header
                      Text(
                        'Recent Transactions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      ).animate().fadeIn(delay: 400.ms),
                    ],
                  ),
                ),
              ),

              // Transaction List
              if (filteredTransactions.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long, size: 48, color: Colors.grey),
                        SizedBox(height: 16),
                        Text('No transactions found', style: TextStyle(color: Colors.grey)),
                      ],
                    ).animate().scale(),
                  ),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final transaction = filteredTransactions[index];
                      // Staggered Animation for List Items
                      return _buildTransactionItem(transaction, currentUserId)
                          .animate().slideX(begin: 0.2, end: 0, delay: (50 * index).ms).fadeIn();
                    },
                    childCount: filteredTransactions.length,
                  ),
                ),
                
              const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddTransactionScreen()),
          );
        },
        label: const Text('Add New'),
        icon: const Icon(Icons.add_circle_outline),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Colors.white,
      ).animate().scale(delay: 500.ms),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
                focusedBorder: InputBorder.none,
                enabledBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            )
          : const Text('Family Ledger'),
      actions: [
        IconButton(
          icon: Icon(_isSearching ? Icons.close : Icons.search),
          onPressed: () {
            setState(() {
              if (_isSearching) {
                _isSearching = false;
                _searchQuery = '';
                _searchController.clear();
              } else {
                _isSearching = true;
              }
            });
          },
        ),
        if (!_isSearching) ...[
          IconButton(
            icon: const Icon(Icons.pie_chart_outline),
            tooltip: 'Stats',
            onPressed: () {
              Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (_) => MembersStatsScreen(month: _selectedMonth, year: _selectedYear),
                 ),
               );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign Out',
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
            },
          ),
        ],
      ],
    );
  }

  Widget _buildDateSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Overview',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(
              DateFormat('MMMM yyyy').format(DateTime(_selectedYear, _selectedMonth)),
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Row(
            children: [
              DropdownButton<int>(
                value: _selectedMonth,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                onChanged: (val) => setState(() => _selectedMonth = val!),
                items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(DateFormat('MMM').format(DateTime(0, index + 1))))),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedYear,
                underline: const SizedBox(),
                icon: const SizedBox.shrink(), // Hide icon for year
                style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w600),
                onChanged: (val) => setState(() => _selectedYear = val!),
                items: List.generate(5, (index) {
                   int year = DateTime.now().year - 2 + index;
                   return DropdownMenuItem(value: year, child: Text(year.toString()));
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTotalBalanceCard(double balance, double income, double expense) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withValues(alpha: 0.8), // Updated to withValues
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3), blurRadius: 15, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.account_balance_wallet, color: Colors.white),
              ),
              const SizedBox(width: 12),
              const Text('Shared Balance', style: TextStyle(color: Colors.white70, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            '₹${balance.toStringAsFixed(2)}', // Currency Change
            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildBalanceDetail(Icons.arrow_downward, 'Income', income, Colors.greenAccent),
              const SizedBox(width: 24),
              _buildBalanceDetail(Icons.arrow_upward, 'Expenses', expense, Colors.redAccent.shade100),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBalanceDetail(IconData icon, String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(0)}', // Currency Change
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16),
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, double amount, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.1)),
        boxShadow: [
           BoxShadow(color: Colors.grey.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Colors.grey[500], fontSize: 13)),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toStringAsFixed(0)}', // Currency Change
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction, String currentUserId) {
    final isIncome = transaction.type == TransactionModel.typeIncome;
    final isPrivate = transaction.visibility == TransactionModel.visibilityPrivate;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withValues(alpha: 0.05)),
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
          child: Row(
            children: [
              Text(
                DateFormat('MMM d').format(transaction.date),
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
              if (isPrivate) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('Private', style: TextStyle(fontSize: 10, color: Colors.grey)),
                ),
              ] else if (transaction.userName.isNotEmpty) ...[
                 const SizedBox(width: 6),
                 Text('• ${transaction.userName.split('@')[0]}', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
              ],
            ],
          ),
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'}₹${transaction.amount.toStringAsFixed(2)}', // Currency Change
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }

  // --- Helper Methods ---

  List<TransactionModel> _filterTransactions(List<TransactionModel> all) {
     return all.where((t) {
        final matchesDate = t.date.month == _selectedMonth && t.date.year == _selectedYear;
        final matchesSearch = _searchQuery.isEmpty || t.category.toLowerCase().contains(_searchQuery);
        return matchesDate && matchesSearch;
     }).toList()
       ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
  }

  double _calculateTotal(List<TransactionModel> txs, String type, String visibility, {String? userId}) {
    return txs
        .where((t) {
          final matchesType = t.type == type;
          final matchesVis = t.visibility == visibility;
          final matchesUser = userId == null || t.userId == userId;
          return matchesType && matchesVis && matchesUser;
        })
        .fold(0.0, (sum, t) => sum + t.amount);
  }
}
