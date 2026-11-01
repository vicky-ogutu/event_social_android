import '../../../../core/models/paginated.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/event.dart';

abstract final class EventMapper {
  static Event fromJson(Json json) => Event(
        id: asInt(json['id']),
        uuid: asString(json['uuid']),
        organizerId: asInt(json['organizer_id']),
        name: asString(json['event_name'], 'Untitled event'),
        description: asStringOrNull(json['event_description']),
        visibility: EventVisibility.parse(asStringOrNull(json['event_type'])),
        accessCode: asStringOrNull(json['access_code']),
        date: asDate(json['event_date']),
        startTime: asString(json['start_time']),
        endTime: asStringOrNull(json['end_time']),
        venue: asStringOrNull(json['venue_address']),
        latitude: asDoubleOrNull(json['latitude']),
        longitude: asDoubleOrNull(json['longitude']),
        expectedAttendees: asIntOrNull(json['expected_attendees']),
        coverImage: asStringOrNull(json['cover_image']),
        budget: asDoubleOrNull(json['budget']),
        isLive: asBool(json['is_live']),
        viewCount: asInt(json['view_count']),
        likeCount: asInt(json['like_count']),
        isLiked: asBool(json['is_liked']),
        organizerName: asStringOrNull(json['organizer_name']),
        organizerPic: asStringOrNull(json['organizer_pic']),
      );

  static Json toJson(EventDraft draft) => {
        'event_name': draft.name,
        'event_description': draft.description,
        'event_type': draft.visibility.name,
        'access_code': draft.visibility == EventVisibility.private ? draft.accessCode : null,
        'event_date': toApiDate(draft.date),
        'start_time': draft.startTime,
        'end_time': draft.endTime,
        'venue_address': draft.venue,
        'expected_attendees': draft.expectedAttendees,
        'cover_image': draft.coverImage,
        'budget': draft.budget,
      };

  /// `{ data: [...], total, page, limit, pages }`, or a bare list.
  static Paginated<Event> page(Object? data) {
    if (data is List) {
      final items = asList(data, fromJson);
      return Paginated(items: items, page: 1, pages: 1, total: items.length);
    }
    final json = asJson(data);
    final items = asList(json['data'] ?? json['events'], fromJson);
    return Paginated(
      items: items,
      page: asInt(json['page'], 1),
      pages: asInt(json['pages'], 1),
      total: asInt(json['total'], items.length),
    );
  }
}
