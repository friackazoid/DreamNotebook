import 'planner_type.dart';
import 'collections_data.dart';
import 'planner_page_data.dart';

class NotebookData {
  const NotebookData({
    required this.daily,
    required this.monthly,
    required this.collections,
  });

  final PlannerPageData daily;
  final PlannerPageData monthly;
  final CollectionsData collections;

  factory NotebookData.empty() => NotebookData(
        daily: PlannerPageData.empty(),
        monthly: PlannerPageData.empty(),
        collections: CollectionsData.empty(),
      );

  PlannerPageData plannerFor(PlannerType type) {
    return switch (type) {
      PlannerType.daily => daily,
      PlannerType.monthly => monthly,
    };
  }

  NotebookData copyWith({
    PlannerPageData? daily,
    PlannerPageData? monthly,
    CollectionsData? collections,
  }) {
    return NotebookData(
      daily: daily ?? this.daily,
      monthly: monthly ?? this.monthly,
      collections: collections ?? this.collections,
    );
  }

  NotebookData copyWithPlanner(PlannerType type, PlannerPageData data) {
    return switch (type) {
      PlannerType.daily => copyWith(daily: data),
      PlannerType.monthly => copyWith(monthly: data),
    };
  }

  factory NotebookData.fromJson(Map<String, dynamic> json) {
    return NotebookData(
      daily: PlannerPageData.fromJson(
          json['daily'] as Map<String, dynamic>? ?? const {}),
      monthly: PlannerPageData.fromJson(
          json['monthly'] as Map<String, dynamic>? ?? const {}),
      collections: CollectionsData.fromJson(
          json['collections'] as Map<String, dynamic>? ?? const {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'daily': daily.toJson(),
      'monthly': monthly.toJson(),
      'collections': collections.toJson(),
    };
  }
}
