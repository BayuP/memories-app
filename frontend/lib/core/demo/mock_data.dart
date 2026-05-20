import 'package:memories_app/features/checkin/domain/entities/checkin_entity.dart';
import 'package:memories_app/features/profile/domain/entities/profile_entity.dart';
import 'package:memories_app/features/trips/domain/entities/trip_entity.dart';

// ---------------------------------------------------------------------------
// Mock user / profile
// ---------------------------------------------------------------------------

final mockProfile = ProfileEntity(
  id: 'user-001',
  handle: 'bayupabisa',
  displayName: 'Bayu Pabisa',
  email: 'bayu@example.com',
  avatarUrl: null,
  createdAt: DateTime(2024, 1, 15),
);

// ---------------------------------------------------------------------------
// Mock collaborators
// ---------------------------------------------------------------------------

const mockMemberFira = MemberEntity(
  userId: 'user-002',
  handle: 'firafira',
  displayName: 'Fira',
  role: 'member',
);

const mockMemberRaka = MemberEntity(
  userId: 'user-003',
  handle: 'raka123',
  displayName: 'Raka',
  role: 'member',
);

const mockMemberMaya = MemberEntity(
  userId: 'user-004',
  handle: 'mayaputri',
  displayName: 'Maya',
  role: 'member',
);

// ---------------------------------------------------------------------------
// Mock trips
// ---------------------------------------------------------------------------

// Trip 1 — Bali Adrenaline Trip (completed, May 8-15 2024)
final mockTripBali = TripEntity(
  id: 'trip-001',
  title: 'Bali Adrenaline Trip 🌴',
  destination: 'Bali, Indonesia',
  startDate: DateTime(2024, 5, 8),
  endDate: DateTime(2024, 5, 15),
  vibes: ['adventure', 'foodie'],
  status: TripStatus.active,
  createdAt: DateTime(2024, 5, 1),
);

// Trip 2 — Tokyo Ramen Run (upcoming, 5 days from now)
final _tokyoStart = DateTime.now().add(const Duration(days: 5));
final _tokyoEnd = _tokyoStart.add(const Duration(days: 6));
final mockTripTokyo = TripEntity(
  id: 'trip-002',
  title: 'Tokyo Ramen Run 🍜',
  destination: 'Tokyo, Japan',
  startDate: _tokyoStart,
  endDate: _tokyoEnd,
  vibes: ['foodie', 'culture'],
  status: TripStatus.active,
  createdAt: DateTime.now().subtract(const Duration(days: 10)),
);

// Trip 3 — Bandung Weekend (completed, last month)
final _bandungStart = DateTime.now().subtract(const Duration(days: 35));
final _bandungEnd = _bandungStart.add(const Duration(days: 2));
final mockTripBandung = TripEntity(
  id: 'trip-003',
  title: 'Bandung Weekend 🌋',
  destination: 'Bandung, Indonesia',
  startDate: _bandungStart,
  endDate: _bandungEnd,
  vibes: ['relaxed'],
  status: TripStatus.active,
  createdAt: _bandungStart.subtract(const Duration(days: 7)),
);

// Convenience list — shown on home / profile
final mockTripsList = [mockTripBali, mockTripTokyo, mockTripBandung];

// ---------------------------------------------------------------------------
// Trip detail entities
// ---------------------------------------------------------------------------

final mockTripBaliDetail = TripDetailEntity(
  trip: mockTripBali,
  members: [mockMemberFira, mockMemberRaka, mockMemberMaya],
);

final mockTripTokyoDetail = TripDetailEntity(
  trip: mockTripTokyo,
  members: [mockMemberFira, mockMemberRaka],
);

final mockTripBandungDetail = TripDetailEntity(
  trip: mockTripBandung,
  members: [mockMemberMaya],
);

TripDetailEntity mockTripDetailFor(String tripId) {
  switch (tripId) {
    case 'trip-002':
      return mockTripTokyoDetail;
    case 'trip-003':
      return mockTripBandungDetail;
    default:
      return mockTripBaliDetail;
  }
}

// ---------------------------------------------------------------------------
// Bali itinerary items (8 days: day 0 = departure, days 1-7)
// ---------------------------------------------------------------------------

final mockBaliItinerary = <ItineraryItemEntity>[
  // Day 0 — Departure
  const ItineraryItemEntity(
    id: 'item-001',
    tripId: 'trip-001',
    day: 0,
    title: 'Departure flight CGK → DPS',
    startTime: '07:00',
    endTime: '09:30',
    description: 'Garuda Indonesia GA-401. Check in 2 hours early.',
    locationName: 'Soekarno-Hatta International Airport',
    lat: -6.1256,
    lng: 106.6559,
    source: 'ai',
  ),
  const ItineraryItemEntity(
    id: 'item-002',
    tripId: 'trip-001',
    day: 0,
    title: 'Hotel check-in — Alaya Resort',
    startTime: '14:00',
    endTime: null,
    description: 'Ubud resort. Pool, jungle view, breakfast included.',
    locationName: 'Alaya Resort Ubud, Jl. Hanoman No.31',
    lat: -8.5102,
    lng: 115.2625,
    source: 'ai',
  ),
  // Day 1
  const ItineraryItemEntity(
    id: 'item-003',
    tripId: 'trip-001',
    day: 1,
    title: 'Tanah Lot Temple',
    startTime: '08:00',
    endTime: '11:00',
    description: 'Iconic sea temple perched on a rock. Go early to avoid crowds.',
    locationName: 'Tanah Lot, Tabanan',
    lat: -8.6215,
    lng: 115.0870,
    source: 'ai',
  ),
  const ItineraryItemEntity(
    id: 'item-004',
    tripId: 'trip-001',
    day: 1,
    title: 'Sunset dinner — Jimbaran Bay',
    startTime: '18:00',
    endTime: '21:00',
    description: 'Fresh seafood on the beach. The grilled lobster is unreal.',
    locationName: 'Jimbaran Beach Seafood, Jimbaran',
    lat: -8.7936,
    lng: 115.1638,
    source: 'ai',
  ),
  // Day 2
  const ItineraryItemEntity(
    id: 'item-005',
    tripId: 'trip-001',
    day: 2,
    title: 'Ubud Monkey Forest',
    startTime: '09:00',
    endTime: '11:30',
    description: 'Sacred Balinese Hindu temple complex inhabited by long-tailed macaques.',
    locationName: 'Mandala Wisata Wenara Wana, Ubud',
    lat: -8.5190,
    lng: 115.2617,
    source: 'ai',
  ),
  const ItineraryItemEntity(
    id: 'item-006',
    tripId: 'trip-001',
    day: 2,
    title: 'Rice Terraces — Tegalalang',
    startTime: '13:00',
    endTime: '15:30',
    description: 'UNESCO-listed rice paddies. Most photogenic spot in Bali.',
    locationName: 'Tegalalang Rice Terrace, Gianyar',
    lat: -8.4314,
    lng: 115.2778,
    source: 'ai',
  ),
  const ItineraryItemEntity(
    id: 'item-007',
    tripId: 'trip-001',
    day: 2,
    title: 'Café Lotus — dinner',
    startTime: '19:00',
    endTime: '21:00',
    description: 'Beautiful lotus pond setting. Try the duck confit nasi campur.',
    locationName: 'Café Lotus, Jl. Raya Ubud',
    lat: -8.5072,
    lng: 115.2621,
    source: 'ai',
  ),
  // Day 3
  const ItineraryItemEntity(
    id: 'item-008',
    tripId: 'trip-001',
    day: 3,
    title: 'Gitgit Waterfall',
    startTime: '09:00',
    endTime: '12:00',
    description: '35 metre waterfall surrounded by rainforest. Bring a change of clothes.',
    locationName: 'Air Terjun Gitgit, Sukasada, Buleleng',
    lat: -8.2045,
    lng: 115.1412,
    source: 'ai',
  ),
  const ItineraryItemEntity(
    id: 'item-009',
    tripId: 'trip-001',
    day: 3,
    title: 'Seminyak Beach Club',
    startTime: '16:00',
    endTime: '20:00',
    description: 'Sunset cocktails at Ku De Ta. Reserve a sunbed in advance.',
    locationName: 'Ku De Ta, Jl. Kayu Aya, Seminyak',
    lat: -8.6817,
    lng: 115.1549,
    source: 'ai',
  ),
  // Day 4
  const ItineraryItemEntity(
    id: 'item-010',
    tripId: 'trip-001',
    day: 4,
    title: 'Surfing lesson — Canggu',
    startTime: '08:00',
    endTime: '10:30',
    description: 'Beginner-friendly waves. Instructor included. Boards provided.',
    locationName: 'Batu Bolong Beach, Canggu',
    lat: -8.6588,
    lng: 115.1293,
    source: 'ai',
  ),
  const ItineraryItemEntity(
    id: 'item-011',
    tripId: 'trip-001',
    day: 4,
    title: 'La Brisa lunch',
    startTime: '12:30',
    endTime: '14:30',
    description: 'Driftwood beach club vibe. Fish tacos and cold beer.',
    locationName: 'La Brisa Bali, Jl. Pantai Batu Mejan, Canggu',
    lat: -8.6537,
    lng: 115.1284,
    source: 'ai',
  ),
  // Day 5
  const ItineraryItemEntity(
    id: 'item-012',
    tripId: 'trip-001',
    day: 5,
    title: 'Uluwatu Temple',
    startTime: '16:00',
    endTime: '19:00',
    description: 'Cliffside temple 70m above the ocean. Kecak fire dance at sunset.',
    locationName: 'Pura Luhur Uluwatu, Pecatu, Badung',
    lat: -8.8291,
    lng: 115.0849,
    source: 'ai',
  ),
  const ItineraryItemEntity(
    id: 'item-013',
    tripId: 'trip-001',
    day: 5,
    title: 'Kecak fire dance',
    startTime: '18:00',
    endTime: '19:30',
    description: 'Ancient Balinese ritual performed as the sun sets behind the temple.',
    locationName: 'Uluwatu Amphitheatre',
    lat: -8.8295,
    lng: 115.0845,
    source: 'ai',
  ),
  const ItineraryItemEntity(
    id: 'item-014',
    tripId: 'trip-001',
    day: 5,
    title: 'Seafood dinner — Jimbaran',
    startTime: '20:00',
    endTime: '22:00',
    description: 'Tables on the sand, waves lapping nearby. Order the mixed grill.',
    locationName: 'Menega Café, Jimbaran',
    lat: -8.7959,
    lng: 115.1640,
    source: 'ai',
  ),
  // Day 6
  const ItineraryItemEntity(
    id: 'item-015',
    tripId: 'trip-001',
    day: 6,
    title: 'Free day — Seminyak shopping',
    startTime: '10:00',
    endTime: '18:00',
    description: 'Browse Seminyak Square and Bali Collective for local crafts and fashion.',
    locationName: 'Seminyak Square, Seminyak',
    lat: -8.6912,
    lng: 115.1595,
    source: 'ai',
  ),
  // Day 7 — Return
  const ItineraryItemEntity(
    id: 'item-016',
    tripId: 'trip-001',
    day: 7,
    title: 'Return flight DPS → CGK',
    startTime: '16:00',
    endTime: '18:30',
    description: 'Garuda Indonesia GA-402. Airport 3 hours early for international departure.',
    locationName: 'Ngurah Rai International Airport, Denpasar',
    lat: -8.7481,
    lng: 115.1670,
    source: 'ai',
  ),
];

// Fallback empty itinerary for other trips
final mockTokyoItinerary = <ItineraryItemEntity>[
  ItineraryItemEntity(
    id: 'item-t01',
    tripId: 'trip-002',
    day: 1,
    title: 'Arrive Narita — check in',
    startTime: '14:00',
    endTime: null,
    description: 'Hotel check-in, grab a ramen near Shinjuku Station.',
    locationName: 'Shinjuku, Tokyo',
    lat: 35.6938,
    lng: 139.7036,
    source: 'ai',
  ),
  ItineraryItemEntity(
    id: 'item-t02',
    tripId: 'trip-002',
    day: 2,
    title: 'Tsukiji Outer Market breakfast',
    startTime: '08:00',
    endTime: '10:00',
    description: 'Fresh tuna sashimi and tamagoyaki for breakfast.',
    locationName: 'Tsukiji Outer Market, Chuo City',
    lat: 35.6654,
    lng: 139.7707,
    source: 'ai',
  ),
  ItineraryItemEntity(
    id: 'item-t03',
    tripId: 'trip-002',
    day: 2,
    title: 'Ichiran Ramen — solo booth experience',
    startTime: '12:30',
    endTime: '14:00',
    description: 'Order your broth intensity at the vending machine. Life-changing.',
    locationName: 'Ichiran Ramen Shibuya, Tokyo',
    lat: 35.6595,
    lng: 139.7004,
    source: 'ai',
  ),
];

final mockBandungItinerary = <ItineraryItemEntity>[
  ItineraryItemEntity(
    id: 'item-b01',
    tripId: 'trip-003',
    day: 1,
    title: 'Floating Market Lembang',
    startTime: '09:00',
    endTime: '12:00',
    description: 'Traditional market on the lake. Try the corn and warm bandrek.',
    locationName: 'Floating Market Lembang, West Bandung',
    lat: -6.8049,
    lng: 107.6180,
    source: 'ai',
  ),
  ItineraryItemEntity(
    id: 'item-b02',
    tripId: 'trip-003',
    day: 2,
    title: 'Kawah Putih crater',
    startTime: '08:00',
    endTime: '11:00',
    description: 'Turquoise sulphur lake inside a volcanic crater. Surreal landscape.',
    locationName: 'Kawah Putih, Ciwidey, Bandung',
    lat: -7.1660,
    lng: 107.4023,
    source: 'ai',
  ),
];

List<ItineraryItemEntity> mockItineraryFor(String tripId) {
  switch (tripId) {
    case 'trip-002':
      return mockTokyoItinerary;
    case 'trip-003':
      return mockBandungItinerary;
    default:
      return mockBaliItinerary;
  }
}

// ---------------------------------------------------------------------------
// Mock check-ins (Trip 1, Day 2)
// ---------------------------------------------------------------------------

final mockCheckinMonkeyForest = CheckinEntity(
  id: 'checkin-001',
  tripId: 'trip-001',
  itineraryItemId: 'item-005',
  kind: 'planned',
  capturedAt: DateTime(2024, 5, 10, 10, 15),
  lat: -8.5190,
  lng: 115.2617,
  memory: const CheckinMemoryEntity(
    note: 'The monkeys stole my sunglasses 😂 Absolutely wild place',
    mood: 'love',
    sharedWith: 'collaborators',
  ),
  logistics: const CheckinLogisticsEntity(
    cost: 80000,
    currency: 'IDR',
    notes: 'Entrance fee per person. Sarong rental included.',
  ),
  recommendation: null,
  media: [
    MediaEntity(
      id: 'media-001',
      r2Key: 'demo/monkey-1.jpg',
      mime: 'image/jpeg',
      url: 'https://picsum.photos/seed/monkey1/800/600',
      width: 800,
      height: 600,
    ),
    MediaEntity(
      id: 'media-002',
      r2Key: 'demo/monkey-2.jpg',
      mime: 'image/jpeg',
      url: 'https://picsum.photos/seed/monkey2/800/600',
      width: 800,
      height: 600,
    ),
    MediaEntity(
      id: 'media-003',
      r2Key: 'demo/monkey-3.jpg',
      mime: 'image/jpeg',
      url: 'https://picsum.photos/seed/monkey3/800/600',
      width: 800,
      height: 600,
    ),
  ],
);

final mockCheckinRiceTerraces = CheckinEntity(
  id: 'checkin-002',
  tripId: 'trip-001',
  itineraryItemId: 'item-006',
  kind: 'planned',
  capturedAt: DateTime(2024, 5, 10, 14, 0),
  lat: -8.4314,
  lng: 115.2778,
  memory: const CheckinMemoryEntity(
    note: 'The view from the top was insane. We stayed for 2 hours',
    mood: 'love',
    sharedWith: 'collaborators',
  ),
  logistics: const CheckinLogisticsEntity(
    cost: 50000,
    currency: 'IDR',
    notes: 'Entrance + swing ride.',
  ),
  recommendation: const CheckinRecommendationEntity(
    title: 'Go at 7am before the tour buses arrive',
    body: 'By 10am it is packed. The light is also better in the morning. Walk the full trail down to the bottom.',
    tags: ['photography', 'sunrise', 'must-do'],
    rating: 5,
  ),
  media: [
    MediaEntity(
      id: 'media-004',
      r2Key: 'demo/rice-1.jpg',
      mime: 'image/jpeg',
      url: 'https://picsum.photos/seed/rice1/800/600',
      width: 800,
      height: 600,
    ),
    MediaEntity(
      id: 'media-005',
      r2Key: 'demo/rice-2.jpg',
      mime: 'image/jpeg',
      url: 'https://picsum.photos/seed/rice2/800/600',
      width: 800,
      height: 600,
    ),
    MediaEntity(
      id: 'media-006',
      r2Key: 'demo/rice-3.jpg',
      mime: 'image/jpeg',
      url: 'https://picsum.photos/seed/rice3/800/600',
      width: 800,
      height: 600,
    ),
    MediaEntity(
      id: 'media-007',
      r2Key: 'demo/rice-4.jpg',
      mime: 'image/jpeg',
      url: 'https://picsum.photos/seed/rice4/800/600',
      width: 800,
      height: 600,
    ),
  ],
);

/// Lookup a mock check-in by id.
CheckinEntity mockCheckinById(String id) {
  switch (id) {
    case 'checkin-002':
      return mockCheckinRiceTerraces;
    default:
      return mockCheckinMonkeyForest;
  }
}

// ---------------------------------------------------------------------------
// Mock user search results
// ---------------------------------------------------------------------------

final mockSearchUsers = [
  const PublicProfileEntity(
    id: 'user-002',
    handle: 'firafira',
    displayName: 'Fira',
    avatarUrl: null,
  ),
  const PublicProfileEntity(
    id: 'user-003',
    handle: 'raka123',
    displayName: 'Raka',
    avatarUrl: null,
  ),
  const PublicProfileEntity(
    id: 'user-004',
    handle: 'mayaputri',
    displayName: 'Maya',
    avatarUrl: null,
  ),
];

/// Returns search results filtered by query (demo mode).
List<PublicProfileEntity> mockSearchUsersFor(String query) {
  final q = query.toLowerCase();
  return mockSearchUsers
      .where(
        (u) =>
            u.handle.contains(q) ||
            u.displayName.toLowerCase().contains(q),
      )
      .toList();
}
