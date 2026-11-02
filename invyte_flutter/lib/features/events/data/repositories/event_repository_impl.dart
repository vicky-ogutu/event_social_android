import '../../../../core/error/failure.dart';
import '../../../../core/models/paginated.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/event.dart';
import '../../domain/repositories/event_repository.dart';
import '../datasources/event_remote_data_source.dart';
import '../models/event_mapper.dart';

class EventRepositoryImpl implements EventRepository {
  const EventRepositoryImpl(this._remote);

  final EventRemoteDataSource _remote;

  @override
  Future<Paginated<Event>> discover({String? search, int page = 1, int limit = 20}) => guard(() async =>
      EventMapper.page(await _remote.list(search: search, eventType: 'public', page: page, limit: limit)));

  @override
  Future<Paginated<Event>> myEvents({int page = 1, int limit = 50}) =>
      guard(() async => EventMapper.page(await _remote.myEvents(page: page, limit: limit)));

  @override
  Future<Event> getEvent(int id) => guard(() async => EventMapper.fromJson(await _remote.get(id)));

  @override
  Future<Event> create(EventDraft draft) =>
      guard(() async => EventMapper.fromJson(await _remote.create(EventMapper.toJson(draft))));

  @override
  Future<Event> update(int id, EventDraft draft) =>
      guard(() async => EventMapper.fromJson(await _remote.update(id, EventMapper.toJson(draft))));

  @override
  Future<void> delete(int id) => guard(() => _remote.delete(id));

  @override
  Future<String> join(int id, {String accessCode = ''}) => guard(() async {
        await _remote.join(id, accessCode);
        return "You're on the guest list! 🎉";
      });

  @override
  Future<Event> joinByCode(String accessCode) =>
      guard(() async => EventMapper.fromJson(await _remote.joinByCode(accessCode.trim().toUpperCase())));

  @override
  Future<bool> toggleLike(int id) => guard(() async => asBool((await _remote.toggleLike(id))['liked']));

  @override
  Future<String> uploadCover(String filePath) => guard(() async {
        final url = asStringOrNull((await _remote.uploadCover(filePath))['cover_image']);
        if (url == null) throw const Failure('Upload failed. Please try another photo.');
        return url;
      });
}
