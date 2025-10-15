class ProgressModel {
  final int? id;
  final int userId;
  final double? weight;
  final double? bmi;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final String? notes;
  final DateTime dateRecorded;

  ProgressModel({
    this.id,
    required this.userId,
    this.weight,
    this.bmi,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.notes,
    required this.dateRecorded,
  });

  factory ProgressModel.fromJson(Map<String, dynamic> json) {
    return ProgressModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      userId: int.parse(json['user_id'].toString()),
      weight: json['weight'] != null ? double.tryParse(json['weight'].toString()) : null,
      bmi: json['bmi'] != null ? double.tryParse(json['bmi'].toString()) : null,
      chestCm: json['chest_cm'] != null ? double.tryParse(json['chest_cm'].toString()) : null,
      waistCm: json['waist_cm'] != null ? double.tryParse(json['waist_cm'].toString()) : null,
      hipsCm: json['hips_cm'] != null ? double.tryParse(json['hips_cm'].toString()) : null,
      notes: json['notes']?.toString(),
      dateRecorded: DateTime.parse(json['date_recorded']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      if (weight != null) 'weight': weight,
      if (bmi != null) 'bmi': bmi,
      if (chestCm != null) 'chest_cm': chestCm,
      if (waistCm != null) 'waist_cm': waistCm,
      if (hipsCm != null) 'hips_cm': hipsCm,
      if (notes != null) 'notes': notes,
      'date_recorded': dateRecorded.toIso8601String().split('T')[0],
    };
  }

  String get formattedDate {
    final now = DateTime.now();
    final difference = now.difference(dateRecorded).inDays;
    if (difference == 0) return 'Today';
    if (difference == 1) return 'Yesterday';
    if (difference < 7) return '$difference days ago';
    return '${dateRecorded.day}/${dateRecorded.month}/${dateRecorded.year}';
  }

  // Getter for body fat percentage (not available in your DB, return null)
  double? get bodyFatPercentage => null;
}

// Extension to help with progress calculations
extension ProgressList on List<ProgressModel> {
  ProgressModel? get latest {
    if (isEmpty) return null;
    return reduce((a, b) => a.dateRecorded.isAfter(b.dateRecorded) ? a : b);
  }

  List<ProgressModel> getEntriesInRange(DateTime startDate, DateTime endDate) {
    return where((progress) =>
        progress.dateRecorded.isAfter(startDate.subtract(Duration(days: 1))) &&
        progress.dateRecorded.isBefore(endDate.add(Duration(days: 1)))).toList();
  }
}
