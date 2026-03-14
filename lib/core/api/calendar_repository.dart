import 'package:cthree/core/api/dio_client.dart';
import 'package:cthree/core/models/calendar_entry_model.dart';
import 'package:dio/dio.dart';
import 'package:cthree/core/models/calendar_entry_model.dart';

class CalendarRepository {
  final Dio _dio = DioClient().dio;

  Future<bool> createDeliverableEntry(CalendarEntryModel calendarEntryModel) async {
    try {
      final reponse = await _dio.post(
        '/calendar_entries',
        data: {
          'calendar_entry': {
            'deliverable_id': calendarEntryModel.deliverableId,
            'title': calendarEntryModel.title,
            'brief': calendarEntryModel.brief,
            'date': "${calendarEntryModel.date}",
            'is_completed': calendarEntryModel.isCompleted,
            'entry_type': calendarEntryModel.entryType
          }
        }
      );

      if (reponse.statusCode == 201) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future<CalendarModel?> getCalendar() async {
    try {
      final response = await _dio.get(
        '/calendar_entries'
      );

      if (response.statusCode == 200) {
        return CalendarModel.fromJson(response.data);
      } else {
        return null;
      }
      
     } catch (e) {
      return null;
    }
  }
}