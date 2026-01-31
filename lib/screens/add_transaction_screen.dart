import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/transaction_model.dart';
import '../models/category_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../utils/toast_utils.dart';
import 'category_management_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final String? initialType;
  final String? initialTabId;
  final TransactionModel? editTransaction;

  const AddTransactionScreen({
    super.key,
    this.initialType,
    this.initialTabId,
    this.editTransaction,
  });

  bool get isEditMode => editTransaction != null;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  late String _transactionType; 
  String? _selectedCategory;
  bool _isPrivate = false;
  bool _isLoading = false;
  String? _familyId;

  @override
  void initState() {
    super.initState();
    
    // Edit mode: pre-fill form with existing transaction data
    if (widget.isEditMode) {
      final tx = widget.editTransaction!;
      _amountController.text = tx.amount.toString();
      _noteController.text = tx.note;
      _transactionType = tx.type;
      _selectedCategory = tx.category;
      _isPrivate = tx.visibility == TransactionModel.visibilityPrivate;
    } else {
      _transactionType = widget.initialType ?? TransactionModel.typeExpense;
    }
    
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFamilyId());
  }

  Future<void> _loadFamilyId() async {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      final userProfile = await context.read<FirestoreService>().getUserProfile(user.id);
      if (mounted) {
        setState(() => _familyId = userProfile?.familyId);
        if (_familyId != null) {
          // Ensure defaults exist so the dropdown isn't empty on first run
          context.read<FirestoreService>().ensureDefaultCategories(_familyId!);
        }
      }
    }
  }

  // Category definitions with icons
  // Removed hardcoded categories


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

      setState(() => _isLoading = true);

      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;
      final String uid = user?.id ?? 'test_user_id';
      final String uName = user?.email ?? 'Test User'; 

      try {
        final firestoreService = Provider.of<FirestoreService>(context, listen: false);
        
        if (widget.isEditMode) {
          // Update existing transaction
          final updatedTransaction = TransactionModel(
            id: widget.editTransaction!.id,
            amount: double.parse(_amountController.text),
            category: _selectedCategory!,
            date: widget.editTransaction!.date, // Keep original date
            userId: widget.editTransaction!.userId,
            userName: widget.editTransaction!.userName,
            type: _transactionType,
            visibility: _isPrivate ? TransactionModel.visibilityPrivate : TransactionModel.visibilityShared,
            familyId: widget.editTransaction!.familyId, // Keep original familyId
            tabId: widget.initialTabId ?? widget.editTransaction!.tabId,
            note: _noteController.text.trim(),
          );
          await firestoreService.updateTransaction(updatedTransaction);
          if (mounted) {
            ToastUtils.showSuccess(context, 'Transaction updated!');
            Navigator.pop(context);
          }
        } else {
          // Add new transaction
          final transaction = TransactionModel(
            id: '',
            amount: double.parse(_amountController.text),
            category: _selectedCategory!,
            date: DateTime.now(),
            userId: uid,
            userName: uName,
            type: _transactionType,
            visibility: _isPrivate ? TransactionModel.visibilityPrivate : TransactionModel.visibilityShared,
            tabId: widget.initialTabId,
            note: _noteController.text.trim(),
          );
          await firestoreService.addTransaction(transaction);
          if (mounted) {
            ToastUtils.showSuccess(context, 'Transaction added!');
            Navigator.pop(context);
          }
        }
      } catch (e) {
        if (mounted) {
          ToastUtils.showError(context, 'Error: $e');
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
        title: Text(widget.isEditMode ? 'Edit Transaction' : 'New Transaction'),
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
                              color: (isExpense ? Colors.red : Colors.green).withValues(alpha: 0.3),
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
                                color: Colors.white.withValues(alpha: 0.9),
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
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                  border: InputBorder.none,
                                  enabledBorder: InputBorder.none,
                                  focusedBorder: InputBorder.none,
                                  hintText: '0.00',
                                  hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
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
                          color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.grey.shade100,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Category',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const CategoryManagementScreen()),
                              );
                            },
                            icon: const Icon(Icons.edit, size: 16),
                            label: const Text('Manage'),
                            style: TextButton.styleFrom(
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      _familyId == null 
                          ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
                          : StreamBuilder<List<CategoryModel>>(
                              stream: context.read<FirestoreService>().streamCategories(_familyId!),
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) {
                                  return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))));
                                }

                                final allCategories = snapshot.data!;
                                // Deduplicate categories by name to prevent Dropdown error if duplicates exist
                                final uniqueCategories = <String>{};
                                final currentCategories = allCategories
                                    .where((c) => c.type == _transactionType && uniqueCategories.add(c.name))
                                    .toList();

                                if (currentCategories.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                                    ),
                                    child: const Text('No categories found. Click Manage to add some!'),
                                  );
                                }

                                // Reset selection if not in list
                                if (_selectedCategory != null && !currentCategories.any((c) => c.name == _selectedCategory)) {
                                  // Don't auto-reset immediately to avoid flicker, or do?
                                  // For now, let's keep it, but it might be invalid.
                                  // Actually, better to reset it safely after build?
                                  // We'll let the user pick again.
                                }

                                return Container(
                                  decoration: BoxDecoration(
                                    color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(
                                      color: _selectedCategory != null 
                                          ? primaryColor.withValues(alpha: 0.5)
                                          : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                                    ),
                                    boxShadow: isDark ? null : [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.04),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<String>(
                                      value: currentCategories.any((c) => c.name == _selectedCategory) ? _selectedCategory : null,
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
                                          value: category.name,
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(horizontal: 16),
                                            child: Row(
                                              children: [
                                                Container(
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: primaryColor.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    IconData(category.iconCode, fontFamily: 'MaterialIcons'),
                                                    color: primaryColor,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Text(
                                                  category.name,
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
                                                    color: primaryColor.withValues(alpha: 0.1),
                                                    borderRadius: BorderRadius.circular(8),
                                                  ),
                                                  child: Icon(
                                                    IconData(category.iconCode, fontFamily: 'MaterialIcons'),
                                                    color: primaryColor,
                                                    size: 20,
                                                  ),
                                                ),
                                                const SizedBox(width: 14),
                                                Text(
                                                  category.name,
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
                                );
                              }
                            ).animate().slideX(begin: 0.1, end: 0, delay: 300.ms).fadeIn(),
                      
                      const SizedBox(height: 24),

                      // Note Input (Optional)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isDark ? null : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
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
                                color: primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.edit_note, color: primaryColor, size: 20),
                            ),
                            filled: true,
                            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
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
                          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _isPrivate 
                                ? Colors.orange.withValues(alpha: 0.5) 
                                : Theme.of(context).dividerColor.withValues(alpha: 0.3),
                          ),
                          boxShadow: isDark ? null : [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
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
                                color: _isPrivate ? Colors.orange.withValues(alpha: 0.15) : Colors.blue.withValues(alpha: 0.15),
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
                                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Switch(
                              value: _isPrivate,
                              onChanged: (val) => setState(() => _isPrivate = val),
                              thumbColor: WidgetStateProperty.all(Colors.orange),
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
                      color: Colors.black.withValues(alpha: 0.05),
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
                      : Text(widget.isEditMode ? 'Update Transaction' : 'Save Transaction', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
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
              ? (isDark ? color.withValues(alpha: 0.2) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected && !isDark 
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 6, offset: const Offset(0, 2))] 
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
