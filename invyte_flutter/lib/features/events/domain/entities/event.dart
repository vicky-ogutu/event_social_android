enum EventVisibility {
  public,
  private;

  static EventVisibility parse(String? value) => value == 'private' ? private : public;
}

class Event {
  const Event({
    required this.id,
    required this.organizerId,
    required this.name,
    required this.visibility,
    required this.startTime,
    this.uuid = '',
    this.date,
    this.description,
    this.accessCode,
    this.endTime,
    this.venue,
    this.latitude,
    this.longitude,
    this.expectedAttendees,
    this.coverImage,
    this.budget,
    this.isLive = false,
    this.viewCount = 0,
    this.likeCount = 0,
    this.isLiked = false,
    this.hasJoined = false,
    this.organizerName,
    this.organizerPic,
  });

  final int id;
  final String uuid;
  final int organizerId;
  final String name;
  final String? description;
  final EventVisibility visibility;
  final String? accessCode;
  final DateTime? date;
  final String startTime;
  final String? endTime;
  final String? venue;
  final double? latitude;
  final double? longitude;
  final int? expectedAttendees;
  final String? coverImage;
  final double? budget;
  final bool isLive;
  final int viewCount;
  final int likeCount;
  final bool isLiked;
  final bool hasJoined;
  final String? organizerName;
  final String? organizerPic;

  bool get isPrivate => visibility == EventVisibility.private;

  bool get isPast {
    if (date == null) return false;
    final now = DateTime.now();
    return date!.isBefore(DateTime(now.year, now.month, now.day));
  }

  Event copyWith({bool? isLive, int? likeCount, bool? isLiked}) => Event(
        id: id,
        uuid: uuid,
        organizerId: organizerId,
        name: name,
        description: description,
        visibility: visibility,
        accessCode: accessCode,
        date: date,
        startTime: startTime,
        endTime: endTime,
        venue: venue,
        latitude: latitude,
        longitude: longitude,
        expectedAttendees: expectedAttendees,
        coverImage: coverImage,
        budget: budget,
        isLive: isLive ?? this.isLive,
        viewCount: viewCount,
        likeCount: likeCount ?? this.likeCount,
        isLiked: isLiked ?? this.isLiked,
        hasJoined: hasJoined,
        organizerName: organizerName,
        organizerPic: organizerPic,
      );
}

/// User input for creating or updating an event.
class EventDraft {
  const EventDraft({
    required this.name,
    required this.date,
    required this.startTime,
    this.description,
    this.visibility = EventVisibility.public,
    this.accessCode,
    this.endTime,
    this.venue,
    this.expectedAttendees,
    this.coverImage,
    this.budget,
  });

  final String name;
  final String? description;
  final EventVisibility visibility;
  final String? accessCode;
  final DateTime date;
  final String startTime;
  final String? endTime;
  final String? venue;
  final int? expectedAttendees;
  final String? coverImage;
  final double? budget;
}

class EventQuery {
  const EventQuery({this.search});

  final String? search;

  @override
  bool operator ==(Object other) => other is EventQuery && other.search == search;

  @override
  int get hashCode => search.hashCode;
}
