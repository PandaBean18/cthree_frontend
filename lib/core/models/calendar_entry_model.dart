import 'dart:collection';

class CalendarEntryModel {
  String? id;
  String? title;
  String? brief; 
  DateTime date;
  String entryType;
  bool isCompleted;
  String? deliverableId;

  CalendarEntryModel({ this.id, this.title, this.brief, required this.date, required this.entryType, required this.isCompleted, this.deliverableId});

  factory CalendarEntryModel.fromJson(Map<String, dynamic> json) {
    return CalendarEntryModel(
      id: json['id'],
      title: json['title'], 
      date: DateTime.parse(json['date']), 
      entryType: json['entry_type'], 
      isCompleted: json['is_completed'],
      brief: json['brief'],
      deliverableId: json['deliverable'] == null ? null : json['deliverable']['id']
    );
  }
}

class CalendarModel {
  final SplayTreeMap<int, SplayTreeMap<int, Map<int, List<CalendarEntryModel>>>> data;

  CalendarModel({required this.data});

  factory CalendarModel.fromJson(List<dynamic> jsonList) {
    final Map<int, SplayTreeMap<int, Map<int, List<CalendarEntryModel>>>> rootMap = {};

    for (var item in jsonList) {
      final entry = CalendarEntryModel.fromJson(item as Map<String, dynamic>);
      final year = entry.date.year;
      final month = entry.date.month;
      final day = entry.date.day;
      
      rootMap.putIfAbsent(year, () => SplayTreeMap<int, Map<int, List<CalendarEntryModel>>>());

      rootMap[year]!.putIfAbsent(month, () => {});
      rootMap[year]![month]!.putIfAbsent(day, () => []);
      rootMap[year]![month]![day]!.add(entry);
    }

    return CalendarModel(data: SplayTreeMap.from(rootMap));    
  }

  Map<int, List<CalendarEntryModel>> getEntriesForMonth(int year, int month) {
    return data[year]?[month] ?? {};
  }
}