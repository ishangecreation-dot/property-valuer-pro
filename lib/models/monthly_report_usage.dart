class MonthlyReportUsage {
  final String currentMonth; // Format: 'YYYY-MM', e.g. '2026-11'
  final int generatedCount;
  final int limit;
  final bool isPremium;

  const MonthlyReportUsage({
    required this.currentMonth,
    required this.generatedCount,
    required this.limit,
    required this.isPremium,
  });

  int get remaining => isPremium ? 999999 : (limit - generatedCount).clamp(0, limit);
  bool get isLimitReached => !isPremium && generatedCount >= limit;
  double get percentUsed => isPremium
      ? 0.0
      : (limit > 0 ? (generatedCount / limit).clamp(0.0, 1.0) : 1.0);

  Map<String, dynamic> toJson() => {
        'currentMonth': currentMonth,
        'generatedCount': generatedCount,
        'limit': limit,
        'isPremium': isPremium,
      };

  factory MonthlyReportUsage.fromJson(Map<String, dynamic> json) => MonthlyReportUsage(
        currentMonth: json['currentMonth'] as String? ?? '',
        generatedCount: json['generatedCount'] as int? ?? 0,
        limit: json['limit'] as int? ?? 5,
        isPremium: json['isPremium'] as bool? ?? false,
      );

  MonthlyReportUsage copyWith({
    String? currentMonth,
    int? generatedCount,
    int? limit,
    bool? isPremium,
  }) {
    return MonthlyReportUsage(
      currentMonth: currentMonth ?? this.currentMonth,
      generatedCount: generatedCount ?? this.generatedCount,
      limit: limit ?? this.limit,
      isPremium: isPremium ?? this.isPremium,
    );
  }
}
