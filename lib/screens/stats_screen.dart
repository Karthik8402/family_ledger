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
      appBar: AppBar(
        title: Text(
          DateFormat('MMMM yyyy').format(DateTime(widget.year, widget.month)),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Categories'),
            Tab(text: 'Trends'),
          ],
          indicatorColor: primaryColor,
          labelColor: primaryColor,
          unselectedLabelColor: Colors.grey,
        ),
      ),
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
          final monthlyTransactions = allTransactions.where((t) {
            return t.date.month == widget.month && t.date.year == widget.year;
          }).toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOverviewTab(context, monthlyTransactions, isDark, primaryColor),
              _buildCategoriesTab(context, monthlyTransactions, isDark),
              _buildTrendsTab(context, monthlyTransactions, isDark, primaryColor),
            ],
          );
        },
      ),
    );
  }

  // --- TAB 1: OVERVIEW (Existing Logic + Totals) ---
  Widget _buildOverviewTab(BuildContext context, List<TransactionModel> transactions, bool isDark, Color primaryColor) {
    final income = transactions
        .where((t) => t.type == TransactionModel.typeIncome && t.visibility == TransactionModel.visibilityShared)
        .fold(0.0, (sum, t) => sum + t.amount);
    
    final expense = transactions
        .where((t) => t.type == TransactionModel.typeExpense && t.visibility == TransactionModel.visibilityShared)
        .fold(0.0, (sum, t) => sum + t.amount);

    final balance = income - expense;

    // Contributions logic (Income only)
    final incomes = transactions.where((t) => t.type == TransactionModel.typeIncome && t.visibility == TransactionModel.visibilityShared);
    final Map<String, double> contributions = {};
    for (var t in incomes) {
      final name = t.userName.isEmpty ? 'Unknown' : t.userName.split('@')[0];
      contributions[name] = (contributions[name] ?? 0) + t.amount;
    }

    final sortedContributors = contributions.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Summary Card
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [primaryColor, primaryColor.withOpacity(0.8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Text('NET BALANCE', style: TextStyle(color: Colors.white70, fontSize: 12, letterSpacing: 1.5)),
              const SizedBox(height: 8),
              Text(
                '₹${balance.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildSummaryItem(Icons.arrow_downward, 'Income', income, Colors.greenAccent),
                  Container(width: 1, height: 40, color: Colors.white24),
                  _buildSummaryItem(Icons.arrow_upward, 'Expense', expense, Colors.redAccent.shade100),
                ],
              ),
            ],
          ),
        ).animate().slideY(begin: 0.1, end: 0, duration: 400.ms),

        const SizedBox(height: 32),
        
        Text('Top Contributors', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 16),
        
        if (sortedContributors.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('No shared income recorded this month.', style: TextStyle(color: Colors.grey)),
          )
        else
          ...sortedContributors.map((e) => ListTile(
            leading: CircleAvatar(
              backgroundColor: primaryColor.withOpacity(0.1),
              child: Text(e.key[0].toUpperCase(), style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold)),
            ),
            title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
            trailing: Text('₹${e.value.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16)),
          )),
      ],
    );
  }

  Widget _buildSummaryItem(IconData icon, String label, double amount, Color color) {
    return Column(
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(color: Colors.white70)),
          ],
        ),
        const SizedBox(height: 4),
        Text('₹${amount.toStringAsFixed(0)}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      ],
    );
  }

  // --- TAB 2: CATEGORIES (Animated Pie Chart) ---
  Widget _buildCategoriesTab(BuildContext context, List<TransactionModel> transactions, bool isDark) {
    final expenses = transactions.where((t) => t.type == TransactionModel.typeExpense && t.visibility == TransactionModel.visibilityShared);
    
    if (expenses.isEmpty) {
      return const Center(child: Text('No expenses to analyze'));
    }

    final Map<String, double> categoryTotals = {};
    for (var t in expenses) {
      categoryTotals[t.category] = (categoryTotals[t.category] ?? 0) + t.amount;
    }

    final chartColors = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.teal, Colors.pink, Colors.amber];
    final sortedCategories = categoryTotals.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        SizedBox(
          height: 250,
          child: AnimatedPieChart(data: categoryTotals, isDark: isDark),
        ),
        const SizedBox(height: 32),
        
        // Detailed List
        ...sortedCategories.asMap().entries.map((entry) {
          final color = chartColors[entry.key % chartColors.length];
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(width: 16, height: 16, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 12),
                Expanded(child: Text(entry.value.key, style: const TextStyle(fontWeight: FontWeight.w600))),
                Text('₹${entry.value.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ).animate().slideX(delay: (50 * entry.key).ms);
        }),
      ],
    );
  }

  // --- TAB 3: TRENDS (Animated Bar Chart) ---
  Widget _buildTrendsTab(BuildContext context, List<TransactionModel> transactions, bool isDark, Color primaryColor) {
    final expenses = transactions.where((t) => t.type == TransactionModel.typeExpense && t.visibility == TransactionModel.visibilityShared);
    
    if (expenses.isEmpty) return const Center(child: Text('No data for trends'));

    final Map<int, double> dailyTotals = {};
    final daysInMonth = DateUtils.getDaysInMonth(widget.year, widget.month);
    for (int i = 1; i <= daysInMonth; i++) dailyTotals[i] = 0;
    
    for (var t in expenses) {
      dailyTotals[t.date.day] = (dailyTotals[t.date.day] ?? 0) + t.amount;
    }

    double maxSpend = 0;
    if (dailyTotals.isNotEmpty) {
      maxSpend = dailyTotals.values.reduce((a, b) => a > b ? a : b);
    }
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Daily Spending', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 24),
          Expanded(
            child: AnimatedBarChart(
              dailyTotals: dailyTotals, 
              maxSpend: maxSpend == 0 ? 100 : maxSpend,
              isDark: isDark, 
              primaryColor: primaryColor
            ),
          ),
          const SizedBox(height: 16),
          const Center(child: Text('Day of Month', style: TextStyle(color: Colors.grey))),
        ],
      ),
    );
  }
}
