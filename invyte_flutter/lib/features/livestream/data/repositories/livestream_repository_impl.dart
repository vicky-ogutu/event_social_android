import '../../../../core/error/failure.dart';
import '../../../../core/utils/json.dart';
import '../../domain/entities/livestream.dart';
import '../../domain/repositories/livestream_repository.dart';
import '../datasources/livestream_remote_data_source.dart';
import '../models/livestream_mapper.dart';

class LivestreamRepositoryImpl implements LivestreamRepository {
  const LivestreamRepositoryImpl(this._remote);

  final LivestreamRemoteDataSource _remote;

  @override
  Future<LiveJoinInfo> joinInfo(int livestreamId) => guard(() async {
        final json = await _remote.joinInfo(livestreamId);
        return LiveJoinInfo(url: asString(json['url']), token: asString(json['token']));
      });

  @override
  Future<Livestream?> forEvent(int eventId) => guard(() async {
        final data = await _remote.forEvent(eventId);
        return data is Map ? LivestreamMapper.fromJson(asJson(data)) : null;
      });

  @override
  Future<Livestream> prepare(int eventId, {double price = 0}) =>
      guard(() async => LivestreamMapper.fromJson(await _remote.create(eventId, price)));

  @override
  Future<void> start(int livestreamId) => guard(() => _remote.start(livestreamId));

  @override
  Future<void> end(int livestreamId) => guard(() => _remote.end(livestreamId));

  @override
  Future<StreamPass> purchase(int livestreamId) =>
      guard(() async => LivestreamMapper.pass(await _remote.purchase(livestreamId)));

  @override
  Future<void> confirmPurchase({required int livestreamId, required String paymentIntentId}) =>
      guard(() => _remote.confirmPurchase(livestreamId, paymentIntentId));
}
