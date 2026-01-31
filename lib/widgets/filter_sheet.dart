import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/filter_model.dart';
import '../models/user_model.dart';

/// Bottom sheet widget for advanced transaction filtering
class FilterSheet extends StatefulWidget {
  final FilterModel currentFilter;
  final List<String> availableCategories;
  final List<UserModel> familyMembers;
  final Function(FilterModel) onApply;

  const FilterSheet({
    super.key,
    required this.currentFilter,
    required this.availableCategories,
    required this.familyMembers,
    required this.onApply,
  });

  /// Show the filter sheet as a modal bottom sheet
  static Future<void> show({
    required BuildContext context,
    required FilterModel currentFilter,
    required List<String> availableCategories,
    required List<UserModel> familyMembers,
    required Function(FilterModel) onApply,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        currentFilter: currentFilter,
        availableCategories: availableCategories,
        familyMembers: familyMembers,
        onApply: onApply,
      ),
    );
  }

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  late DateTime? _startDate;
  late DateTime? _endDate;
  late List<String> _selectedCategories;
  late double? _minAmount;
  late double? _maxAmount;
  late List<String> _selectedMemberIds;

  final _minAmountController = TextEditingController();
  final _maxAmountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startDate = widget.currentFilter.startDate;
    _endDate = widget.currentFilter.endDate;
    _selectedCategories = List.from(widget.currentFilter.categories);
    _minAmount = widget.currentFilter.minAmount;
    _maxAmount = widget.currentFilter.maxAmount;
    _selectedMemberIds = List.from(widget.currentFilter.memberIds);

    _minAmountController.text = _minAmount?.toString() ?? '';
    _maxAmountController.text = _maxAmount?.toString() ?? '';
  }

  @override
  void dispose() {
    _minAmountController.dispose();
    _maxAmountController.dispose();
    super.dispose();
  }

  void _clearAllFilters() {
    setState(() {
      _startDate = null;
      _endDate = null;
      _selectedCategories = [];
      _minAmount = null;
      _maxAmount = null;
      _selectedMemberIds = [];
      _minAmountController.clear();
      _maxAmountController.clear();
    });
  }

  void _applyFilters() {
    final filter = FilterModel(
      startDate: _startDate,
      endDate: _endDate,
      categories: _selectedCategories,
      minAmount: double.tryParse(_minAmountController.text),
      maxAmount: double.tryParse(_maxAmountController.text),
      memberIds: _selectedMemberIds,
    );
    widget.onApply(filter);
    Navigator.pop(context);
  }

  Future<void> _selectDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
      initialDateRange: _startDate != null && _endDate != null
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.only(top: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Filters',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: _clearAllFilters,
                      child: const Text('Clear All'),
                    ),
                  ],
                ),
              ),

              const Divider(height: 1),

              // Filter content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Date Range Section
                    _buildSectionTitle('Date Range', Icons.calendar_today),
                    const SizedBox(height: 8),
                    _buildDateRangeSelector(theme),
                    const SizedBox(height: 24),

                    // Categories Section
                    _buildSectionTitle('Categories', Icons.category),
                    const SizedBox(height: 8),
                    _buildCategoryChips(theme),
                    const SizedBox(height: 24),

                    // Amount Range Section
                    _buildSectionTitle('Amount Range', Icons.attach_money),
                    const SizedBox(height: 8),
                    _buildAmountRangeInputs(theme),
                    const SizedBox(height: 24),

                    // Members Section
                    if (widget.familyMembers.length > 1) ...[
                      _buildSectionTitle('Members', Icons.people),
                      const SizedBox(height: 8),
                      _buildMemberChips(theme),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),

              // Apply Button
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor,
                  border: Border(
                    top: BorderSide(color: theme.dividerColor),
                  ),
                ),
                child: SafeArea(
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: _applyFilters,
                      icon: const Icon(Icons.check),
                      label: const Text('Apply Filters'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector(ThemeData theme) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final hasDateRange = _startDate != null && _endDate != null;

    return InkWell(
      onTap: _selectDateRange,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasDateRange
              ? theme.colorScheme.primaryContainer.withValues(alpha: 0.3)
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          border: hasDateRange
              ? Border.all(
                  color: theme.colorScheme.primary.withValues(alpha: 0.5),
                )
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                hasDateRange
                    ? '${dateFormat.format(_startDate!)} - ${dateFormat.format(_endDate!)}'
                    : 'Select date range',
                style: TextStyle(
                  color: hasDateRange
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
            if (hasDateRange)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                onPressed: () => setState(() {
                  _startDate = null;
                  _endDate = null;
                }),
                visualDensity: VisualDensity.compact,
              )
            else
              Icon(
                Icons.arrow_drop_down,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChips(ThemeData theme) {
    if (widget.availableCategories.isEmpty) {
      return Text(
        'No categories available',
        style: TextStyle(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.availableCategories.map((category) {
        final isSelected = _selectedCategories.contains(category);
        return FilterChip(
          label: Text(category),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedCategories.add(category);
              } else {
                _selectedCategories.remove(category);
              }
            });
          },
          selectedColor: theme.colorScheme.primaryContainer,
          checkmarkColor: theme.colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAmountRangeInputs(ThemeData theme) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _minAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Min',
              prefixText: '₹ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text('to'),
        ),
        Expanded(
          child: TextField(
            controller: _maxAmountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: 'Max',
              prefixText: '₹ ',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMemberChips(ThemeData theme) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: widget.familyMembers.map((member) {
        final isSelected = _selectedMemberIds.contains(member.id);
        return FilterChip(
          avatar: member.photoUrl != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(member.photoUrl!),
                  radius: 12,
                )
              : CircleAvatar(
                  radius: 12,
                  child: Text(
                    member.name.isNotEmpty ? member.name[0].toUpperCase() : '?',
                    style: const TextStyle(fontSize: 10),
                  ),
                ),
          label: Text(member.name.split(' ').first),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedMemberIds.add(member.id);
              } else {
                _selectedMemberIds.remove(member.id);
              }
            });
          },
          selectedColor: theme.colorScheme.primaryContainer,
          checkmarkColor: theme.colorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        );
      }).toList(),
    );
  }
}
