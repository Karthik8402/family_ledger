import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Animation Import
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../models/transaction_model.dart';
import '../models/user_model.dart';
import '../models/tracking_tab_model.dart';
import '../providers/theme_provider.dart';
import 'add_transaction_screen.dart';
import 'stats_screen.dart';
import 'settings_screen.dart';
import '../widgets/app_bar_action_button.dart';
import '../widgets/home/family_info_sheet.dart';
import '../widgets/home/transaction_item.dart';
import '../widgets/home/stat_card.dart';
import '../widgets/home/date_selector.dart';
import '../utils/toast_utils.dart';
import '../models/filter_model.dart';
import '../widgets/filter_sheet.dart';

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

  // Advanced Filter State
  FilterModel _advancedFilter = FilterModel.empty;
  List<UserModel> _familyMembers = [];
  List<TransactionModel> _allTransactions = [];
  bool _isAddingTab = false;

  @override
  void initState() {
    super.initState();
    // Sync latest user profile data (photo, name) from Google
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncUserProfile());
  }

  Future<void> _syncUserProfile() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final user = authService.currentUser;

    if (user != null) {
      await firestoreService.syncGoogleProfile(
          user.uid, user.displayName, user.email, user.photoURL);

      // Load family members for filter
      final userProfile = await firestoreService.getUserProfile(user.uid);
      if (userProfile?.familyId != null && mounted) {
        final members =
            await firestoreService.getFamilyMembers(userProfile!.familyId!);
        setState(() => _familyMembers = members);
      }
    }
  }

  void _showFilterSheet(List<TransactionModel> transactions) {
    // Get unique categories from transactions
    final categories = transactions.map((t) => t.category).toSet().toList()
      ..sort();

    FilterSheet.show(
      context: context,
      currentFilter: _advancedFilter,
      availableCategories: categories,
      familyMembers: _familyMembers,
      onApply: (filter) {
        setState(() => _advancedFilter = filter);
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController?.dispose();
    super.dispose();
  }

  void _updateTabController(int newLength) {
    // Add 1 for the "+" add tab
    final actualLength = newLength + 1;
    if (_tabController == null || _tabController!.length != actualLength) {
      final oldIndex = _tabController?.index ?? 0;
      _tabController?.dispose();
      _tabController = TabController(
        length: actualLength,
        vsync: this,
        initialIndex:
            oldIndex < newLength ? oldIndex : 0, // Don't start on + tab
      );
      _tabController!.addListener(() {
        if (!_tabController!.indexIsChanging) setState(() {});

        // If user taps the "+" tab, show dialog
        if (_tabController!.index == actualLength - 1 && !_isAddingTab) {
          _handleNewTabSelection();
        }
      });
    }
  }

  Future<void> _handleNewTabSelection() async {
    _isAddingTab = true;
    await _showAddTabDialog();

    if (mounted && _tabController != null) {
      // Go back to previous tab or home
      int target = _tabController!.previousIndex;
      // Safety check if previous index is somehow invalid or same
      if (target >= _tabController!.length - 1 || target < 0) target = 0;

      _tabController!.animateTo(target);
      _isAddingTab = false;
    } else {
      _isAddingTab = false;
    }
  }

  Future<void> _showAddTabDialog() async {
    final controller = TextEditingController();
    await showDialog(
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
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              if (controller.text.trim().isNotEmpty) {
                await Provider.of<FirestoreService>(context, listen: false)
                    .createTrackingTab(controller.text.trim());
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
        content: Text(
            'Are you sure you want to delete "${tab.name}"? Transactions in this tab will NOT be deleted but will effectively disappear from this view.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await Provider.of<FirestoreService>(context, listen: false)
                  .deleteTrackingTab(tab.id);
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
    final String currentUserId = user?.uid ?? 'test_user_id';

    return StreamBuilder<List<TrackingTab>>(
      stream: firestoreService.streamTrackingTabs(),
      builder: (context, tabSnapshot) {
        // Handle Tabs
        final trackingTabs = tabSnapshot.data ?? [];
        final totalTabs =
            2 + trackingTabs.length; // Expenses + Income + Custom Tabs

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
              // Store for filter sheet access
              if (allTransactions.isNotEmpty && _allTransactions.isEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted)
                    setState(() => _allTransactions = allTransactions);
                });
              } else if (allTransactions.length != _allTransactions.length) {
                _allTransactions = allTransactions;
              }
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

                  // Placeholder for + tab (user never sees this as tapping + opens dialog)
                  const SizedBox.shrink(),
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
                MaterialPageRoute(
                    builder: (context) => AddTransactionScreen(
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
              onChanged: (value) =>
                  setState(() => _searchQuery = value.toLowerCase()),
            )
          : const Text('Family Ledger'),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: Theme.of(context).colorScheme.primary,
        labelColor: Theme.of(context).colorScheme.primary,
        unselectedLabelColor: Colors.grey,
        isScrollable:
            customTabs.length > 2, // Only scroll if needed, else fill width
        tabs: [
          const Tab(text: 'Expenses', icon: Icon(Icons.credit_card)),
          const Tab(text: 'Income', icon: Icon(Icons.savings)),
          ...customTabs.map((tab) => Tab(
                text: tab.name,
                icon: const Icon(Icons.label_important_outline),
              )),
          // Add Tab button as last tab
          const Tab(icon: Icon(Icons.add_circle_outline), text: 'New'),
        ],
      ),
      actions: [
        // Filter button - only visible in search mode
        if (_isSearching) ...[
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filters',
                onPressed: () => _showFilterSheet(_allTransactions),
              ),
              if (_advancedFilter.hasActiveFilters)
                Positioned(
                  right: 4,
                  top: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${_advancedFilter.activeFilterCount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
                  _advancedFilter =
                      FilterModel.empty; // Clear filters when exiting search
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
                  builder: (_) =>
                      StatsScreen(month: _selectedMonth, year: _selectedYear),
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
            icon: Icons.settings,
            tooltip: 'Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
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
      {required String? tabId}) {
    // Filter by type AND tabId
    // For main tabs, tabId is null, so we show transactions where t.tabId == null
    final tabTransactions = allTransactions
        .where((t) => t.type == type && t.tabId == tabId)
        .toList();

    // Calculate Totals
    final sharedSum = _calculateTotal(
        tabTransactions, type, TransactionModel.visibilityShared);
    final myPrivateSum = _calculateTotal(
        tabTransactions, type, TransactionModel.visibilityPrivate,
        userId: currentUserId);

    // Calculate search results total
    final searchResultsTotal =
        tabTransactions.fold(0.0, (sum, t) => sum + t.amount);

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
                  _buildSearchResultsCard(
                      tabTransactions.length, searchResultsTotal, color),
                  const SizedBox(height: 16),
                ] else ...[
                  _buildTypeStatCard(
                          totalLabel, sharedSum, color, totalIcon, myPrivateSum)
                      .animate()
                      .slideY(
                          begin: 0.2,
                          end: 0,
                          duration: 250.ms,
                          curve: Curves.easeOut)
                      .fadeIn(),
                ],

                const SizedBox(height: 32),
                Text(
                  _searchQuery.isNotEmpty ? 'Search Results' : 'Recent $type',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
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
    final tabTransactions =
        allTransactions.where((t) => t.tabId == tab.id).toList();

    // Calculate stats specifically for this tab
    // Income - Expense
    final income = tabTransactions
        .where((t) => t.type == TransactionModel.typeIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final expense = tabTransactions
        .where((t) => t.type == TransactionModel.typeExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

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
                    Expanded(
                        child:
                            _buildDateSelector()), // Wrap in Expanded to fill space
                    const SizedBox(width: 8),
                    IconButton(
                      icon:
                          const Icon(Icons.delete_outline, color: Colors.grey),
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
                      BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Column(
                    children: [
                      Text(tab.name,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 16)),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              const Text('Income',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 8),
                              Text(
                                '₹${income.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Icon(Icons.arrow_downward,
                                  color: Colors.greenAccent, size: 20),
                            ],
                          ),
                          Container(
                              width: 1, height: 50, color: Colors.white24),
                          Column(
                            children: [
                              const Text('Expense',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 14)),
                              const SizedBox(height: 8),
                              Text(
                                '₹${expense.toStringAsFixed(2)}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              const Icon(Icons.arrow_upward,
                                  color: Colors.redAccent, size: 20),
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
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
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

  Widget _buildTransactionList(List<TransactionModel> transactions,
      String currentUserId, String typeLabel) {
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
              .animate()
              .slideX(
                  begin: 1.0,
                  end: 0,
                  delay: (50 * index).ms,
                  duration: 400.ms,
                  curve: Curves.easeOut)
              .fadeIn(); // Right to Left
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

  Widget _buildTypeStatCard(String title, double sharedAmount, Color color,
      IconData icon, double privateAmount) {
    return StatCardWidget(
      title: title,
      sharedAmount: sharedAmount,
      privateAmount: privateAmount,
      color: color,
      icon: icon,
    );
  }

  Widget _buildTransactionItem(
      TransactionModel transaction, String currentUserId) {
    return TransactionItemWidget(
      transaction: transaction,
      currentUserId: currentUserId,
      onEdit: () => _editTransaction(transaction),
      onDelete: () => _confirmDeleteTransaction(transaction),
    );
  }

  void _editTransaction(TransactionModel transaction) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AddTransactionScreen(
          initialType: transaction.type,
          initialTabId: transaction.tabId,
          editTransaction: transaction,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteTransaction(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: Text(
          'Are you sure you want to delete this ${transaction.category} transaction of ₹${transaction.amount.toStringAsFixed(2)}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await Provider.of<FirestoreService>(context, listen: false)
            .deleteTransaction(transaction.id);
        if (mounted) {
          ToastUtils.showSuccess(context, 'Transaction deleted');
        }
      } catch (e) {
        if (mounted) {
          ToastUtils.showError(context, 'Failed to delete: $e');
        }
      }
    }
  }

  // --- Helper Methods ---

  // Search Results Summary Card
  Widget _buildSearchResultsCard(int count, double total, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
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
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Column(
                children: [
                  Text('$count',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text('Transactions',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6))),
                ],
              ),
              Container(
                  width: 1, height: 40, color: color.withValues(alpha: 0.3)),
              Column(
                children: [
                  Text('₹${total.toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text('Total Amount',
                      style: TextStyle(
                          color: Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.6))),
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
      // Basic date filter (month/year selector)
      final matchesDate =
          t.date.month == _selectedMonth && t.date.year == _selectedYear;

      // Search Logic
      final query = _searchQuery.toLowerCase().trim();
      final matchesSearch = _searchQuery.isEmpty ||
          t.category.toLowerCase().contains(query) ||
          t.amount.toString().contains(query) ||
          t.userName.toLowerCase().contains(query);

      // Advanced Filters
      bool matchesAdvanced = true;

      // Date range filter (overrides month/year if set)
      if (_advancedFilter.startDate != null &&
          _advancedFilter.endDate != null) {
        final afterStart = !t.date.isBefore(_advancedFilter.startDate!);
        final beforeEnd = !t.date
            .isAfter(_advancedFilter.endDate!.add(const Duration(days: 1)));
        matchesAdvanced = matchesAdvanced && afterStart && beforeEnd;
      }

      // Category filter
      if (_advancedFilter.categories.isNotEmpty) {
        matchesAdvanced =
            matchesAdvanced && _advancedFilter.categories.contains(t.category);
      }

      // Amount range filter
      if (_advancedFilter.minAmount != null) {
        matchesAdvanced =
            matchesAdvanced && t.amount >= _advancedFilter.minAmount!;
      }
      if (_advancedFilter.maxAmount != null) {
        matchesAdvanced =
            matchesAdvanced && t.amount <= _advancedFilter.maxAmount!;
      }

      // Member filter
      if (_advancedFilter.memberIds.isNotEmpty) {
        matchesAdvanced =
            matchesAdvanced && _advancedFilter.memberIds.contains(t.userId);
      }

      // If advanced date filter is set, ignore basic month/year filter
      final useBasicDateFilter =
          _advancedFilter.startDate == null && _advancedFilter.endDate == null;

      return (useBasicDateFilter ? matchesDate : true) &&
          matchesSearch &&
          matchesAdvanced;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date)); // Sort by date descending
  }

  double _calculateTotal(
      List<TransactionModel> txs, String type, String visibility,
      {String? userId}) {
    return txs.where((t) {
      final matchesType = t.type == type;
      final matchesVis = t.visibility == visibility;
      final matchesUser = userId == null || t.userId == userId;
      return matchesType && matchesVis && matchesUser;
    }).fold(0.0, (sum, t) => sum + t.amount);
  }

  void _showFamilyInfoSheet(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;
    if (user == null) return;

    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    showFamilyInfoSheet(
      context: context,
      firestoreService: firestoreService,
      userId: user.uid,
    );
  }
}
