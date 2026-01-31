import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transaction_model.dart';
import '../models/budget_model.dart';
import '../services/firestore_service.dart';
import '../widgets/animated_pie_chart.dart';
import '../widgets/animated_bar_chart.dart';

class StatsScreen extends StatefulWidget {
  final int month;
  final int year;

  const StatsScreen({
    super.key,
    required this.month,
    required this.year,
  });

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this); // Added Compare tab
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = Provider.of<FirestoreService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0D1117) : Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Statistics',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            Text(
              DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month)),
              style: TextStyle(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4)),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: primaryColor,
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
              labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Categories'),
                Tab(text: 'Trends'),
                Tab(text: 'Compare'),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: firestoreService.getTransactions(),
        builder: (context, txnSnapshot) {
          if (txnSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator(color: primaryColor));
          }

          if (txnSnapshot.hasError) {
            return Center(child: Text('Error: ${txnSnapshot.error}'));
          }

          final allTransactions = txnSnapshot.data ?? [];
          final monthlyTransactions = allTransactions.where((t) {
            return t.date.month == widget.month && t.date.year == widget.year && t.tabId == null;
          }).toList();

          return StreamBuilder<List<BudgetModel>>(
            stream: firestoreService.streamBudgets(widget.month, widget.year),
            builder: (context, budgetSnapshot) {
              final budgets = budgetSnapshot.data ?? [];

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(context, monthlyTransactions, isDark, primaryColor),
                  _buildCategoriesTab(context, monthlyTransactions, budgets, isDark, primaryColor),
                  _buildTrendsTab(context, monthlyTransactions, isDark, primaryColor),
                  _buildCompareTab(context, allTransactions, isDark, primaryColor),
                ],
              );
            }
          );
        },
      ),
    );
  }

  // --- TAB 1: OVERVIEW ---
  Widget _buildOverviewTab(BuildContext context, List<TransactionModel> transactions, bool isDark, Color primaryColor) {
    final income = transactions
        .where((t) => t.type == TransactionModel.typeIncome && t.visibility == TransactionModel.visibilityShared)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final expense = transactions
        .where((t) => t.type == TransactionModel.typeExpense && t.visibility == TransactionModel.visibilityShared)
        .fold(0.0, (sum, t) => sum + t.amount);

    final savingsRate = income > 0 ? ((income - expense) / income * 100).clamp(0, 100) : 0.0;

    // Contributions logic (Income only)
    final incomes = transactions.where((t) => t.type == TransactionModel.typeIncome && t.visibility == TransactionModel.visibilityShared);
    final Map<String, double> contributions = {};
    for (var t in incomes) {
      final name = t.userName.isEmpty ? 'Unknown' : t.userName.split('@')[0];
      contributions[name] = (contributions[name] ?? 0) + t.amount;
    }
    final sortedContributors = contributions.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    // Expenses by user
    final expensesByUser = transactions.where((t) => t.type == TransactionModel.typeExpense && t.visibility == TransactionModel.visibilityShared);
    final Map<String, double> spendingByUser = {};
    for (var t in expensesByUser) {
      final name = t.userName.isEmpty ? 'Unknown' : t.userName.split('@')[0];
      spendingByUser[name] = (spendingByUser[name] ?? 0) + t.amount;
    }
    final sortedSpenders = spendingByUser.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Income & Expense Cards
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_up, color: Colors.green, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Income',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '₹${NumberFormat('#,##,###').format(income)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.trending_down, color: Colors.red, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Expense',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      '₹${NumberFormat('#,##,###').format(expense)}',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ).animate().slideY(begin: 0.1, end: 0, duration: 500.ms, curve: Curves.easeOutQuart).fadeIn(),

        const SizedBox(height: 24),

        // Savings Rate Card
        _buildGlassCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Savings Rate', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                  Text('${savingsRate.toStringAsFixed(1)}%', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: primaryColor)),
                ],
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: savingsRate / 100,
                  minHeight: 12,
                  backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(savingsRate > 20 ? Colors.green : (savingsRate > 0 ? Colors.orange : Colors.red)),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                savingsRate > 30 ? '🎉 Excellent! You\'re saving well.' 
                  : savingsRate > 10 ? '👍 Good progress, keep it up!' 
                  : savingsRate > 0 ? '⚠️ Consider reducing expenses.' 
                  : '❌ Spending exceeds income.',
                style: TextStyle(color: isDark ? Colors.white54 : Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ).animate().slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms).fadeIn(),

        const SizedBox(height: 24),
        
        // Two-column: Contributors & Spenders
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: _buildMemberListCard(
                isDark: isDark,
                title: '💰 Top Earners',
                members: sortedContributors,
                color: Colors.green,
                emptyText: 'No income yet',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildMemberListCard(
                isDark: isDark,
                title: '💸 Top Spenders',
                members: sortedSpenders,
                color: Colors.red,
                emptyText: 'No expenses yet',
              ),
            ),
          ],
        ).animate().slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 400.ms).fadeIn(),
      ],
    );
  }



  Widget _buildGlassCard({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMemberListCard({required bool isDark, required String title, required List<MapEntry<String, double>> members, required Color color, required String emptyText}) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 12),
          if (members.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(emptyText, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
            )
          else
            ...members.take(3).map((e) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: color.withValues(alpha: 0.15),
                    child: Text(e.key[0].toUpperCase(), style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(e.key, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87), overflow: TextOverflow.ellipsis)),
                  Text('₹${NumberFormat.compact().format(e.value)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color)),
                ],
              ),
            )),
        ],
      ),
    );
  }

  // --- TAB 2: CATEGORIES ---
  Widget _buildCategoriesTab(BuildContext context, List<TransactionModel> transactions, List<BudgetModel> budgets, bool isDark, Color primaryColor) {
    final expenses = transactions.where((t) => t.type == TransactionModel.typeExpense && t.visibility == TransactionModel.visibilityShared);
    
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.pie_chart_outline, size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No expenses to analyze', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ],
        ).animate().scale(duration: 300.ms),
      );
    }

    final Map<String, double> categoryTotals = {};
    for (var t in expenses) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    final totalExpense = categoryTotals.values.fold(0.0, (a, b) => a + b);
    final chartColors = [
      const Color(0xFF667eea), const Color(0xFFf5576c), const Color(0xFF4facfe), 
      const Color(0xFF43e97b), const Color(0xFFfa709a), const Color(0xFFfee140),
      const Color(0xFF30cfd0), const Color(0xFFa18cd1),
    ];
    final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Pie Chart Card
        _buildGlassCard(
          isDark: isDark,
          child: SizedBox(
            height: 280,
            child: AnimatedPieChart(data: categoryTotals, isDark: isDark),
          ),
        ).animate().scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 400.ms).fadeIn(),
        
        const SizedBox(height: 24),
        
        Text('Expense Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isDark ? Colors.white : Colors.black87)),
        const SizedBox(height: 16),
        
        // Category Cards with Progress
        ...sortedCategories.asMap().entries.map((entry) {
          final color = chartColors[entry.key % chartColors.length];
          final categoryName = entry.value.key;
          final amount = entry.value.value;
          final percentage = (amount / totalExpense * 100);
          
          // Check for budget
          final budget = budgets.firstWhere(
            (b) => b.categoryName == categoryName, 
            orElse: () => BudgetModel(id: '', familyId: '', categoryName: '', amount: 0, month: 0, year: 0)
          );
          final hasBudget = budget.amount > 0;
          final budgetProgress = hasBudget ? (amount / budget.amount) : 0.0;
          final budgetColor = budgetProgress > 1.0 ? Colors.red : (budgetProgress > 0.8 ? Colors.orange : color);

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(_getCategoryEmoji(categoryName), style: const TextStyle(fontSize: 18))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(categoryName, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                          const SizedBox(height: 2),
                          if (hasBudget)
                             Text(
                               '${(budgetProgress * 100).toStringAsFixed(0)}% of ₹${NumberFormat.compact().format(budget.amount)} Budget',
                               style: TextStyle(color: budgetColor, fontSize: 12, fontWeight: FontWeight.bold)
                             )
                          else
                            Text('${percentage.toStringAsFixed(1)}% of total', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₹${NumberFormat('#,##,###').format(amount)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                        if (hasBudget && amount > budget.amount)
                          Text('+₹${NumberFormat.compact().format(amount - budget.amount)} over', style: const TextStyle(color: Colors.red, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Stack(
                  children: [
                    // Background track
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: 0, // Just track
                        minHeight: 8, // Thicker for budget
                        backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                      ),
                    ),
                     // Progress
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: hasBudget ? budgetProgress.clamp(0.0, 1.0) : percentage / 100,
                        minHeight: 8,
                        backgroundColor: Colors.transparent,
                        valueColor: AlwaysStoppedAnimation(hasBudget ? budgetColor : color),
                      ),
                    ),
                  ],
                ),
                if (hasBudget)
                   Padding(
                     padding: const EdgeInsets.only(top: 4),
                     child: Row(
                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
                       children: [
                         Text('₹0', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 10)),
                         Text('₹${NumberFormat.compact().format(budget.amount)}', style: TextStyle(color: isDark ? Colors.white24 : Colors.black26, fontSize: 10)),
                       ],
                     ),
                   ),
              ],
            ),
          ).animate().slideX(begin: 0.1, end: 0, delay: (60 * entry.key).ms, duration: 350.ms).fadeIn();
        }),
      ],
    );
  }

  String _getCategoryEmoji(String category) {
    final lowerCategory = category.toLowerCase();
    if (lowerCategory.contains('food') || lowerCategory.contains('grocery')) return '🍔';
    if (lowerCategory.contains('transport') || lowerCategory.contains('fuel') || lowerCategory.contains('travel')) return '🚗';
    if (lowerCategory.contains('health') || lowerCategory.contains('medical')) return '💊';
    if (lowerCategory.contains('shopping') || lowerCategory.contains('cloth')) return '🛍️';
    if (lowerCategory.contains('entertainment') || lowerCategory.contains('movie')) return '🎬';
    if (lowerCategory.contains('bill') || lowerCategory.contains('utility')) return '📄';
    if (lowerCategory.contains('rent') || lowerCategory.contains('home')) return '🏠';
    if (lowerCategory.contains('education') || lowerCategory.contains('book')) return '📚';
    return '💳';
  }

  // --- TAB 3: TRENDS ---
  Widget _buildTrendsTab(BuildContext context, List<TransactionModel> transactions, bool isDark, Color primaryColor) {
    final expenses = transactions.where((t) => t.type == TransactionModel.typeExpense && t.visibility == TransactionModel.visibilityShared);
    
    if (expenses.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 64, color: isDark ? Colors.white24 : Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('No data for trends', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
          ],
        ).animate().scale(duration: 300.ms),
      );
    }

    final Map<int, double> dailyTotals = {};
    final daysInMonth = DateUtils.getDaysInMonth(widget.year, widget.month);
    for (int i = 1; i <= daysInMonth; i++) dailyTotals[i] = 0;
    
    for (var t in expenses) {
      dailyTotals[t.date.day] = (dailyTotals[t.date.day] ?? 0) + t.amount;
    }

    double maxSpend = dailyTotals.values.isEmpty ? 0 : dailyTotals.values.reduce((a, b) => a > b ? a : b);
    double totalSpend = dailyTotals.values.fold(0.0, (a, b) => a + b);
    double avgDailySpend = totalSpend / daysInMonth;
    
    // Find peak day
    int peakDay = 1;
    double peakAmount = 0;
    dailyTotals.forEach((day, amount) {
      if (amount > peakAmount) {
        peakDay = day;
        peakAmount = amount;
      }
    });
    
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Quick Stats Row
        Row(
          children: [
            Expanded(child: _buildQuickStatCard(isDark: isDark, icon: Icons.calendar_today, label: 'Avg/Day', value: '₹${NumberFormat.compact().format(avgDailySpend)}', color: Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickStatCard(isDark: isDark, icon: Icons.arrow_upward, label: 'Peak Day', value: 'Day $peakDay', color: Colors.orange)),
            const SizedBox(width: 12),
            Expanded(child: _buildQuickStatCard(isDark: isDark, icon: Icons.account_balance_wallet, label: 'Total', value: '₹${NumberFormat.compact().format(totalSpend)}', color: Colors.purple)),
          ],
        ).animate().slideY(begin: 0.1, end: 0, duration: 400.ms).fadeIn(),

        const SizedBox(height: 24),
        
        // Chart Card
        _buildGlassCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Daily Spending Pattern', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$daysInMonth days', style: TextStyle(color: primaryColor, fontSize: 12, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                height: 200,
                child: AnimatedBarChart(
                  dailyTotals: dailyTotals, 
                  maxSpend: maxSpend == 0 ? 100 : maxSpend,
                  isDark: isDark, 
                  primaryColor: primaryColor
                ),
              ),
              const SizedBox(height: 12),
              Center(child: Text('Day of Month', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12))),
            ],
          ),
        ).animate().slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms).fadeIn(),

        const SizedBox(height: 24),

        // Insight Card
        if (peakAmount > 0)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.orange.shade400, Colors.deepOrange.shade400],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.white, size: 28),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Spending Insight', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 4),
                      Text(
                        'Your highest spending was ₹${NumberFormat.compact().format(peakAmount)} on day $peakDay.',
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate().slideY(begin: 0.1, end: 0, delay: 200.ms, duration: 400.ms).fadeIn(),
      ],
    );
  }

  Widget _buildQuickStatCard({required bool isDark, required IconData icon, required String label, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 11)),
        ],
      ),
    );
  }

  // --- TAB 4: YEAR-OVER-YEAR COMPARISON ---
  Widget _buildCompareTab(BuildContext context, List<TransactionModel> allTransactions, bool isDark, Color primaryColor) {
    final currentYear = widget.year;
    final previousYear = widget.year - 1;
    final currentMonth = widget.month;

    // Filter transactions for current and previous year (same month)
    final currentYearTxns = allTransactions.where((t) => 
      t.date.month == currentMonth && 
      t.date.year == currentYear && 
      t.tabId == null &&
      t.visibility == TransactionModel.visibilityShared
    ).toList();

    final previousYearTxns = allTransactions.where((t) => 
      t.date.month == currentMonth && 
      t.date.year == previousYear && 
      t.tabId == null &&
      t.visibility == TransactionModel.visibilityShared
    ).toList();

    // Calculate totals
    final currentIncome = currentYearTxns
        .where((t) => t.type == TransactionModel.typeIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final currentExpense = currentYearTxns
        .where((t) => t.type == TransactionModel.typeExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    final previousIncome = previousYearTxns
        .where((t) => t.type == TransactionModel.typeIncome)
        .fold(0.0, (sum, t) => sum + t.amount);
    final previousExpense = previousYearTxns
        .where((t) => t.type == TransactionModel.typeExpense)
        .fold(0.0, (sum, t) => sum + t.amount);

    // Calculate percentage changes
    double incomeChange = previousIncome > 0 
        ? ((currentIncome - previousIncome) / previousIncome * 100) 
        : (currentIncome > 0 ? 100 : 0);
    double expenseChange = previousExpense > 0 
        ? ((currentExpense - previousExpense) / previousExpense * 100) 
        : (currentExpense > 0 ? 100 : 0);

    // Category comparison for expenses
    final Map<String, double> currentCategories = {};
    final Map<String, double> previousCategories = {};
    
    for (var t in currentYearTxns.where((t) => t.type == TransactionModel.typeExpense)) {
      currentCategories[t.category] = (currentCategories[t.category] ?? 0) + t.amount;
    }
    for (var t in previousYearTxns.where((t) => t.type == TransactionModel.typeExpense)) {
      previousCategories[t.category] = (previousCategories[t.category] ?? 0) + t.amount;
    }

    // All unique categories
    final allCategories = {...currentCategories.keys, ...previousCategories.keys}.toList()..sort();

    final monthName = DateFormat('MMMM').format(DateTime(currentYear, currentMonth));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Header
        Text(
          '$monthName Comparison',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '$currentYear vs $previousYear',
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 24),

        // Main Comparison Cards
        Row(
          children: [
            Expanded(
              child: _buildComparisonCard(
                isDark: isDark,
                icon: Icons.trending_up,
                title: 'Income',
                currentValue: currentIncome,
                previousValue: previousIncome,
                percentChange: incomeChange,
                isPositiveGood: true,
                primaryColor: Colors.green,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildComparisonCard(
                isDark: isDark,
                icon: Icons.trending_down,
                title: 'Expenses',
                currentValue: currentExpense,
                previousValue: previousExpense,
                percentChange: expenseChange,
                isPositiveGood: false,
                primaryColor: Colors.red,
              ),
            ),
          ],
        ).animate().slideY(begin: 0.1, end: 0, duration: 400.ms).fadeIn(),

        const SizedBox(height: 24),

        // Net Savings Comparison
        _buildGlassCard(
          isDark: isDark,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Net Savings',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _buildYearColumn(
                      year: previousYear,
                      amount: previousIncome - previousExpense,
                      isDark: isDark,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Icon(
                      Icons.arrow_forward,
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                  Expanded(
                    child: _buildYearColumn(
                      year: currentYear,
                      amount: currentIncome - currentExpense,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ).animate().slideY(begin: 0.1, end: 0, delay: 100.ms, duration: 400.ms).fadeIn(),

        const SizedBox(height: 24),

        // Category Comparison
        if (allCategories.isNotEmpty) ...[
          Text(
            'Category Breakdown',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ...allCategories.asMap().entries.map((entry) {
            final category = entry.value;
            final current = currentCategories[category] ?? 0;
            final previous = previousCategories[category] ?? 0;
            final change = previous > 0 
                ? ((current - previous) / previous * 100) 
                : (current > 0 ? 100.0 : 0.0);

            return _buildCategoryComparisonRow(
              category: category,
              currentAmount: current,
              previousAmount: previous,
              percentChange: change,
              isDark: isDark,
              delay: 150 + (entry.key * 50),
            );
          }),
        ] else
          _buildGlassCard(
            isDark: isDark,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.compare_arrows,
                      size: 48,
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No data available for comparison',
                      style: TextStyle(
                        color: isDark ? Colors.white54 : Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(),
      ],
    );
  }

  Widget _buildComparisonCard({
    required bool isDark,
    required IconData icon,
    required String title,
    required double currentValue,
    required double previousValue,
    required double percentChange,
    required bool isPositiveGood,
    required Color primaryColor,
  }) {
    final isPositive = percentChange >= 0;
    final isGood = isPositiveGood ? isPositive : !isPositive;
    final changeColor = isGood ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '₹${NumberFormat('#,##,###').format(currentValue)}',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: changeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward : Icons.arrow_downward,
                  color: changeColor,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  '${isPositive ? '+' : ''}${percentChange.toStringAsFixed(1)}%',
                  style: TextStyle(
                    color: changeColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Last year: ₹${NumberFormat.compact().format(previousValue)}',
            style: TextStyle(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildYearColumn({
    required int year,
    required double amount,
    required bool isDark,
  }) {
    final isPositive = amount >= 0;
    return Column(
      children: [
        Text(
          '$year',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black54,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '₹${NumberFormat('#,##,###').format(amount.abs())}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isPositive ? Colors.green : Colors.red,
          ),
        ),
        Text(
          isPositive ? 'Saved' : 'Deficit',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? Colors.white38 : Colors.black38,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryComparisonRow({
    required String category,
    required double currentAmount,
    required double previousAmount,
    required double percentChange,
    required bool isDark,
    required int delay,
  }) {
    final isPositive = percentChange >= 0;
    final changeColor = isPositive ? Colors.red : Colors.green; // For expenses, decrease is good

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade100),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(_getCategoryEmoji(category), style: const TextStyle(fontSize: 18)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Was ₹${NumberFormat.compact().format(previousAmount)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '₹${NumberFormat.compact().format(currentAmount)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              if (previousAmount > 0 || currentAmount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: changeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${isPositive ? '+' : ''}${percentChange.toStringAsFixed(0)}%',
                    style: TextStyle(
                      color: changeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ).animate().slideX(begin: 0.1, end: 0, delay: delay.ms, duration: 350.ms).fadeIn();
  }
}
