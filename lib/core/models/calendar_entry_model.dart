class CalendarEntryModel {
  String? title;
  String? brief; 
  DateTime date;
  String entryType;
  bool isCompleted;
  String? deliverableId;

  CalendarEntryModel({ this.title, this.brief, required this.date, required this.entryType, required this.isCompleted, this.deliverableId});

  factory CalendarEntryModel.fromJson(Map<String, dynamic> json) {
    return CalendarEntryModel(
      title: json['title'], 
      date: json['date'], 
      entryType: json['entry_type'], 
      isCompleted: json['is_completed'],
      brief: json['brief'] ?? null,
      deliverableId: json['deliverable'] == null ? null : json['deliverable']['id']
    );
  }
}