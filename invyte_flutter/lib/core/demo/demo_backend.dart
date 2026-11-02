import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import '../realtime/realtime_service.dart';
import '../utils/json.dart';
import 'demo_seed.dart';

/// An in-memory implementation of the Invyte REST API.
///
/// It is exposed as an [http.Client], so in demo mode the *real* data layer
/// (data sources → repositories → providers) runs unchanged; only the
/// transport is swapped. State lives for the lifetime of the app process.
class DemoBackend {
  DemoBackend() {
    client = MockClient(_handle);
  }

  late final http.Client client;

  final _random = Random();
  final _users = DemoSeed.users();
  final _vendors = DemoSeed.vendors();
  final _categories = DemoSeed.categories();
  final _services = DemoSeed.services();
  final _portfolio = DemoSeed.portfolio();
  final _events = DemoSeed.events();
  final _bookings = DemoSeed.bookings();
  final _posts = DemoSeed.posts();
  final _comments = DemoSeed.comments();
  final _eventChat = DemoSeed.eventChat();
  final _messages = DemoSeed.directMessages();
  final _passwords = <String, String>{};
  final _eventLikes = <(int, int)>{(1, 2)};
  final _eventGuests = <(int, int)>{};
  final _postLikes = <(int, int)>{(1, 1), (1, 3)};
  final _livestreams = DemoSeed.livestreams();
  final _streamPasses = <(int, int)>{};

  final _eventMessages = StreamController<Json>.broadcast();
  final _privateMessages = StreamController<Json>.broadcast();

  late final RealtimeService realtime = _DemoRealtime(this);

  static String tokenFor(int userId) => 'demo.$userId';

  Future<http.Response> _handle(http.Request request) async {
    await Future<void>.delayed(Duration(milliseconds: 220 + _random.nextInt(320)));
    final segments = request.url.pathSegments.skipWhile((s) => s != 'api').skip(1).toList();
    final me = _authUser(request);
    final query = request.url.queryParameters;
    final body = _jsonBody(request);

    try {
      return switch ((request.method, segments)) {
        ('POST', ['auth', 'login']) => _login(body),
        ('POST', ['auth', 'register']) => _register(body),
        ('POST', ['auth', 'refresh']) => _refresh(body),
        ('POST', ['auth', 'logout']) => _ok(null, 'Logged out'),
        _ when me == null => _error(401, 'Please sign in to continue.'),
        _ => _route(request, segments, me, query, body),
      };
    } on _HttpError catch (e) {
      return _error(e.status, e.message);
    }
  }

  http.Response _route(http.Request request, List<String> path, Json me, Map<String, String> q, Json body) {
    final myId = asInt(me['id']);
    return switch ((request.method, path)) {
      // ---- Users ----
      ('POST', ['auth', 'logout-all']) => _ok(null, 'Signed out of all devices'),
      ('PUT', ['users', 'profile']) => _updateProfile(me, body),
      ('PUT', ['users', 'password']) => _changePassword(me, body),
      ('POST', ['users', 'upload-avatar']) => _uploadAvatar(me, request),

      // ---- Vendor self-service ----
      ('GET', ['vendors', 'profile']) => _ok(_vendorProfile(_requireVendor(myId))),
      ('POST', ['vendors', 'profile']) => _createVendorProfile(me, body),
      ('GET', ['vendors', 'payouts', 'status']) => _ok({'has_account': true, 'ready': true}),
      ('PUT', ['vendors', 'profile']) => _updateVendorProfile(myId, body),
      ('GET', ['vendors', 'services']) =>
        _ok(_services.where((s) => s['vendor_id'] == _requireVendor(myId)['id']).map(_serviceView).toList()),
      ('POST', ['vendors', 'services']) => _createService(myId, body),
      ('PUT', ['vendors', 'services', final id]) => _updateService(myId, asInt(id), body),
      ('DELETE', ['vendors', 'services', final id]) => _deleteService(myId, asInt(id)),
      ('GET', ['vendors', 'portfolio']) =>
        _ok(_portfolio.where((p) => p['vendor_id'] == _requireVendor(myId)['id']).toList().reversed.toList()),
      ('POST', ['vendors', 'portfolio']) => _uploadPortfolio(myId, request),
      ('GET', ['vendors', 'categories']) => _ok(_categories),

      // ---- Vendor discovery ----
      ('GET', ['vendors']) => _listVendors(q),
      ('GET', ['vendors', final id]) => _ok(_vendorDetail(_find(_vendors, asInt(id), 'Vendor'))),
      ('GET', ['vendors', final id, 'services']) =>
        _ok(_services.where((s) => s['vendor_id'] == asInt(id)).map(_serviceView).toList()),

      // ---- Events ----
      ('POST', ['events', 'upload-cover']) => _ok({'cover_image': _storeUpload(request)}),
      ('GET', ['events', 'my-events']) => _ok(_page(
          _events
              .where((e) => e['organizer_id'] == myId || _eventGuests.contains((myId, asInt(e['id']))))
              .map((e) => _eventView(e, myId))
              .toList()
            ..sort((a, b) => asString(a['event_date']).compareTo(asString(b['event_date']))),
          q)),
      ('GET', ['events']) => _listEvents(q, myId),
      ('POST', ['events']) => _createEvent(me, body),
      ('GET', ['events', final id]) => _getEvent(asInt(id), myId),
      ('PUT', ['events', final id]) => _updateEvent(asInt(id), myId, body),
      ('DELETE', ['events', final id]) => _deleteEvent(asInt(id), myId),
      ('POST', ['events', 'join']) => _joinEventByCode(myId, body),
      ('POST', ['events', final id, 'join']) => _joinEvent(asInt(id), myId, body),
      ('POST', ['events', final id, 'like']) => _likeEvent(asInt(id), myId),

      // ---- Bookings & payments ----
      ('POST', ['bookings']) => _createBooking(myId, body),
      ('GET', ['bookings', 'my-bookings']) => _ok(_bookings
          .where((b) => b['consumer_id'] == myId)
          .map(_bookingView)
          .toList()
          .reversed
          .toList()),
      ('GET', ['bookings', 'vendor']) => _ok(_bookings
          .where((b) => b['vendor_id'] == _requireVendor(myId)['id'])
          .map(_bookingView)
          .toList()
          .reversed
          .toList()),
      ('GET', ['bookings', final id]) => _ok(_bookingView(_find(_bookings, asInt(id), 'Booking'))),
      ('POST', ['bookings', final id, 'confirm-service']) => _setBookingStatus(asInt(id), myId, 'confirmed'),
      ('POST', ['bookings', final id, 'reject']) => _setBookingStatus(asInt(id), myId, 'rejected'),
      ('POST', ['bookings', final id, 'complete']) => _setBookingStatus(asInt(id), myId, 'completed'),
      ('GET', ['payments', 'config']) => _ok({'publishableKey': 'pk_demo', 'merchantDisplayName': 'Invyte'}),
      ('POST', ['payments', 'create-intent']) => _ok({
          'clientSecret': 'pi_demo_${asInt(body['booking_id'])}_secret',
          'paymentIntentId': 'pi_demo_${asInt(body['booking_id'])}',
        }),
      ('POST', ['payments', 'confirm']) => _confirmPayment(me, asString(body['payment_intent_id'])),

      // ---- Social ----
      ('GET', ['social', 'feed']) => _feed(q, myId),
      ('POST', ['social', 'posts']) => _createPost(myId, body),
      ('POST', ['social', 'upload']) => _ok({'url': _storeUpload(request), 'media_type': 'image'}, 'Uploaded'),
      ('POST', ['social', 'posts', final id, 'like']) => _likePost(asInt(id), myId),
      ('GET', ['social', 'posts', final id, 'comments']) =>
        _ok(_comments.where((c) => c['post_id'] == asInt(id)).map(_withAuthor).toList()),
      ('POST', ['social', 'posts', final id, 'comment']) => _addComment(asInt(id), myId, body),
      ('GET', ['social', 'events', final id, 'chat']) =>
        _ok(_eventChat.where((m) => m['event_id'] == asInt(id)).map(_withAuthor).toList()),
      ('POST', ['social', 'chat']) => _sendEventChat(myId, body),

      // ---- Livestream ----
      ('GET', ['livestream', 'event', final eventId]) => _ok(_livestreamFor(asInt(eventId), myId)),
      ('POST', ['livestream']) => _createLivestream(myId, body),
      ('POST', ['livestream', 'confirm-purchase']) => _grantPass(asInt(body['livestream_id']), myId),
      ('POST', ['livestream', final id, 'start']) => _setLive(asInt(id), myId, true),
      ('POST', ['livestream', final id, 'end']) => _setLive(asInt(id), myId, false),
      ('POST', ['livestream', final id, 'purchase']) => _purchasePass(asInt(id), myId),

      // ---- Direct messages ----
      ('GET', ['messages', 'conversations']) => _conversations(myId),
      ('GET', ['messages', final userId]) => _thread(myId, asInt(userId)),
      ('POST', ['messages']) => _sendDirect(myId, body),

      _ => _error(404, 'Not found: ${request.method} /${path.join('/')}'),
    };
  }

  // ===================================================================
  // Auth & users
  // ===================================================================

  http.Response _login(Json body) {
    final email = asString(body['email']).trim().toLowerCase();
    final user = _users.where((u) => u['email'] == email).firstOrNull;
    final expected = _passwords[email] ?? DemoSeed.password;
    if (user == null || asString(body['password']) != expected) {
      return _error(401, 'Invalid email or password.');
    }
    return _ok(_authPayload(user), 'Welcome back!');
  }

  http.Response _register(Json body) {
    final email = asString(body['email']).trim().toLowerCase();
    if (_users.any((u) => u['email'] == email)) {
      return _error(409, 'An account with this email already exists.');
    }
    final id = _nextId(_users);
    final user = {
      'id': id,
      'uuid': 'demo-user-$id',
      'email': email,
      'phone': null,
      'full_name': asString(body['full_name']),
      'profile_picture': null,
      'bio': null,
      'user_type': asString(body['user_type'], 'consumer'),
      'is_verified': 0,
      'rating': '0.0',
      'review_count': 0,
      'wallet_balance': '0.00',
      'total_spent': '0.00',
    };
    _users.add(user);
    _passwords[email] = asString(body['password']);
    return _ok(_authPayload(user), 'Account created');
  }

  /// Demo refresh tokens just encode the user id.
  http.Response _refresh(Json body) {
    final id = int.tryParse(asString(body['refresh_token']).replaceFirst('demo-refresh.', ''));
    if (id == null || !_users.any((u) => u['id'] == id)) {
      return _json(401, {'success': false, 'code': 'SESSION_EXPIRED', 'message': 'Session expired'});
    }
    return _ok({'access_token': tokenFor(id), 'refresh_token': 'demo-refresh.$id', 'expires_in': 900});
  }

  Json _authPayload(Json user) => {
        'token': tokenFor(asInt(user['id'])),
        'access_token': tokenFor(asInt(user['id'])),
        'refresh_token': 'demo-refresh.${user['id']}',
        'expires_in': 900,
        'user': _userView(user),
        'dashboard': user['user_type'] == 'vendor' ? 'vendor_home' : 'consumer_home',
      };

  Json _userView(Json user) {
    final vendor = _vendorFor(asInt(user['id']));
    return {
      ...user,
      if (vendor != null)
        'vendor': {
          'business_name': vendor['business_name'],
          'is_approved': vendor['is_approved'],
          'stripe_onboarding_complete': 1,
          'total_earnings': asDouble(vendor['total_earnings']).toStringAsFixed(2),
          'completed_jobs': vendor['completed_jobs'],
        },
    };
  }

  http.Response _updateProfile(Json me, Json body) {
    me['full_name'] = asString(body['full_name'], asString(me['full_name']));
    me['bio'] = body['bio'];
    return _ok({'user': _userView(me)}, 'Profile updated');
  }

  http.Response _changePassword(Json me, Json body) {
    final email = asString(me['email']);
    if (asString(body['old_password']) != (_passwords[email] ?? DemoSeed.password)) {
      return _error(400, 'Your current password is incorrect.');
    }
    _passwords[email] = asString(body['new_password']);
    final id = asInt(me['id']);
    return _ok({'access_token': tokenFor(id), 'refresh_token': 'demo-refresh.$id'}, 'Password updated');
  }

  http.Response _uploadAvatar(Json me, http.Request request) {
    me['profile_picture'] = _storeUpload(request);
    return _ok({'user': _userView(me)}, 'Photo updated');
  }

  // ===================================================================
  // Vendors
  // ===================================================================

  Json? _vendorFor(int userId) => _vendors.where((v) => v['user_id'] == userId).firstOrNull;

  Json _requireVendor(int userId) =>
      _vendorFor(userId) ?? (throw const _HttpError(404, 'Vendor profile not found'));

  Json _vendorProfile(Json v) => {
        'id': v['id'],
        'user_id': v['user_id'],
        'business_name': v['business_name'],
        'address': v['business_address'],
        'phone': v['business_phone'],
        'description': v['description'],
        'is_approved': asBool(v['is_approved']),
        'rating': asDouble(v['rating']).toStringAsFixed(1),
        'review_count': v['review_count'],
      };

  Json _vendorSummary(Json v) {
    final owner = _users.firstWhere((u) => u['id'] == v['user_id']);
    return {...v, 'full_name': owner['full_name'], 'profile_picture': owner['profile_picture']};
  }

  Json _vendorDetail(Json v) => {
        ..._vendorSummary(v),
        'services': _services.where((s) => s['vendor_id'] == v['id']).map(_serviceView).toList(),
        'portfolio': _portfolio.where((p) => p['vendor_id'] == v['id']).toList(),
      };

  Json _serviceView(Json s) => {
        ...s,
        'category_name': _categories.where((c) => c['id'] == s['category_id']).firstOrNull?['name'],
      };

  http.Response _listVendors(Map<String, String> q) {
    final category = q['category']?.toLowerCase();
    final search = q['search']?.toLowerCase();
    final minRating = double.tryParse(q['min_rating'] ?? '');
    final list = _vendors.where((v) {
      if (category != null && asString(v['service_category']).toLowerCase() != category) return false;
      if (minRating != null && asDouble(v['rating']) < minRating) return false;
      if (search != null && search.isNotEmpty) {
        final haystack = '${v['business_name']} ${v['service_category']} ${v['business_address']}'.toLowerCase();
        if (!haystack.contains(search)) return false;
      }
      return true;
    }).map(_vendorSummary).toList()
      ..sort((a, b) => asDouble(b['rating']).compareTo(asDouble(a['rating'])));
    return _ok(_page(list, q));
  }

  http.Response _createVendorProfile(Json me, Json body) {
    final userId = asInt(me['id']);
    if (_vendorFor(userId) != null) return _error(409, 'Vendor profile already exists');
    final vendor = {
      'id': _nextId(_vendors),
      'user_id': userId,
      'business_name': asString(body['business_name']),
      'business_address': body['address'],
      'business_phone': body['phone'],
      'business_email': me['email'],
      'service_category': null,
      'description': body['description'],
      'is_approved': 0,
      'total_earnings': 0.0,
      'completed_jobs': 0,
      'rating': 0.0,
      'review_count': 0,
      'cover_image': null,
    };
    _vendors.add(vendor);
    return _ok(_vendorProfile(vendor), 'Business profile created');
  }

  http.Response _updateVendorProfile(int userId, Json body) {
    final vendor = _requireVendor(userId)
      ..['business_name'] = asString(body['business_name'])
      ..['business_address'] = body['address']
      ..['business_phone'] = body['phone']
      ..['description'] = body['description'];
    return _ok(_vendorProfile(vendor), 'Business profile updated');
  }

  http.Response _createService(int userId, Json body) {
    final vendor = _requireVendor(userId);
    final categoryId = asInt(body['category_id']);
    final service = {
      'id': _nextId(_services),
      'vendor_id': vendor['id'],
      'category_id': categoryId,
      'service_name': asString(body['service_name']),
      'description': body['description'],
      'base_price': asDouble(body['base_price']),
      'price_unit': 'event',
      'is_active': 1,
    };
    _services.add(service);
    vendor['service_category'] ??= _categories.where((c) => c['id'] == categoryId).firstOrNull?['name'];
    return _ok(_serviceView(service), 'Service created');
  }

  http.Response _updateService(int userId, int id, Json body) {
    final service = _ownedService(userId, id)
      ..['category_id'] = asInt(body['category_id'])
      ..['service_name'] = asString(body['service_name'])
      ..['description'] = body['description']
      ..['base_price'] = asDouble(body['base_price']);
    return _ok(_serviceView(service), 'Service updated');
  }

  http.Response _deleteService(int userId, int id) {
    _services.remove(_ownedService(userId, id));
    return _ok(null, 'Service deleted');
  }

  Json _ownedService(int userId, int id) {
    final service = _find(_services, id, 'Service');
    if (service['vendor_id'] != _requireVendor(userId)['id']) throw const _HttpError(403, 'Not your service');
    return service;
  }

  http.Response _uploadPortfolio(int userId, http.Request request) {
    final vendor = _requireVendor(userId);
    final caption = _multipartField(request, 'caption');
    final item = {
      'id': _nextId(_portfolio),
      'vendor_id': vendor['id'],
      'media_url': _storeUpload(request),
      'media_type': 'image',
      'title': caption,
      'caption': caption,
      'likes_count': 0,
      'is_cover': 0,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    _portfolio.add(item);
    return _ok([item], 'Uploaded');
  }

  // ===================================================================
  // Events
  // ===================================================================

  Json _eventView(Json e, int viewerId) {
    final organizer = _users.firstWhere((u) => u['id'] == e['organizer_id']);
    return {
      ...e,
      'organizer_name': organizer['full_name'],
      'organizer_pic': organizer['profile_picture'],
      'is_liked': _eventLikes.contains((viewerId, asInt(e['id']))),
      'has_joined': _eventGuests.contains((viewerId, asInt(e['id']))),
      // Hide access codes and budgets from everyone except the organizer.
      if (e['organizer_id'] != viewerId) ...{'access_code': null, 'budget': null},
    };
  }

  http.Response _listEvents(Map<String, String> q, int myId) {
    final search = q['search']?.toLowerCase();
    final type = q['event_type'] ?? 'public';
    final list = _events.where((e) {
      if (e['event_type'] != type) return false;
      if (search != null && search.isNotEmpty) {
        final haystack = '${e['event_name']} ${e['venue_address']} ${e['event_description']}'.toLowerCase();
        if (!haystack.contains(search)) return false;
      }
      return true;
    }).map((e) => _eventView(e, myId)).toList()
      ..sort((a, b) {
        final live = asInt(b['is_live']).compareTo(asInt(a['is_live']));
        return live != 0 ? live : asString(a['event_date']).compareTo(asString(b['event_date']));
      });
    return _ok(_page(list, q));
  }

  http.Response _getEvent(int id, int myId) {
    final event = _find(_events, id, 'Event');
    if (event['event_type'] == 'private' && event['organizer_id'] != myId && !_eventGuests.contains((myId, id))) {
      return _error(403, 'You do not have access to this private event');
    }
    event['view_count'] = asInt(event['view_count']) + 1;
    return _ok(_eventView(event, myId));
  }

  http.Response _createEvent(Json me, Json body) {
    final id = _nextId(_events);
    final event = <String, dynamic>{
      'id': id,
      'uuid': 'demo-event-$id',
      'organizer_id': me['id'],
      ..._eventFields(body),
      'is_live': 0,
      'view_count': 0,
      'like_count': 0,
      'created_at': DateTime.now().toUtc().toIso8601String(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    _events.add(event);
    return _ok(_eventView(event, asInt(me['id'])), 'Event created');
  }

  http.Response _updateEvent(int id, int myId, Json body) {
    final event = _ownedEvent(id, myId)..addAll(_eventFields(body));
    event['updated_at'] = DateTime.now().toUtc().toIso8601String();
    return _ok(_eventView(event, myId), 'Event updated');
  }

  Json _eventFields(Json body) => {
        for (final key in const [
          'event_name', 'event_description', 'event_type', 'access_code', 'event_date', 'start_time',
          'end_time', 'venue_address', 'latitude', 'longitude', 'expected_attendees', 'cover_image', 'budget',
        ])
          key: body[key],
      };

  http.Response _deleteEvent(int id, int myId) {
    _events.remove(_ownedEvent(id, myId));
    return _ok(null, 'Event deleted');
  }

  Json _ownedEvent(int id, int myId) {
    final event = _find(_events, id, 'Event');
    if (event['organizer_id'] != myId) throw const _HttpError(403, 'Only the organizer can do that');
    return event;
  }

  http.Response _joinEvent(int id, int myId, Json body) {
    final event = _find(_events, id, 'Event');
    if (event['event_type'] == 'private' &&
        asString(body['access_code']).trim().toUpperCase() != asString(event['access_code']).toUpperCase()) {
      return _error(403, 'That access code doesn\'t match this event.');
    }
    if (event['organizer_id'] != myId) _eventGuests.add((myId, id));
    return _ok(null, "You're on the guest list! 🎉");
  }

  http.Response _joinEventByCode(int myId, Json body) {
    final code = asString(body['access_code']).trim().toUpperCase();
    final event = _events
        .where((e) => e['event_type'] == 'private' && asString(e['access_code']).toUpperCase() == code)
        .firstOrNull;
    if (event == null) return _error(403, 'Invalid access code');
    if (event['organizer_id'] != myId) _eventGuests.add((myId, asInt(event['id'])));
    return _ok(_eventView(event, myId), "You're on the guest list! 🎉");
  }

  http.Response _likeEvent(int id, int myId) {
    final event = _find(_events, id, 'Event');
    final key = (myId, id);
    final liked = !_eventLikes.remove(key);
    if (liked) _eventLikes.add(key);
    event['like_count'] = asInt(event['like_count']) + (liked ? 1 : -1);
    return _ok({'liked': liked});
  }

  Json _livestreamView(Json l, int viewerId) {
    final event = _find(_events, asInt(l['event_id']), 'Event');
    final host = event['organizer_id'] == viewerId;
    return {
      ...l,
      'is_host': host,
      'has_access': host || asDouble(l['pay_per_view_price']) <= 0 || _streamPasses.contains((asInt(l['id']), viewerId)),
    };
  }

  Json? _livestreamFor(int eventId, int viewerId) {
    final l = _livestreams
        .where((l) => l['event_id'] == eventId && l['stream_status'] != 'ended')
        .lastOrNull;
    return l == null ? null : _livestreamView(l, viewerId);
  }

  http.Response _createLivestream(int myId, Json body) {
    final eventId = asInt(body['event_id']);
    _ownedEvent(eventId, myId);
    final existing = _livestreamFor(eventId, myId);
    if (existing != null) return _ok(existing, 'Livestream ready');
    final row = {
      'id': _nextId(_livestreams),
      'event_id': eventId,
      'stream_status': 'scheduled',
      'pay_per_view_price': asDouble(body['pay_per_view_price']),
      'view_count': 0,
    };
    _livestreams.add(row);
    return _ok(_livestreamView(row, myId), 'Livestream created');
  }

  http.Response _setLive(int livestreamId, int myId, bool live) {
    final stream = _find(_livestreams, livestreamId, 'Livestream');
    _ownedEvent(asInt(stream['event_id']), myId)['is_live'] = live ? 1 : 0;
    stream['stream_status'] = live ? 'live' : 'ended';
    return _ok(null, live ? 'You are live!' : 'Stream ended');
  }

  http.Response _purchasePass(int livestreamId, int myId) {
    final stream = _find(_livestreams, livestreamId, 'Livestream');
    if (asDouble(stream['pay_per_view_price']) <= 0) return _grantPass(livestreamId, myId);
    return _ok({
      'client_secret': 'pi_demo_live_${livestreamId}_secret',
      'payment_intent_id': 'pi_demo_live_$livestreamId',
    });
  }

  http.Response _grantPass(int livestreamId, int myId) {
    _find(_livestreams, livestreamId, 'Livestream');
    _streamPasses.add((livestreamId, myId));
    return _ok({'access_token': 'demo-pass-$livestreamId-$myId'}, 'Enjoy the show!');
  }

  // ===================================================================
  // Bookings & payments
  // ===================================================================

  Json _bookingView(Json b) {
    final event = _events.where((e) => e['id'] == b['event_id']).firstOrNull;
    final vendor = _vendors.where((v) => v['id'] == b['vendor_id']).firstOrNull;
    final service = _services.where((s) => s['id'] == b['vendor_service_id']).firstOrNull;
    final consumer = _users.where((u) => u['id'] == b['consumer_id']).firstOrNull;
    return {
      ...b,
      'event_name': event?['event_name'] ?? 'Private event',
      'vendor_name': vendor?['business_name'],
      'service_name': service?['service_name'],
      'consumer_name': consumer?['full_name'],
    };
  }

  http.Response _createBooking(int myId, Json body) {
    final service = _find(_services, asInt(body['vendor_service_id']), 'Service');
    final quantity = max(1, asInt(body['quantity'], 1));
    final agreed = asDouble(service['base_price']) * quantity;
    final fee = double.parse((agreed * 0.05).toStringAsFixed(2));
    const tax = 0.0;
    final id = _nextId(_bookings);
    final booking = {
      'id': id,
      'booking_reference': 'INV-${(48210 + id * 37).toRadixString(36).toUpperCase()}',
      'event_id': asInt(body['event_id']),
      'vendor_service_id': service['id'],
      'vendor_id': service['vendor_id'],
      'consumer_id': myId,
      'booking_date': DateTime.now().toUtc().toIso8601String(),
      'service_date': body['service_date'],
      'service_time': body['service_time'],
      'quantity': quantity,
      'agreed_price': agreed,
      'service_fee': fee,
      'tax_amount': tax,
      'total_amount': agreed + fee + tax,
      'amount_paid': 0,
      'payment_status': 'pending',
      'vendor_payment_status': 'pending',
      'booking_status': 'pending',
      'special_requests': body['special_requests'],
    };
    _bookings.add(booking);
    return _ok(_bookingView(booking), 'Booking requested');
  }

  http.Response _setBookingStatus(int id, int myId, String status) {
    final booking = _find(_bookings, id, 'Booking');
    final vendor = _vendorFor(myId);
    final isVendor = vendor != null && vendor['id'] == booking['vendor_id'];
    final isConsumer = booking['consumer_id'] == myId;
    if (!isVendor && !isConsumer) return _error(403, 'This booking isn\'t yours');
    if (status != 'completed' && !isVendor) return _error(403, 'Only the vendor can do that');
    final paid = booking['payment_status'] == 'completed';
    if (status == 'confirmed' && !paid) return _error(409, 'The customer has not paid for this booking yet');
    if (status == 'rejected' && paid) {
      booking['payment_status'] = 'refunded';
      booking['amount_paid'] = 0;
    }
    booking['booking_status'] = status;
    if (status == 'completed') {
      booking['vendor_payment_status'] = 'released';
      final v = _vendors.firstWhere((v) => v['id'] == booking['vendor_id']);
      v['completed_jobs'] = asInt(v['completed_jobs']) + 1;
      v['total_earnings'] = asDouble(v['total_earnings']) + asDouble(booking['agreed_price']);
    }
    return _ok(null, 'Booking ${status == 'confirmed' ? 'accepted' : status}');
  }

  http.Response _confirmPayment(Json me, String paymentIntentId) {
    final bookingId = int.tryParse(paymentIntentId.replaceFirst('pi_demo_', ''));
    final booking = _find(_bookings, bookingId ?? 0, 'Booking');
    if (booking['consumer_id'] != me['id']) return _error(403, 'Unauthorized');
    if (booking['payment_status'] != 'completed') {
      booking['amount_paid'] = booking['total_amount'];
      booking['payment_status'] = 'completed';
      me['total_spent'] = (asDouble(me['total_spent']) + asDouble(booking['total_amount'])).toStringAsFixed(2);
    }
    return _ok(_bookingView(booking), 'Payment confirmed');
  }

  // ===================================================================
  // Social
  // ===================================================================

  Json _withAuthor(Json row) {
    final author = _users.firstWhere((u) => u['id'] == row['user_id']);
    return {...row, 'full_name': author['full_name'], 'profile_picture': author['profile_picture']};
  }

  http.Response _feed(Map<String, String> q, int myId) {
    final eventId = int.tryParse(q['event_id'] ?? '');
    final list = _posts
        .where((p) => eventId == null || p['event_id'] == eventId)
        .map((p) => {..._withAuthor(p), 'is_liked': _postLikes.contains((myId, asInt(p['id'])))})
        .toList()
      ..sort((a, b) => asString(b['created_at']).compareTo(asString(a['created_at'])));
    return _ok(list);
  }

  http.Response _createPost(int myId, Json body) {
    final post = {
      'id': _nextId(_posts),
      'event_id': asInt(body['event_id']),
      'user_id': myId,
      'content': asString(body['content']),
      'media_urls': asStringList(body['media_urls']),
      'media_type': asString(body['media_type'], 'image'),
      'like_count': 0,
      'comment_count': 0,
      'share_count': 0,
      'is_pinned': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    _posts.add(post);
    return _ok({..._withAuthor(post), 'is_liked': false}, 'Posted');
  }

  http.Response _likePost(int id, int myId) {
    final post = _find(_posts, id, 'Post');
    final key = (myId, id);
    final liked = !_postLikes.remove(key);
    if (liked) _postLikes.add(key);
    post['like_count'] = asInt(post['like_count']) + (liked ? 1 : -1);
    return _ok(null);
  }

  http.Response _addComment(int postId, int myId, Json body) {
    final post = _find(_posts, postId, 'Post');
    final comment = {
      'id': _nextId(_comments),
      'post_id': postId,
      'user_id': myId,
      'content': asString(body['content']),
      'parent_comment_id': body['parent_comment_id'],
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    _comments.add(comment);
    post['comment_count'] = asInt(post['comment_count']) + 1;
    return _ok(_withAuthor(comment), 'Comment added');
  }

  http.Response _sendEventChat(int myId, Json body) {
    final eventId = asInt(body['event_id']);
    final message = _addEventChat(eventId, myId, asString(body['message']));
    // Simulate the crowd replying so the demo feels alive.
    Timer(Duration(milliseconds: 1600 + _random.nextInt(1800)), () {
      final others = [10, 11, 12, 13].where((id) => id != myId).toList();
      final reply = _addEventChat(
        eventId,
        others[_random.nextInt(others.length)],
        DemoSeed.crowdChatter[_random.nextInt(DemoSeed.crowdChatter.length)],
      );
      if (!_eventMessages.isClosed) _eventMessages.add(reply);
    });
    return _ok(message);
  }

  Json _addEventChat(int eventId, int userId, String text) {
    final row = {
      'id': _nextId(_eventChat),
      'event_id': eventId,
      'user_id': userId,
      'message': text,
      'message_type': 'text',
      'media_url': null,
      'is_read': false,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    _eventChat.add(row);
    return _withAuthor(row);
  }

  // ===================================================================
  // Direct messages
  // ===================================================================

  http.Response _conversations(int myId) {
    final byUser = <int, List<Json>>{};
    for (final m in _messages) {
      if (m['sender_id'] != myId && m['receiver_id'] != myId) continue;
      final other = m['sender_id'] == myId ? asInt(m['receiver_id']) : asInt(m['sender_id']);
      byUser.putIfAbsent(other, () => []).add(m);
    }
    final list = byUser.entries.map((entry) {
      final user = _users.firstWhere((u) => u['id'] == entry.key);
      final last = entry.value.last;
      final vendor = _vendorFor(entry.key);
      return {
        'user_id': entry.key,
        'full_name': vendor?['business_name'] ?? user['full_name'],
        'profile_picture': user['profile_picture'],
        'user_type': user['user_type'],
        'last_message': last['message'],
        'last_message_time': last['created_at'],
        'unread_count': entry.value.where((m) => m['receiver_id'] == myId && m['is_read'] != true).length,
      };
    }).toList()
      ..sort((a, b) => asString(b['last_message_time']).compareTo(asString(a['last_message_time'])));
    return _ok(list);
  }

  http.Response _thread(int myId, int otherId) {
    final thread = _messages
        .where((m) =>
            (m['sender_id'] == myId && m['receiver_id'] == otherId) ||
            (m['sender_id'] == otherId && m['receiver_id'] == myId))
        .toList();
    for (final m in thread) {
      if (m['receiver_id'] == myId) m['is_read'] = true;
    }
    return _ok(thread);
  }

  http.Response _sendDirect(int myId, Json body) {
    final receiverId = asInt(body['receiver_id']);
    if (!_users.any((u) => u['id'] == receiverId)) return _error(404, 'User not found');
    final message = _addDirect(myId, receiverId, asString(body['message']));
    Timer(Duration(milliseconds: 1800 + _random.nextInt(1500)), () {
      final reply = _addDirect(
        receiverId,
        myId,
        DemoSeed.autoReplies[_random.nextInt(DemoSeed.autoReplies.length)],
      );
      if (!_privateMessages.isClosed) _privateMessages.add(reply);
    });
    return _ok(message);
  }

  Json _addDirect(int from, int to, String text) {
    final row = {
      'id': _nextId(_messages),
      'sender_id': from,
      'receiver_id': to,
      'message': text,
      'is_read': false,
      'read_at': null,
      'created_at': DateTime.now().toUtc().toIso8601String(),
    };
    _messages.add(row);
    return row;
  }

  // ===================================================================
  // Helpers
  // ===================================================================

  Json? _authUser(http.Request request) {
    final header = request.headers['authorization'] ?? request.headers['Authorization'];
    if (header == null || !header.startsWith('Bearer demo.')) return null;
    final id = int.tryParse(header.substring('Bearer demo.'.length));
    return _users.where((u) => u['id'] == id).firstOrNull;
  }

  Json _jsonBody(http.Request request) {
    final type = request.headers['content-type'] ?? '';
    if (!type.contains('application/json') || request.body.isEmpty) return {};
    try {
      return asJson(jsonDecode(request.body));
    } on FormatException {
      return {};
    }
  }

  Json _find(List<Json> table, int id, String name) =>
      table.where((row) => row['id'] == id).firstOrNull ?? (throw _HttpError(404, '$name not found'));

  int _nextId(List<Json> table) => table.fold<int>(0, (m, row) => max(m, asInt(row['id']))) + 1;

  Json _page(List<Json> list, Map<String, String> q) {
    final limit = int.tryParse(q['limit'] ?? '') ?? 20;
    final page = int.tryParse(q['page'] ?? '') ?? 1;
    final start = min((page - 1) * limit, list.length);
    return {
      'data': list.sublist(start, min(start + limit, list.length)),
      'total': list.length,
      'page': page,
      'limit': limit,
      'pages': max(1, (list.length / limit).ceil()),
    };
  }

  /// Persists the uploaded file to a temp file and returns a `file://` URL
  /// that the image widgets know how to render.
  String _storeUpload(http.Request request) {
    final bytes = _multipartFile(request);
    if (bytes == null) throw const _HttpError(400, 'No file uploaded');
    final file = File('${Directory.systemTemp.path}/invyte_demo_${DateTime.now().microsecondsSinceEpoch}.jpg')
      ..writeAsBytesSync(bytes);
    return file.uri.toString();
  }

  Uint8List? _multipartFile(http.Request request) {
    final boundary = _boundary(request);
    if (boundary == null) return null;
    final body = request.bodyBytes;
    final marker = latin1.encode('filename=');
    final at = _indexOf(body, marker, 0);
    if (at < 0) return null;
    final start = _indexOf(body, latin1.encode('\r\n\r\n'), at);
    if (start < 0) return null;
    final end = _indexOf(body, latin1.encode('\r\n--$boundary'), start + 4);
    if (end < 0) return null;
    return Uint8List.sublistView(body, start + 4, end);
  }

  String? _multipartField(http.Request request, String name) {
    if (_boundary(request) == null) return null;
    final text = latin1.decode(request.bodyBytes, allowInvalid: true);
    final match = RegExp('name="$name"\r\n\r\n([^\r]*)\r\n').firstMatch(text);
    final value = match?.group(1);
    return value == null || value.isEmpty ? null : utf8.decode(latin1.encode(value), allowMalformed: true);
  }

  String? _boundary(http.Request request) {
    final type = request.headers['content-type'] ?? '';
    final match = RegExp(r'boundary=("?)([^";]+)\1').firstMatch(type);
    return match?.group(2);
  }

  static int _indexOf(List<int> haystack, List<int> needle, int from) {
    outer:
    for (var i = from; i <= haystack.length - needle.length; i++) {
      for (var j = 0; j < needle.length; j++) {
        if (haystack[i + j] != needle[j]) continue outer;
      }
      return i;
    }
    return -1;
  }

  http.Response _ok(Object? data, [String message = 'OK']) =>
      _json(200, {'success': true, 'message': message, 'data': data});

  http.Response _error(int status, String message) =>
      _json(status, {'success': false, 'message': message});

  http.Response _json(int status, Object body) => http.Response.bytes(
        utf8.encode(jsonEncode(body)),
        status,
        headers: {'content-type': 'application/json; charset=utf-8'},
      );
}

class _HttpError implements Exception {
  const _HttpError(this.status, this.message);
  final int status;
  final String message;
}

class _DemoRealtime implements RealtimeService {
  _DemoRealtime(this._backend);
  final DemoBackend _backend;

  @override
  Stream<Json> get eventMessages => _backend._eventMessages.stream;

  @override
  Stream<Json> get privateMessages => _backend._privateMessages.stream;

  @override
  void connect() {}

  @override
  void disconnect() {}

  @override
  void joinEvent(int eventId) {}

  @override
  void leaveEvent(int eventId) {}

  // There is no media relay in demo mode: hosts see their own camera locally,
  // and viewers are told the host isn't connected yet.
  @override
  void send(String event, Json data) {}

  @override
  Future<Json> request(String event, Json data, {Duration timeout = const Duration(seconds: 10)}) async =>
      {'ok': true, 'hostOnline': false};

  @override
  Stream<Json> on(String event) => const Stream.empty();
}
