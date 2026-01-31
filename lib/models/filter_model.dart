/// Filter model for advanced transaction filtering
class FilterModel {
  final DateTime? startDate;
  final DateTime? endDate;
  final List<String> categories;
  final double? minAmount;
  final double? maxAmount;
  final List<String> memberIds;

  const FilterModel({
    this.startDate,
    this.endDate,
    this.categories = const [],
    this.minAmount,
    this.maxAmount,
    this.memberIds = const [],
  });

  /// Check if any filter is active
  bool get hasActiveFilters =>
      startDate != null ||
      endDate != null ||
      categories.isNotEmpty ||
      minAmount != null ||
      maxAmount != null ||
      memberIds.isNotEmpty;

  /// Count of active filters
  int get activeFilterCount {
    int count = 0;
    if (startDate != null || endDate != null) count++;
    if (categories.isNotEmpty) count++;
    if (minAmount != null || maxAmount != null) count++;
    if (memberIds.isNotEmpty) count++;
    return count;
  }

  /// Create a copy with updated fields
  FilterModel copyWith({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? categories,
    double? minAmount,
    double? maxAmount,
    List<String>? memberIds,
    bool clearStartDate = false,
    bool clearEndDate = false,
    bool clearMinAmount = false,
    bool clearMaxAmount = false,
  }) {
    return FilterModel(
      startDate: clearStartDate ? null : (startDate ?? this.startDate),
      endDate: clearEndDate ? null : (endDate ?? this.endDate),
      categories: categories ?? this.categories,
      minAmount: clearMinAmount ? null : (minAmount ?? this.minAmount),
      maxAmount: clearMaxAmount ? null : (maxAmount ?? this.maxAmount),
      memberIds: memberIds ?? this.memberIds,
    );
  }

  /// Empty filter (no filters applied)
  static const empty = FilterModel();

  /// Clear all filters
  FilterModel clear() => empty;
}
