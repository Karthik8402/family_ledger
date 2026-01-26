import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart'; // Correctly placed import
import '../models/transaction_model.dart';
import '../services/firestore_service.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Form Fields
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _categoryController = TextEditingController();
  String _transactionType = TransactionModel.typeExpense; 
  bool _isPrivate = false;

  // Loading state
  bool _isLoading = false;

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Future<void> _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final user = FirebaseAuth.instance.currentUser;
      final String uid = user?.uid ?? 'test_user_id';
      final String uName = user?.email ?? 'Test User'; 

      try {
        final transaction = TransactionModel(
          id: '',
          amount: double.parse(_amountController.text),
          category: _categoryController.text,
          date: DateTime.now(),
          userId: uid,
          userName: uName,
          type: _transactionType,
          visibility: _isPrivate ? TransactionModel.visibilityPrivate : TransactionModel.visibilityShared,
        );

        await Provider.of<FirestoreService>(context, listen: false).addTransaction(transaction);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Transaction added successfully!'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('New Transaction'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Amount Input (Large Central)
                      const Text(
                        'Amount',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      IntrinsicWidth(
                        child: TextFormField(
                          controller: _amountController,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: isExpense ? Colors.red : Colors.green,
                          ),
                          decoration: const InputDecoration(
                            prefixText: '₹', // Currency Change
                            prefixStyle: TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: Colors.grey),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            hintText: '0.00',
                            filled: false,
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) return 'Enter amount';
                            if (double.tryParse(value) == null) return 'Invalid number';
                            return null;
                          },
                        ),
                      ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
                      const SizedBox(height: 32),

                      // 2. Type Selector
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.all(4),
                        child: Row(
                          children: [
                            Expanded(child: _buildTypeButton('Expense', TransactionModel.typeExpense, Colors.red)),
                            Expanded(child: _buildTypeButton('Income', TransactionModel.typeIncome, Colors.green)),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 24),

                      // 3. Category Input
                      TextFormField(
                        controller: _categoryController,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          hintText: 'What is this for?',
                          prefixIcon: Icon(Icons.category, color: Theme.of(context).colorScheme.primary),
                        ),
                        validator: (value) => value == null || value.isEmpty ? 'Required' : null,
                      ).animate().slideX(begin: 0.1, end: 0, delay: 300.ms).fadeIn(),
                      const SizedBox(height: 24),

                      // 4. Privacy Toggle
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Private Transaction', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          _isPrivate ? 'Visible only to you' : 'Shared with family',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                        secondary: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _isPrivate ? Colors.red.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            _isPrivate ? Icons.lock : Icons.public,
                            color: _isPrivate ? Colors.red : Colors.blue,
                          ),
                        ),
                        value: _isPrivate,
                        onChanged: (val) => setState(() => _isPrivate = val),
                      ).animate().slideX(begin: 0.1, end: 0, delay: 400.ms).fadeIn(),
                    ],
                  ),
                ),
              ),

              // Submit Button (Bottom Docked)
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: FilledButton(
                  onPressed: _isLoading ? null : _submitTransaction,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    backgroundColor: Theme.of(context).colorScheme.primary,
                  ),
                  child: _isLoading 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Save Transaction', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ).animate().slideY(begin: 1.0, end: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(String label, String value, Color color) {
    final isSelected = _transactionType == value;
    return GestureDetector(
      onTap: () => setState(() => _transactionType = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? color : Colors.grey,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
