import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/category_model.dart';
import '../models/budget_model.dart';

class CategoryManagementScreen extends StatefulWidget {
  const CategoryManagementScreen({super.key});

  @override
  State<CategoryManagementScreen> createState() =>
      _CategoryManagementScreenState();
}

class _CategoryManagementScreenState extends State<CategoryManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _familyId;
  bool _isLoading = true;

  // Icon Codes for Picker (Material Icons)
  final List<int> _iconOptions = [
    0xe596, // shopping_cart
    0xe532, // restaurant
    0xe1d7, // directions_car
    0xef6e, // receipt_long
    0xe318, // home
    0xe59c, // shopping_bag
    0xe3ae, // local_hospital
    0xe404, // movie
    0xe559, // school
    0xe3ad, // local_gas_station
    0xe6f2, // work
    0xe0af, // business
    0xe8f6, // card_giftcard
    0xe6e1, // trending_up
    0xe195, // flight
    0xe3b7, // local_dining
    0xe57a, // pool
    0xe541, // local_florist
    0xeb43, // fitness_center
    0xe41d, // pets
    0xe328, // child_care
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFamilyId());
  }

  Future<void> _loadFamilyId() async {
    final user = context.read<AuthService>().currentUser;
    if (user != null) {
      final userProfile =
          await context.read<FirestoreService>().getUserProfile(user.uid);
      if (mounted) {
        setState(() {
          _familyId = userProfile?.familyId;
          _isLoading = false;
        });

        // Seed defaults if empty
        if (_familyId != null) {
          context.read<FirestoreService>().ensureDefaultCategories(_familyId!);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Categories'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Expense'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _familyId == null
              ? const Center(child: Text('No family found'))
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildCategoryList('expense'),
                    _buildCategoryList('income'),
                  ],
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddCategoryDialog,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCategoryList(String type) {
    return StreamBuilder<List<CategoryModel>>(
      stream: context.read<FirestoreService>().streamCategories(_familyId!),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());

        final categories = snapshot.data!.where((c) => c.type == type).toList();

        if (categories.isEmpty) {
          return const Center(child: Text('No categories found'));
        }

        return ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    Theme.of(context).primaryColor.withValues(alpha: 0.1),
                child: Icon(IconData(cat.iconCode, fontFamily: 'MaterialIcons'),
                    color: Theme.of(context).primaryColor),
              ),
              title: Text(cat.name),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (type == 'expense')
                    IconButton(
                      icon: const Icon(Icons.attach_money, color: Colors.green),
                      tooltip: 'Set Monthly Budget',
                      onPressed: () => _showSetBudgetDialog(cat),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey),
                    onPressed: () => _deleteCategory(cat),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
            'Delete "${category.name}"? Transactions using this will keep the name.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true && _familyId != null) {
      if (mounted) {
        await context
            .read<FirestoreService>()
            .deleteCategory(_familyId!, category.id);
      }
    }
  }

  void _showAddCategoryDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddCategoryDialog(
        familyId: _familyId!,
        initialType: _tabController.index == 0 ? 'expense' : 'income',
        iconOptions: _iconOptions,
      ),
    );
  }

  Future<void> _showSetBudgetDialog(CategoryModel category) async {
    final controller = TextEditingController();

    // Check for existing budget (optional, skipping for speed, will just overwrite)
    // To make it nicer, we could fetch it, but let's keep it snappy.

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set Budget for ${category.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Set a monthly limit for this category. (Current Month)'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Amount (₹)',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text.trim());
              if (amount != null && amount > 0 && _familyId != null) {
                final now = DateTime.now();
                final budget = BudgetModel(
                  id: '', // Generated ID in service
                  familyId: _familyId!,
                  categoryName: category.name,
                  amount: amount,
                  month: now.month,
                  year: now.year,
                );

                await context
                    .read<FirestoreService>()
                    .setBudget(_familyId!, budget);
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            'Budget of ₹$amount set for ${category.name}')),
                  );
                }
              }
            },
            child: const Text('Save Budget'),
          ),
        ],
      ),
    );
  }
}

class AddCategoryDialog extends StatefulWidget {
  final String familyId;
  final String initialType;
  final List<int> iconOptions;

  const AddCategoryDialog({
    super.key,
    required this.familyId,
    required this.initialType,
    required this.iconOptions,
  });

  @override
  State<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends State<AddCategoryDialog> {
  late String _type;
  final _nameController = TextEditingController();
  late int _selectedIcon;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _selectedIcon = widget.iconOptions.first;
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final newCat = CategoryModel(
        id: '',
        name: _nameController.text.trim(),
        iconCode: _selectedIcon,
        type: _type,
      );

      await context
          .read<FirestoreService>()
          .addCategory(widget.familyId, newCat);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Handle error
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('New Category'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Category Name',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            const Text('Select Icon:'),
            const SizedBox(height: 8),
            SizedBox(
              height: 200,
              width: double.maxFinite,
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: widget.iconOptions.length,
                itemBuilder: (context, index) {
                  final code = widget.iconOptions[index];
                  final isSelected = _selectedIcon == code;
                  return InkWell(
                    onTap: () => setState(() => _selectedIcon = code),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Theme.of(context)
                                .primaryColor
                                .withValues(alpha: 0.2)
                            : null,
                        border: isSelected
                            ? Border.all(color: Theme.of(context).primaryColor)
                            : null,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(IconData(code, fontFamily: 'MaterialIcons')),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isLoading ? null : _save,
          child: _isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Save'),
        ),
      ],
    );
  }
}
