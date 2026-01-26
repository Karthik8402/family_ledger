import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Animation Import
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/transaction_model.dart';
import '../models/family_model.dart';
import '../models/user_model.dart';
import '../providers/theme_provider.dart';
import 'add_transaction_screen.dart';
import 'stats_screen.dart';
import '../widgets/app_bar_action_button.dart';

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
  
  // Stream State
  late Stream<List<TransactionModel>> _transactionStream;

  @override
  void initState() {
    super.initState();
    // Initialize stream once to avoid reloading on every set state
    _transactionStream = Provider.of<FirestoreService>(context, listen: false).getTransactions();
  }

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
        stream: _transactionStream,
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
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: AppBarActionButton(
            icon: _isSearching ? Icons.close : Icons.search,
            tooltip: _isSearching ? 'Close Search' : 'Search',
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
        ),
        if (!_isSearching) ...[
          // Theme Toggle Button
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return AppBarActionButton(
                icon: themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                tooltip: 'Toggle Theme',
                onPressed: () => themeProvider.toggleTheme(),
              );
            },
          ),
          AppBarActionButton(
            icon: Icons.pie_chart_outline,
            tooltip: 'Stats',
            onPressed: () {
              Navigator.push(
                 context,
                 MaterialPageRoute(
                   builder: (_) => StatsScreen(month: _selectedMonth, year: _selectedYear),
                 ),
               );
            },
          ),
          AppBarActionButton(
            icon: Icons.family_restroom,
            tooltip: 'Family Info',
            onPressed: () => _showFamilyInfoSheet(context),
          ),
          AppBarActionButton(
            icon: Icons.logout,
            tooltip: 'Sign Out',
            onPressed: () {
              Provider.of<AuthService>(context, listen: false).signOut();
            },
          ),
          const SizedBox(width: 8),
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
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Theme.of(context).dividerColor),
          ),
          child: Row(
            children: [
              DropdownButton<int>(
                value: _selectedMonth,
                underline: const SizedBox(),
                icon: const Icon(Icons.arrow_drop_down, size: 20),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
                onChanged: (val) => setState(() => _selectedMonth = val!),
                items: List.generate(12, (index) => DropdownMenuItem(value: index + 1, child: Text(DateFormat('MMM').format(DateTime(0, index + 1))))),
              ),
              const SizedBox(width: 8),
              DropdownButton<int>(
                value: _selectedYear,
                underline: const SizedBox(),
                icon: const SizedBox.shrink(), // Hide icon for year
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface, fontWeight: FontWeight.w600),
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
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.1)),
        boxShadow: [
           BoxShadow(color: Theme.of(context).shadowColor.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.1),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 13)),
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
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isIncome ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
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
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 13),
              ),
              if (isPrivate) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text('Private', style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ),
              ] else if (transaction.userName.isNotEmpty) ...[
                 const SizedBox(width: 6),
                 Text('• ${transaction.userName.split('@')[0]}', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5), fontSize: 12)),
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

  void _showFamilyInfoSheet(BuildContext context) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final userProfile = await firestoreService.getUserProfile(user.uid);
    
    if (userProfile?.familyId == null) return;
    
    final family = await firestoreService.getFamily(userProfile!.familyId!);
    if (family == null) return;

    final members = await firestoreService.getFamilyMembers(userProfile.familyId!);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // Family Icon
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.family_restroom, size: 40, color: primaryColor),
                  ),
                  const SizedBox(height: 16),
                  
                  // Family Name
                  Text(
                    family.name,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  
                  // Family Code Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: primaryColor.withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'FAMILY CODE',
                          style: TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.5,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              family.code,
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 6,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            IconButton(
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: family.code));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.check, color: Colors.white),
                                        SizedBox(width: 12),
                                        Text('Code copied to clipboard!'),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                );
                              },
                              icon: Icon(Icons.copy, color: primaryColor),
                              tooltip: 'Copy Code',
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Share this code with family members',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Members Section
                  Row(
                    children: [
                      Text(
                        'Members (${members.length})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  ...members.map((member) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: primaryColor.withOpacity(0.15),
                          child: Text(
                            member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                            style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(member.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              Text(
                                member.email,
                                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        ),
                        if (member.id == family.ownerId)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.amber.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Owner',
                              style: TextStyle(fontSize: 11, color: Colors.amber, fontWeight: FontWeight.bold),
                            ),
                          ),
                      ],
                    ),
                  )),
                ],
              ),
            ),
            SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ],
        ),
      ),
    );
  }
}

