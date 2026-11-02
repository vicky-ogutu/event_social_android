import '../utils/json.dart';

/// Seed data for demo mode, shaped exactly like the Node backend's JSON.
abstract final class DemoSeed {
  static const password = 'demo1234';
  static const consumerEmail = 'amara@invyte.app';
  static const vendorEmail = 'daniel@lumiere.studio';

  /// Curated photos bundled in `assets/demo/` (see CREDITS.md there), so the
  /// demo looks right and works offline.
  static String photo(String name) => 'asset://assets/demo/$name.jpg';

  static String avatar(int n) => 'https://i.pravatar.cc/300?img=$n';

  static String day(int offset) => toApiDate(DateTime.now().add(Duration(days: offset)));

  static String ago(Duration d) => DateTime.now().subtract(d).toUtc().toIso8601String();

  static List<Json> categories() => [
        _cat(1, 'Photography', 'Photographers & videographers'),
        _cat(2, 'Catering', 'Chefs, caterers & bartenders'),
        _cat(3, 'Decor', 'Florists, stylists & set design'),
        _cat(4, 'Music & DJ', 'DJs, bands & sound engineers'),
        _cat(5, 'Venues', 'Gardens, halls & rooftops'),
        _cat(6, 'Beauty', 'Makeup artists & stylists'),
        _cat(7, 'Cakes & Desserts', 'Bakers & dessert tables'),
        _cat(8, 'Transport', 'Luxury cars & shuttles'),
      ];

  static Json _cat(int id, String name, String description) => {
        'id': id,
        'name': name,
        'slug': name.toLowerCase().replaceAll(RegExp(r'[^a-z]+'), '-'),
        'description': description,
      };

  static List<Json> users() => [
        _user(1, 'Amara Okafor', consumerEmail, 'consumer', 5,
            bio: 'Event lover, brunch enthusiast and soon-to-be bride 💍', spent: '4812.40'),
        _user(2, 'Daniel Mwangi', vendorEmail, 'vendor', 12,
            bio: 'Lead photographer at Lumière Studios.', rating: '4.9', reviews: 128),
        _user(3, 'Grace Achieng', 'grace@savorytable.co', 'vendor', 45, rating: '4.8', reviews: 96),
        _user(4, 'Naomi Wanjiru', 'naomi@bloompetal.co', 'vendor', 47, rating: '4.7', reviews: 74),
        _user(5, 'Brian Otieno', 'brian@pulsesound.co', 'vendor', 15, rating: '4.9', reviews: 151),
        _user(6, 'Peter Kamau', 'peter@grandgardens.co', 'vendor', 59, rating: '4.6', reviews: 58),
        _user(7, 'Aisha Mohamed', 'aisha@glowbeauty.co', 'vendor', 44, rating: '4.8', reviews: 83),
        _user(8, 'Mercy Njeri', 'mercy@sweetlayers.co', 'vendor', 32, rating: '4.9', reviews: 112),
        _user(9, 'James Mutua', 'james@eliterides.co', 'vendor', 53, rating: '4.5', reviews: 41),
        _user(10, 'Zuri Akinyi', 'zuri@invyte.app', 'consumer', 9),
        _user(11, 'Kofi Mensah', 'kofi@invyte.app', 'consumer', 11),
        _user(12, 'Leah Wambui', 'leah@invyte.app', 'consumer', 16),
        _user(13, 'Marcus Ouma', 'marcus@invyte.app', 'consumer', 33),
      ];

  static Json _user(int id, String name, String email, String type, int avatarN,
          {String? bio, String rating = '0.0', int reviews = 0, String spent = '0.00'}) =>
      {
        'id': id,
        'uuid': 'demo-user-$id',
        'email': email,
        'phone': '+254 7${id.toString().padLeft(2, '0')} 555 0${id.toString().padLeft(2, '0')}',
        'full_name': name,
        'profile_picture': avatar(avatarN),
        'bio': bio,
        'user_type': type,
        'is_verified': 1,
        'rating': rating,
        'review_count': reviews,
        'wallet_balance': '0.00',
        'total_spent': spent,
      };

  static List<Json> vendors() => [
        _vendor(1, 2, 'Lumière Studios', 'Photography', 4.9, 128, 214, 48250, 'Westlands, Nairobi',
            'Award-winning wedding & event photography. We capture the candid, the golden-hour and everything between.'),
        _vendor(2, 3, 'Savory Table Catering', 'Catering', 4.8, 96, 172, 61300, 'Kilimani, Nairobi',
            'Farm-to-table menus for 20 to 2,000 guests, from canapés to five-course plated dinners.'),
        _vendor(3, 4, 'Bloom & Petal Decor', 'Decor', 4.7, 74, 133, 35900, 'Karen, Nairobi',
            'Floral design and full venue styling that turns any space into a story.'),
        _vendor(4, 5, 'Pulse Sound & DJ', 'Music & DJ', 4.9, 151, 260, 42800, 'Lavington, Nairobi',
            'DJs, live bands and concert-grade sound & lighting for unforgettable dance floors.'),
        _vendor(5, 6, 'Grand Gardens Venue', 'Venues', 4.6, 58, 97, 88400, 'Runda, Nairobi',
            'Three acres of manicured gardens with a glass pavilion for up to 600 guests.'),
        _vendor(6, 7, 'Glow Beauty Bar', 'Beauty', 4.8, 83, 156, 22750, 'Kileleshwa, Nairobi',
            'Bridal and editorial makeup artists who travel to you.'),
        _vendor(7, 8, 'Sweet Layers Cakes', 'Cakes & Desserts', 4.9, 112, 301, 19800, 'Parklands, Nairobi',
            'Couture cakes and dessert tables baked from scratch.'),
        _vendor(8, 9, 'Elite Rides', 'Transport', 4.5, 41, 88, 27600, 'Upper Hill, Nairobi',
            'Chauffeured vintage and luxury cars plus guest shuttles.'),
      ];

  static Json _vendor(int id, int userId, String name, String category, double rating, int reviews,
          int jobs, double earnings, String address, String description) =>
      {
        'id': id,
        'user_id': userId,
        'business_name': name,
        'business_address': address,
        'business_phone': '+254 700 100 ${id.toString().padLeft(3, '0')}',
        'business_email': 'hello@${name.toLowerCase().replaceAll(RegExp(r'[^a-z]'), '')}.co',
        'service_category': category,
        'description': description,
        'is_approved': 1,
        'total_earnings': earnings,
        'completed_jobs': jobs,
        'rating': rating,
        'review_count': reviews,
        'cover_image': photo('p${id}_0'),
      };

  /// (vendorId, categoryId, name, description, price, unit)
  static List<Json> services() {
    var id = 0;
    Json s(int vendorId, int categoryId, String name, String description, double price, String unit) => {
          'id': ++id,
          'vendor_id': vendorId,
          'category_id': categoryId,
          'service_name': name,
          'description': description,
          'base_price': price,
          'price_unit': unit,
          'is_active': 1,
        };
    return [
      s(1, 1, 'Wedding Photography', 'Full-day coverage, two shooters, 600+ edited images and an online gallery.', 1800, 'event'),
      s(1, 1, 'Event Videography', 'Cinematic 4K highlight film plus full ceremony edit.', 1500, 'event'),
      s(1, 1, 'Photo Booth', 'Open-air booth with instant prints and custom backdrop.', 450, 'event'),
      s(2, 2, 'Buffet Catering', 'Three mains, four sides, salads and dessert station.', 35, 'guest'),
      s(2, 2, 'Plated Fine Dining', 'Five-course seated dinner with wine pairing.', 65, 'guest'),
      s(2, 2, 'Cocktail Canapés', 'Eight canapé varieties served by waiting staff.', 22, 'guest'),
      s(3, 3, 'Full Venue Styling', 'Concept, florals, tablescapes, lighting and setup.', 2400, 'event'),
      s(3, 3, 'Floral Arrangements', 'Bouquets, centrepieces and installations.', 650, 'package'),
      s(4, 4, 'DJ Set (5 hours)', 'Resident DJ with MC, full PA system and dance-floor lighting.', 900, 'event'),
      s(4, 4, 'Live Band', 'Six-piece band covering Afro-pop, jazz and soul.', 2200, 'event'),
      s(4, 4, 'Sound & Lighting', 'Line-array sound, moving heads and a technician.', 750, 'event'),
      s(5, 5, 'Garden Venue Hire', 'Exclusive use of gardens and pavilion for the day.', 3500, 'day'),
      s(5, 5, 'Marquee & Tent', 'Clear-span marquee with flooring and chandeliers.', 1200, 'day'),
      s(6, 6, 'Bridal Makeup', 'Trial session plus wedding-day makeup and touch-ups.', 350, 'person'),
      s(6, 6, 'Glam Squad', 'Makeup and hair for bridal parties and guests.', 120, 'person'),
      s(7, 7, 'Wedding Cake (3-tier)', 'Custom design, tasting session and delivery.', 480, 'cake'),
      s(7, 7, 'Dessert Table', 'Macarons, tarts and mini cakes styled to your theme.', 600, 'package'),
      s(8, 8, 'Luxury Car Hire', 'Chauffeured vintage or executive car with decor.', 300, 'day'),
      s(8, 8, 'Guest Shuttle', '33-seater coach with driver for guest transfers.', 550, 'day'),
    ];
  }

  static List<Json> portfolio() {
    var id = 0;
    const captions = ['Signature work', 'Behind the scenes', 'Details', 'Celebration', 'Recent event'];
    return [
      for (var v = 1; v <= 8; v++)
        for (var i = 0; i < 5; i++)
          {
            'id': ++id,
            'vendor_id': v,
            'media_url': photo('p${v}_$i'),
            'media_type': 'image',
            'title': captions[i],
            'caption': captions[i],
            'likes_count': 12 + (v * 7 + i * 13) % 90,
            'is_cover': i == 0 ? 1 : 0,
            'created_at': ago(Duration(days: 10 + i * 6)),
          },
    ];
  }

  static List<Json> events() => [
        _event(1, 1, "Amara & Tobi's Wedding",
            'Join us as we say "I do" surrounded by the people we love. Garden ceremony followed by dinner and dancing.',
            'private', 38, '14:00:00', '23:00:00', 'Windsor Golf Hotel, Nairobi', 180,
            budget: 25000, code: 'LOVE2026', views: 412, likes: 96),
        _event(2, 1, 'Invyte Launch Night',
            'An evening of music, demos and good company as we unveil the future of event planning.',
            'public', 12, '18:30:00', '22:00:00', 'The Alchemist, Westlands', 250,
            budget: 12000, views: 2304, likes: 381),
        _event(3, 1, 'Sunday Brunch Social',
            'Bottomless mimosas, a live acoustic set and the best people in town.',
            'public', 5, '11:00:00', '15:00:00', 'Tribe Hotel Rooftop', 60,
            budget: 2500, views: 640, likes: 122),
        _event(4, 10, 'Jazz Under the Stars',
            'An open-air jazz night with Nairobi\'s finest musicians. Bring a blanket!',
            'public', 0, '19:00:00', '23:00:00', 'Nairobi Arboretum', 800,
            live: true, views: 12840, likes: 2310),
        _event(5, 11, 'Founders & Funders Mixer',
            'Speed-networking between early-stage founders and angel investors.',
            'public', 9, '17:30:00', '21:00:00', 'iHub, Kilimani', 150, views: 1890, likes: 254),
        _event(6, 12, 'Contemporary Art Night',
            'Opening night of "New Horizons" featuring twelve emerging East African artists.',
            'public', 16, '18:00:00', '22:00:00', 'Circle Art Gallery', 120, views: 975, likes: 188),
        _event(7, 13, 'Rooftop Summer Party',
            'Sunset views, Afrobeats and signature cocktails.',
            'public', 21, '16:00:00', '23:59:00', 'Sankara Rooftop', 300, views: 3311, likes: 640),
        _event(8, 11, 'Kofi & Ama Engagement',
            'An intimate celebration with family and friends.',
            'private', 30, '15:00:00', '20:00:00', 'Hemingways, Karen', 80, code: 'ENGAGE', views: 88, likes: 31),
      ];

  static Json _event(int id, int organizer, String name, String description, String type, int dayOffset,
          String start, String end, String venue, int attendees,
          {double? budget, String? code, bool live = false, int views = 0, int likes = 0}) =>
      {
        'id': id,
        'uuid': 'demo-event-$id',
        'organizer_id': organizer,
        'event_name': name,
        'event_description': description,
        'event_type': type,
        'access_code': code,
        'event_date': day(dayOffset),
        'start_time': start,
        'end_time': end,
        'venue_address': venue,
        'latitude': null,
        'longitude': null,
        'expected_attendees': attendees,
        'cover_image': photo('event_$id'),
        'budget': budget,
        'is_live': live ? 1 : 0,
        'view_count': views,
        'like_count': likes,
        'created_at': ago(Duration(days: 40 - id)),
        'updated_at': ago(const Duration(days: 2)),
      };

  /// The jazz night is broadcasting with a paid stream pass.
  static List<Json> livestreams() => [
        {'id': 1, 'event_id': 4, 'stream_status': 'live', 'pay_per_view_price': 4.99, 'view_count': 12840},
      ];

  static List<Json> bookings() {
    var id = 0;
    Json b(int eventId, int serviceId, int vendorId, int consumerId, int dayOffset, String time, int qty,
        double unitPrice, String status, bool paid, {String? notes, int bookedDaysAgo = 7}) {
      final agreed = unitPrice * qty;
      final fee = double.parse((agreed * 0.05).toStringAsFixed(2));
      final tax = double.parse((agreed * 0.16).toStringAsFixed(2));
      final total = agreed + fee + tax;
      ++id;
      return {
        'id': id,
        'booking_reference': 'INV-${(48210 + id * 37).toRadixString(36).toUpperCase()}',
        'event_id': eventId,
        'vendor_service_id': serviceId,
        'vendor_id': vendorId,
        'consumer_id': consumerId,
        'booking_date': ago(Duration(days: bookedDaysAgo)),
        'service_date': day(dayOffset),
        'service_time': time,
        'quantity': qty,
        'agreed_price': agreed,
        'service_fee': fee,
        'tax_amount': tax,
        'total_amount': total,
        'amount_paid': paid ? total : 0,
        'payment_status': paid ? 'completed' : 'pending',
        'vendor_payment_status': status == 'completed' ? 'released' : 'pending',
        'booking_status': status,
        'special_requests': notes,
      };
    }

    return [
      b(1, 1, 1, 1, 38, '14:00:00', 1, 1800, 'confirmed', true,
          notes: 'Golden-hour couple portraits please!', bookedDaysAgo: 21),
      b(1, 4, 2, 1, 38, '17:00:00', 180, 35, 'pending', false,
          notes: '20 vegetarian and 4 gluten-free plates.', bookedDaysAgo: 2),
      b(3, 8, 3, 1, 5, '09:00:00', 2, 650, 'completed', true, bookedDaysAgo: 18),
      b(2, 9, 4, 1, 12, '18:30:00', 1, 900, 'confirmed', true, bookedDaysAgo: 9),
      // Lumière Studios' pipeline
      b(5, 2, 1, 11, 9, '17:30:00', 1, 1500, 'pending', false,
          notes: 'Need a 60-second recap for LinkedIn.', bookedDaysAgo: 1),
      b(8, 1, 1, 11, 30, '15:00:00', 1, 1800, 'confirmed', true, bookedDaysAgo: 12),
      b(7, 3, 1, 13, 21, '16:00:00', 1, 450, 'pending', false, bookedDaysAgo: 0),
      b(6, 2, 1, 12, -12, '18:00:00', 1, 1500, 'completed', true, bookedDaysAgo: 40),
      b(4, 1, 1, 10, -35, '19:00:00', 1, 1800, 'completed', true, bookedDaysAgo: 60),
      b(6, 3, 1, 12, -64, '18:00:00', 2, 450, 'completed', true, bookedDaysAgo: 80),
      b(7, 1, 1, 13, -95, '16:00:00', 1, 1800, 'completed', true, bookedDaysAgo: 110),
      b(5, 2, 1, 10, -128, '17:30:00', 1, 1500, 'completed', true, bookedDaysAgo: 150),
      b(2, 3, 1, 11, -150, '18:30:00', 1, 450, 'rejected', false, bookedDaysAgo: 160),
    ];
  }

  static List<Json> posts() => [
        _post(1, 4, 10, 'That saxophone solo tonight 🎷✨ Nairobi, you showed up!',
            [photo('post_1a'), photo('post_1b')], 342, 2, const Duration(minutes: 25)),
        _post(2, 2, 1, 'Two weeks to launch night! Venue is locked in and Pulse Sound is on the decks 🔥',
            [photo('post_2')], 128, 2, const Duration(hours: 2), pinned: true),
        _post(3, 6, 12, 'Sneak peek of the pieces going up at the gallery next week 🎨',
            [photo('post_3a'), photo('post_3b')], 211, 0, const Duration(hours: 5)),
        _post(4, 5, 11, 'Founders: bring your pitch decks. Funders: bring your questions. Coffee is on us ☕',
            const [], 87, 1, const Duration(days: 1)),
        _post(5, 1, 2, "Scouting golden-hour spots for Amara & Tobi's big day 📸",
            [photo('post_5')], 164, 1, const Duration(days: 2)),
        _post(6, 7, 13, "Rooftop season is BACK. Who's coming? 🌇",
            [photo('post_6')], 402, 0, const Duration(days: 3)),
      ];

  static Json _post(int id, int eventId, int userId, String content, List<String> media, int likes,
          int comments, Duration age, {bool pinned = false}) =>
      {
        'id': id,
        'event_id': eventId,
        'user_id': userId,
        'content': content,
        'media_urls': media,
        'media_type': 'image',
        'like_count': likes,
        'comment_count': comments,
        'share_count': likes ~/ 9,
        'is_pinned': pinned,
        'created_at': ago(age),
      };

  static List<Json> comments() {
    var id = 0;
    Json c(int postId, int userId, String content, Duration age) => {
          'id': ++id,
          'post_id': postId,
          'user_id': userId,
          'content': content,
          'parent_comment_id': null,
          'created_at': ago(age),
        };
    return [
      c(1, 11, 'Best night of the year, no contest.', const Duration(minutes: 20)),
      c(1, 1, 'Wish I was there 😭 Watching the stream though!', const Duration(minutes: 12)),
      c(2, 10, "Can't wait!!", const Duration(hours: 1)),
      c(2, 2, "We're ready to capture every moment.", const Duration(minutes: 50)),
      c(4, 13, "I'll be there with a deck 👀", const Duration(hours: 20)),
      c(5, 1, 'This is going to be magical 😍', const Duration(days: 1)),
    ];
  }

  static List<Json> eventChat() {
    var id = 0;
    Json m(int eventId, int userId, String message, Duration age) => {
          'id': ++id,
          'event_id': eventId,
          'user_id': userId,
          'message': message,
          'message_type': 'text',
          'media_url': null,
          'is_read': true,
          'created_at': ago(age),
        };
    return [
      m(4, 11, 'Sound is incredible from the back row 🙌', const Duration(minutes: 18)),
      m(4, 12, 'Anyone know the name of the opening track?', const Duration(minutes: 11)),
      m(4, 10, '"Nairobi Nights" by the Arboretum Quartet!', const Duration(minutes: 9)),
      m(4, 13, 'Streaming from Mombasa, the vibes are unreal', const Duration(minutes: 3)),
      m(1, 1, 'Welcome to our wedding chat! Details and updates will be shared here 💕', const Duration(days: 3)),
      m(1, 10, 'So excited for you both!', const Duration(days: 2)),
      m(2, 1, "Who's coming early for the soundcheck?", const Duration(hours: 6)),
    ];
  }

  static List<Json> directMessages() {
    var id = 0;
    Json m(int from, int to, String message, Duration age, {bool read = true}) => {
          'id': ++id,
          'sender_id': from,
          'receiver_id': to,
          'message': message,
          'is_read': read,
          'read_at': null,
          'created_at': ago(age),
        };
    return [
      m(1, 2, 'Hi Daniel! We loved your portfolio. Are you free on our wedding date?', const Duration(days: 22)),
      m(2, 1, "Congratulations! Yes, we're available. I've sent over our wedding package.", const Duration(days: 22)),
      m(1, 2, 'Booked! Could we do a few golden-hour portraits?', const Duration(days: 21)),
      m(2, 1, "Absolutely, I've noted it. We'll scout the venue next week 📸", const Duration(days: 2)),
      m(1, 3, 'Hello Grace, can you accommodate 20 vegetarian guests?', const Duration(days: 2)),
      m(3, 1, 'Of course! I just need final numbers two weeks before.', const Duration(hours: 3), read: false),
      m(11, 2, 'Hey, are you able to do a 60s recap video for our mixer?', const Duration(hours: 20)),
      m(13, 2, 'Is the photo booth available for a rooftop event?', const Duration(minutes: 40), read: false),
    ];
  }

  static const autoReplies = [
    'Sounds great! Let me check the calendar and get right back to you.',
    'Thanks for reaching out 😊 That works for us.',
    "Perfect, I've made a note of that.",
    'Absolutely, happy to help with that!',
  ];

  static const crowdChatter = [
    'This is amazing 🔥',
    'Hello from Kisumu 👋',
    'Can\'t wait!',
    'The energy here is unreal',
    'Love this 😍',
    'Who else is here early?',
  ];
}
