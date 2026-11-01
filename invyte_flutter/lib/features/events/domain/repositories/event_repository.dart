import '../../../../core/models/paginated.dart';
import '../entities/event.dart';

abstract interface class EventRepository {
  Future<Paginated<Event>> discover({String? search, int page = 1, int limit = 20});

  Future<Paginated<Event>> myEvents({int page = 1, int limit = 50});

  Future<Event> getEvent(int id);

  Future<Event> create(EventDraft draft);

  Future<Event> update(int id, EventDraft draft);

  Future<void> delete(int id);

  /// Returns a confirmation message from the server.
  Future<String> join(int id, {String accessCode = ''});

  /// Returns whether the event is now liked.
  Future<bool> toggleLike(int id);

  /// Uploads a cover photo and returns its public URL.
  Future<String> uploadCover(String filePath);
}
