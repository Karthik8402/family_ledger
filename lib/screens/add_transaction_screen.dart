import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  String _transactionType = TransactionModel.typeExpense; 
  String? _selectedCategory;
  bool _isPrivate = false;
  bool _isLoading = false;

  // Category definitions with icons
  static const List<Map<String, dynamic>> expenseCategories = [
    {'name': 'Grocery', 'icon': Icons.shopping_cart},
    {'name': 'Food', 'icon': Icons.restaurant},
    {'name': 'Transport', 'icon': Icons.directions_car},
    {'name': 'Bills', 'icon': Icons.receipt_long},
    {'name': 'Rent', 'icon': Icons.home},
    {'name': 'Shopping', 'icon': Icons.shopping_bag},
    {'name': 'Healthcare', 'icon': Icons.local_hospital},
    {'name': 'Entertainment', 'icon': Icons.movie},
    {'name': 'Education', 'icon': Icons.school},
    {'name': 'Fuel', 'icon': Icons.local_gas_station},
    {'name': 'Electricity', 'icon': Icons.electric_bolt},
    {'name': 'Water', 'icon': Icons.water_drop},
    {'name': 'Internet', 'icon': Icons.wifi},
    {'name': 'Phone', 'icon': Icons.phone_android},
    {'name': 'Others', 'icon': Icons.more_horiz},
  ];

  static const List<Map<String, dynamic>> incomeCategories = [
    {'name': 'Salary', 'icon': Icons.work},
    {'name': 'Commission', 'icon': Icons.handshake},
    {'name': 'Business', 'icon': Icons.business},
    {'name': 'Investment', 'icon': Icons.trending_up},
    {'name': 'Freelance', 'icon': Icons.laptop_mac},
    {'name': 'Rental', 'icon': Icons.apartment},
    {'name': 'Gift', 'icon': Icons.card_giftcard},
    {'name': 'Bonus', 'icon': Icons.star},
    {'name': 'Interest', 'icon': Icons.savings},
    {'name': 'Dividend', 'icon': Icons.account_balance},
    {'name': 'Others', 'icon': Icons.more_horiz},
  ];

  List<Map<String, dynamic>> get currentCategories => 
      _transactionType == TransactionModel.typeExpense ? expenseCategories : incomeCategories;

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedCategory == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(Icons.warning, color: Colors.white),
                SizedBox(width: 12),
                Text('Please select a category'),
              ],
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange.shade600,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        return;
      }

      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      final String uid = user?.uid ?? 'test_user_id';
      final String uName = user?.email ?? 'Test User'; 

      try {
        final transaction = TransactionModel(
          id: '',
          amount: double.parse(_amountController.text),
          category: _selectedCategory!,
          date: DateTime.now(),
          userId: uid,
          userName: uName,
          type: _transactionType,
          visibility: _isPrivate ? TransactionModel.visibilityPrivate : TransactionModel.visibilityShared,
        );

        await Provider.of<FirestoreService>(context, listen: false).addTransaction(transaction);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 12),
                  Text('Transaction added successfully!'),
                ],
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green.shade600,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isExpense = _transactionType == TransactionModel.typeExpense;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.close, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Transaction'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Amount Display Card
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isExpense
                                ? [Colors.red.shade400, Colors.red.shade600]
                                : [Colors.green.shade400, Colors.green.shade600],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: (isExpense ? Colors.red : Colors.green).withOpacity(0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              isExpense ? 'Expense Amount' : 'Income Amount',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            IntrinsicWidth(
                              child: TextFormField(
                                controller: _amountController,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontSize: 44,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                                decoration: InputDecoration(
                                  prefixText: '₹',
                                  prefixStyle: TextStyle(
                                    fontSize: 44,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white.withOpacity(0.8),
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintText: '0.00',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
                                  filled: false,
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty) return 'Enter amount';
                                  if (double.tryParse(value) == null) return 'Invalid number';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                      
                      const SizedBox(height: 24),

                      // Type Selector
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.08) : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(child: _buildTypeButton('Expense', TransactionModel.typeExpense, Colors.red, isDark)),
                            Expanded(child: _buildTypeButton('Income', TransactionModel.typeIncome, Colors.green, isDark)),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      
                      const SizedBox(height: 24),

                      // Category Dropdown
                      Text(
                        'Category',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Container(
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _selectedCategory != null 
                                ? primaryColor.withOpacity(0.5)
                                : Theme.of(context).dividerColor.withOpacity(0.3),
                          ),
                          boxShadow: isDark ? null : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCategory,
                            hint: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Row(
                                children: [
                                  Icon(Icons.category, color: Colors.grey.shade500),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Select Category',
                                    style: TextStyle(color: Colors.grey.shade500),
                                  ),
                                ],
                              ),
                            ),
                            isExpanded: true,
                            icon: Padding(
                              padding: const EdgeInsets.only(right: 16),
                              child: Icon(Icons.keyboard_arrow_down, color: primaryColor),
                            ),
                            dropdownColor: isDark ? const Color(0xFF2D2D44) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            items: currentCategories.map((category) {
                              return DropdownMenuItem<String>(
                                value: category['name'],
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          category['icon'],
                                          color: primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        category['name'],
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedCategory = value);
                            },
                            selectedItemBuilder: (context) {
                              return currentCategories.map((category) {
                                return Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Icon(
                                          category['icon'],
                                          color: primaryColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Text(
                                        category['name'],
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 16,
                                          color: primaryColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ).animate().slideX(begin: 0.1, end: 0, delay: 300.ms).fadeIn(),
                      
                      const SizedBox(height: 24),

                      // Note Input (Optional)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isDark ? null : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _noteController,
                          decoration: InputDecoration(
                            labelText: 'Note (Optional)',
                            hintText: 'Add a note...',
                            prefixIcon: Container(
                              margin: const EdgeInsets.all(12),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.edit_note, color: primaryColor, size: 20),
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ).animate().slideX(begin: 0.1, end: 0, delay: 400.ms).fadeIn(),
                      
                      const SizedBox(height: 20),

                      // Privacy Toggle
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isPrivate 
                                ? Colors.orange.withOpacity(0.5) 
                                : Theme.of(context).dividerColor.withOpacity(0.3),
                          ),
                          boxShadow: isDark ? null : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: _isPrivate ? Colors.orange.withOpacity(0.15) : Colors.blue.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _isPrivate ? Icons.lock : Icons.public,
                                color: _isPrivate ? Colors.orange : Colors.blue,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Private Transaction', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isPrivate ? 'Visible only to you' : 'Shared with family',
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isPrivate,
                              onChanged: (val) => setState(() => _isPrivate = val),
                              activeColor: Colors.orange,
                            ),
                          ],
                        ),
                      ).animate().slideX(begin: 0.1, end: 0, delay: 500.ms).fadeIn(),
                    ],
                  ),
                ),
              ),

              // Submit Button
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -5),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _submitTransaction,
                    style: FilledButton.styleFrom(
                      backgroundColor: primaryColor,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : const Text('Save Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                ),
              ).animate().slideY(begin: 0.5, end: 0, duration: 400.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, String value, Color color, bool isDark) {
    final isSelected = _transactionType == value;
    return GestureDetector(
      onTap: () => setState(() {
        _transactionType = value;
        _selectedCategory = null;
      }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDark ? color.withOpacity(0.2) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected && !isDark 
              ? [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 6, offset: const Offset(0, 2))] 
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              value == TransactionModel.typeExpense ? Icons.arrow_upward : Icons.arrow_downward,
              size: 18,
              color: isSelected ? color : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? color : Colors.grey,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
