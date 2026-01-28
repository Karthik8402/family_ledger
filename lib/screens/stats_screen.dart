import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transaction_model.dart';
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
    _tabController = TabController(length: 3, vsync: this);
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
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
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
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<List<TransactionModel>>(
        stream: firestoreService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  const SizedBox(height: 16),
                  Text('Loading statistics...', style: TextStyle(color: isDark ? Colors.white54 : Colors.black54)),
                ],
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allTransactions = snapshot.data ?? [];
          final monthlyTransactions = allTransactions.where((t) {
            return t.date.month == widget.month && t.date.year == widget.year && t.tabId == null;
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, monthlyTransactions, isDark, primaryColor),
              _buildCategoriesTab(context, monthlyTransactions, isDark, primaryColor),
              _buildTrendsTab(context, monthlyTransactions, isDark, primaryColor),
            ],
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

    final balance = income - expense;
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
        // Main Balance Card with Glassmorphism
        Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: balance >= 0 
                ? [const Color(0xFF667eea), const Color(0xFF764ba2)] 
                : [const Color(0xFFf093fb), const Color(0xFFf5576c)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: (balance >= 0 ? const Color(0xFF667eea) : const Color(0xFFf5576c)).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            children: [
              // Income & Expense Row (Net Balance removed)
              Row(
                children: [
                  Expanded(child: _buildStatBox(Icons.trending_down, 'Income', income, Colors.greenAccent.shade200)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatBox(Icons.trending_up, 'Expense', expense, Colors.redAccent.shade100)),
                ],
              ),
            ],
          ),
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

  Widget _buildStatBox(IconData icon, String label, double amount, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '₹${NumberFormat('#,##,###').format(amount)}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required bool isDark, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.grey.shade200),
        boxShadow: isDark ? [] : [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
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
                    backgroundColor: color.withOpacity(0.15),
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
  Widget _buildCategoriesTab(BuildContext context, List<TransactionModel> transactions, bool isDark, Color primaryColor) {
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
          final percentage = (entry.value.value / totalExpense * 100);
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
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
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(child: Text(_getCategoryEmoji(entry.value.key), style: const TextStyle(fontSize: 18))),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(entry.value.key, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
                          const SizedBox(height: 2),
                          Text('${percentage.toStringAsFixed(1)}% of total', style: TextStyle(color: isDark ? Colors.white38 : Colors.black38, fontSize: 12)),
                        ],
                      ),
                    ),
                    Text('₹${NumberFormat('#,##,###').format(entry.value.value)}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color)),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: percentage / 100,
                    minHeight: 6,
                    backgroundColor: isDark ? Colors.white12 : Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(color),
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
                      color: primaryColor.withOpacity(0.1),
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
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
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
}
