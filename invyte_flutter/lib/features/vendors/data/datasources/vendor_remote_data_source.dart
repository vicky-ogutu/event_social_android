import '../../../../core/network/api_client.dart';
import '../../../../core/utils/json.dart';

class VendorRemoteDataSource {
  const VendorRemoteDataSource(this._api);

  final ApiClient _api;

  Future<Object?> categories() => _api.get('api/vendors/categories');

  Future<Object?> list({String? search, String? category, double? minRating, int page = 1, int limit = 20}) =>
      _api.get('api/vendors', query: {
        'search': search,
        'category': category,
        'min_rating': minRating,
        'page': page,
        'limit': limit,
      });

  Future<Json> get(int id) async => asJson(await _api.get('api/vendors/$id'));

  Future<Object?> servicesOf(int vendorId) => _api.get('api/vendors/$vendorId/services');

  Future<Json> myProfile() async => asJson(await _api.get('api/vendors/profile'));

  Future<Json> createProfile(Json body) async => asJson(await _api.post('api/vendors/profile', body: body));

  Future<Json> updateProfile(Json body) async => asJson(await _api.put('api/vendors/profile', body: body));

  Future<Json> payoutStatus() async => asJson(await _api.get('api/users/payouts/status'));

  Future<Json> startPayoutOnboarding() async => asJson(await _api.post('api/users/payouts/onboard'));

  Future<Object?> myServices() => _api.get('api/vendors/services');

  Future<Json> createService(Json body) async => asJson(await _api.post('api/vendors/services', body: body));

  Future<Json> updateService(int id, Json body) async =>
      asJson(await _api.put('api/vendors/services/$id', body: body));

  Future<void> deleteService(int id) => _api.delete('api/vendors/services/$id');

  Future<Object?> myPortfolio() => _api.get('api/vendors/portfolio');

  Future<Object?> uploadPortfolio(String filePath, String? caption) => _api.upload(
        'api/vendors/portfolio',
        fileField: 'image',
        filePath: filePath,
        fields: {'caption': ?caption, 'title': ?caption},
      );
}
