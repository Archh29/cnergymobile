class ProgramDetailModel {
  final int? id;
  final int programHdrId;
  final int dayNumber;
  final String? focus;
  final String scheduledDay;

  ProgramDetailModel({
    this.id,
    required this.programHdrId,
    required this.dayNumber,
    this.focus,
    required this.scheduledDay,
  });

  factory ProgramDetailModel.fromJson(Map<String, dynamic> json) {
    return ProgramDetailModel(
      id: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      programHdrId: int.parse(json['program_hdr_id'].toString()),
      dayNumber: int.parse(json['day_number'].toString()),
      focus: json['focus']?.toString(),
      scheduledDay: json['scheduled_day'].toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'program_hdr_id': programHdrId,
      'day_number': dayNumber,
      if (focus != null) 'focus': focus,
      'scheduled_day': scheduledDay,
    };
  }

  String get dayName => scheduledDay;
  
  static List<String> get weekDays => [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'
  ];
  
  static String getDayFromIndex(int index) {
    return weekDays[index % 7];
  }
  
  static int getIndexFromDay(String day) {
    return weekDays.indexOf(day);
  }
}
