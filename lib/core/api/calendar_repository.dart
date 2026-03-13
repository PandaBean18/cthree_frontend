import 'package:cthree/core/api/dio_client.dart';
import 'package:cthree/core/models/calendar_entry_model.dart';
import 'package:dio/dio.dart';

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
}