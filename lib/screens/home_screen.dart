import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Animation Import
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/tracking_tab_model.dart';
import '../providers/theme_provider.dart';
import 'add_transaction_screen.dart';
import 'stats_screen.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/home/family_info_sheet.dart';
import '../widgets/home/transaction_item.dart';
import '../widgets/home/stat_card.dart';
import '../widgets/home/date_selector.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Date Filtering State
  int _selectedMonth = DateTime.now().month;
  int _selectedYear = DateTime.now().year;

  // Search State
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // Tab State
  TabController? _tabController;
  List<TrackingTab> _tabs = [];
  bool _isLoadingTabs = true;

  @override
  void initState() {
    super.initState();
    // Sync latest user profile data (photo, name) from Google
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncUserProfile());
  }

  Future<void> _syncUserProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    final user = authService.currentUser;
    
    if (user != null) {
      await firestoreService.syncGoogleProfile(
        user.id, 
        user.displayName, 
        user.email, 
        user.photoUrl
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _updateTabController(int newLength) {
    if (_tabController == null || _tabController!.length != newLength) {
      final oldIndex = _tabController?.index ?? 0;
      _tabController?.dispose();
      _tabController = TabController(
        length: newLength, 
        vsync: this,
        initialIndex: oldIndex < newLength ? oldIndex : 0,
      );
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) setState(() {});
      });
    }
  }

  void _showAddTabDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Tracking Tab'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Tab Name (e.g., Vacation, Renovation)',
            border: OutlineInputBorder(),
          ),
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await Provider.of<FirestoreService>(context, listen: false).createTrackingTab(controller.text.trim());
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _deleteTab(TrackingTab tab) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Tab?'),
        content: Text('Are you sure you want to delete "${tab.name}"? Transactions in this tab will NOT be deleted but will effectively disappear from this view.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await Provider.of<FirestoreService>(context, listen: false).deleteTrackingTab(tab.id);
              if (mounted) Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    final String currentUserId = user?.id ?? 'test_user_id';

    return StreamBuilder<List<TrackingTab>>(
      stream: firestoreService.streamTrackingTabs(),
      builder: (context, tabSnapshot) {
        // Handle Tabs
        final trackingTabs = tabSnapshot.data ?? [];
        final totalTabs = 2 + trackingTabs.length; // Expenses + Income + Custom Tabs
        
        // Update Controller safely
        _updateTabController(totalTabs); // Only recreates if length changes

        return Scaffold(
          appBar: _buildAppBar(trackingTabs),
          body: StreamBuilder<List<TransactionModel>>(
            stream: firestoreService.getTransactions(),
            builder: (context, txnSnapshot) {
              // if (txnSnapshot.connectionState == ConnectionState.waiting) {
              //    return const Center(child: CircularProgressIndicator());
              // }
              
              final allTransactions = txnSnapshot.data ?? [];
              final filteredTransactions = _filterTransactions(allTransactions);

              return TabBarView(
                controller: _tabController,
                children: [
                   // 1. Expenses Tab (Main)
                  _buildTransactionTab(
                    context, 
                    filteredTransactions, 
                    TransactionModel.typeExpense, 
                    currentUserId,
                    Colors.redAccent,
                    'Total Expenses',
                    Icons.arrow_downward,
                    tabId: null, // Main tab
                  ),
                  
                  // 2. Income Tab (Main)
                  _buildTransactionTab(
                    context, 
                    filteredTransactions, 
                    TransactionModel.typeIncome, 
                    currentUserId,
                    Colors.greenAccent,
                    'Total Income',
                    Icons.arrow_upward,
                    tabId: null, // Main tab
                  ),

                  // 3+. Custom Tracking Tabs
                  ...trackingTabs.map((tab) => _buildCustomTab(
                    context,
                    filteredTransactions,
                    currentUserId,
                    tab,
                  )),
                ],
              );
            },
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              final index = _tabController!.index;
              String? initialType;
              String? initialTabId;

              if (index == 0) {
                initialType = TransactionModel.typeExpense;
              } else if (index == 1) {
                initialType = TransactionModel.typeIncome;
              } else {
                // Custom Tab
                initialTabId = trackingTabs[index - 2].id;
              }
                  
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddTransactionScreen(
                  initialType: initialType,
                  initialTabId: initialTabId,
                )),
              );
            },
            label: const Text('Add New'),
            icon: const Icon(Icons.add_circle_outline),
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Colors.white,
          ).animate().scale(delay: 500.ms),
        );
      },
    );
  }

  PreferredSizeWidget _buildAppBar(List<TrackingTab> customTabs) {
    return AppBar(
      title: _isSearching
          ? TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(fontSize: 18),
              decoration: const InputDecoration(
                hintText: 'Search...',
                border: InputBorder.none,
                filled: false,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            )
          : const Text('Family Ledger'),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Colors.grey,
        isScrollable: true, // Allow scrolling if many tabs
        tabs: [
          const Tab(text: 'Expenses', icon: Icon(Icons.credit_card)), // Distinct icon for Expenses
          const Tab(text: 'Income', icon: Icon(Icons.savings)), // Distinct icon for Income
          ...customTabs.map((tab) => Tab(
            text: tab.name,
            icon: const Icon(Icons.label_important_outline),
          )),
          // Hidden tab for add button visually? No, add button in actions.
        ],
      ),
      actions: [
        if (!_isSearching) ...[
           IconButton(
             icon: const Icon(Icons.playlist_add),
             tooltip: 'Add Tracking Tab',
             onPressed: _showAddTabDialog,
           ),
           // ... other actions ...
        ],
        // Existing Actions
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
          Consumer<ThemeProvider>(
            builder: (context, themeProvider, child) {
              return ThemeToggleButton(
                isDark: themeProvider.isDarkMode,
                onToggle: () => themeProvider.toggleTheme(),
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
        ]
      ],
    );
  }

  // --- Main Tabs (Expense / Income) ---
  Widget _buildTransactionTab(
    BuildContext context, 
    List<TransactionModel> allTransactions, 
    String type, 
    String currentUserId,
    Color color,
    String totalLabel,
    IconData totalIcon,
    {required String? tabId}
  ) {
    // Filter by type AND tabId
    // For main tabs, tabId is null, so we show transactions where t.tabId == null
    final tabTransactions = allTransactions.where((t) => t.type == type && t.tabId == tabId).toList();
    
    // Calculate Totals
    final sharedSum = _calculateTotal(tabTransactions, type, TransactionModel.visibilityShared);
    final myPrivateSum = _calculateTotal(tabTransactions, type, TransactionModel.visibilityPrivate, userId: currentUserId);

    // Calculate search results total
    final searchResultsTotal = tabTransactions.fold(0.0, (sum, t) => sum + t.amount);

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDateSelector(),
                const SizedBox(height: 24),
                
                // Show Search Results Summary if searching
                if (_searchQuery.isNotEmpty) ...[
                  _buildSearchResultsCard(tabTransactions.length, searchResultsTotal, color),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildTypeStatCard(totalLabel, sharedSum, color, totalIcon, myPrivateSum)
                      .animate().slideY(begin: 0.2, end: 0, duration: 250.ms, curve: Curves.easeOut).fadeIn(),
                ],
                
                const SizedBox(height: 32),
                Text(
                  _searchQuery.isNotEmpty ? 'Search Results' : 'Recent $type',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
        ),
        _buildTransactionList(tabTransactions, currentUserId, type),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  // --- Custom Tracking Tabs ---
  Widget _buildCustomTab(
    BuildContext context, 
    List<TransactionModel> allTransactions, 
    String currentUserId,
    TrackingTab tab,
  ) {
    // Filter transactions for this tab
    final tabTransactions = allTransactions.where((t) => t.tabId == tab.id).toList();
    
    // Calculate stats specifically for this tab
    // Income - Expense
    final income = tabTransactions.where((t) => t.type == TransactionModel.typeIncome).fold(0.0, (sum, t) => sum + t.amount);
    final expense = tabTransactions.where((t) => t.type == TransactionModel.typeExpense).fold(0.0, (sum, t) => sum + t.amount);
    final balance = income - expense;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: _buildDateSelector()), // Wrap in Expanded to fill space
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.grey), 
                      onPressed: () => _deleteTab(tab),
                      tooltip: 'Delete Tab',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Custom Tab Summary Card
                 Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade800, Colors.blue.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(tab.name, style: const TextStyle(color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 24),
                       Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                           Column(
                             children: [
                               const Text('Income', style: TextStyle(color: Colors.white70, fontSize: 14)),
                               const SizedBox(height: 8),
                               Text(
                                 '₹${income.toStringAsFixed(2)}', 
                                 style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                               ),
                               const SizedBox(height: 4),
                               const Icon(Icons.arrow_downward, color: Colors.greenAccent, size: 20),
                             ],
                           ),
                           Container(width: 1, height: 50, color: Colors.white24),
                           Column(
                             children: [
                               const Text('Expense', style: TextStyle(color: Colors.white70, fontSize: 14)),
                               const SizedBox(height: 8),
                               Text(
                                 '₹${expense.toStringAsFixed(2)}', 
                                 style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                               ),
                               const SizedBox(height: 4),
                               const Icon(Icons.arrow_upward, color: Colors.redAccent, size: 20),
                             ],
                           ),
                        ],
                      )
                    ],
                  ),
                ).animate().fadeIn(duration: 300.ms), // Removed slideY
                
                const SizedBox(height: 32),
                Text(
                  'Transactions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ).animate().fadeIn(delay: 200.ms),
              ],
            ),
          ),
        ),
        _buildTransactionList(tabTransactions, currentUserId, 'Transactions'),
        const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
      ],
    );
  }

  Widget _buildTransactionList(List<TransactionModel> transactions, String currentUserId, String typeLabel) {
    if (transactions.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 48, color: Colors.grey),
              SizedBox(height: 16),
              Text('No $typeLabel found', style: TextStyle(color: Colors.grey)),
            ],
          ).animate().scale(),
        ),
      );
    }
    
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final transaction = transactions[index];
          return _buildTransactionItem(transaction, currentUserId)
              .animate().slideX(begin: 1.0, end: 0, delay: (50 * index).ms, duration: 400.ms, curve: Curves.easeOut).fadeIn(); // Right to Left
        },
        childCount: transactions.length,
      ),
    );
  }

  Widget _buildDateSelector() {
    return DateSelectorWidget(
      selectedMonth: _selectedMonth,
      selectedYear: _selectedYear,
      onMonthChanged: (val) => setState(() => _selectedMonth = val),
      onYearChanged: (val) => setState(() => _selectedYear = val),
    );
  }

  Widget _buildTypeStatCard(String title, double sharedAmount, Color color, IconData icon, double privateAmount) {
    return StatCardWidget(
      title: title,
      sharedAmount: sharedAmount,
      privateAmount: privateAmount,
      color: color,
      icon: icon,
    );
  }
  Widget _buildTransactionItem(TransactionModel transaction, String currentUserId) {
    return TransactionItemWidget(transaction: transaction, currentUserId: currentUserId);
  }

  // --- Helper Methods ---

  Widget _buildBalanceDetail(IconData icon, String label, double amount, Color color) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7))),
        const SizedBox(height: 4),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  // Search Results Summary Card
  Widget _buildSearchResultsCard(int count, double total, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.search, color: color),
              const SizedBox(width: 8),
              Text(
                'Results for "$_searchQuery"',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('$count', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
                  Text('Transactions', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
              Container(width: 1, height: 40, color: color.withOpacity(0.3)),
              Column(
                children: [
                  Text('₹${total.toStringAsFixed(2)}', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
                  Text('Total Amount', style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
                ],
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> all) {
     return all.where((t) {
        final matchesDate = t.date.month == _selectedMonth && t.date.year == _selectedYear;
        
        // Improved Search Logic
        final query = _searchQuery.toLowerCase().trim();
        final matchesSearch = _searchQuery.isEmpty || 
                              t.category.toLowerCase().contains(query) || 
                              t.amount.toString().contains(query) ||
                              t.userName.toLowerCase().contains(query);
                              
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

  // Modern overlay toast that appears on top of everything
  void _showModernToast(BuildContext context, String message, IconData icon, Color color) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        child: Material(
          color: Colors.transparent,
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: 0.8 + (0.2 * value),
                child: Opacity(
                  opacity: value.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color.withOpacity(0.9), color.withOpacity(0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // Auto-dismiss after 2 seconds with fade-out
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  void _showFamilyInfoSheet(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    final firestoreService = Provider.of<FirestoreService>(context, listen: false);
    
    showFamilyInfoSheet(
      context: context,
      firestoreService: firestoreService,
      userId: user.id,
    );
  }
}
